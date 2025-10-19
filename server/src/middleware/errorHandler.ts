/**
 * Error Handling Middleware
 * Following ARCHITECTURE.md - Error Handling
 */

import { Request, Response, NextFunction } from 'express';
import { ZodError } from 'zod';
import { loggers } from '../config/logger';

export class ApiError extends Error {
  constructor(
    public statusCode: number,
    public message: string,
    public details?: unknown
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export function errorHandler(
  error: Error,
  req: Request,
  res: Response,
  _next: NextFunction
): void {
  // Log the error
  loggers.error(error, {
    path: req.path,
    method: req.method,
    body: req.body,
  });

  // Handle Zod validation errors
  if (error instanceof ZodError) {
    res.status(400).json({
      error: 'validation_error',
      message: 'Invalid request data',
      details: error.errors.map(e => ({
        path: e.path.join('.'),
        message: e.message,
      })),
      timestamp: new Date().toISOString(),
      path: req.path,
    });
    return;
  }

  // Handle custom API errors
  if (error instanceof ApiError) {
    res.status(error.statusCode).json({
      error: error.message.toLowerCase().replace(/\s+/g, '_'),
      message: error.message,
      details: error.details,
      timestamp: new Date().toISOString(),
      path: req.path,
    });
    return;
  }

  // Handle generic errors
  const statusCode = 500;
  const message = error.message || 'Internal server error';

  res.status(statusCode).json({
    error: 'internal_server_error',
    message,
    timestamp: new Date().toISOString(),
    path: req.path,
  });
}
