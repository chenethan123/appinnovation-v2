## FormulaQuizzer – Cursor AI Overview

This folder contains quick-reference docs for working on the project with AI tools.

### High-level
- **Frontend**: Flutter app with Riverpod; local SQLite; notifications; optional Supabase sync.
- **Backend**: Node.js/Express + OpenAI; endpoints to generate MCQs; simple in-memory cache.

### Primary entry points
- App entry: `lib/main.dart` → initializes notifications, loads default courses, optional Supabase, runs `AuthScreen`.
- Server entry: `server/src/index.ts` → Express API, rate limiting, pino logging, cache, routes.

### Key flows
- Manual/Timer quiz → subject picked (adaptive) → AI backend `POST /api/generate-mcq` → display MCQ → save to SQLite → stats update.
- Batch pre-warm → `POST /api/generate-mcq-batch` → cache filled → faster UX, lower cost.

### Important configuration
- Flutter config: `lib/config/api_config.dart` (base URL, timeouts, Supabase toggles/keys).
- Server config: `.env` (OPENAI_API_KEY, PORT, CORS_ORIGIN, LOG_LEVEL).

### Useful docs in repo
- `README.md`, `STARTUP_GUIDE.md`, `PRODUCTION_DEPLOYMENT.md`, `ARCHITECTURE.md`.

### Quick links
- Frontend map: `AI/cursor/FRONTEND.md`
- Backend map: `AI/cursor/BACKEND.md`
- Endpoints: `AI/cursor/ENDPOINTS.md`
- Config notes: `AI/cursor/CONFIG.md`


