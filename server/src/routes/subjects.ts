/**
 * Subjects Routes
 * Following API_SPECIFICATION.md
 */

import { Router } from 'express';
import { subjectService } from '../services/SubjectService';
import { validateRequest, schemas } from '../middleware/validator';

const router = Router();

/**
 * GET /api/v1/subjects
 * Get all subjects
 */
router.get('/', async (_req, res, next) => {
  try {
    const subjects = await subjectService.getAllSubjects();
    res.json({
      data: subjects,
      pagination: {
        page: 1,
        page_size: subjects.length,
        total: subjects.length,
        total_pages: 1,
      },
    });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/subjects/:id
 * Get subject by ID
 */
router.get('/:id', validateRequest({ params: schemas.idParam }), async (req, res, next) => {
  try {
    const subject = await subjectService.getSubjectById(req.params.id as unknown as number);
    res.json(subject);
  } catch (error) {
    next(error);
  }
});

/**
 * POST /api/v1/subjects
 * Create a new subject
 */
router.post('/', validateRequest({ body: schemas.createSubject }), async (req, res, next) => {
  try {
    const subject = await subjectService.createSubject(req.body);
    res.status(201).json(subject);
  } catch (error) {
    next(error);
  }
});

/**
 * PATCH /api/v1/subjects/:id
 * Update a subject
 */
router.patch(
  '/:id',
  validateRequest({ params: schemas.idParam, body: schemas.updateSubject }),
  async (req, res, next) => {
    try {
      const subject = await subjectService.updateSubject(
        req.params.id as unknown as number,
        req.body
      );
      res.json(subject);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * DELETE /api/v1/subjects/:id
 * Delete a subject
 */
router.delete('/:id', validateRequest({ params: schemas.idParam }), async (req, res, next) => {
  try {
    await subjectService.deleteSubject(req.params.id as unknown as number);
    res.status(204).send();
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/v1/subjects/:id/analytics
 * Get subject analytics
 */
router.get('/:id/analytics', validateRequest({ params: schemas.idParam }), async (req, res, next) => {
  try {
    const analytics = await subjectService.getSubjectAnalytics(req.params.id as unknown as number);
    res.json(analytics);
  } catch (error) {
    next(error);
  }
});

export default router;
