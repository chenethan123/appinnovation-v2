/**
 * Quiz Session Model
 * Following ARCHITECTURE.md - Database Schema
 */

export interface QuizSession {
  id: string;
  subjectId: number;
  startedAt: Date;
  completedAt: Date | null;
  score: number;
  totalQuestions: number;
}

export interface QuizAnswer {
  sessionId: string;
  questionId: number;
  userAnswer: string;
  isCorrect: boolean;
  timeSpentSeconds: number;
  answeredAt: Date;
}

export interface StartQuizRequest {
  subjectId: number;
  numQuestions: number;
  difficulty?: 'easy' | 'medium' | 'hard';
}

export interface StartQuizResponse {
  sessionId: string;
  subjectId: number;
  questions: Array<{
    id: number;
    questionText: string;
    options: string[];
    difficulty: string;
  }>;
  startedAt: Date;
}

export interface SubmitAnswerRequest {
  sessionId: string;
  questionId: number;
  userAnswer: string;
  timeSpentSeconds?: number;
}

export interface SubmitAnswerResponse {
  isCorrect: boolean;
  correctAnswer: string;
  explanation: string;
}

export interface CompleteQuizRequest {
  sessionId: string;
}

export interface CompleteQuizResponse {
  sessionId: string;
  score: number;
  totalQuestions: number;
  accuracy: number;
  completedAt: Date;
}
