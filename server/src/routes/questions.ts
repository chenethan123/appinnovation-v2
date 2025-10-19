/**
 * Questions Routes
 * Following API_SPECIFICATION.md
 */

import { Router } from 'express';
import { questionService } from '../services/QuestionService';
import { validateRequest, schemas } from '../middleware/validator';
import { z } from 'zod';

const router = Router();

/**
 * GET /api/v1/questions
 * Get all questions (with optional filtering)
 */
router.get('/', async (req, res, next) => {
  try {
    const subjectId = req.query.subject_id ? parseInt(req.query.subject_id as string, 10) : undefined;
    const difficulty = req.query.difficulty as 'easy' | 'medium' | 'hard' | undefined;
    
    const questions = await questionService.getAllQuestions(subjectId, difficulty);
    res.json({
      data: questions,
      pagination: {
        page: 1,
        page_size: questions.length,
        total: questions.length,
        total_pages: 1,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/questions/:id
 * Get question by ID
 */
router.get('/:id', validateRequest({ params: schemas.idParam }), async (req, res, next) => {
  try {
    const question = await questionService.getQuestionById(req.params.id as unknown as number);
    res.json(question);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/questions
 * Create a new question manually
 */
router.post('/', validateRequest({ body: schemas.createQuestion }), async (req, res, next) => {
  try {
    const question = await questionService.createQuestion(req.body);
    res.status(201).json(question);
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/v1/questions/:id
 * Update a question
 */
router.patch('/:id', validateRequest({ params: schemas.idParam }), async (req, res, next) => {
  try {
    const question = await questionService.updateQuestion(
      req.params.id as unknown as number,
      req.body
    );
    res.json(question);
  } catch (error) {
    next(error);
  }
});

/**
 * DELETE /api/v1/questions/:id
 * Delete a question
 */
router.delete('/:id', validateRequest({ params: schemas.idParam }), async (req, res, next) => {
  try {
    await questionService.deleteQuestion(req.params.id as unknown as number);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

export default router;
