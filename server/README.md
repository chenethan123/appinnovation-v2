# FormulaQuizzer Server 🎓

**A standalone backend API for educational quiz services with AI-powered question generation, subject management, and adaptive learning.**

---

## ⚠️ Important Notice

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  THIS IS A STANDALONE SERVER PROJECT                             │
│                                                                   │
│  ✅ Independent from formula_quizzer Flutter app                │
│  ✅ Separate codebase and database                              │
│  ✅ Can be used by any client (Flutter, React, CLI, etc.)       │
│  ⛔ WILL NOT modify or touch the original formula_quizzer/      │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Quick Start

### Prerequisites

- **Node.js 20+** LTS
- **PostgreSQL 15+** (or SQLite for development)
- **OpenAI API Key** (for AI question generation)

### Installation

```bash
# Clone or navigate to the project
cd formula_quizzer_server

# Install dependencies
npm install

# Copy environment variables
cp .env.example .env

# Edit .env and add your OpenAI API key
nano .env

# Run database migrations
npm run migrate

# Start development server
npm run dev
```

Server will start on `http://localhost:3000`

### Quick Test

```bash
# Health check
curl http://localhost:3000/api/v1/health

# Expected response:
# {"status":"ok","timestamp":"2024-10-13T09:19:04-04:00"}
```

---

## ✨ Features

### 🤖 AI-Powered Question Generation
- OpenAI GPT-4 Turbo integration for intelligent MCQ generation
- Subject-specific question generation with context awareness
- Option-specific explanations (why each choice is right/wrong)
- Fallback mechanisms for API failures
- Cost optimization with smart caching (~70% API cost reduction)

### 📚 Subject Management
- Unlimited subject creation with color coding
- Active/inactive status management
- Performance tracking (accuracy, total questions)
- Adaptive learning algorithm for quiz prioritization
- Subject metadata support (custom fields via JSONB)

### 📝 Question Management
- Multiple question types (multiple choice, true/false, fill-blank)
- Difficulty levels (easy, medium, hard)
- Source attribution (AI-generated, scraped, manual)
- Category tagging and filtering
- Bulk import/export capabilities

### 📊 Analytics & Progress Tracking
- Real-time performance statistics
- Subject-specific analytics
- Quiz session history with time tracking
- Adaptive learning priority calculation
- Progress over time visualization data

### 🔒 Security & Performance
- API key authentication
- Rate limiting (60 req/min per IP)
- Input validation with Zod schemas
- LRU caching for question responses
- PostgreSQL with connection pooling
- Structured logging with Pino

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | Complete system architecture and design patterns |
| **[API_SPECIFICATION.md](./API_SPECIFICATION.md)** | Detailed API endpoint documentation |
| **[DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)** | Development workflows and coding standards |
| **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** | Production deployment instructions |
| **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** | Directory layout and file organization |

---

## 🛠️ Technology Stack

### Core Technologies
- **Runtime**: Node.js 20+ LTS
- **Language**: TypeScript 5.x
- **Framework**: Express 4.x
- **Database**: PostgreSQL 15+ | SQLite 3.x (development)
- **Caching**: Redis 7.x (optional) + In-memory LRU
- **Validation**: Zod 3.x
- **Authentication**: JWT + API Keys
- **Logging**: Pino + Pino-HTTP
- **Testing**: Jest + Supertest

### External Services
- **AI**: OpenAI API (GPT-4 Turbo)
- **Monitoring**: Prometheus + Grafana (optional)
- **Deployment**: Railway, Render, AWS, Docker

---

## 📋 API Overview

### Base URL
```
Development: http://localhost:3000/api/v1
Production:  https://your-domain.com/api/v1
```

### Authentication
```bash
# All requests require API key (except health check)
curl -H "Authorization: Bearer YOUR_API_KEY" \
     http://localhost:3000/api/v1/subjects
```

### Core Endpoints

#### Subjects
```bash
GET    /api/v1/subjects           # List all subjects
POST   /api/v1/subjects           # Create new subject
GET    /api/v1/subjects/:id       # Get subject details
PUT    /api/v1/subjects/:id       # Update subject
DELETE /api/v1/subjects/:id       # Delete subject
```

#### Questions
```bash
GET    /api/v1/questions          # List questions (with filters)
POST   /api/v1/questions          # Create question manually
GET    /api/v1/questions/:id      # Get question details
DELETE /api/v1/questions/:id      # Delete question
```

#### AI Generation
```bash
POST   /api/v1/ai/generate-question    # Generate single question
POST   /api/v1/ai/generate-batch       # Generate multiple questions
POST   /api/v1/ai/explain-answer       # Get detailed explanation
```

#### Quiz Sessions
```bash
POST   /api/v1/quiz/start         # Start new quiz session
POST   /api/v1/quiz/answer        # Submit answer
POST   /api/v1/quiz/complete      # Complete quiz session
GET    /api/v1/quiz/history       # Get quiz history
```

#### Analytics
```bash
GET    /api/v1/analytics/overview       # Overall statistics
GET    /api/v1/analytics/subject/:id    # Subject-specific stats
GET    /api/v1/analytics/progress       # Progress over time
```

#### Health & Monitoring
```bash
GET    /api/v1/health            # Health check (no auth required)
GET    /api/v1/metrics           # Prometheus metrics (optional)
```

**📚 Full API Documentation**: See [API_SPECIFICATION.md](./API_SPECIFICATION.md)

---

## 🎯 Example Usage

### Create a Subject

```bash
curl -X POST http://localhost:3000/api/v1/subjects \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "AP Physics 1",
    "description": "College-level introductory physics",
    "color": "#2196F3"
  }'
```

### Generate AI Question

```bash
curl -X POST http://localhost:3000/api/v1/ai/generate-question \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_id": 1,
    "difficulty": "medium",
    "num_choices": 4
  }'
```

### Start Quiz Session

```bash
curl -X POST http://localhost:3000/api/v1/quiz/start \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_id": 1,
    "num_questions": 10
  }'
```

---

## 🔧 Development

### Project Structure

```
formula_quizzer_server/
├── src/
│   ├── config/              # Configuration management
│   ├── models/              # Data models and schemas
│   ├── database/            # Database layer (repositories, migrations)
│   ├── services/            # Business logic layer
│   ├── routes/              # API route handlers
│   ├── middleware/          # Express middleware
│   ├── utils/               # Utility functions
│   └── index.ts             # Application entry point
├── tests/                   # Test suites
├── scripts/                 # Utility scripts
├── docs/                    # Documentation
└── package.json             # Dependencies
```

### Development Workflow

```bash
# Install dependencies
npm install

# Run in development mode (hot reload)
npm run dev

# Run tests
npm test

# Run tests with coverage
npm run test:coverage

# Lint code
npm run lint

# Format code
npm run format

# Build for production
npm run build

# Start production server
npm start
```

### Environment Variables

Create `.env` file in the root directory:

```env
# Server Configuration
NODE_ENV=development
PORT=3000
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgresql://user:password@localhost:5432/formula_quizzer
# Or for SQLite:
# DATABASE_URL=sqlite:./database.sqlite

# Redis Configuration (optional)
REDIS_URL=redis://localhost:6379

# OpenAI Configuration
OPENAI_API_KEY=sk-your-api-key-here

# Authentication
JWT_SECRET=your-jwt-secret-here
API_KEYS=key1,key2,key3  # Comma-separated list

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=60

# CORS
CORS_ORIGIN=http://localhost:8080,https://your-domain.com
```

---

## 🧪 Testing

### Run All Tests
```bash
npm test
```

### Run Unit Tests Only
```bash
npm run test:unit
```

### Run Integration Tests
```bash
npm run test:integration
```

### Generate Coverage Report
```bash
npm run test:coverage
```

### Test Coverage Requirements
- **Unit Tests**: > 80% coverage
- **Integration Tests**: All API endpoints
- **E2E Tests**: Critical user flows

---

## 🚢 Deployment

### Docker Deployment

```bash
# Build Docker image
docker build -t formula-quizzer-server .

# Run container
docker run -p 3000:3000 \
  -e OPENAI_API_KEY=your-key \
  -e DATABASE_URL=your-db-url \
  formula-quizzer-server
```

### Docker Compose

```bash
# Start all services (API, PostgreSQL, Redis)
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### Cloud Platforms

#### Railway
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway up
```

#### Render
1. Connect GitHub repository
2. Select "Web Service"
3. Set environment variables
4. Deploy automatically on push

#### AWS/Heroku/Fly.io
See [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) for detailed instructions.

---

## 📊 Monitoring & Observability

### Structured Logging

All logs are in JSON format for easy parsing:

```json
{
  "timestamp": "2024-10-13T09:19:04-04:00",
  "level": "info",
  "msg": "Question generated successfully",
  "subject_id": 1,
  "question_id": 42,
  "duration_ms": 1850,
  "cache_hit": false,
  "tokens_used": 725
}
```

### Health Check

```bash
curl http://localhost:3000/api/v1/health
```

### Metrics (Prometheus)

```bash
curl http://localhost:3000/api/v1/metrics
```

---

## 💰 Cost Optimization

### OpenAI API Costs
- **GPT-4 Turbo**: ~$0.02-0.04 per MCQ
- **LRU Cache**: Reduces API calls by ~70%
- **Batch Generation**: No additional cost savings (same per-MCQ price)
- **Monitor Usage**: https://platform.openai.com/usage

### Recommendations
- Set OpenAI billing alerts
- Use batch generation to pre-warm cache
- Enable Redis for production caching
- Monitor token usage per subject

---

## 🔒 Security Best Practices

### ✅ Implemented
- ✅ API key authentication
- ✅ Request validation with Zod
- ✅ Rate limiting per IP/API key
- ✅ CORS configuration
- ✅ Environment-based secrets
- ✅ SQL injection prevention (parameterized queries)
- ✅ No PII in logs

### 🚨 Production Checklist
- [ ] Use HTTPS only
- [ ] Rotate API keys regularly
- [ ] Set up database backups
- [ ] Configure firewall rules
- [ ] Enable audit logging
- [ ] Set up monitoring alerts
- [ ] Use secrets manager (AWS Secrets Manager, Vault)

---

## 🐛 Troubleshooting

### Server Won't Start

```bash
# Check Node.js version
node --version  # Should be 20+

# Clean install
rm -rf node_modules package-lock.json
npm install

# Check environment variables
cat .env
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
psql -h localhost -U postgres -d formula_quizzer

# Check DATABASE_URL format
echo $DATABASE_URL
```

### OpenAI API Errors

```bash
# Verify API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Check OpenAI status
open https://status.openai.com
```

### Rate Limit Errors

- Wait 60 seconds and retry
- Implement exponential backoff on client side
- Consider increasing rate limits in `.env`

---

## 🤝 Integration with Flutter App

The Flutter app (`formula_quizzer`) can consume this API:

### Flutter HTTP Client Example

```dart
import 'package:dio/dio.dart';

class FormulaQuizzerApiClient {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:3000/api/v1',
    headers: {'Authorization': 'Bearer YOUR_API_KEY'},
  ));

  Future<List<Subject>> getSubjects() async {
    final response = await _dio.get('/subjects');
    return (response.data as List)
        .map((json) => Subject.fromJson(json))
        .toList();
  }

  Future<Question> generateQuestion(int subjectId) async {
    final response = await _dio.post('/ai/generate-question', data: {
      'subject_id': subjectId,
      'difficulty': 'medium',
      'num_choices': 4,
    });
    return Question.fromJson(response.data);
  }
}
```

---

## 📚 Additional Resources

### Documentation
- [Architecture Overview](./ARCHITECTURE.md)
- [API Reference](./API_SPECIFICATION.md)
- [Development Guide](./DEVELOPMENT_GUIDE.md)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)

### External Links
- [OpenAI API Documentation](https://platform.openai.com/docs)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Express.js Documentation](https://expressjs.com/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

---

## 📄 License

MIT License - See [LICENSE](./LICENSE) file for details.

---

## 🙋 Support

### Common Issues
1. **Database connection failed** → Check DATABASE_URL and PostgreSQL service
2. **OpenAI API timeout** → Check API key and network connectivity
3. **Rate limit exceeded** → Wait and implement exponential backoff
4. **Port already in use** → Change PORT in .env or kill process

### Getting Help
- Check [TROUBLESHOOTING.md](./docs/TROUBLESHOOTING.md)
- Review logs with `npm run dev`
- Test OpenAI key in playground
- Check OpenAI status page

---

## 🎓 Educational Disclaimer

**This server generates educational content for learning purposes only.**

All AI-generated questions and explanations should be verified with authoritative sources. This tool is designed to supplement, not replace, traditional educational materials.

---

**Ready to start?** → `npm run dev`

🚀 Happy coding!
