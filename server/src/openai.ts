import OpenAI from "openai";
import { z } from "zod";
import { v4 as uuidv4 } from "uuid";

// Initialize OpenAI client
export const openai = new OpenAI({ 
  apiKey: process.env.OPENAI_API_KEY 
});

// Model configuration - using gpt-4-turbo-preview as it's the current recommended model
export const MODEL = "gpt-4-turbo-preview";

// Zod schemas for validation
const letterEnum = z.enum(['A', 'B', 'C', 'D', 'E']);
export type Letter = z.infer<typeof letterEnum>;

const OptionSchema = z.object({
  letter: letterEnum,
  text: z.string().min(1, "Option text cannot be empty")
});

export const MCQSchema = z.object({
  id: z.string().optional(),
  subject: z.string(),
  stem: z.string().min(8, "Question stem must be at least 8 characters"),
  options: z.array(OptionSchema).min(2).max(5),
  correct_option: letterEnum,
  explanation_correct: z.string().min(3, "Correct explanation required"),
  explanations_by_option: z.record(letterEnum, z.string().min(3)),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  source_hint: z.string().optional()
}).refine(
  (data) => {
    const letters = new Set(data.options.map(opt => opt.letter));
    return letters.has(data.correct_option);
  },
  { message: "correct_option must exist in options array" }
).refine(
  (data) => {
    const letters = data.options.map(opt => opt.letter);
    return new Set(letters).size === letters.length;
  },
  { message: "options must have unique letters" }
);

export type MCQ = z.infer<typeof MCQSchema>;

// System prompt for OpenAI
const SYSTEM_PROMPT = `You generate rigorous, unambiguous multiple-choice questions. Output ONLY valid JSON matching the MCQ schema. Explanations must be concise, self-contained, and tailored to each option (distinct reason for each). Do not include prose outside JSON.`;

// Generate user prompt template
function getUserPrompt(subject: string, choices: number): string {
  return `
Subject: ${subject}
Choices: ${choices}

Task: Create ONE MCQ that tests a granular, high-yield concept for this subject.
Constraints:
- Options must be plausible and mutually exclusive.
- Exactly one correct option.
- Provide a short topic tag in "source_hint".
- Difficulty: default medium; vary occasionally.
- In "explanations_by_option", explain briefly why EACH option is right or wrong (different rationale per option).
- Keep total reading time ~45–60 seconds.

Return JSON ONLY (MCQ schema).
  `.trim();
}

/**
 * Generate a single MCQ for the given subject
 */
export async function generateMcq(
  subject: string, 
  choices: number = 4
): Promise<MCQ> {
  if (!process.env.OPENAI_API_KEY) {
    throw new Error("OPENAI_API_KEY not configured");
  }

  if (choices < 2 || choices > 5) {
    throw new Error("Choices must be between 2 and 5");
  }

  if (!subject || subject.trim().length === 0) {
    throw new Error("Subject cannot be empty");
  }

  try {
    const response = await openai.chat.completions.create({
      model: MODEL,
      messages: [
        { role: "system", content: SYSTEM_PROMPT },
        { role: "user", content: getUserPrompt(subject, choices) }
      ],
      response_format: { type: "json_object" },
      temperature: 0.7,
      max_tokens: 2000
    });

    const rawContent = response.choices[0]?.message?.content ?? "{}";
    
    // Parse and validate the response
    let parsed;
    try {
      parsed = JSON.parse(rawContent);
    } catch (parseError) {
      console.error("OpenAI returned invalid JSON");
      throw new Error("OpenAI returned invalid JSON");
    }

    // Validate against schema
    const validated = MCQSchema.parse(parsed);

    // Ensure ID is set
    if (!validated.id) {
      validated.id = uuidv4();
    }

    // Ensure subject matches request
    validated.subject = subject;

    return validated;
  } catch (error) {
    if (error instanceof z.ZodError) {
      console.error("MCQ validation failed:", error.errors);
      throw new Error("Generated MCQ failed validation");
    }
    
    if (error instanceof OpenAI.APIError) {
      console.error("OpenAI API error:", error.message);
      throw new Error(`OpenAI API error: ${error.message}`);
    }

    throw error;
  }
}

/**
 * Generate multiple MCQs for batch pre-warming
 */
export async function generateMcqBatch(
  subject: string,
  choices: number = 4,
  count: number = 5
): Promise<MCQ[]> {
  if (count < 1 || count > 20) {
    throw new Error("Count must be between 1 and 20");
  }

  const promises: Promise<MCQ>[] = [];
  
  for (let i = 0; i < count; i++) {
    promises.push(generateMcq(subject, choices));
  }

  // Execute all requests concurrently
  const results = await Promise.allSettled(promises);
  
  // Filter successful results
  const mcqs: MCQ[] = [];
  for (const result of results) {
    if (result.status === 'fulfilled') {
      mcqs.push(result.value);
    } else {
      console.error("Batch generation error:", result.reason);
    }
  }

  if (mcqs.length === 0) {
    throw new Error("All batch generations failed");
  }

  return mcqs;
}
