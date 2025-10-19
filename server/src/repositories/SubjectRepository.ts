/**
 * Subject Repository
 * Following ARCHITECTURE.md - Repository Pattern
 */

import { mockDb } from '../database/MockDatabase';
import { Subject, CreateSubjectData, UpdateSubjectData } from '../models/Subject';
import { loggers } from '../config/logger';

export class SubjectRepository {
  async findAll(): Promise<Subject[]> {
    const startTime = Date.now();
    const subjects = mockDb.getAllSubjects();
    loggers.database('SELECT', 'subjects', Date.now() - startTime);
    return subjects;
  }

  async findById(id: number): Promise<Subject | null> {
    const startTime = Date.now();
    const subject = mockDb.getSubjectById(id);
    loggers.database('SELECT', 'subjects', Date.now() - startTime);
    return subject || null;
  }

  async findByName(name: string): Promise<Subject | null> {
    const startTime = Date.now();
    const subjects = mockDb.getAllSubjects();
    const subject = subjects.find(s => s.name.toLowerCase() === name.toLowerCase());
    loggers.database('SELECT', 'subjects', Date.now() - startTime);
    return subject || null;
  }

  async create(data: CreateSubjectData): Promise<Subject> {
    const startTime = Date.now();
    const subject = mockDb.createSubject(data);
    loggers.database('INSERT', 'subjects', Date.now() - startTime);
    loggers.info('Subject created', { subjectId: subject.id, name: subject.name });
    return subject;
  }

  async update(id: number, data: UpdateSubjectData): Promise<Subject | null> {
    const startTime = Date.now();
    const subject = mockDb.updateSubject(id, data);
    loggers.database('UPDATE', 'subjects', Date.now() - startTime);
    if (subject) {
      loggers.info('Subject updated', { subjectId: subject.id });
    }
    return subject || null;
  }

  async delete(id: number): Promise<boolean> {
    const startTime = Date.now();
    const deleted = mockDb.deleteSubject(id);
    loggers.database('DELETE', 'subjects', Date.now() - startTime);
    if (deleted) {
      loggers.info('Subject deleted', { subjectId: id });
    }
    return deleted;
  }

  async incrementQuestionCount(id: number, correct: boolean = false): Promise<void> {
    const subject = await this.findById(id);
    if (!subject) return;

    await this.update(id, {
      totalQuestions: subject.totalQuestions + 1,
      correctAnswers: correct ? subject.correctAnswers + 1 : subject.correctAnswers,
    });
  }
}

export const subjectRepository = new SubjectRepository();
