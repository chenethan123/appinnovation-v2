/**
 * AI Generation Routes
 * Following API_SPECIFICATION.md
 * USES REAL OPENAI API
 */

import { Router } from 'express';
import { questionService } from '../services/QuestionService';
import { validateRequest, schemas } from '../middleware/validator';

const router = Router();

/**
 * POST /api/v1/ai/generate-question
 * Generate a single question using AI
 */
router.post('/generate-question', validateRequest({ body: schemas.generateQuestion }), async (req, res, next) => {
  try {
    const { subject_id, difficulty, num_choices } = req.body;
    
    const result = await questionService.generateQuestion(
      subject_id,
      difficulty,
      num_choices
    );

    res.json({
      id: result.question.id,
      subject_id: result.question.subjectId,
      question_text: result.question.questionText,
      options: result.question.options,
      correct_answer: result.question.correctAnswer,
      explanation: result.question.explanation,
      difficulty: result.question.difficulty,
      is_from_ai: result.question.isFromAI,
      generation_time_ms: result.generationTimeMs,
      cache_hit: result.cacheHit,
    });
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/ai/generate-questions-batch
 * Generate multiple questions using AI
 */
router.post('/generate-questions-batch', validateRequest({ body: schemas.generateQuestionsBatch }), async (req, res, next) => {
  try {
    const { subject_id, count, difficulty, num_choices } = req.body;
    
    const result = await questionService.generateQuestionsBatch(
      subject_id,
      count,
      difficulty,
      num_choices
    );

    res.json({
      questions: result.questions.map(q => ({
        id: q.id,
        subject_id: q.subjectId,
        question_text: q.questionText,
        options: q.options,
        correct_answer: q.correctAnswer,
        explanation: q.explanation,
        difficulty: q.difficulty,
        is_from_ai: q.isFromAI,
      })),
      count: result.questions.length,
      total_generation_time_ms: result.totalGenerationTimeMs,
      avg_generation_time_ms: Math.round(result.totalGenerationTimeMs / result.questions.length),
      cache_hits: result.cacheHits,
    });
  } catch (error) {
    next(error);
  }
});

export default router;
