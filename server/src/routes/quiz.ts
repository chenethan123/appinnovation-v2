/**
 * Quiz Routes
 * Following API_SPECIFICATION.md
 */

import { Router } from 'express';
import { quizService } from '../services/QuizService';
import { validateRequest, schemas } from '../middleware/validator';

const router = Router();

/**
 * POST /api/v1/quiz/start
 * Start a new quiz session
 */
router.post('/start', validateRequest({ body: schemas.startQuiz }), async (req, res, next) => {
  try {
    const { subject_id, num_questions, difficulty } = req.body;
    
    const result = await quizService.startQuiz({
      subjectId: subject_id,
      numQuestions: num_questions,
      difficulty,
    });

    res.json({
      session_id: result.sessionId,
      subject_id: result.subjectId,
      questions: result.questions,
      started_at: result.startedAt.toISOString(),
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/quiz/answer
 * Submit an answer to a question
 */
router.post('/answer', validateRequest({ body: schemas.submitAnswer }), async (req, res, next) => {
  try {
    const { session_id, question_id, user_answer, time_spent_seconds } = req.body;
    
    const result = await quizService.submitAnswer({
      sessionId: session_id,
      questionId: question_id,
      userAnswer: user_answer,
      timeSpentSeconds: time_spent_seconds,
    });

    res.json({
      is_correct: result.isCorrect,
      correct_answer: result.correctAnswer,
      explanation: result.explanation,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/quiz/complete
 * Complete a quiz session
 */
router.post('/complete', validateRequest({ body: schemas.completeQuiz }), async (req, res, next) => {
  try {
    const { session_id } = req.body;
    
    const result = await quizService.completeQuiz(session_id);

    res.json({
      session_id: result.sessionId,
      score: result.score,
      total_questions: result.totalQuestions,
      accuracy: result.accuracy,
      completed_at: result.completedAt.toISOString(),
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/quiz/:sessionId
 * Get quiz session details
 */
router.get('/:sessionId', async (req, res, next) => {
  try {
    const result = await quizService.getQuizSession(req.params.sessionId);

    res.json({
      session: {
        id: result.session.id,
        subject_id: result.session.subjectId,
        started_at: result.session.startedAt.toISOString(),
        completed_at: result.session.completedAt?.toISOString() || null,
        score: result.session.score,
        total_questions: result.session.totalQuestions,
      },
      subject: result.subject,
      answers: result.answers,
      accuracy: result.accuracy,
    });
  } catch (error) {
    next(error);
  }
});

export default router;
