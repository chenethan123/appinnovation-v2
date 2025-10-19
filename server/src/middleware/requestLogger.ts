/**
 * Request Logging Middleware
 * Following ARCHITECTURE.md - Observability
 */

import { Request, Response, NextFunction } from 'express';
import { loggers } from '../config/logger';

export function requestLogger(req: Request, res: Response, next: NextFunction): void {
  const startTime = Date.now();

  // Log when response finishes
  res.on('finish', () => {
    const duration = Date.now() - startTime;
    loggers.request(req.method, req.path, res.statusCode, duration);
  });

  next();
}
