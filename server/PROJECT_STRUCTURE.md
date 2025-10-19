# FormulaQuizzer Server Project Structure

Complete directory structure and file organization guide for the FormulaQuizzer Server.

---

## Overview

```
formula_quizzer_server/
├── src/                    # Source code (TypeScript)
├── dist/                   # Compiled JavaScript (generated)
├── tests/                  # Test suites
├── scripts/                # Utility scripts
├── docs/                   # Documentation
├── .env.example            # Environment variables template
├── .gitignore              # Git ignore rules
├── package.json            # Node.js dependencies
├── tsconfig.json           # TypeScript configuration
├── jest.config.js          # Jest test configuration
├── Dockerfile              # Docker container definition
├── docker-compose.yml      # Docker Compose setup
└── README.md               # Project overview
```

---

## Source Code Directory (`/src`)

### Complete Structure

```
src/
├── config/                 # Configuration management
│   ├── database.ts         # Database connection config
│   ├── openai.ts           # OpenAI API configuration
│   ├── redis.ts            # Redis cache configuration
│   └── env.ts              # Environment variables validation
│
├── models/                 # Data models and schemas
│   ├── subject.ts          # Subject model with validation
│   ├── question.ts         # Question model with types
│   ├── quiz_session.ts     # Quiz session tracking
│   └── user.ts             # User model (optional)
│
├── database/               # Database layer
│   ├── connection.ts       # DB connection management
│   ├── migrations/         # SQL migration files
│   │   ├── 001_create_subjects.ts
│   │   ├── 002_create_questions.ts
│   │   ├── 003_create_quiz_sessions.ts
│   │   └── 004_create_indexes.ts
│   ├── repositories/       # Data access layer
│   │   ├── subject_repository.ts
│   │   ├── question_repository.ts
│   │   ├── session_repository.ts
│   │   └── analytics_repository.ts
│   └── seeds/              # Sample data for development
│       ├── subjects.ts
│       └── questions.ts
│
├── services/               # Business logic layer
│   ├── ai_service.ts       # OpenAI integration
│   ├── question_generator.ts  # Question generation logic
│   ├── quiz_service.ts     # Quiz session management
│   ├── subject_service.ts  # Subject CRUD operations
│   └── analytics_service.ts    # Progress tracking
│
├── routes/                 # API route handlers
│   ├── api.ts              # Main API router
│   ├── subjects.ts         # Subject management endpoints
│   ├── questions.ts        # Question CRUD endpoints
│   ├── quiz.ts             # Quiz session endpoints
│   ├── ai.ts               # AI generation endpoints
│   ├── analytics.ts        # Analytics endpoints
│   └── health.ts           # Health check endpoints
│
├── middleware/             # Express middleware
│   ├── auth.ts             # Authentication middleware
│   ├── validation.ts       # Request validation
│   ├── error_handler.ts    # Error handling
│   ├── rate_limit.ts       # Rate limiting
│   ├── logger.ts           # Request logging
│   └── cors.ts             # CORS configuration
│
├── utils/                  # Utility functions
│   ├── cache.ts            # LRU cache implementation
│   ├── logger.ts           # Logging setup
│   ├── errors.ts           # Custom error classes
│   ├── validators.ts       # Input validation helpers
│   └── helpers.ts          # General helpers
│
├── types/                  # TypeScript type definitions
│   ├── api.ts              # API request/response types
│   ├── database.ts         # Database types
│   ├── express.d.ts        # Express type extensions
│   └── index.ts            # Exported types
│
└── index.ts                # Application entry point
```

---

## Detailed File Descriptions

### `/src/config/` - Configuration

#### `database.ts`
```typescript
/**
 * Database connection configuration
 * - PostgreSQL connection pool setup
 * - Connection retry logic
 * - SSL configuration for production
 */

import { Pool } from 'pg';

export const databaseConfig = {
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  max: parseInt(process.env.DB_POOL_MAX || '10'),
  min: parseInt(process.env.DB_POOL_MIN || '2'),
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
};
```

#### `openai.ts`
```typescript
/**
 * OpenAI API configuration
 * - API key management
 * - Model selection
 * - Token limits and temperature
 */

export const openAIConfig = {
  apiKey: process.env.OPENAI_API_KEY,
  model: process.env.OPENAI_MODEL || 'gpt-4-turbo-preview',
  maxTokens: parseInt(process.env.OPENAI_MAX_TOKENS || '2000'),
  temperature: parseFloat(process.env.OPENAI_TEMPERATURE || '0.7'),
};
```

#### `env.ts`
```typescript
/**
 * Environment variables validation
 * - Validates all required env vars on startup
 * - Provides type-safe access to config
 */

import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'production', 'test']),
  PORT: z.string().default('3000'),
  DATABASE_URL: z.string().url(),
  OPENAI_API_KEY: z.string().min(1),
  JWT_SECRET: z.string().min(32),
  API_KEYS: z.string(),
});

export const env = envSchema.parse(process.env);
```

---

### `/src/models/` - Data Models

#### `subject.ts`
```typescript
/**
 * Subject model
 * - Subject data structure
 * - Validation rules
 * - Database serialization
 * - Adaptive learning calculations
 */

export interface Subject {
  id: number;
  name: string;
  description: string;
  color: string;  // Hex color code
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
  totalQuestions: number;
  correctAnswers: number;
  difficultyWeight: number;
  metadata?: Record<string, any>;
}

export class SubjectModel {
  // Factory methods
  static fromDatabase(row: any): Subject { ... }
  static toDatabase(subject: Subject): any { ... }
  
  // Business logic
  static calculateAccuracy(subject: Subject): number { ... }
  static calculateAdaptivePriority(subject: Subject): number { ... }
}
```

#### `question.ts`
```typescript
/**
 * Question model
 * - Question data structure
 * - Multiple question types support
 * - AI generation metadata
 */

export interface Question {
  id: number;
  subjectId: number;
  questionText: string;
  options: string[];
  correctAnswer: string;
  explanation: string;
  difficulty: 'easy' | 'medium' | 'hard';
  category?: string;
  questionType: 'multiple_choice' | 'true_false' | 'fill_blank';
  createdAt: Date;
  isFromAI: boolean;
  source?: string;
  sourceUrl?: string;
  metadata?: Record<string, any>;
}
```

---

### `/src/database/` - Database Layer

#### `connection.ts`
```typescript
/**
 * Database connection management
 * - Connection pool setup
 * - Health checks
 * - Query helpers
 */

import { Pool } from 'pg';
import { databaseConfig } from '../config/database';

export class Database {
  private pool: Pool;
  
  constructor() {
    this.pool = new Pool(databaseConfig);
  }
  
  async query(text: string, params?: any[]): Promise<any> { ... }
  async getClient(): Promise<PoolClient> { ... }
  async healthCheck(): Promise<boolean> { ... }
}
```

#### `migrations/` - Database Migrations

**File Naming Convention:** `NNN_description.ts` (e.g., `001_create_subjects.ts`)

```typescript
/**
 * Migration: 001_create_subjects.ts
 * Creates subjects table with indexes
 */

export async function up(db: Database): Promise<void> {
  await db.query(`
    CREATE TABLE subjects (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) UNIQUE NOT NULL,
      description TEXT NOT NULL,
      color VARCHAR(7) NOT NULL,
      created_at TIMESTAMP DEFAULT NOW(),
      updated_at TIMESTAMP DEFAULT NOW(),
      is_active BOOLEAN DEFAULT TRUE,
      total_questions INTEGER DEFAULT 0,
      correct_answers INTEGER DEFAULT 0,
      difficulty_weight REAL DEFAULT 0.5,
      metadata JSONB
    );
    
    CREATE INDEX idx_subjects_is_active ON subjects(is_active);
    CREATE INDEX idx_subjects_name ON subjects(name);
  `);
}

export async function down(db: Database): Promise<void> {
  await db.query('DROP TABLE IF EXISTS subjects CASCADE');
}
```

#### `repositories/` - Data Access Layer

```typescript
/**
 * Repository pattern implementation
 * - CRUD operations
 * - Complex queries
 * - Transaction support
 */

export class SubjectRepository {
  constructor(private db: Database) {}
  
  async findById(id: number): Promise<Subject | null> { ... }
  async findAll(filters: SubjectFilters): Promise<Subject[]> { ... }
  async create(data: CreateSubjectData): Promise<Subject> { ... }
  async update(id: number, data: UpdateSubjectData): Promise<Subject> { ... }
  async delete(id: number): Promise<void> { ... }
  async count(filters: SubjectFilters): Promise<number> { ... }
}
```

---

### `/src/services/` - Business Logic

#### `ai_service.ts`
```typescript
/**
 * OpenAI API integration
 * - Question generation
 * - Answer explanation
 * - Error handling and retries
 * - Token usage tracking
 */

export class AIService {
  private openai: OpenAI;
  
  async generateQuestion(params: GenerateQuestionParams): Promise<Question> {
    // 1. Build prompt
    // 2. Call OpenAI API
    // 3. Parse response
    // 4. Validate output
    // 5. Return question
  }
  
  async generateBatch(params: GenerateBatchParams): Promise<Question[]> {
    // Batch generation for efficiency
  }
  
  async explainAnswer(question: Question, userAnswer: string): Promise<string> {
    // Generate detailed explanation
  }
}
```

#### `question_generator.ts`
```typescript
/**
 * Question generation orchestration
 * - Combines AI service with caching
 * - Manages question quality
 * - Handles fallbacks
 */

export class QuestionGenerator {
  constructor(
    private aiService: AIService,
    private cache: CacheService,
    private questionRepo: QuestionRepository
  ) {}
  
  async generate(subjectId: number): Promise<Question> {
    // 1. Check cache
    // 2. Generate with AI if cache miss
    // 3. Validate and store
    // 4. Return question
  }
}
```

#### `quiz_service.ts`
```typescript
/**
 * Quiz session management
 * - Session creation and tracking
 * - Answer submission
 * - Statistics calculation
 */

export class QuizService {
  async startSession(params: StartSessionParams): Promise<QuizSession> { ... }
  async submitAnswer(params: SubmitAnswerParams): Promise<AnswerResult> { ... }
  async completeSession(sessionId: string): Promise<SessionResults> { ... }
  async getHistory(filters: HistoryFilters): Promise<QuizSession[]> { ... }
}
```

---

### `/src/routes/` - API Routes

#### `api.ts` - Main Router
```typescript
/**
 * Main API router
 * - Combines all sub-routers
 * - Applies global middleware
 */

import express from 'express';
import subjectsRouter from './subjects';
import questionsRouter from './questions';
import quizRouter from './quiz';
import aiRouter from './ai';
import analyticsRouter from './analytics';
import healthRouter from './health';

const router = express.Router();

router.use('/subjects', subjectsRouter);
router.use('/questions', questionsRouter);
router.use('/quiz', quizRouter);
router.use('/ai', aiRouter);
router.use('/analytics', analyticsRouter);
router.use('/health', healthRouter);

export default router;
```

#### `subjects.ts` - Subjects Router
```typescript
/**
 * Subject management endpoints
 * - CRUD operations for subjects
 * - Authentication required
 * - Input validation
 */

router.get('/', requireAuth, listSubjects);
router.post('/', requireAuth, validateRequest(createSubjectSchema), createSubject);
router.get('/:id', requireAuth, getSubjectById);
router.put('/:id', requireAuth, validateRequest(updateSubjectSchema), updateSubject);
router.delete('/:id', requireAuth, deleteSubject);
```

---

### `/src/middleware/` - Middleware

#### `auth.ts`
```typescript
/**
 * Authentication middleware
 * - Validates API keys
 * - Attaches user info to request
 */

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const apiKey = extractAPIKey(req);
  
  if (!isValidAPIKey(apiKey)) {
    throw new ApiError('Unauthorized', 401);
  }
  
  req.user = { apiKey };
  next();
}
```

#### `validation.ts`
```typescript
/**
 * Request validation middleware
 * - Zod schema validation
 * - Body, query, params validation
 */

export function validateRequest(schema: z.ZodSchema) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      schema.parse({
        body: req.body,
        query: req.query,
        params: req.params,
      });
      next();
    } catch (error) {
      throw new ValidationError('Invalid request data', error);
    }
  };
}
```

#### `error_handler.ts`
```typescript
/**
 * Global error handler
 * - Catches all errors
 * - Formats error responses
 * - Logs errors
 */

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  logger.error({ error: err, path: req.path }, 'Request error');
  
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      error: err.code,
      message: err.message,
    });
  }
  
  res.status(500).json({
    error: 'internal_server_error',
    message: 'An unexpected error occurred',
  });
}
```

---

### `/src/utils/` - Utilities

#### `cache.ts`
```typescript
/**
 * LRU cache implementation
 * - In-memory caching
 * - TTL support
 * - Redis integration (optional)
 */

export class CacheService {
  private cache: LRUCache<string, any>;
  
  constructor(options: CacheOptions) {
    this.cache = new LRUCache(options);
  }
  
  async get<T>(key: string): Promise<T | null> { ... }
  async set<T>(key: string, value: T, ttl?: number): Promise<void> { ... }
  async del(key: string): Promise<void> { ... }
  async clear(): Promise<void> { ... }
}
```

#### `logger.ts`
```typescript
/**
 * Structured logging setup
 * - Pino logger configuration
 * - Log levels and formatting
 * - Production vs development modes
 */

import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  timestamp: pino.stdTimeFunctions.isoTime,
  redact: ['req.headers.authorization', 'password'],
});
```

#### `errors.ts`
```typescript
/**
 * Custom error classes
 * - Standard error types
 * - HTTP status codes
 * - Error codes for clients
 */

export class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public code?: string
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

export class ValidationError extends ApiError {
  constructor(message: string, details?: any) {
    super(message, 400, 'validation_error');
  }
}

export class NotFoundError extends ApiError {
  constructor(resource: string) {
    super(`${resource} not found`, 404, 'not_found');
  }
}
```

---

### `/src/index.ts` - Application Entry Point

```typescript
/**
 * Application entry point
 * - Express app setup
 * - Middleware registration
 * - Route mounting
 * - Server startup
 */

import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { logger } from './utils/logger';
import { errorHandler } from './middleware/error_handler';
import apiRouter from './routes/api';

const app = express();
const port = process.env.PORT || 3000;

// Global middleware
app.use(helmet());
app.use(cors({ origin: process.env.CORS_ORIGIN }));
app.use(express.json());

// API routes
app.use('/api/v1', apiRouter);

// Error handler (must be last)
app.use(errorHandler);

// Start server
app.listen(port, () => {
  logger.info({ port }, 'Server started');
});

export { app };
```

---

## Test Directory (`/tests`)

```
tests/
├── unit/                   # Unit tests
│   ├── services/
│   │   ├── subject_service.test.ts
│   │   └── quiz_service.test.ts
│   ├── repositories/
│   │   └── subject_repository.test.ts
│   └── utils/
│       └── cache.test.ts
│
├── integration/            # Integration tests
│   ├── routes/
│   │   ├── subjects.test.ts
│   │   └── quiz.test.ts
│   └── database/
│       └── migrations.test.ts
│
├── e2e/                    # End-to-end tests
│   ├── quiz_flow.test.ts
│   └── ai_generation.test.ts
│
└── helpers/                # Test utilities
    ├── db_helper.ts
    ├── fixtures.ts
    └── api_helper.ts
```

---

## Scripts Directory (`/scripts`)

```
scripts/
├── migrate.ts              # Run database migrations
├── seed.ts                 # Seed sample data
├── generate_api_key.ts     # Generate new API keys
├── cleanup_old_data.ts     # Clean old quiz sessions
└── setup.ts                # Initial project setup
```

**Example: `migrate.ts`**
```typescript
/**
 * Database migration script
 * Usage: npm run migrate
 */

import { Database } from '../src/database/connection';
import { migrations } from '../src/database/migrations';

async function runMigrations() {
  const db = new Database();
  
  for (const migration of migrations) {
    await migration.up(db);
    console.log(`✅ Migration ${migration.name} completed`);
  }
  
  await db.close();
}

runMigrations().catch(console.error);
```

---

## Documentation Directory (`/docs`)

```
docs/
├── ARCHITECTURE.md         # System architecture
├── API_SPECIFICATION.md    # API documentation
├── DEVELOPMENT_GUIDE.md    # Development standards
├── DEPLOYMENT_GUIDE.md     # Deployment instructions
├── PROJECT_STRUCTURE.md    # This file
└── TROUBLESHOOTING.md      # Common issues and solutions
```

---

## Configuration Files

### `package.json`
```json
{
  "name": "formula-quizzer-server",
  "version": "1.0.0",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write src/**/*.ts",
    "migrate": "ts-node scripts/migrate.ts",
    "seed": "ts-node scripts/seed.ts"
  }
}
```

### `tsconfig.json`
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "module": "commonjs",
    "lib": ["ES2020"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### `jest.config.js`
```javascript
module.exports = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
    '!src/index.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 80,
      functions: 80,
      lines: 80,
      statements: 80,
    },
  },
};
```

---

## File Naming Conventions

### TypeScript Files
- **snake_case**: `subject_service.ts`, `question_repository.ts`
- **Classes**: PascalCase within files
- **Functions**: camelCase
- **Constants**: UPPER_SNAKE_CASE

### Test Files
- **Pattern**: `*.test.ts`
- **Location**: Mirror source structure in `/tests`

### Migration Files
- **Pattern**: `NNN_description.ts` (e.g., `001_create_subjects.ts`)
- **Sequential numbering**: 001, 002, 003, etc.

---

## Import Organization

**Standard Import Order:**
```typescript
// 1. External dependencies
import express from 'express';
import { z } from 'zod';

// 2. Internal modules (absolute paths)
import { SubjectService } from '@/services/subject_service';
import { logger } from '@/utils/logger';

// 3. Types
import type { Subject, Question } from '@/types';

// 4. Relative imports (only for co-located files)
import { helper } from './helpers';
```

---

## Environment-Specific Files

```
.env.development        # Development environment
.env.production         # Production environment
.env.test               # Test environment
.env.example            # Template (committed to git)
```

**Never commit actual `.env` files!**

---

## Build Output (`/dist`)

```
dist/
├── config/
├── models/
├── database/
├── services/
├── routes/
├── middleware/
├── utils/
├── types/
└── index.js
```

**Note:** This directory is generated by `npm run build` and should be gitignored.

---

## Summary

### Key Principles

1. **Separation of Concerns**: Each directory has a single responsibility
2. **Layered Architecture**: Database → Services → Routes
3. **Type Safety**: TypeScript types in `/types` directory
4. **Testability**: Mirrors source structure in `/tests`
5. **Scalability**: Easy to add new features without refactoring
6. **Independence**: Completely separate from `formula_quizzer` Flutter app

### Quick Navigation

- **Add new endpoint**: Create route in `/src/routes`
- **Add business logic**: Create service in `/src/services`
- **Add database query**: Create repository in `/src/database/repositories`
- **Add configuration**: Add to `/src/config`
- **Add middleware**: Create in `/src/middleware`
- **Add utility**: Create in `/src/utils`

---

**Last Updated:** 2024-10-13  
**Project Version:** 1.0.0
