/**
 * Health Check Routes
 * Following API_SPECIFICATION.md
 */

import { Router } from 'express';
import { config } from '../config/environment';

const router = Router();

/**
 * GET /api/v1/health
 * Health check endpoint
 */
router.get('/', (_req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    environment: config.server.nodeEnv,
    database: config.database.useMockData ? 'mock' : 'connected',
    openai: config.openai.apiKey ? 'configured' : 'not_configured',
  });
});

export default router;
