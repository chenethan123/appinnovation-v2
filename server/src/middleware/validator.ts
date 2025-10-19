/**
 * Request Validation Middleware
 * Following ARCHITECTURE.md - Input Validation with Zod
 */

import { Request, Response, NextFunction } from 'express';
import { z, ZodSchema } from 'zod';

export function validateRequest(schema: {
  body?: ZodSchema;
  query?: ZodSchema;
  params?: ZodSchema;
}) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    try {
      if (schema.body) {
        req.body = schema.body.parse(req.body);
      }
      if (schema.query) {
        req.query = schema.query.parse(req.query) as typeof req.query;
      }
      if (schema.params) {
        req.params = schema.params.parse(req.params);
      }
      next();
    } catch (error) {
      next(error);
    }
  };
}

// Common validation schemas
export const schemas = {
  // Pagination
  pagination: z.object({
    page: z.string().optional().transform(val => val ? parseInt(val, 10) : 1),
    page_size: z.string().optional().transform(val => val ? parseInt(val, 10) : 20),
  }),

  // ID parameter
  idParam: z.object({
    id: z.string().transform(val => parseInt(val, 10)),
  }),

  // Subject creation
  createSubject: z.object({
    name: z.string().min(1).max(100),
    description: z.string().min(1).max(500),
    color: z.string().regex(/^#[0-9A-F]{6}$/i, 'Must be a valid hex color'),
  }),

  // Subject update
  updateSubject: z.object({
    name: z.string().min(1).max(100).optional(),
    description: z.string().min(1).max(500).optional(),
    color: z.string().regex(/^#[0-9A-F]{6}$/i).optional(),
    isActive: z.boolean().optional(),
  }),

  // Question creation
  createQuestion: z.object({
    subjectId: z.number().int().positive(),
    questionText: z.string().min(10).max(1000),
    options: z.array(z.string()).min(2).max(6),
    correctAnswer: z.string(),
    explanation: z.string().min(20).max(2000),
    difficulty: z.enum(['easy', 'medium', 'hard']),
    isFromAI: z.boolean().default(false),
  }),

  // AI question generation
  generateQuestion: z.object({
    subject_id: z.number().int().positive(),
    difficulty: z.enum(['easy', 'medium', 'hard']).default('medium'),
    num_choices: z.number().int().min(2).max(6).default(4),
  }),

  // AI batch generation
  generateQuestionsBatch: z.object({
    subject_id: z.number().int().positive(),
    count: z.number().int().min(1).max(20),
    difficulty: z.enum(['easy', 'medium', 'hard']).default('medium'),
    num_choices: z.number().int().min(2).max(6).default(4),
  }),

  // Start quiz
  startQuiz: z.object({
    subject_id: z.number().int().positive(),
    num_questions: z.number().int().min(1).max(50),
    difficulty: z.enum(['easy', 'medium', 'hard']).optional(),
  }),

  // Submit answer
  submitAnswer: z.object({
    session_id: z.string().uuid(),
    question_id: z.number().int().positive(),
    user_answer: z.string(),
    time_spent_seconds: z.number().int().min(0).optional(),
  }),

  // Complete quiz
  completeQuiz: z.object({
    session_id: z.string().uuid(),
  }),
};
