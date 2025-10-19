# FormulaQuizzer Server Development Guide

## Development Standards

This guide outlines the coding standards, workflows, and best practices for developing the FormulaQuizzer Server.

---

## ⚠️ Critical Reminder

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  THIS SERVER IS INDEPENDENT FROM formula_quizzer                 │
│                                                                   │
│  ⛔ NEVER modify files in ../formula_quizzer/                   │
│  ⛔ NEVER import from ../formula_quizzer/                       │
│  ⛔ NEVER share database files                                  │
│  ✅ Keep all code in formula_quizzer_server/                   │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## TypeScript Coding Standards

### File Naming Conventions

```typescript
// Use snake_case for files
subject_service.ts         // ✅ Good
SubjectService.ts          // ❌ Bad
subject-service.ts         // ❌ Bad

// Use PascalCase for classes
export class SubjectService {}      // ✅ Good
export class subject_service {}     // ❌ Bad

// Use camelCase for variables and functions
const subjectName = "Physics";      // ✅ Good
const SubjectName = "Physics";      // ❌ Bad
```

### Code Organization Rules

```typescript
// 1. IMPORTS: Group and order imports
// External dependencies first
import express from 'express';
import { z } from 'zod';

// Internal imports second
import { SubjectService } from '../services/subject_service';
import { logger } from '../utils/logger';
import type { Subject } from '../types';

// 2. TYPES/INTERFACES: Define at top of file
interface CreateSubjectRequest {
  name: string;
  description: string;
  color: string;
}

// 3. CONSTANTS: After types
const DEFAULT_PAGE_SIZE = 20;
const MAX_PAGE_SIZE = 100;

// 4. MAIN CODE: Functions and classes
export class SubjectRepository {
  // Implementation
}

// 5. EXPORTS: Use named exports, avoid default
export { SubjectRepository, CreateSubjectRequest };
```

### TypeScript Best Practices

```typescript
// ✅ ALWAYS use explicit types for function parameters and returns
export async function createSubject(
  data: CreateSubjectRequest
): Promise<Subject> {
  // Implementation
}

// ❌ NEVER use 'any' type (use 'unknown' if needed)
function processData(data: any) {}          // ❌ Bad
function processData(data: unknown) {}      // ✅ Good

// ✅ ALWAYS use optional chaining and nullish coalescing
const subjectName = subject?.name ?? 'Unnamed';

// ✅ ALWAYS use readonly for immutable data
interface SubjectConfig {
  readonly id: number;
  readonly createdAt: Date;
}

// ✅ ALWAYS use strict null checks
// Enable in tsconfig.json: "strictNullChecks": true

// ✅ ALWAYS use interfaces for object shapes, types for unions
interface Subject {           // ✅ For object structures
  id: number;
  name: string;
}

type Difficulty = 'easy' | 'medium' | 'hard';  // ✅ For unions
```

---

## Express Route Standards

### Route Handler Pattern

```typescript
// routes/subjects.ts

import { Router } from 'express';
import { z } from 'zod';
import { SubjectService } from '../services/subject_service';
import { validateRequest } from '../middleware/validation';
import { requireAuth } from '../middleware/auth';
import { logger } from '../utils/logger';
import { ApiError } from '../utils/errors';

const router = Router();
const subjectService = new SubjectService();

// Define Zod schema for validation
const createSubjectSchema = z.object({
  body: z.object({
    name: z.string().min(1).max(255),
    description: z.string().min(1).max(1000),
    color: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
  }),
});

// Route handler with proper error handling
router.post(
  '/',
  requireAuth,
  validateRequest(createSubjectSchema),
  async (req, res, next) => {
    try {
      const subject = await subjectService.create(req.body);
      
      logger.info({
        action: 'subject_created',
        subject_id: subject.id,
        user_id: req.user?.id,
      });
      
      res.status(201).json(subject);
    } catch (error) {
      // Let error handler middleware process it
      next(error);
    }
  }
);

export default router;
```

### Request Validation Rules

```typescript
// ALWAYS validate all inputs with Zod schemas

// ✅ Good: Comprehensive validation
const createQuestionSchema = z.object({
  body: z.object({
    subject_id: z.number().int().positive(),
    question_text: z.string().min(10).max(2000),
    options: z.array(z.string().min(1)).min(2).max(5),
    correct_answer: z.string().min(1),
    difficulty: z.enum(['easy', 'medium', 'hard']),
  }),
  query: z.object({
    // Optional query params
  }).optional(),
  params: z.object({
    id: z.string().regex(/^\d+$/),
  }).optional(),
});

// ❌ Bad: No validation
router.post('/', async (req, res) => {
  const { subject_id, question_text } = req.body;  // Unsafe!
  // ...
});
```

---

## Database Standards

### Repository Pattern

```typescript
// database/repositories/subject_repository.ts

import { Database } from '../connection';
import { Subject } from '../../models/subject';
import { logger } from '../../utils/logger';

export class SubjectRepository {
  private db: Database;

  constructor(db: Database) {
    this.db = db;
  }

  // ✅ ALWAYS use parameterized queries (prevents SQL injection)
  async findById(id: number): Promise<Subject | null> {
    try {
      const result = await this.db.query(
        'SELECT * FROM subjects WHERE id = $1',
        [id]
      );
      
      return result.rows[0] ? Subject.fromDatabase(result.rows[0]) : null;
    } catch (error) {
      logger.error({ error, id }, 'Failed to find subject');
      throw new DatabaseError('Failed to retrieve subject');
    }
  }

  // ✅ ALWAYS use transactions for multi-step operations
  async createWithQuestions(
    subject: Omit<Subject, 'id'>,
    questions: Question[]
  ): Promise<Subject> {
    const client = await this.db.pool.connect();
    
    try {
      await client.query('BEGIN');
      
      // Create subject
      const subjectResult = await client.query(
        'INSERT INTO subjects (name, description, color) VALUES ($1, $2, $3) RETURNING *',
        [subject.name, subject.description, subject.color]
      );
      
      const createdSubject = Subject.fromDatabase(subjectResult.rows[0]);
      
      // Create questions
      for (const question of questions) {
        await client.query(
          'INSERT INTO questions (subject_id, question_text, options, correct_answer) VALUES ($1, $2, $3, $4)',
          [createdSubject.id, question.text, JSON.stringify(question.options), question.correctAnswer]
        );
      }
      
      await client.query('COMMIT');
      return createdSubject;
    } catch (error) {
      await client.query('ROLLBACK');
      throw error;
    } finally {
      client.release();
    }
  }

  // ✅ ALWAYS use proper indexing for queries
  async findByNamePattern(pattern: string): Promise<Subject[]> {
    // Assumes index: CREATE INDEX idx_subjects_name ON subjects(name);
    const result = await this.db.query(
      'SELECT * FROM subjects WHERE name ILIKE $1 ORDER BY name',
      [`%${pattern}%`]
    );
    
    return result.rows.map(row => Subject.fromDatabase(row));
  }
}
```

### Database Migration Standards

```typescript
// database/migrations/001_create_subjects_table.ts

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

    -- Create indexes
    CREATE INDEX idx_subjects_is_active ON subjects(is_active);
    CREATE INDEX idx_subjects_name ON subjects(name);

    -- Create updated_at trigger
    CREATE OR REPLACE FUNCTION update_updated_at_column()
    RETURNS TRIGGER AS $$
    BEGIN
      NEW.updated_at = NOW();
      RETURN NEW;
    END;
    $$ language 'plpgsql';

    CREATE TRIGGER update_subjects_updated_at
      BEFORE UPDATE ON subjects
      FOR EACH ROW
      EXECUTE FUNCTION update_updated_at_column();
  `);
}

export async function down(db: Database): Promise<void> {
  await db.query(`
    DROP TRIGGER IF EXISTS update_subjects_updated_at ON subjects;
    DROP FUNCTION IF EXISTS update_updated_at_column();
    DROP TABLE IF EXISTS subjects CASCADE;
  `);
}
```

---

## Service Layer Standards

### Service Class Pattern

```typescript
// services/subject_service.ts

import { SubjectRepository } from '../database/repositories/subject_repository';
import { QuestionRepository } from '../database/repositories/question_repository';
import { Subject, CreateSubjectData } from '../models/subject';
import { ApiError } from '../utils/errors';
import { logger } from '../utils/logger';

export class SubjectService {
  private subjectRepo: SubjectRepository;
  private questionRepo: QuestionRepository;

  constructor(
    subjectRepo: SubjectRepository,
    questionRepo: QuestionRepository
  ) {
    this.subjectRepo = subjectRepo;
    this.questionRepo = questionRepo;
  }

  // ✅ ALWAYS include proper error handling
  async create(data: CreateSubjectData): Promise<Subject> {
    try {
      // Validate business rules
      const existingSubject = await this.subjectRepo.findByName(data.name);
      if (existingSubject) {
        throw new ApiError('Subject with this name already exists', 409);
      }

      // Create subject
      const subject = await this.subjectRepo.create(data);

      logger.info({ subject_id: subject.id }, 'Subject created successfully');
      return subject;
    } catch (error) {
      if (error instanceof ApiError) {
        throw error;
      }
      
      logger.error({ error, data }, 'Failed to create subject');
      throw new ApiError('Failed to create subject', 500);
    }
  }

  // ✅ ALWAYS implement pagination for list operations
  async list(options: {
    page?: number;
    pageSize?: number;
    isActive?: boolean;
  } = {}): Promise<{ subjects: Subject[]; total: number; page: number }> {
    const page = options.page ?? 1;
    const pageSize = Math.min(options.pageSize ?? 20, 100);
    const offset = (page - 1) * pageSize;

    const [subjects, total] = await Promise.all([
      this.subjectRepo.findMany({
        limit: pageSize,
        offset,
        isActive: options.isActive,
      }),
      this.subjectRepo.count({ isActive: options.isActive }),
    ]);

    return { subjects, total, page };
  }

  // ✅ ALWAYS implement soft delete when possible
  async delete(id: number): Promise<void> {
    const subject = await this.subjectRepo.findById(id);
    if (!subject) {
      throw new ApiError('Subject not found', 404);
    }

    // Soft delete by setting is_active = false
    await this.subjectRepo.update(id, { isActive: false });
    
    logger.info({ subject_id: id }, 'Subject soft deleted');
  }
}
```

---

## Error Handling Standards

### Custom Error Classes

```typescript
// utils/errors.ts

export class ApiError extends Error {
  constructor(
    message: string,
    public statusCode: number,
    public code?: string,
    public details?: any
  ) {
    super(message);
    this.name = 'ApiError';
    Error.captureStackTrace(this, this.constructor);
  }
}

export class ValidationError extends ApiError {
  constructor(message: string, details?: any) {
    super(message, 400, 'validation_error', details);
    this.name = 'ValidationError';
  }
}

export class DatabaseError extends ApiError {
  constructor(message: string, details?: any) {
    super(message, 500, 'database_error', details);
    this.name = 'DatabaseError';
  }
}

export class NotFoundError extends ApiError {
  constructor(resource: string) {
    super(`${resource} not found`, 404, 'not_found');
    this.name = 'NotFoundError';
  }
}
```

### Error Handler Middleware

```typescript
// middleware/error_handler.ts

import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/errors';
import { logger } from '../utils/logger';

export function errorHandler(
  err: Error,
  req: Request,
  res: Response,
  next: NextFunction
) {
  // Log error
  logger.error({
    error: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method,
  }, 'Request error');

  // Handle known API errors
  if (err instanceof ApiError) {
    return res.status(err.statusCode).json({
      error: err.code || 'error',
      message: err.message,
      ...(process.env.NODE_ENV === 'development' && { details: err.details }),
    });
  }

  // Handle unknown errors
  res.status(500).json({
    error: 'internal_server_error',
    message: process.env.NODE_ENV === 'production' 
      ? 'An unexpected error occurred'
      : err.message,
  });
}
```

---

## Testing Standards

### Unit Test Pattern

```typescript
// tests/unit/services/subject_service.test.ts

import { SubjectService } from '../../../src/services/subject_service';
import { SubjectRepository } from '../../../src/database/repositories/subject_repository';
import { QuestionRepository } from '../../../src/database/repositories/question_repository';
import { ApiError } from '../../../src/utils/errors';

// Mock repositories
jest.mock('../../../src/database/repositories/subject_repository');
jest.mock('../../../src/database/repositories/question_repository');

describe('SubjectService', () => {
  let service: SubjectService;
  let subjectRepo: jest.Mocked<SubjectRepository>;
  let questionRepo: jest.Mocked<QuestionRepository>;

  beforeEach(() => {
    subjectRepo = new SubjectRepository({} as any) as jest.Mocked<SubjectRepository>;
    questionRepo = new QuestionRepository({} as any) as jest.Mocked<QuestionRepository>;
    service = new SubjectService(subjectRepo, questionRepo);
  });

  describe('create', () => {
    it('should create subject successfully', async () => {
      const createData = {
        name: 'Physics',
        description: 'Physics subject',
        color: '#2196F3',
      };

      const expectedSubject = { id: 1, ...createData };
      subjectRepo.findByName.mockResolvedValue(null);
      subjectRepo.create.mockResolvedValue(expectedSubject as any);

      const result = await service.create(createData);

      expect(result).toEqual(expectedSubject);
      expect(subjectRepo.create).toHaveBeenCalledWith(createData);
    });

    it('should throw error if subject name already exists', async () => {
      const createData = {
        name: 'Physics',
        description: 'Physics subject',
        color: '#2196F3',
      };

      subjectRepo.findByName.mockResolvedValue({ id: 1 } as any);

      await expect(service.create(createData)).rejects.toThrow(ApiError);
      expect(subjectRepo.create).not.toHaveBeenCalled();
    });
  });
});
```

### Integration Test Pattern

```typescript
// tests/integration/routes/subjects.test.ts

import request from 'supertest';
import { app } from '../../../src/index';
import { db } from '../../../src/database/connection';

describe('POST /api/v1/subjects', () => {
  beforeAll(async () => {
    await db.migrate.latest();
  });

  afterAll(async () => {
    await db.destroy();
  });

  beforeEach(async () => {
    await db('subjects').del();
  });

  it('should create subject with valid data', async () => {
    const response = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', 'Bearer test_api_key')
      .send({
        name: 'Physics',
        description: 'Physics subject',
        color: '#2196F3',
      });

    expect(response.status).toBe(201);
    expect(response.body).toMatchObject({
      id: expect.any(Number),
      name: 'Physics',
      description: 'Physics subject',
      color: '#2196F3',
    });
  });

  it('should return 400 for invalid data', async () => {
    const response = await request(app)
      .post('/api/v1/subjects')
      .set('Authorization', 'Bearer test_api_key')
      .send({
        name: '',  // Invalid: empty name
        description: 'Test',
        color: 'invalid',  // Invalid: not hex color
      });

    expect(response.status).toBe(400);
    expect(response.body.error).toBe('validation_error');
  });
});
```

---

## Logging Standards

### Structured Logging Pattern

```typescript
// utils/logger.ts

import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  formatters: {
    level: (label) => ({ level: label }),
  },
  timestamp: () => `,"timestamp":"${new Date().toISOString()}"`,
  ...(process.env.NODE_ENV === 'development' && {
    transport: {
      target: 'pino-pretty',
      options: {
        colorize: true,
        translateTime: 'SYS:standard',
        ignore: 'pid,hostname',
      },
    },
  }),
});

// Usage examples
logger.info({ subject_id: 42, action: 'created' }, 'Subject created');
logger.error({ error: err, subject_id: 42 }, 'Failed to create subject');
logger.warn({ cache_size: 1000 }, 'Cache size approaching limit');
logger.debug({ query: 'SELECT * FROM subjects' }, 'Executing query');
```

---

## Security Standards

### Input Sanitization

```typescript
// ✅ ALWAYS sanitize user inputs
import { escape } from 'validator';

function sanitizeInput(input: string): string {
  return escape(input.trim());
}

// ✅ ALWAYS use parameterized queries
await db.query('SELECT * FROM subjects WHERE name = $1', [sanitizedName]);

// ❌ NEVER concatenate user input into SQL
await db.query(`SELECT * FROM subjects WHERE name = '${name}'`);  // SQL injection!
```

### Authentication & Authorization

```typescript
// middleware/auth.ts

import { Request, Response, NextFunction } from 'express';
import { ApiError } from '../utils/errors';

export function requireAuth(req: Request, res: Response, next: NextFunction) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    throw new ApiError('Missing or invalid authorization header', 401);
  }

  const apiKey = authHeader.substring(7);
  const validKeys = process.env.API_KEYS?.split(',') || [];

  if (!validKeys.includes(apiKey)) {
    throw new ApiError('Invalid API key', 401);
  }

  // Attach user info to request (optional)
  req.user = { apiKey };
  next();
}
```

---

## Git Workflow Standards

### Branch Naming

```bash
# Feature branches
feature/add-subject-management
feature/ai-question-generation

# Bug fix branches
fix/database-connection-leak
fix/rate-limit-bypass

# Refactor branches
refactor/repository-pattern
refactor/error-handling

# Documentation branches
docs/api-specification
docs/deployment-guide
```

### Commit Message Format

```bash
# Format: <type>(<scope>): <subject>

feat(subjects): add pagination support
fix(database): resolve connection pool leak
perf(cache): optimize LRU cache performance
docs(api): update endpoint documentation
test(subjects): add integration tests
refactor(services): implement repository pattern
chore(deps): update dependencies
```

### Pre-Commit Checklist

```bash
# Before committing:
✅ Run linter: npm run lint
✅ Run formatter: npm run format
✅ Run tests: npm test
✅ Check types: npm run type-check
✅ Build project: npm run build
✅ Review changes: git diff
```

---

## Performance Best Practices

### Caching Strategy

```typescript
// utils/cache.ts

import { LRUCache } from 'lru-cache';

// Configure cache with appropriate limits
const questionCache = new LRUCache<string, Question[]>({
  max: 100,              // Maximum 100 subjects
  maxSize: 2000,         // Maximum 2000 questions total
  sizeCalculation: (questions) => questions.length,
  ttl: 1000 * 60 * 5,   // 5 minutes
  updateAgeOnGet: true,  // Refresh TTL on access
  updateAgeOnHas: false,
});

// Usage
async function getQuestions(subjectId: number): Promise<Question[]> {
  const cacheKey = `subject:${subjectId}:questions`;
  
  // Check cache first
  const cached = questionCache.get(cacheKey);
  if (cached) {
    logger.debug({ subject_id: subjectId }, 'Cache hit');
    return cached;
  }

  // Fetch from database
  const questions = await questionRepo.findBySubjectId(subjectId);
  questionCache.set(cacheKey, questions);
  
  logger.debug({ subject_id: subjectId }, 'Cache miss');
  return questions;
}
```

### Database Connection Pooling

```typescript
// config/database.ts

import { Pool } from 'pg';

export const pool = new Pool({
  host: process.env.DB_HOST,
  port: parseInt(process.env.DB_PORT || '5432'),
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  min: 2,                    // Minimum connections
  max: 10,                   // Maximum connections
  idleTimeoutMillis: 30000,  // Close idle connections after 30s
  connectionTimeoutMillis: 2000,  // Fail after 2s
});
```

---

## Environment Configuration

### Environment Variables

```bash
# .env.example

# Server Configuration
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/formula_quizzer
DB_POOL_MIN=2
DB_POOL_MAX=10

# Redis Configuration (optional)
REDIS_URL=redis://localhost:6379
REDIS_TTL=300

# OpenAI Configuration
OPENAI_API_KEY=sk-your-key-here
OPENAI_MODEL=gpt-4-turbo-preview
OPENAI_MAX_TOKENS=2000
OPENAI_TEMPERATURE=0.7

# Authentication
JWT_SECRET=your-secret-here
API_KEYS=key1,key2,key3

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=60

# CORS
CORS_ORIGIN=http://localhost:8080,https://your-domain.com
```

---

## Code Review Checklist

### Before Submitting PR

- [ ] All tests pass (`npm test`)
- [ ] Code is linted (`npm run lint`)
- [ ] Code is formatted (`npm run format`)
- [ ] TypeScript compiles (`npm run build`)
- [ ] No console.log statements (use logger instead)
- [ ] Environment variables documented in .env.example
- [ ] Database migrations included if schema changed
- [ ] API documentation updated if endpoints changed
- [ ] Error handling is comprehensive
- [ ] Input validation is in place
- [ ] Security best practices followed
- [ ] Performance considerations addressed
- [ ] No hardcoded secrets or API keys

---

## Maintenance Protocols

### Regular Tasks

```bash
# Daily
- Monitor error logs
- Check API usage metrics
- Review OpenAI costs

# Weekly
- Update dependencies: npm update
- Review and merge dependabot PRs
- Clean up old branches

# Monthly
- Database vacuum/optimize
- Review and update documentation
- Security audit: npm audit
- Performance testing
```

---

## Conclusion

Following these development standards ensures:
- **Consistency**: All code follows the same patterns
- **Maintainability**: Easy to understand and modify
- **Security**: Protected against common vulnerabilities
- **Performance**: Optimized for production use
- **Quality**: High test coverage and reliability

Remember: **This server is completely independent from the Flutter app.** Never modify files outside of `formula_quizzer_server/`.
