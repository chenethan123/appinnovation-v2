/**
 * Logger Configuration
 * Following ARCHITECTURE.md - Structured Logging with Pino
 */

import pino from 'pino';
import { config } from './environment';

// Create logger instance
export const logger = pino({
  level: config.logging.level,
  transport: config.server.isDevelopment
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'HH:MM:ss',
          ignore: 'pid,hostname',
          singleLine: false,
        },
      }
    : undefined,
});

// Helper functions for structured logging
export const loggers = {
  /**
   * Log HTTP request
   */
  request: (method: string, path: string, statusCode: number, duration: number) => {
    logger.info({
      type: 'http_request',
      method,
      path,
      statusCode,
      duration,
    }, `${method} ${path} - ${statusCode} (${duration}ms)`);
  },

  /**
   * Log API call to external service
   */
  apiCall: (service: string, operation: string, duration: number, cached?: boolean) => {
    logger.info({
      type: 'api_call',
      service,
      operation,
      duration,
      cached,
    }, `${service}.${operation} (${duration}ms)${cached ? ' [CACHED]' : ''}`);
  },

  /**
   * Log database operation
   */
  database: (operation: string, table: string, duration: number) => {
    logger.debug({
      type: 'database',
      operation,
      table,
      duration,
    }, `DB ${operation} on ${table} (${duration}ms)`);
  },

  /**
   * Log error with context
   */
  error: (error: Error, context?: Record<string, unknown>) => {
    logger.error({
      type: 'error',
      error: {
        message: error.message,
        stack: error.stack,
        name: error.name,
      },
      ...context,
    }, error.message);
  },

  /**
   * Log warning
   */
  warn: (message: string, context?: Record<string, unknown>) => {
    logger.warn({
      type: 'warning',
      ...context,
    }, message);
  },

  /**
   * Log info
   */
  info: (message: string, context?: Record<string, unknown>) => {
    logger.info({
      type: 'info',
      ...context,
    }, message);
  },

  /**
   * Log cache operation
   */
  cache: (operation: 'hit' | 'miss' | 'set', key: string) => {
    logger.debug({
      type: 'cache',
      operation,
      key,
    }, `Cache ${operation.toUpperCase()}: ${key}`);
  },
};

export default logger;
