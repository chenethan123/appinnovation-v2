/**
 * OpenAI Service
 * Following ARCHITECTURE.md - AI Integration
 * REAL OpenAI integration with caching
 */

import OpenAI from 'openai';
import { z } from 'zod';
import { config } from '../config/environment';
import { loggers } from '../config/logger';
import { QuestionDifficulty } from '../models/Question';

// Zod schema for validating OpenAI response
const MCQSchema = z.object({
  questionText: z.string().min(10),
  options: z.array(z.string()).min(2).max(6),
  correctAnswer: z.string(),
  explanation: z.string().min(20),
  difficulty: z.enum(['easy', 'medium', 'hard']),
});

type MCQData = z.infer<typeof MCQSchema>;

// LRU Cache for reducing API costs
class LRUCache<K, V> {
  private cache = new Map<K, { value: V; timestamp: number }>();
  private maxSize: number;
  private ttlMs: number;

  constructor(maxSize: number, ttlSeconds: number) {
    this.maxSize = maxSize;
    this.ttlMs = ttlSeconds * 1000;
  }

  get(key: K): V | undefined {
    const item = this.cache.get(key);
    if (!item) {
      loggers.cache('miss', String(key));
      return undefined;
    }

    // Check if expired
    if (Date.now() - item.timestamp > this.ttlMs) {
      this.cache.delete(key);
      loggers.cache('miss', String(key));
      return undefined;
    }

    // Move to end (LRU)
    this.cache.delete(key);
    this.cache.set(key, item);
    loggers.cache('hit', String(key));
    return item.value;
  }

  set(key: K, value: V): void {
    // Remove oldest if at capacity
    if (this.cache.size >= this.maxSize) {
      const firstKey = this.cache.keys().next().value;
      this.cache.delete(firstKey);
    }

    this.cache.set(key, { value, timestamp: Date.now() });
    loggers.cache('set', String(key));
  }

  clear(): void {
    this.cache.clear();
  }
}

export class OpenAIService {
  private client: OpenAI;
  private cache: LRUCache<string, MCQData>;

  constructor() {
    // Initialize OpenAI client with YOUR API key
    this.client = new OpenAI({
      apiKey: config.openai.apiKey,
    });

    // Initialize cache
    this.cache = new LRUCache(
      config.cache.maxItems,
      config.cache.ttlSeconds
    );

    loggers.info('OpenAI service initialized', {
      model: config.openai.model,
      cacheSize: config.cache.maxItems,
      cacheTTL: config.cache.ttlSeconds,
    });
  }

  /**
   * Generate a single MCQ question using OpenAI
   */
  async generateQuestion(
    subjectName: string,
    difficulty: QuestionDifficulty,
    numChoices: number = 4
  ): Promise<MCQData & { generationTimeMs: number; cacheHit: boolean }> {
    const startTime = Date.now();

    // Generate cache key
    const cacheKey = `${subjectName}-${difficulty}-${numChoices}`;

    // Check cache first
    const cached = this.cache.get(cacheKey);
    if (cached) {
      const duration = Date.now() - startTime;
      loggers.apiCall('OpenAI', 'generateQuestion', duration, true);
      return {
        ...cached,
        generationTimeMs: duration,
        cacheHit: true,
      };
    }

    try {
      // Call OpenAI API
      const response = await this.client.chat.completions.create({
        model: config.openai.model,
        messages: [
          {
            role: 'system',
            content: `You are an expert educator creating high-quality multiple choice questions for ${subjectName}. 
Generate questions that are clear, educational, and accurate. 
Provide detailed explanations that help students understand the concept.`,
          },
          {
            role: 'user',
            content: `Create a ${difficulty} difficulty multiple choice question about ${subjectName}.

Requirements:
- Question should be clear and unambiguous
- Provide exactly ${numChoices} answer options
- Include one correct answer
- Provide a detailed explanation (2-3 sentences minimum)

Return ONLY a JSON object with this exact structure (no markdown, no code blocks):
{
  "questionText": "The question text",
  "options": ["Option 1", "Option 2", "Option 3", "Option 4"],
  "correctAnswer": "The correct option (must match one of the options exactly)",
  "explanation": "Detailed explanation of why this is correct",
  "difficulty": "${difficulty}"
}`,
          },
        ],
        temperature: config.openai.temperature,
        max_tokens: config.openai.maxTokens,
        response_format: { type: 'json_object' },
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No response from OpenAI');
      }

      // Parse and validate response
      const parsed = JSON.parse(content);
      const validated = MCQSchema.parse(parsed);

      // Verify correct answer is in options
      if (!validated.options.includes(validated.correctAnswer)) {
        throw new Error('Correct answer not in options list');
      }

      // Cache the result
      this.cache.set(cacheKey, validated);

      const duration = Date.now() - startTime;
      loggers.apiCall('OpenAI', 'generateQuestion', duration, false);

      return {
        ...validated,
        generationTimeMs: duration,
        cacheHit: false,
      };
    } catch (error) {
      const duration = Date.now() - startTime;
      loggers.error(error as Error, {
        operation: 'generateQuestion',
        subject: subjectName,
        difficulty,
      });

      // Rethrow with context
      if (error instanceof z.ZodError) {
        throw new Error(`Invalid AI response format: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * Generate multiple questions in batch
   */
  async generateQuestions(
    subjectName: string,
    difficulty: QuestionDifficulty,
    count: number,
    numChoices: number = 4
  ): Promise<Array<MCQData & { generationTimeMs: number; cacheHit: boolean }>> {
    const questions: Array<MCQData & { generationTimeMs: number; cacheHit: boolean }> = [];

    for (let i = 0; i < count; i++) {
      const question = await this.generateQuestion(subjectName, difficulty, numChoices);
      questions.push(question);
    }

    return questions;
  }

  /**
   * Clear the cache
   */
  clearCache(): void {
    this.cache.clear();
    loggers.info('OpenAI cache cleared');
  }
}

export const openAIService = new OpenAIService();
