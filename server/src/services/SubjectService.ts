/**
 * Subject Service
 * Following ARCHITECTURE.md - Service Layer Pattern
 */

import { subjectRepository } from '../repositories/SubjectRepository';
import { Subject, CreateSubjectData, UpdateSubjectData, toSubjectWithStats } from '../models/Subject';
import { questionRepository } from '../repositories/QuestionRepository';
import { loggers } from '../config/logger';

export class SubjectService {
  /**
   * Get all subjects with statistics
   */
  async getAllSubjects() {
    const subjects = await subjectRepository.findAll();
    return subjects.map(toSubjectWithStats);
  }

  /**
   * Get subject by ID with statistics
   */
  async getSubjectById(id: number) {
    const subject = await subjectRepository.findById(id);
    if (!subject) {
      throw new Error(`Subject with ID ${id} not found`);
    }
    return toSubjectWithStats(subject);
  }

  /**
   * Create a new subject
   */
  async createSubject(data: CreateSubjectData): Promise<Subject> {
    // Validate that name doesn't already exist
    const existing = await subjectRepository.findByName(data.name);
    if (existing) {
      throw new Error(`Subject with name "${data.name}" already exists`);
    }

    // Validate color format (hex color)
    if (!/^#[0-9A-F]{6}$/i.test(data.color)) {
      throw new Error('Color must be a valid hex color (e.g., #2196F3)');
    }

    return await subjectRepository.create(data);
  }

  /**
   * Update subject
   */
  async updateSubject(id: number, data: UpdateSubjectData): Promise<Subject> {
    // Check if subject exists
    const existing = await subjectRepository.findById(id);
    if (!existing) {
      throw new Error(`Subject with ID ${id} not found`);
    }

    // If updating name, check for duplicates
    if (data.name && data.name !== existing.name) {
      const duplicate = await subjectRepository.findByName(data.name);
      if (duplicate) {
        throw new Error(`Subject with name "${data.name}" already exists`);
      }
    }

    // Validate color if provided
    if (data.color && !/^#[0-9A-F]{6}$/i.test(data.color)) {
      throw new Error('Color must be a valid hex color (e.g., #2196F3)');
    }

    const updated = await subjectRepository.update(id, data);
    if (!updated) {
      throw new Error(`Failed to update subject ${id}`);
    }

    return updated;
  }

  /**
   * Delete subject
   */
  async deleteSubject(id: number): Promise<void> {
    const subject = await subjectRepository.findById(id);
    if (!subject) {
      throw new Error(`Subject with ID ${id} not found`);
    }

    // Check if subject has questions
    const questions = await questionRepository.findBySubjectId(id);
    if (questions.length > 0) {
      loggers.warn(`Deleting subject ${id} with ${questions.length} questions`);
      // Delete all questions first
      for (const question of questions) {
        await questionRepository.delete(question.id);
      }
    }

    const deleted = await subjectRepository.delete(id);
    if (!deleted) {
      throw new Error(`Failed to delete subject ${id}`);
    }
  }

  /**
   * Get subject analytics
   */
  async getSubjectAnalytics(id: number) {
    const subject = await this.getSubjectById(id);
    const questions = await questionRepository.findBySubjectId(id);

    return {
      subject: toSubjectWithStats(subject),
      totalQuestions: questions.length,
      questionsByDifficulty: {
        easy: questions.filter(q => q.difficulty === 'easy').length,
        medium: questions.filter(q => q.difficulty === 'medium').length,
        hard: questions.filter(q => q.difficulty === 'hard').length,
      },
      aiGeneratedQuestions: questions.filter(q => q.isFromAI).length,
      manualQuestions: questions.filter(q => !q.isFromAI).length,
    };
  }
}

export const subjectService = new SubjectService();
