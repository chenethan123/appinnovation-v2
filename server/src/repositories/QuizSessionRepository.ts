/**
 * Quiz Session Repository
 * Following ARCHITECTURE.md - Repository Pattern
 */

import { mockDb } from '../database/MockDatabase';
import { QuizSession, QuizAnswer } from '../models/QuizSession';
import { loggers } from '../config/logger';

export class QuizSessionRepository {
  async findById(id: string): Promise<QuizSession | null> {
    const startTime = Date.now();
    const session = mockDb.getQuizSessionById(id);
    loggers.database('SELECT', 'quiz_sessions', Date.now() - startTime);
    return session || null;
  }

  async create(data: { id: string; subjectId: number; totalQuestions: number }): Promise<QuizSession> {
    const startTime = Date.now();
    const session = mockDb.createQuizSession(data);
    loggers.database('INSERT', 'quiz_sessions', Date.now() - startTime);
    loggers.info('Quiz session created', { sessionId: session.id, subjectId: session.subjectId });
    return session;
  }

  async update(id: string, data: Partial<QuizSession>): Promise<QuizSession | null> {
    const startTime = Date.now();
    const session = mockDb.updateQuizSession(id, data);
    loggers.database('UPDATE', 'quiz_sessions', Date.now() - startTime);
    if (session) {
      loggers.info('Quiz session updated', { sessionId: session.id });
    }
    return session || null;
  }

  async createAnswer(answer: QuizAnswer): Promise<void> {
    const startTime = Date.now();
    mockDb.createQuizAnswer(answer);
    loggers.database('INSERT', 'quiz_answers', Date.now() - startTime);
    loggers.info('Answer recorded', { 
      sessionId: answer.sessionId, 
      questionId: answer.questionId,
      isCorrect: answer.isCorrect,
    });
  }

  async getAnswers(sessionId: string): Promise<QuizAnswer[]> {
    const startTime = Date.now();
    const answers = mockDb.getQuizAnswers(sessionId);
    loggers.database('SELECT', 'quiz_answers', Date.now() - startTime);
    return answers;
  }
}

export const quizSessionRepository = new QuizSessionRepository();
