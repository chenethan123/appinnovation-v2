/**
 * Quiz Service
 * Following ARCHITECTURE.md - Service Layer Pattern
 */

import { v4 as uuidv4 } from 'uuid';
import { quizSessionRepository } from '../repositories/QuizSessionRepository';
import { questionRepository } from '../repositories/QuestionRepository';
import { subjectRepository } from '../repositories/SubjectRepository';
import { questionService } from './QuestionService';
import {
  StartQuizRequest,
  StartQuizResponse,
  SubmitAnswerRequest,
  SubmitAnswerResponse,
  CompleteQuizResponse,
  QuizAnswer,
} from '../models/QuizSession';
import { QuestionDifficulty } from '../models/Question';
import { loggers } from '../config/logger';

export class QuizService {
  /**
   * Start a new quiz session
   */
  async startQuiz(request: StartQuizRequest): Promise<StartQuizResponse> {
    // Verify subject exists
    const subject = await subjectRepository.findById(request.subjectId);
    if (!subject) {
      throw new Error(`Subject with ID ${request.subjectId} not found`);
    }

    // Validate number of questions
    if (request.numQuestions < 1 || request.numQuestions > 50) {
      throw new Error('Number of questions must be between 1 and 50');
    }

    loggers.info('Starting quiz session', {
      subjectId: request.subjectId,
      subjectName: subject.name,
      numQuestions: request.numQuestions,
      difficulty: request.difficulty,
    });

    // Get existing questions or generate new ones
    let questions = await questionRepository.getRandomQuestions(
      request.subjectId,
      request.numQuestions,
      request.difficulty
    );

    // If not enough questions exist, generate with AI
    if (questions.length < request.numQuestions) {
      const needed = request.numQuestions - questions.length;
      const difficulty: QuestionDifficulty = request.difficulty || 'medium';
      
      loggers.info(`Generating ${needed} additional questions with AI`);
      
      const generated = await questionService.generateQuestionsBatch(
        request.subjectId,
        needed,
        difficulty
      );
      
      questions = [...questions, ...generated.questions];
    }

    // Create quiz session
    const sessionId = uuidv4();
    const session = await quizSessionRepository.create({
      id: sessionId,
      subjectId: request.subjectId,
      totalQuestions: questions.length,
    });

    loggers.info('Quiz session created', {
      sessionId: session.id,
      subjectId: session.subjectId,
      totalQuestions: session.totalQuestions,
    });

    // Return session with questions (without correct answers)
    return {
      sessionId: session.id,
      subjectId: session.subjectId,
      questions: questions.map(q => ({
        id: q.id,
        questionText: q.questionText,
        options: q.options,
        difficulty: q.difficulty,
      })),
      startedAt: session.startedAt,
    };
  }

  /**
   * Submit an answer to a question
   */
  async submitAnswer(request: SubmitAnswerRequest): Promise<SubmitAnswerResponse> {
    // Verify session exists
    const session = await quizSessionRepository.findById(request.sessionId);
    if (!session) {
      throw new Error(`Quiz session ${request.sessionId} not found`);
    }

    // Check if session is already completed
    if (session.completedAt) {
      throw new Error('Quiz session is already completed');
    }

    // Get the question
    const question = await questionRepository.findById(request.questionId);
    if (!question) {
      throw new Error(`Question with ID ${request.questionId} not found`);
    }

    // Verify question belongs to same subject
    if (question.subjectId !== session.subjectId) {
      throw new Error('Question does not belong to this quiz session');
    }

    // Check if answer is valid
    if (!question.options.includes(request.userAnswer)) {
      throw new Error('Invalid answer: must be one of the question options');
    }

    // Determine if answer is correct
    const isCorrect = request.userAnswer === question.correctAnswer;

    // Save the answer
    const answer: QuizAnswer = {
      sessionId: request.sessionId,
      questionId: request.questionId,
      userAnswer: request.userAnswer,
      isCorrect,
      timeSpentSeconds: request.timeSpentSeconds || 0,
      answeredAt: new Date(),
    };

    await quizSessionRepository.createAnswer(answer);

    // Update session score if correct
    if (isCorrect) {
      await quizSessionRepository.update(request.sessionId, {
        score: session.score + 1,
      });
    }

    loggers.info('Answer submitted', {
      sessionId: request.sessionId,
      questionId: request.questionId,
      isCorrect,
      timeSpent: request.timeSpentSeconds,
    });

    // Return result with explanation
    return {
      isCorrect,
      correctAnswer: question.correctAnswer,
      explanation: question.explanation,
    };
  }

  /**
   * Complete a quiz session
   */
  async completeQuiz(sessionId: string): Promise<CompleteQuizResponse> {
    // Verify session exists
    const session = await quizSessionRepository.findById(sessionId);
    if (!session) {
      throw new Error(`Quiz session ${sessionId} not found`);
    }

    // Check if already completed
    if (session.completedAt) {
      throw new Error('Quiz session is already completed');
    }

    // Get all answers for this session
    const answers = await quizSessionRepository.getAnswers(sessionId);

    // Mark session as completed
    const completedAt = new Date();
    await quizSessionRepository.update(sessionId, {
      completedAt,
    });

    // Update subject statistics
    await subjectRepository.incrementQuestionCount(session.subjectId);
    for (const answer of answers) {
      if (answer.isCorrect) {
        await subjectRepository.incrementQuestionCount(session.subjectId, true);
      }
    }

    const accuracy = session.totalQuestions > 0
      ? Math.round((session.score / session.totalQuestions) * 100 * 10) / 10
      : 0;

    loggers.info('Quiz session completed', {
      sessionId: session.id,
      score: session.score,
      totalQuestions: session.totalQuestions,
      accuracy,
    });

    return {
      sessionId: session.id,
      score: session.score,
      totalQuestions: session.totalQuestions,
      accuracy,
      completedAt,
    };
  }

  /**
   * Get quiz session details
   */
  async getQuizSession(sessionId: string) {
    const session = await quizSessionRepository.findById(sessionId);
    if (!session) {
      throw new Error(`Quiz session ${sessionId} not found`);
    }

    const answers = await quizSessionRepository.getAnswers(sessionId);
    const subject = await subjectRepository.findById(session.subjectId);

    return {
      session,
      subject,
      answers,
      accuracy: session.totalQuestions > 0
        ? Math.round((session.score / session.totalQuestions) * 100 * 10) / 10
        : 0,
    };
  }
}

export const quizService = new QuizService();
