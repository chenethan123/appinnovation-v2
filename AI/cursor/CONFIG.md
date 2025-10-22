## Config Notes

### Flutter (`lib/config/api_config.dart`)
- `useDirectOpenAI = true` (default) → app calls OpenAI directly with `openAIApiKey`.
- For backend mode set `useDirectOpenAI = false` and configure:
  - `useLocalBackend = true` for dev (`http://localhost:8787`).
  - `productionBaseUrl` for deployed server.
- Supabase: `enableSync`, `supabaseUrl`, `supabaseAnonKey`.
- Timeouts: `timeout` for HTTP calls.

### Server (`server`)
- `.env` expected: `OPENAI_API_KEY`, optionally `PORT`, `CORS_ORIGIN`, `LOG_LEVEL`.
- Start (dev): `cd server && npm install && npm run dev`.

### Health/verification
- Backend running: `GET /api/health` should return `{ ok: true }`.
- Frontend backend-mode: `AIService.checkHealth()` returns true.


