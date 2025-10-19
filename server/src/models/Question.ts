/**
 * Question Model
 * Following ARCHITECTURE.md - Database Schema
 */

export type QuestionDifficulty = 'easy' | 'medium' | 'hard';

export interface Question {
  id: number;
  subjectId: number;
  questionText: string;
  options: string[];
  correctAnswer: string;
  explanation: string;
  difficulty: QuestionDifficulty;
  isFromAI: boolean;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateQuestionData {
  subjectId: number;
  questionText: string;
  options: string[];
  correctAnswer: string;
  explanation: string;
  difficulty: QuestionDifficulty;
  isFromAI: boolean;
}

export interface UpdateQuestionData {
  questionText?: string;
  options?: string[];
  correctAnswer?: string;
  explanation?: string;
  difficulty?: QuestionDifficulty;
}

export interface AIQuestionRequest {
  subjectId: number;
  difficulty: QuestionDifficulty;
  numChoices?: number;
}

export interface AIQuestionResponse {
  question: Question;
  generationTimeMs: number;
  cacheHit: boolean;
}
