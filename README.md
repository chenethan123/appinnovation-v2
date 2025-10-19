# FormulaQuizzer - Unified Client & Server

Complete FormulaQuizzer system with **Flutter client** and **Node.js server** in one place.

## Directory Structure

```
formula_quizzer_unified/
├── client/              # Flutter mobile/desktop app
│   ├── lib/            # Flutter source code
│   ├── README.md       # Client documentation
│   └── QUICK_START.md  # Quick start guide
│
└── server/              # Node.js + TypeScript backend
    ├── src/            # Server source code
    ├── API_SPECIFICATION.md # 40+ API endpoints
    ├── ARCHITECTURE.md      # System architecture
    └── README.md           # Server documentation
```

## Quick Start (5 minutes)

### 1. Start the Server

```bash
cd server
npm install
npm run dev
```

✅ Server runs at: **http://localhost:3000**

### 2. Run the Client

```bash
# Open a new terminal
cd client
flutter pub get
flutter run
```

Choose your device when prompted (iOS/Android/macOS/Chrome).

---

## Features

### Client (Flutter)
- ✅ Cross-platform (iOS, Android, macOS, Web)
- ✅ Offline-first with SQLite
- ✅ Real-time server sync
- ✅ Material 3 UI with dark mode
- ✅ Riverpod state management

### Server (Node.js + TypeScript)
- ✅ REST API with 40+ endpoints
- ✅ PostgreSQL database (SQLite for dev)
- ✅ OpenAI GPT-4 Turbo integration
- ✅ JWT authentication
- ✅ Rate limiting & caching

---

## Documentation

| Topic | Location |
|-------|----------|
| **Client Quick Start** | `client/QUICK_START.md` |
| **Client Full Docs** | `client/README.md` |
| **Server Quick Start** | `server/QUICK_START.md` |
| **Server Full Docs** | `server/README.md` |
| **API Reference** | `server/API_SPECIFICATION.md` |
| **Architecture** | `server/ARCHITECTURE.md` |
| **Deployment** | `server/DEPLOYMENT_GUIDE.md` |

---

## Development Workflow

**Typical Development:**

```bash
# Terminal 1: Run server
cd server && npm run dev

# Terminal 2: Run client  
cd client && flutter run
```

**Hot Reload:**
- Press `r` in Flutter terminal for hot reload
- Server auto-reloads on file changes

---

## Testing

### Test Server Health

```bash
curl http://localhost:3000/api/v1/health
```

Should return:
```json
{
  "status": "healthy",
  "timestamp": "2025-10-14T09:42:00.000Z"
}
```

### Test Client

1. Create a subject
2. Start a quiz
3. Answer questions
4. See immediate feedback

---

## Tech Stack

| Component | Technology |
|-----------|-----------|
| **Client** | Flutter 3.5+, Dart 3.5+ |
| **State Mgmt** | Riverpod 2.6+ |
| **Local DB** | SQLite (sqflite) |
| **Server** | Node.js 20+, TypeScript 5.9+ |
| **API** | Express.js |
| **Database** | PostgreSQL 15+ |
| **AI** | OpenAI GPT-4 Turbo |
| **Auth** | JWT |

---

## Project Stats

```
Client:
  - 3 models (Subject, Question, QuizSession)
  - 3 screens (Home, AddSubject, Quiz)
  - 2 providers (Subject, Quiz)
  - 1 API service
  - 1 local database (SQLite)

Server:
  - 40+ API endpoints
  - 8 database models
  - OpenAI integration
  - JWT authentication
  - Rate limiting
```

---

## Common Commands

### Client

```bash
# Install dependencies
cd client && flutter pub get

# Run on specific device
flutter run -d ios      # iOS Simulator
flutter run -d android  # Android Emulator
flutter run -d macos    # macOS Desktop
flutter run -d chrome   # Web Browser

# Build release
flutter build apk --release     # Android
flutter build ios --release     # iOS
flutter build macos --release   # macOS

# Clean build
flutter clean && flutter pub get
```

### Server

```bash
# Install dependencies
cd server && npm install

# Development mode (with auto-reload)
npm run dev

# Production mode
npm run build
npm start

# Database migrations
npm run migrate

# Run tests
npm test
```

---

## Troubleshooting

### "Server unavailable" in Client

**Check:**
1. Is server running? `cd server && npm run dev`
2. Correct URL in `client/lib/config/api_config.dart`?
3. Using device IP (not localhost) for physical devices?

**Fix for physical device:**
```dart
// client/lib/config/api_config.dart
static const String baseUrl = 'http://192.168.1.XXX:3000';
```

### Build Errors in Client

```bash
cd client
flutter clean
flutter pub get
flutter run
```

### Server Won't Start

**Check:**
1. Node.js installed? `node --version`
2. Dependencies installed? `npm install`
3. Port 3000 available? `lsof -i :3000`

---

## API Quick Reference

```
Health Check
  GET  /api/v1/health

Subjects
  GET    /api/v1/subjects
  POST   /api/v1/subjects
  DELETE /api/v1/subjects/:id

Questions
  GET    /api/v1/questions?subject_id=:id
  POST   /api/v1/questions

AI Generation
  POST   /api/v1/ai/generate-question
  POST   /api/v1/ai/generate-questions-batch

Quiz
  POST   /api/v1/quiz/start
  POST   /api/v1/quiz/answer
  POST   /api/v1/quiz/complete
```

Full API documentation: `server/API_SPECIFICATION.md`

---

## License

MIT License

---

## Support

**Questions?**
- Check `client/README.md` for client issues
- Check `server/README.md` for server issues
- Review `server/API_SPECIFICATION.md` for API details

**Built with ❤️ using Flutter and Node.js**
