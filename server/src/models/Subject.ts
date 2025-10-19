/**
 * Subject Model
 * Following ARCHITECTURE.md - Database Schema
 */

export interface Subject {
  id: number;
  name: string;
  description: string;
  color: string;
  isActive: boolean;
  totalQuestions: number;
  correctAnswers: number;
  createdAt: Date;
  updatedAt: Date;
}

export interface CreateSubjectData {
  name: string;
  description: string;
  color: string;
}

export interface UpdateSubjectData {
  name?: string;
  description?: string;
  color?: string;
  isActive?: boolean;
}

export interface SubjectWithStats extends Subject {
  accuracy: number;
  questionsAnswered: number;
}

// Helper function to calculate accuracy
export function calculateAccuracy(correctAnswers: number, totalQuestions: number): number {
  if (totalQuestions === 0) return 0;
  return Math.round((correctAnswers / totalQuestions) * 100 * 10) / 10;
}

// Helper function to convert Subject to SubjectWithStats
export function toSubjectWithStats(subject: Subject): SubjectWithStats {
  return {
    ...subject,
    accuracy: calculateAccuracy(subject.correctAnswers, subject.totalQuestions),
    questionsAnswered: subject.totalQuestions,
  };
}
