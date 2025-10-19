/**
 * Mock In-Memory Database
 * Following ARCHITECTURE.md - Data Layer
 * Allows testing without a real database
 */

import { Subject } from '../models/Subject';
import { Question } from '../models/Question';
import { QuizSession, QuizAnswer } from '../models/QuizSession';

class MockDatabase {
  private subjects: Map<number, Subject> = new Map();
  private questions: Map<number, Question> = new Map();
  private quizSessions: Map<string, QuizSession> = new Map();
  private quizAnswers: Map<string, QuizAnswer[]> = new Map();
  
  private subjectIdCounter = 1;
  private questionIdCounter = 1;

  constructor() {
    this.seedInitialData();
  }

  // ==================== SUBJECTS ====================
  
  getAllSubjects(): Subject[] {
    return Array.from(this.subjects.values());
  }

  getSubjectById(id: number): Subject | undefined {
    return this.subjects.get(id);
  }

  createSubject(data: { name: string; description: string; color: string }): Subject {
    const subject: Subject = {
      id: this.subjectIdCounter++,
      name: data.name,
      description: data.description,
      color: data.color,
      isActive: true,
      totalQuestions: 0,
      correctAnswers: 0,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.subjects.set(subject.id, subject);
    return subject;
  }

  updateSubject(id: number, data: Partial<Subject>): Subject | undefined {
    const subject = this.subjects.get(id);
    if (!subject) return undefined;

    const updated = {
      ...subject,
      ...data,
      updatedAt: new Date(),
    };
    this.subjects.set(id, updated);
    return updated;
  }

  deleteSubject(id: number): boolean {
    return this.subjects.delete(id);
  }

  // ==================== QUESTIONS ====================
  
  getAllQuestions(): Question[] {
    return Array.from(this.questions.values());
  }

  getQuestionById(id: number): Question | undefined {
    return this.questions.get(id);
  }

  getQuestionsBySubjectId(subjectId: number): Question[] {
    return Array.from(this.questions.values())
      .filter(q => q.subjectId === subjectId);
  }

  createQuestion(data: {
    subjectId: number;
    questionText: string;
    options: string[];
    correctAnswer: string;
    explanation: string;
    difficulty: 'easy' | 'medium' | 'hard';
    isFromAI: boolean;
  }): Question {
    const question: Question = {
      id: this.questionIdCounter++,
      subjectId: data.subjectId,
      questionText: data.questionText,
      options: data.options,
      correctAnswer: data.correctAnswer,
      explanation: data.explanation,
      difficulty: data.difficulty,
      isFromAI: data.isFromAI,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    this.questions.set(question.id, question);
    return question;
  }

  updateQuestion(id: number, data: Partial<Question>): Question | undefined {
    const question = this.questions.get(id);
    if (!question) return undefined;

    const updated = {
      ...question,
      ...data,
      updatedAt: new Date(),
    };
    this.questions.set(id, updated);
    return updated;
  }

  deleteQuestion(id: number): boolean {
    return this.questions.delete(id);
  }

  // ==================== QUIZ SESSIONS ====================
  
  getQuizSessionById(id: string): QuizSession | undefined {
    return this.quizSessions.get(id);
  }

  createQuizSession(data: {
    id: string;
    subjectId: number;
    totalQuestions: number;
  }): QuizSession {
    const session: QuizSession = {
      id: data.id,
      subjectId: data.subjectId,
      startedAt: new Date(),
      completedAt: null,
      score: 0,
      totalQuestions: data.totalQuestions,
    };
    this.quizSessions.set(session.id, session);
    this.quizAnswers.set(session.id, []);
    return session;
  }

  updateQuizSession(id: string, data: Partial<QuizSession>): QuizSession | undefined {
    const session = this.quizSessions.get(id);
    if (!session) return undefined;

    const updated = { ...session, ...data };
    this.quizSessions.set(id, updated);
    return updated;
  }

  // ==================== QUIZ ANSWERS ====================
  
  createQuizAnswer(answer: QuizAnswer): void {
    const answers = this.quizAnswers.get(answer.sessionId) || [];
    answers.push(answer);
    this.quizAnswers.set(answer.sessionId, answers);
  }

  getQuizAnswers(sessionId: string): QuizAnswer[] {
    return this.quizAnswers.get(sessionId) || [];
  }

  // ==================== UTILITIES ====================
  
  reset(): void {
    this.subjects.clear();
    this.questions.clear();
    this.quizSessions.clear();
    this.quizAnswers.clear();
    this.subjectIdCounter = 1;
    this.questionIdCounter = 1;
    this.seedInitialData();
  }

  private seedInitialData(): void {
    // Seed some initial subjects
    const physics = this.createSubject({
      name: 'AP Physics 1',
      description: 'Algebra-based introductory college-level physics',
      color: '#2196F3',
    });

    const calculus = this.createSubject({
      name: 'AP Calculus BC',
      description: 'Advanced placement calculus',
      color: '#4CAF50',
    });

    const chemistry = this.createSubject({
      name: 'AP Chemistry',
      description: 'College-level chemistry course',
      color: '#FF9800',
    });

    // Seed some sample questions for physics
    this.createQuestion({
      subjectId: physics.id,
      questionText: 'What is the SI unit of force?',
      options: ['Newton', 'Joule', 'Watt', 'Pascal'],
      correctAnswer: 'Newton',
      explanation: 'The Newton (N) is the SI unit of force, defined as kg⋅m/s²',
      difficulty: 'easy',
      isFromAI: false,
    });

    this.createQuestion({
      subjectId: physics.id,
      questionText: 'A 5kg object accelerates at 2 m/s². What is the net force?',
      options: ['7 N', '10 N', '2.5 N', '3 N'],
      correctAnswer: '10 N',
      explanation: 'Using F = ma: F = 5kg × 2m/s² = 10N',
      difficulty: 'medium',
      isFromAI: false,
    });

    // Seed sample questions for calculus
    this.createQuestion({
      subjectId: calculus.id,
      questionText: 'What is the derivative of x²?',
      options: ['x', '2x', 'x²/2', '2'],
      correctAnswer: '2x',
      explanation: 'Using the power rule: d/dx(x²) = 2x',
      difficulty: 'easy',
      isFromAI: false,
    });

    console.log('✅ Mock database seeded with initial data');
    console.log(`   - ${this.subjects.size} subjects`);
    console.log(`   - ${this.questions.size} questions`);
  }
}

// Singleton instance
export const mockDb = new MockDatabase();
