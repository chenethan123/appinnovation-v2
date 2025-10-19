/**
 * Question Service
 * Following ARCHITECTURE.md - Service Layer Pattern
 */

import { questionRepository } from '../repositories/QuestionRepository';
import { subjectRepository } from '../repositories/SubjectRepository';
import { openAIService } from './OpenAIService';
import { Question, CreateQuestionData, QuestionDifficulty } from '../models/Question';
import { loggers } from '../config/logger';

export class QuestionService {
  /**
   * Get all questions
   */
  async getAllQuestions(subjectId?: number, difficulty?: QuestionDifficulty): Promise<Question[]> {
    if (subjectId) {
      return await questionRepository.findBySubjectId(subjectId, difficulty);
    }
    return await questionRepository.findAll();
  }

  /**
   * Get question by ID
   */
  async getQuestionById(id: number): Promise<Question> {
    const question = await questionRepository.findById(id);
    if (!question) {
      throw new Error(`Question with ID ${id} not found`);
    }
    return question;
  }

  /**
   * Create a new question manually
   */
  async createQuestion(data: CreateQuestionData): Promise<Question> {
    // Verify subject exists
    const subject = await subjectRepository.findById(data.subjectId);
    if (!subject) {
      throw new Error(`Subject with ID ${data.subjectId} not found`);
    }

    // Validate options
    if (data.options.length < 2) {
      throw new Error('Question must have at least 2 options');
    }

    if (data.options.length > 6) {
      throw new Error('Question cannot have more than 6 options');
    }

    // Validate correct answer is in options
    if (!data.options.includes(data.correctAnswer)) {
      throw new Error('Correct answer must be one of the provided options');
    }

    return await questionRepository.create(data);
  }

  /**
   * Generate question using AI
   */
  async generateQuestion(
    subjectId: number,
    difficulty: QuestionDifficulty,
    numChoices: number = 4
  ): Promise<{ question: Question; generationTimeMs: number; cacheHit: boolean }> {
    // Verify subject exists
    const subject = await subjectRepository.findById(subjectId);
    if (!subject) {
      throw new Error(`Subject with ID ${subjectId} not found`);
    }

    loggers.info('Generating AI question', { 
      subjectId, 
      subjectName: subject.name,
      difficulty,
      numChoices,
    });

    // Generate using OpenAI
    const aiResult = await openAIService.generateQuestion(
      subject.name,
      difficulty,
      numChoices
    );

    // Save to database
    const question = await questionRepository.create({
      subjectId,
      questionText: aiResult.questionText,
      options: aiResult.options,
      correctAnswer: aiResult.correctAnswer,
      explanation: aiResult.explanation,
      difficulty: aiResult.difficulty,
      isFromAI: true,
    });

    loggers.info('AI question generated and saved', {
      questionId: question.id,
      subjectId,
      difficulty,
      generationTimeMs: aiResult.generationTimeMs,
      cacheHit: aiResult.cacheHit,
    });

    return {
      question,
      generationTimeMs: aiResult.generationTimeMs,
      cacheHit: aiResult.cacheHit,
    };
  }

  /**
   * Generate multiple questions using AI
   */
  async generateQuestionsBatch(
    subjectId: number,
    count: number,
    difficulty: QuestionDifficulty,
    numChoices: number = 4
  ): Promise<{
    questions: Question[];
    totalGenerationTimeMs: number;
    cacheHits: number;
  }> {
    // Verify subject exists
    const subject = await subjectRepository.findById(subjectId);
    if (!subject) {
      throw new Error(`Subject with ID ${subjectId} not found`);
    }

    // Validate count
    if (count < 1 || count > 20) {
      throw new Error('Batch count must be between 1 and 20');
    }

    loggers.info('Generating AI question batch', { 
      subjectId, 
      subjectName: subject.name,
      count,
      difficulty,
      numChoices,
    });

    const questions: Question[] = [];
    let totalGenerationTimeMs = 0;
    let cacheHits = 0;

    for (let i = 0; i < count; i++) {
      const result = await this.generateQuestion(subjectId, difficulty, numChoices);
      questions.push(result.question);
      totalGenerationTimeMs += result.generationTimeMs;
      if (result.cacheHit) cacheHits++;
    }

    loggers.info('AI question batch completed', {
      subjectId,
      count: questions.length,
      totalGenerationTimeMs,
      cacheHits,
      avgTimeMs: Math.round(totalGenerationTimeMs / count),
    });

    return {
      questions,
      totalGenerationTimeMs,
      cacheHits,
    };
  }

  /**
   * Update question
   */
  async updateQuestion(id: number, data: Partial<CreateQuestionData>): Promise<Question> {
    const existing = await questionRepository.findById(id);
    if (!existing) {
      throw new Error(`Question with ID ${id} not found`);
    }

    // Validate options if provided
    if (data.options) {
      if (data.options.length < 2 || data.options.length > 6) {
        throw new Error('Question must have between 2 and 6 options');
      }

      // Validate correct answer is in new options
      const correctAnswer = data.correctAnswer || existing.correctAnswer;
      if (!data.options.includes(correctAnswer)) {
        throw new Error('Correct answer must be one of the provided options');
      }
    }

    const updated = await questionRepository.update(id, data);
    if (!updated) {
      throw new Error(`Failed to update question ${id}`);
    }

    return updated;
  }

  /**
   * Delete question
   */
  async deleteQuestion(id: number): Promise<void> {
    const question = await questionRepository.findById(id);
    if (!question) {
      throw new Error(`Question with ID ${id} not found`);
    }

    const deleted = await questionRepository.delete(id);
    if (!deleted) {
      throw new Error(`Failed to delete question ${id}`);
    }
  }
}

export const questionService = new QuestionService();
