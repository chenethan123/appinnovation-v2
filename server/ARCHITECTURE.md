# FormulaQuizzer Server Architecture

## Project Overview

**FormulaQuizzer Server** is a standalone backend implementation designed to provide educational quiz services with AI-powered question generation, subject management, and progress tracking. This server is **completely independent** from the Flutter app (`formula_quizzer`) and can be deployed as a standalone API service.

---

## ⚠️ CRITICAL: Project Independence

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  ⛔ THIS SERVER WILL NOT TOUCH THE ORIGINAL formula_quizzer     │
│                                                                   │
│  - Separate codebase in formula_quizzer_server/                 │
│  - Independent database and storage                              │
│  - Standalone deployment                                         │
│  - Can be used by Flutter app OR any other client                │
│  - No shared files or dependencies with the Flutter project      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Core Architecture Principles

### 1. **API-First Design**
- RESTful API with clear endpoint definitions
- JSON request/response format
- Standard HTTP status codes and error handling
- OpenAPI/Swagger documentation
- Versioned API endpoints (/api/v1/...)

### 2. **Scalable Backend Architecture**
- Stateless API design for horizontal scaling
- Database connection pooling
- Caching strategies (Redis/in-memory)
- Background job processing for expensive operations
- Rate limiting and throttling

### 3. **AI Integration**
- OpenAI API integration for question generation
- Fallback mechanisms for API failures
- Cost optimization with caching and batching
- Token usage monitoring and limits
- Educational disclaimer enforcement

### 4. **Data Persistence**
- PostgreSQL for production reliability
- SQLite for development simplicity
- Proper indexing for query performance
- Database migrations with version control
- Automatic cleanup of old data

### 5. **Security & Privacy**
- API key authentication
- Rate limiting per API key/IP
- Input validation and sanitization
- No PII storage without consent
- CORS configuration for frontend access
- Environment-based configuration

### 6. **Observability**
- Structured logging (JSON format)
- Request/response logging
- Performance metrics
- Error tracking and alerting
- API usage analytics

---

## Technology Stack

### Core Technologies
```typescript
{
  "runtime": "Node.js 20+ LTS",
  "language": "TypeScript 5.x",
  "framework": "Express 4.x",
  "database": "PostgreSQL 15+ (primary) | SQLite 3.x (development)",
  "caching": "Redis 7.x (optional, for production)",
  "validation": "Zod 3.x",
  "authentication": "JWT + API Keys",
  "logging": "Pino + Pino-HTTP",
  "testing": "Jest + Supertest"
}
```

### AI & External Services
```typescript
{
  "ai": "OpenAI API (GPT-4 Turbo)",
  "rateLimit": "express-rate-limit",
  "cors": "cors middleware",
  "monitoring": "Prometheus + Grafana (optional)"
}
```

---

## Directory Structure

```
formula_quizzer_server/
├── src/
│   ├── config/              # Configuration management
│   │   ├── database.ts      # Database connection config
│   │   ├── openai.ts        # OpenAI API config
│   │   └── env.ts           # Environment variables validation
│   │
│   ├── models/              # Data models and schemas
│   │   ├── subject.ts       # Subject model with validation
│   │   ├── question.ts      # Question model with types
│   │   ├── quiz_session.ts  # Quiz session tracking
│   │   └── user.ts          # User model (optional)
│   │
│   ├── database/            # Database layer
│   │   ├── connection.ts    # DB connection management
│   │   ├── migrations/      # SQL migration files
│   │   ├── repositories/    # Data access layer
│   │   │   ├── subject_repository.ts
│   │   │   ├── question_repository.ts
│   │   │   └── session_repository.ts
│   │   └── seeds/           # Sample data for development
│   │
│   ├── services/            # Business logic layer
│   │   ├── ai_service.ts    # OpenAI integration
│   │   ├── question_generator.ts # Question generation logic
│   │   ├── quiz_service.ts  # Quiz session management
│   │   ├── subject_service.ts # Subject CRUD operations
│   │   └── analytics_service.ts # Progress tracking
│   │
│   ├── routes/              # API route handlers
│   │   ├── api.ts           # Main API router
│   │   ├── subjects.ts      # Subject management endpoints
│   │   ├── questions.ts     # Question CRUD endpoints
│   │   ├── quiz.ts          # Quiz session endpoints
│   │   ├── ai.ts            # AI generation endpoints
│   │   └── health.ts        # Health check endpoints
│   │
│   ├── middleware/          # Express middleware
│   │   ├── auth.ts          # Authentication middleware
│   │   ├── validation.ts    # Request validation
│   │   ├── error_handler.ts # Error handling
│   │   ├── rate_limit.ts    # Rate limiting
│   │   └── logger.ts        # Request logging
│   │
│   ├── utils/               # Utility functions
│   │   ├── cache.ts         # LRU cache implementation
│   │   ├── logger.ts        # Logging setup
│   │   ├── errors.ts        # Custom error classes
│   │   └── helpers.ts       # General helpers
│   │
│   ├── types/               # TypeScript type definitions
│   │   ├── api.ts           # API request/response types
│   │   ├── database.ts      # Database types
│   │   └── index.ts         # Exported types
│   │
│   └── index.ts             # Application entry point
│
├── tests/                   # Test suites
│   ├── unit/                # Unit tests
│   ├── integration/         # Integration tests
│   └── e2e/                 # End-to-end tests
│
├── scripts/                 # Utility scripts
│   ├── migrate.ts           # Database migrations
│   ├── seed.ts              # Seed sample data
│   └── setup.ts             # Initial setup
│
├── docs/                    # Documentation
│   ├── ARCHITECTURE.md      # This file
│   ├── API_SPECIFICATION.md # API documentation
│   ├── DEPLOYMENT_GUIDE.md  # Deployment instructions
│   └── DEVELOPMENT_GUIDE.md # Development workflow
│
├── .env.example             # Environment variables template
├── .gitignore               # Git ignore rules
├── package.json             # Node.js dependencies
├── tsconfig.json            # TypeScript configuration
├── jest.config.js           # Jest test configuration
├── Dockerfile               # Docker container definition
├── docker-compose.yml       # Docker Compose setup
└── README.md                # Project overview
```

---

## Data Flow Architecture

### 1. Question Generation Flow
```
Client Request → Auth Middleware → Validation → AI Service
     ↓
OpenAI API Call → Cache Check → Generate Question
     ↓
Question Repository → Save to Database → Return Response
     ↓
Client Receives → Display Question
```

### 2. Quiz Session Flow
```
Start Quiz → Select Subject → Load Questions (cached or generated)
     ↓
User Answers → Validate Answer → Update Statistics
     ↓
Save Session → Update Subject Performance → Return Feedback
     ↓
Adaptive Learning → Recalculate Subject Priority
```

### 3. Subject Management Flow
```
Create Subject → Validate Input → Check Duplicates
     ↓
Save to Database → Initialize Stats → Return Subject
     ↓
Background: Pre-generate Questions (optional)
```

---

## API Architecture

### RESTful Endpoint Design

```typescript
// Subject Management
GET    /api/v1/subjects           // List all subjects
POST   /api/v1/subjects           // Create new subject
GET    /api/v1/subjects/:id       // Get subject details
PUT    /api/v1/subjects/:id       // Update subject
DELETE /api/v1/subjects/:id       // Delete subject

// Question Management
GET    /api/v1/questions          // List questions (filtered)
POST   /api/v1/questions          // Create question manually
GET    /api/v1/questions/:id      // Get question details
DELETE /api/v1/questions/:id      // Delete question

// AI Generation
POST   /api/v1/ai/generate-question    // Generate single question
POST   /api/v1/ai/generate-batch       // Generate multiple questions
POST   /api/v1/ai/explain-answer       // Get detailed explanation

// Quiz Sessions
POST   /api/v1/quiz/start         // Start new quiz session
POST   /api/v1/quiz/answer        // Submit answer
POST   /api/v1/quiz/complete      // Complete quiz session
GET    /api/v1/quiz/history       // Get quiz history

// Analytics
GET    /api/v1/analytics/overview       // Overall statistics
GET    /api/v1/analytics/subject/:id    // Subject-specific stats
GET    /api/v1/analytics/progress       // Progress over time

// Health & Monitoring
GET    /api/v1/health            // Health check
GET    /api/v1/metrics           // Prometheus metrics (optional)
```

---

## Database Schema

### Core Tables

```sql
-- Subjects Table
CREATE TABLE subjects (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) UNIQUE NOT NULL,
    description TEXT NOT NULL,
    color VARCHAR(7) NOT NULL,            -- Hex color code
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    total_questions INTEGER DEFAULT 0,
    correct_answers INTEGER DEFAULT 0,
    difficulty_weight REAL DEFAULT 0.5,   -- Adaptive learning weight
    metadata JSONB                        -- Flexible metadata storage
);

-- Questions Table
CREATE TABLE questions (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER REFERENCES subjects(id) ON DELETE CASCADE,
    question_text TEXT NOT NULL,
    options JSONB NOT NULL,               -- Array of options
    correct_answer TEXT NOT NULL,
    explanation TEXT NOT NULL,
    difficulty VARCHAR(20) DEFAULT 'medium',
    category VARCHAR(100),
    question_type VARCHAR(20) DEFAULT 'multiple',
    created_at TIMESTAMP DEFAULT NOW(),
    is_from_ai BOOLEAN DEFAULT TRUE,
    source_url TEXT,
    source VARCHAR(100),
    metadata JSONB
);

-- Quiz Sessions Table
CREATE TABLE quiz_sessions (
    id SERIAL PRIMARY KEY,
    subject_id INTEGER REFERENCES subjects(id) ON DELETE CASCADE,
    question_id INTEGER REFERENCES questions(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES users(id),  -- Optional user tracking
    user_answer TEXT NOT NULL,
    is_correct BOOLEAN NOT NULL,
    answered_at TIMESTAMP DEFAULT NOW(),
    time_spent_seconds INTEGER DEFAULT 0,
    difficulty VARCHAR(20) NOT NULL,
    metadata JSONB
);

-- Users Table (Optional - for multi-user support)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE,
    email VARCHAR(255) UNIQUE,
    api_key VARCHAR(64) UNIQUE NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    is_active BOOLEAN DEFAULT TRUE,
    metadata JSONB
);

-- Indexes for Performance
CREATE INDEX idx_questions_subject_id ON questions(subject_id);
CREATE INDEX idx_quiz_sessions_subject_id ON quiz_sessions(subject_id);
CREATE INDEX idx_quiz_sessions_answered_at ON quiz_sessions(answered_at);
CREATE INDEX idx_subjects_is_active ON subjects(is_active);
```

---

## Caching Strategy

### Multi-Layer Caching

```typescript
// Layer 1: In-Memory LRU Cache
const questionCache = new LRUCache({
  maxEntries: 100,      // Store up to 100 subjects
  maxItemsPerKey: 20,   // 20 questions per subject
  ttl: 300000,          // 5 minutes
});

// Layer 2: Redis (Production)
const redisCache = {
  key: 'subject:{subjectId}:questions',
  ttl: 3600,            // 1 hour
  strategy: 'write-through',
};

// Layer 3: Database
const dbCache = {
  indexedQueries: true,
  connectionPool: 10,
};
```

### Cache Invalidation Rules
- Clear subject cache when subject is updated/deleted
- Clear question cache when questions are added/removed
- TTL-based expiration for AI-generated content
- Manual cache clear via admin endpoint

---

## Error Handling

### Error Response Format
```typescript
interface ErrorResponse {
  error: string;         // Error code (snake_case)
  message: string;       // Human-readable message
  statusCode: number;    // HTTP status code
  timestamp: string;     // ISO timestamp
  path: string;          // Request path
  details?: any;         // Additional context (dev only)
}
```

### Error Categories
- `validation_error` (400) - Invalid input
- `not_found` (404) - Resource not found
- `rate_limit_exceeded` (429) - Too many requests
- `ai_service_unavailable` (503) - OpenAI API down
- `database_error` (500) - Database operation failed
- `internal_server_error` (500) - Unexpected error

---

## Performance Requirements

### Response Time Targets
- Health check: < 50ms
- Simple CRUD: < 100ms
- AI generation: < 3000ms (with caching < 200ms)
- Analytics queries: < 500ms
- Batch operations: < 5000ms

### Scalability Targets
- Support 1000+ concurrent users
- Handle 100 req/sec sustained load
- Database: 10k+ questions per subject
- Cache: 100 subjects with 2000 questions total

---

## Security Architecture

### Authentication & Authorization
```typescript
// API Key Authentication
headers: {
  'Authorization': 'Bearer <api_key>',
  'Content-Type': 'application/json'
}

// Rate Limiting
- Per API Key: 100 req/min
- Per IP: 60 req/min
- Burst: 10 req/sec
```

### Input Validation
- All inputs validated with Zod schemas
- SQL injection prevention (parameterized queries)
- XSS prevention (sanitized outputs)
- CORS whitelist configuration

---

## Monitoring & Observability

### Structured Logging
```typescript
{
  "timestamp": "2024-10-13T09:19:04-04:00",
  "level": "info",
  "msg": "Question generated",
  "subject_id": 42,
  "question_id": 1234,
  "duration_ms": 1850,
  "cache_hit": false,
  "tokens_used": 725
}
```

### Metrics to Track
- Request rate per endpoint
- Response time percentiles (p50, p95, p99)
- Error rate by type
- Cache hit rate
- OpenAI API usage and costs
- Database connection pool utilization

---

## Testing Strategy

### Test Pyramid
```
       /\
      /e2e\        10% - End-to-end tests
     /------\
    /integ. \      30% - Integration tests
   /----------\
  /   unit     \   60% - Unit tests
 /--------------\
```

### Coverage Requirements
- Unit tests: > 80% coverage
- Integration tests: All API endpoints
- E2E tests: Critical user flows
- Load tests: Performance benchmarks

---

## Deployment Architecture

### Development Environment
```
Local Machine
  ├── Node.js server (port 3000)
  ├── PostgreSQL (Docker, port 5432)
  ├── Redis (Docker, port 6379)
  └── OpenAI API (external)
```

### Production Environment
```
Cloud Platform (Railway/Render/AWS)
  ├── API Servers (auto-scaling, 2+ instances)
  ├── Load Balancer (HTTPS, SSL termination)
  ├── PostgreSQL (managed service)
  ├── Redis (managed service)
  ├── Monitoring (Prometheus + Grafana)
  └── Logging (CloudWatch/Datadog)
```

---

## Integration Points

### With Flutter App
```typescript
// Flutter app calls this server's API
FlutterApp → HTTP Client → formula_quizzer_server API
  ↓
Response: JSON data (subjects, questions, analytics)
```

### With Other Clients
- Web dashboard (React/Vue)
- Mobile apps (iOS/Android native)
- CLI tools
- Third-party integrations via API keys

---

## Future Enhancements

### Planned Features
- [ ] Multi-user support with authentication
- [ ] Real-time quiz multiplayer mode
- [ ] Advanced analytics with ML insights
- [ ] Question recommendation engine
- [ ] Spaced repetition algorithm
- [ ] Import/export functionality
- [ ] Webhook support for events
- [ ] GraphQL API option

### Technical Improvements
- [ ] Microservices architecture (split AI service)
- [ ] Message queue for async operations
- [ ] CDN for static assets
- [ ] Multi-region deployment
- [ ] Advanced caching with CDN edge cache

---

## Design Patterns

### Repository Pattern
- Separate data access from business logic
- Makes testing easier with mocks
- Database-agnostic interface

### Service Layer Pattern
- Business logic in service classes
- Reusable across different endpoints
- Clear separation of concerns

### Middleware Chain Pattern
- Request processing pipeline
- Composable middleware functions
- Easy to add/remove features

---

## Conclusion

This architecture provides a solid foundation for a scalable, maintainable, and secure educational quiz backend. The design emphasizes **separation of concerns**, **testability**, and **production-readiness** while maintaining **complete independence** from the Flutter app.

The server can be deployed standalone and consumed by any client application through its RESTful API.
