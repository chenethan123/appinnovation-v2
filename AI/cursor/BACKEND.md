## Backend (Node/Express) Quick Map

### Entry
- `server/src/index.ts`: Express app, middleware (CORS, JSON, pino), rate limiting, cache setup, routes, error handlers, server start.

### Core modules
- `server/src/openai.ts`:
  - `MODEL = gpt-4-turbo-preview`
  - `MCQSchema` (zod) defining response contract
  - `generateMcq(subject, choices, difficulty?)`
  - `generateMcqBatch(subject, choices, count)` (concurrent)
- `server/src/cache.ts`:
  - `LRUCache<T>` with TTL
  - `MCQCache` keyed by `subject:choices`, stores small arrays for variety

### Routes
- `POST /api/generate-mcq` → body: `{ subject, choices?, difficulty? }` → returns `MCQ`
- `POST /api/generate-mcq-batch` → body: `{ subject, choices?, count?, difficulty? }` → returns `{ items: MCQ[], count }`
- `GET /api/health` → `{ ok, timestamp, cache_size }`
- `GET /api/cache/stats` → `{ size, timestamp }`
- `POST /api/cache/clear` → `{ ok, message }`

### Environment
- `OPENAI_API_KEY` (required)
- `PORT` (default 8787)
- `CORS_ORIGIN` (default `*`)
- `LOG_LEVEL` (default `info`)

### Behavior & safeguards
- Zod validation for inputs and MCQ schema.
- Rate limit: 60 req/min/IP on `/api`.
- Pino structured logs; pretty in dev.
- Cache: up to 50 subjects, 5-min TTL, up to 20 MCQs per subject for variety.


