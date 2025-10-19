/**
 * FormulaQuizzer Server
 * Following ARCHITECTURE.md - Express Application Structure
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { config } from './config/environment';
import { logger, loggers } from './config/logger';
import { requestLogger } from './middleware/requestLogger';
import { errorHandler } from './middleware/errorHandler';

// Import routes
import healthRoutes from './routes/health';
import subjectsRoutes from './routes/subjects';
import questionsRoutes from './routes/questions';
import aiRoutes from './routes/ai';
import quizRoutes from './routes/quiz';

// Create Express app
const app = express();

// ==================== MIDDLEWARE ====================

// Security headers
app.use(helmet());

// CORS
app.use(cors({
  origin: config.cors.origin,
  credentials: true,
}));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Request logging
app.use(requestLogger);

// Rate limiting
const limiter = rateLimit({
  windowMs: config.rateLimit.windowMs,
  max: config.rateLimit.maxRequests,
  message: {
    error: 'rate_limit_exceeded',
    message: 'Too many requests, please try again later',
    timestamp: new Date().toISOString(),
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api/', limiter);

// ==================== ROUTES ====================

// Health check (no rate limiting)
app.use('/api/v1/health', healthRoutes);

// API routes (with rate limiting)
app.use('/api/v1/subjects', subjectsRoutes);
app.use('/api/v1/questions', questionsRoutes);
app.use('/api/v1/ai', aiRoutes);
app.use('/api/v1/quiz', quizRoutes);

// Root endpoint
app.get('/', (_req, res) => {
  res.json({
    name: 'FormulaQuizzer Server',
    version: '1.0.0',
    description: 'Backend API for FormulaQuizzer with AI-powered question generation',
    documentation: '/api/v1/health',
    endpoints: {
      health: '/api/v1/health',
      subjects: '/api/v1/subjects',
      questions: '/api/v1/questions',
      ai: '/api/v1/ai',
      quiz: '/api/v1/quiz',
    },
  });
});

// 404 handler
app.use((_req, res) => {
  res.status(404).json({
    error: 'not_found',
    message: 'The requested resource was not found',
    timestamp: new Date().toISOString(),
  });
});

// ==================== ERROR HANDLING ====================

app.use(errorHandler);

// ==================== SERVER START ====================

const PORT = config.server.port;

app.listen(PORT, () => {
  console.log('\n┌─────────────────────────────────────────────────────────┐');
  console.log('│                                                         │');
  console.log('│  🚀 FormulaQuizzer Server Started                      │');
  console.log('│                                                         │');
  console.log('└─────────────────────────────────────────────────────────┘\n');
  
  loggers.info('Server started successfully', {
    port: PORT,
    environment: config.server.nodeEnv,
    database: config.database.useMockData ? 'Mock (In-Memory)' : 'External',
    openai: config.openai.model,
  });

  console.log('📍 Server running at:');
  console.log(`   → http://localhost:${PORT}`);
  console.log(`   → http://localhost:${PORT}/api/v1/health\n`);

  console.log('📚 Available endpoints:');
  console.log(`   → GET    /api/v1/health`);
  console.log(`   → GET    /api/v1/subjects`);
  console.log(`   → POST   /api/v1/subjects`);
  console.log(`   → GET    /api/v1/questions`);
  console.log(`   → POST   /api/v1/questions`);
  console.log(`   → POST   /api/v1/ai/generate-question`);
  console.log(`   → POST   /api/v1/ai/generate-questions-batch`);
  console.log(`   → POST   /api/v1/quiz/start`);
  console.log(`   → POST   /api/v1/quiz/answer`);
  console.log(`   → POST   /api/v1/quiz/complete\n`);

  console.log('💡 Configuration:');
  console.log(`   → Environment: ${config.server.nodeEnv}`);
  console.log(`   → Database: ${config.database.useMockData ? '📦 Mock Data (No real DB needed)' : '🗄️  External Database'}`);
  console.log(`   → OpenAI: ${config.openai.model}`);
  console.log(`   → Cache: ${config.cache.maxItems} items, ${config.cache.ttlSeconds}s TTL`);
  console.log(`   → Rate Limit: ${config.rateLimit.maxRequests} req/${config.rateLimit.windowMs}ms\n`);

  console.log('✅ Ready to accept requests!\n');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  loggers.info('SIGTERM received, shutting down gracefully');
  process.exit(0);
});

process.on('SIGINT', () => {
  loggers.info('SIGINT received, shutting down gracefully');
  process.exit(0);
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
  loggers.error(new Error('Unhandled Rejection'), { reason, promise });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
  loggers.error(error, { type: 'uncaughtException' });
  process.exit(1);
});

export default app;
