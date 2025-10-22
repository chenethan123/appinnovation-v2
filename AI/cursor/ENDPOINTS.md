## API Endpoints

Base URL (dev): configured in `lib/config/api_config.dart` → typically `http://localhost:8787`

### POST /api/generate-mcq
- Body: `{ "subject": string, "choices"?: 2..5, "difficulty"?: "easy"|"medium"|"hard" }`
- 200: `MCQ`
- 4xx: validation error
- 5xx/503: OpenAI/config errors (frontend should fallback gracefully)

### POST /api/generate-mcq-batch
- Body: `{ "subject": string, "choices"?: 2..5, "count"?: 1..20, "difficulty"?: enum }`
- 200: `{ items: MCQ[], count: number }`

### GET /api/health
- 200: `{ ok: true, timestamp: string, cache_size: number }`

### GET /api/cache/stats
- 200: `{ size: number, timestamp: string }`

### POST /api/cache/clear
- 200: `{ ok: true, message: string }`


