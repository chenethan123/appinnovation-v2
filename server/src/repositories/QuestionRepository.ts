/**
 * Question Repository
 * Following ARCHITECTURE.md - Repository Pattern
 */

import { mockDb } from '../database/MockDatabase';
import { Question, CreateQuestionData, UpdateQuestionData, QuestionDifficulty } from '../models/Question';
import { loggers } from '../config/logger';

export class QuestionRepository {
  async findAll(): Promise<Question[]> {
    const startTime = Date.now();
    const questions = mockDb.getAllQuestions();
    loggers.database('SELECT', 'questions', Date.now() - startTime);
    return questions;
  }

  async findById(id: number): Promise<Question | null> {
    const startTime = Date.now();
    const question = mockDb.getQuestionById(id);
    loggers.database('SELECT', 'questions', Date.now() - startTime);
    return question || null;
  }

  async findBySubjectId(subjectId: number, difficulty?: QuestionDifficulty): Promise<Question[]> {
    const startTime = Date.now();
    let questions = mockDb.getQuestionsBySubjectId(subjectId);
    
    if (difficulty) {
      questions = questions.filter(q => q.difficulty === difficulty);
    }
    
    loggers.database('SELECT', 'questions', Date.now() - startTime);
    return questions;
  }

  async create(data: CreateQuestionData): Promise<Question> {
    const startTime = Date.now();
    const question = mockDb.createQuestion(data);
    loggers.database('INSERT', 'questions', Date.now() - startTime);
    loggers.info('Question created', { 
      questionId: question.id, 
      subjectId: question.subjectId,
      isFromAI: question.isFromAI,
    });
    return question;
  }

  async update(id: number, data: UpdateQuestionData): Promise<Question | null> {
    const startTime = Date.now();
    const question = mockDb.updateQuestion(id, data);
    loggers.database('UPDATE', 'questions', Date.now() - startTime);
    if (question) {
      loggers.info('Question updated', { questionId: question.id });
    }
    return question || null;
  }

  async delete(id: number): Promise<boolean> {
    const startTime = Date.now();
    const deleted = mockDb.deleteQuestion(id);
    loggers.database('DELETE', 'questions', Date.now() - startTime);
    if (deleted) {
      loggers.info('Question deleted', { questionId: id });
    }
    return deleted;
  }

  async getRandomQuestions(subjectId: number, count: number, difficulty?: QuestionDifficulty): Promise<Question[]> {
    const questions = await this.findBySubjectId(subjectId, difficulty);
    
    // Shuffle and take 'count' questions
    const shuffled = questions.sort(() => Math.random() - 0.5);
    return shuffled.slice(0, Math.min(count, shuffled.length));
  }
}

export const questionRepository = new QuestionRepository();
