# Getting Started with FormulaQuizzer Server

Complete setup guide to get the FormulaQuizzer Server running on your local machine.

---

## ⚠️ Important Note

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                   │
│  THIS SERVER IS COMPLETELY INDEPENDENT                           │
│                                                                   │
│  ✅ Works standalone without the Flutter app                    │
│  ✅ Has its own database and configuration                      │
│  ✅ Can be tested independently                                 │
│  ⛔ NEVER modifies files in ../formula_quizzer/                │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## Prerequisites

### Required Software

| Software | Version | Installation |
|----------|---------|--------------|
| **Node.js** | 20+ LTS | `brew install node` (macOS) |
| **PostgreSQL** | 15+ | `brew install postgresql@15` (macOS) |
| **npm** | 10+ | Comes with Node.js |

### Optional Software

| Software | Purpose | Installation |
|----------|---------|--------------|
| **Redis** | Caching (optional) | `brew install redis` |
| **Docker** | Containerization | Download from docker.com |
| **Postman** | API testing | Download from postman.com |

### External Services

- **OpenAI API Key**: Get from https://platform.openai.com/api-keys
  - Costs: ~$0.02-0.04 per MCQ generated
  - Set up billing alerts to monitor usage

---

## Installation Steps

### Step 1: Clone or Navigate to Project

```bash
cd /Users/ethanchen/Desktop/App\ Innovation/formula_quizzer_server
```

### Step 2: Install Dependencies

```bash
npm install
```

**Expected Output:**
```
added 245 packages, and audited 246 packages in 15s
```

### Step 3: Set Up PostgreSQL Database

#### Option A: Local PostgreSQL

```bash
# Start PostgreSQL service
brew services start postgresql@15

# Create database
createdb formula_quizzer

# Create user (optional)
psql postgres -c "CREATE USER formula_quizzer_user WITH PASSWORD 'your_password';"
psql postgres -c "GRANT ALL PRIVILEGES ON DATABASE formula_quizzer TO formula_quizzer_user;"
```

#### Option B: Docker PostgreSQL

```bash
docker run --name formula-quizzer-db \
  -e POSTGRES_DB=formula_quizzer \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=password \
  -p 5432:5432 \
  -d postgres:15-alpine
```

### Step 4: Configure Environment Variables

Create `.env` file in the project root:

```bash
cp .env.example .env
```

Edit `.env` with your configuration:

```bash
# Server Configuration
NODE_ENV=development
PORT=3000
LOG_LEVEL=debug

# Database Configuration
DATABASE_URL=postgresql://postgres:password@localhost:5432/formula_quizzer

# OpenAI Configuration
OPENAI_API_KEY=sk-your-api-key-here

# Authentication (generate secure keys)
JWT_SECRET=$(node -e "console.log(require('crypto').randomBytes(32).toString('hex'))")
API_KEYS=dev_key_1,dev_key_2

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=60

# CORS
CORS_ORIGIN=http://localhost:8080,http://localhost:3000
```

### Step 5: Run Database Migrations

```bash
npm run migrate
```

**Expected Output:**
```
✅ Migration 001_create_subjects completed
✅ Migration 002_create_questions completed
✅ Migration 003_create_quiz_sessions completed
✅ Migration 004_create_indexes completed
```

### Step 6: Seed Sample Data (Optional)

```bash
npm run seed
```

**Expected Output:**
```
✅ Created 5 subjects
✅ Created 50 questions
✅ Database seeded successfully
```

### Step 7: Start Development Server

```bash
npm run dev
```

**Expected Output:**
```
Server started on port 3000
Database connected
✨ Ready to accept requests at http://localhost:3000
```

---

## Verify Installation

### Health Check

```bash
curl http://localhost:3000/api/v1/health
```

**Expected Response:**
```json
{
  "status": "ok",
  "timestamp": "2024-10-13T09:19:04-04:00",
  "services": {
    "database": "ok",
    "openai": "ok"
  }
}
```

### Test API Authentication

```bash
curl -H "Authorization: Bearer dev_key_1" \
     http://localhost:3000/api/v1/subjects
```

**Expected Response:**
```json
{
  "data": [],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 0,
    "total_pages": 0
  }
}
```

### Create Test Subject

```bash
curl -X POST \
  -H "Authorization: Bearer dev_key_1" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Physics",
    "description": "Test physics subject",
    "color": "#2196F3"
  }' \
  http://localhost:3000/api/v1/subjects
```

**Expected Response:**
```json
{
  "id": 1,
  "name": "Test Physics",
  "description": "Test physics subject",
  "color": "#2196F3",
  "created_at": "2024-10-13T09:00:00Z",
  "is_active": true,
  ...
}
```

### Generate AI Question (Requires OpenAI API Key)

```bash
curl -X POST \
  -H "Authorization: Bearer dev_key_1" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_id": 1,
    "difficulty": "medium",
    "num_choices": 4
  }' \
  http://localhost:3000/api/v1/ai/generate-question
```

**Expected Response:**
```json
{
  "id": 1,
  "subject_id": 1,
  "question_text": "What is the acceleration due to gravity on Earth?",
  "options": ["9.8 m/s²", "10 m/s²", "8.9 m/s²", "11 m/s²"],
  "correct_answer": "9.8 m/s²",
  "explanation": "The standard acceleration due to gravity...",
  ...
}
```

---

## Development Workflow

### Run in Development Mode (Hot Reload)

```bash
npm run dev
```

Changes to files in `src/` will automatically restart the server.

### Run Tests

```bash
# Run all tests
npm test

# Run tests in watch mode
npm run test:watch

# Run tests with coverage
npm run test:coverage
```

### Lint Code

```bash
npm run lint
```

### Format Code

```bash
npm run format
```

### Build for Production

```bash
npm run build
```

Output will be in `dist/` directory.

### Start Production Server

```bash
npm start
```

---

## Project Structure Overview

```
formula_quizzer_server/
├── src/
│   ├── config/         # Configuration files
│   ├── models/         # Data models
│   ├── database/       # Database layer
│   ├── services/       # Business logic
│   ├── routes/         # API routes
│   ├── middleware/     # Express middleware
│   ├── utils/          # Utilities
│   ├── types/          # TypeScript types
│   └── index.ts        # Entry point
├── tests/              # Test suites
├── scripts/            # Utility scripts
├── docs/               # Documentation
├── .env                # Environment variables (DO NOT COMMIT)
├── .env.example        # Environment template
├── package.json        # Dependencies
└── tsconfig.json       # TypeScript config
```

**See [PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md) for detailed explanation.**

---

## Common Issues & Solutions

### Issue: Port 3000 Already in Use

**Solution:**
```bash
# Find process using port 3000
lsof -ti:3000

# Kill the process
kill -9 <PID>

# Or change port in .env
PORT=3001
```

### Issue: Database Connection Failed

**Solution:**
```bash
# Check PostgreSQL is running
brew services list | grep postgresql

# Start PostgreSQL if stopped
brew services start postgresql@15

# Test connection
psql -U postgres -d formula_quizzer -c "SELECT 1"
```

### Issue: OpenAI API Key Invalid

**Solution:**
```bash
# Verify API key is set
echo $OPENAI_API_KEY

# Test API key
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

# Get new key from: https://platform.openai.com/api-keys
```

### Issue: npm install Fails

**Solution:**
```bash
# Clear npm cache
npm cache clean --force

# Delete node_modules and package-lock.json
rm -rf node_modules package-lock.json

# Reinstall
npm install
```

### Issue: TypeScript Build Errors

**Solution:**
```bash
# Clean dist folder
rm -rf dist

# Rebuild
npm run build

# Check TypeScript version
npx tsc --version
```

---

## Next Steps

### 1. Explore the API

- Review [API_SPECIFICATION.md](./API_SPECIFICATION.md) for all endpoints
- Use Postman or curl to test endpoints
- Try generating questions with different parameters

### 2. Read Documentation

- **[README.md](./README.md)** - Project overview
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System design
- **[DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)** - Coding standards
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Production deployment

### 3. Start Development

```bash
# Create a new feature branch
git checkout -b feature/my-new-feature

# Make changes
# Write tests
npm test

# Commit changes
git add .
git commit -m "feat: add new feature"
```

### 4. Integration with Flutter App

The Flutter app (`formula_quizzer`) can consume this API:

```dart
// In Flutter app
final apiClient = Dio(BaseOptions(
  baseUrl: 'http://localhost:3000/api/v1',
  headers: {'Authorization': 'Bearer dev_key_1'},
));

final response = await apiClient.get('/subjects');
```

---

## Useful Commands Cheat Sheet

```bash
# Development
npm run dev              # Start dev server with hot reload
npm test                 # Run tests
npm run lint             # Check code style
npm run format           # Format code

# Database
npm run migrate          # Run migrations
npm run seed             # Seed sample data
psql $DATABASE_URL       # Connect to database

# Production
npm run build            # Build for production
npm start                # Start production server

# Docker
docker-compose up -d     # Start all services
docker-compose logs -f   # View logs
docker-compose down      # Stop services

# Cleanup
rm -rf node_modules      # Remove dependencies
rm -rf dist              # Remove build output
npm cache clean --force  # Clear npm cache
```

---

## Environment Variables Reference

### Required

| Variable | Description | Example |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://user:pass@host:5432/db` |
| `OPENAI_API_KEY` | OpenAI API key | `sk-proj-abc123...` |
| `JWT_SECRET` | JWT signing secret (min 32 chars) | Random hex string |
| `API_KEYS` | Comma-separated API keys | `key1,key2,key3` |

### Optional

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | `3000` |
| `NODE_ENV` | Environment | `development` |
| `LOG_LEVEL` | Logging level | `info` |
| `REDIS_URL` | Redis connection string | - |
| `CORS_ORIGIN` | Allowed origins | `*` |
| `RATE_LIMIT_WINDOW_MS` | Rate limit window | `60000` |
| `RATE_LIMIT_MAX_REQUESTS` | Max requests per window | `60` |

---

## Testing the Server

### Unit Tests

```bash
npm run test:unit
```

Tests individual functions and classes in isolation.

### Integration Tests

```bash
npm run test:integration
```

Tests API endpoints with real database.

### End-to-End Tests

```bash
npm run test:e2e
```

Tests complete user flows.

### Test Coverage

```bash
npm run test:coverage
```

Generates coverage report in `coverage/` directory.

---

## API Testing with Postman

### Import Collection

1. Download [Postman Collection](./postman_collection.json)
2. Open Postman
3. Click "Import" → Select file
4. Configure environment variables:
   - `BASE_URL`: `http://localhost:3000/api/v1`
   - `API_KEY`: `dev_key_1`

### Test Endpoints

Use the pre-configured requests in the collection to test all API endpoints.

---

## Development Tips

### Hot Reload

The server automatically restarts when you save files in `src/`. No need to manually restart!

### Debugging

```bash
# Start with debugger
node --inspect dist/index.js

# Or use VS Code debugger
# Add breakpoints and press F5
```

### Database Inspection

```bash
# Connect to database
psql $DATABASE_URL

# View tables
\dt

# View subjects
SELECT * FROM subjects;

# View questions
SELECT * FROM questions LIMIT 10;
```

### Log Levels

Set `LOG_LEVEL` in `.env`:
- `debug` - All logs (development)
- `info` - Important events (default)
- `warn` - Warnings only
- `error` - Errors only

---

## Getting Help

### Documentation

- **[README.md](./README.md)** - Start here
- **[ARCHITECTURE.md](./ARCHITECTURE.md)** - System design
- **[API_SPECIFICATION.md](./API_SPECIFICATION.md)** - API reference
- **[DEVELOPMENT_GUIDE.md](./DEVELOPMENT_GUIDE.md)** - Best practices
- **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** - Production deployment
- **[PROJECT_STRUCTURE.md](./PROJECT_STRUCTURE.md)** - File organization

### Troubleshooting

1. Check server logs: `npm run dev`
2. Test health endpoint: `curl http://localhost:3000/api/v1/health`
3. Verify environment variables: `cat .env`
4. Check database connection: `psql $DATABASE_URL -c "SELECT 1"`
5. Review error messages carefully

### Community Resources

- Node.js Documentation: https://nodejs.org/docs
- Express.js Guide: https://expressjs.com/guide
- TypeScript Handbook: https://www.typescriptlang.org/docs
- PostgreSQL Docs: https://www.postgresql.org/docs
- OpenAI API Reference: https://platform.openai.com/docs

---

## Quick Start Summary

```bash
# 1. Install dependencies
npm install

# 2. Set up database
createdb formula_quizzer

# 3. Configure environment
cp .env.example .env
# Edit .env with your values

# 4. Run migrations
npm run migrate

# 5. Start server
npm run dev

# 6. Test health
curl http://localhost:3000/api/v1/health

# ✅ You're ready to develop!
```

---

## What's Next?

Now that you have the server running:

1. **Explore the API** - Try different endpoints with curl or Postman
2. **Read the docs** - Understand the architecture and design patterns
3. **Write tests** - Add tests for your new features
4. **Deploy** - Follow [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) to deploy to production
5. **Integrate** - Connect the Flutter app to use this API

---

**Happy Coding!** 🚀

If you encounter any issues, refer to the troubleshooting section or review the comprehensive documentation in the `/docs` directory.

---

**Last Updated:** 2024-10-13  
**Project Version:** 1.0.0
