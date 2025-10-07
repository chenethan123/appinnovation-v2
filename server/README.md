# FormulaQuizzer MCQ Backend API

Backend API for generating multiple-choice questions (MCQs) using OpenAI's GPT API. Pre-generates all explanations in a single API call to minimize latency and costs.

## Features

- ✅ Single MCQ generation with all explanations pre-generated
- ✅ Batch MCQ generation for cache pre-warming
- ✅ Subject-based LRU caching with TTL (5-minute default)
- ✅ Rate limiting (60 req/min per IP)
- ✅ Zod schema validation
- ✅ Comprehensive error handling
- ✅ Structured logging with Pino
- ✅ CORS support for Flutter frontend
- ✅ Health check endpoint

## Tech Stack

- **Runtime**: Node.js + TypeScript
- **Framework**: Express
- **AI**: OpenAI SDK (GPT-4 Turbo)
- **Validation**: Zod
- **Logging**: Pino
- **Rate Limiting**: express-rate-limit

## Quick Start

### 1. Install Dependencies

```bash
cd server
npm install
```

### 2. Configure Environment

The `.env` file has already been created with your API key. If you need to change it:

```bash
cp .env.example .env
# Edit .env and set OPENAI_API_KEY
```

### 3. Run Development Server

```bash
npm run dev
```

Server will start on `http://localhost:8787`

### 4. Build for Production

```bash
npm run build
npm start
```

## API Endpoints

### 1. Generate Single MCQ

**Endpoint**: `POST /api/generate-mcq`

**Request**:
```json
{
  "subject": "AP Physics 1",
  "choices": 4
}
```

**Response**:
```json
{
  "id": "uuid-here",
  "subject": "AP Physics 1",
  "stem": "A block of mass 5kg is pushed...",
  "options": [
    { "letter": "A", "text": "10 N" },
    { "letter": "B", "text": "25 N" },
    { "letter": "C", "text": "50 N" },
    { "letter": "D", "text": "100 N" }
  ],
  "correct_option": "B",
  "explanation_correct": "Using F=ma with a=5m/s², F=5×5=25N",
  "explanations_by_option": {
    "A": "Too small - doesn't account for mass properly",
    "B": "Correct! F=ma gives 5kg × 5m/s² = 25N",
    "C": "Double the correct value",
    "D": "Way too large for this scenario"
  },
  "difficulty": "medium",
  "source_hint": "Newton's Second Law"
}
```

### 2. Generate MCQ Batch

**Endpoint**: `POST /api/generate-mcq-batch`

**Request**:
```json
{
  "subject": "APUSH",
  "choices": 4,
  "count": 5
}
```

**Response**:
```json
{
  "items": [/* array of 5 MCQ objects */],
  "count": 5
}
```

### 3. Health Check

**Endpoint**: `GET /api/health`

**Response**:
```json
{
  "ok": true,
  "timestamp": "2024-10-04T23:30:00.000Z",
  "cache_size": 12
}
```

### 4. Cache Stats

**Endpoint**: `GET /api/cache/stats`

**Response**:
```json
{
  "size": 12,
  "timestamp": "2024-10-04T23:30:00.000Z"
}
```

### 5. Clear Cache

**Endpoint**: `POST /api/cache/clear`

**Response**:
```json
{
  "ok": true,
  "message": "Cache cleared"
}
```

## Error Responses

All errors follow this format:

```json
{
  "error": "error_code",
  "message": "Human-readable description"
}
```

**Error Codes**:
- `invalid_request` (400) - Invalid request parameters
- `rate_limit_exceeded` (429) - Too many requests
- `configuration_error` (500) - API key not configured
- `openai_error` (503) - OpenAI service unavailable
- `generation_failed` (500) - MCQ generation failed
- `batch_generation_failed` (500) - Batch generation failed

## Caching Strategy

### Server-Side (Current Implementation)
- **LRU Cache**: 50 subjects max, 5-minute TTL
- **Per-Subject Storage**: Up to 20 MCQs per subject for variety
- **Random Selection**: Returns random cached MCQ to avoid repetition
- **Auto-Cleanup**: Expires entries every 5 minutes

### Client-Side (Recommended for Flutter)
- Maintain FIFO cache of 20 MCQs per subject
- Prefetch during idle time using batch endpoint
- Exponential backoff on 429/5xx errors
- Store current MCQ in localStorage for refresh persistence

## Rate Limiting

- **Default**: 60 requests per minute per IP
- **Response**: 429 with retry-after header
- **Client Recommendation**: Implement exponential backoff with jitter

## Security Best Practices

✅ **Implemented**:
- API key read from environment (never hardcoded)
- Request validation with Zod
- Rate limiting per IP
- CORS configuration
- No PII logged in prompts/responses

⚠️ **Production Recommendations**:
- Set `CORS_ORIGIN` to your Flutter app domain
- Use HTTPS in production
- Consider API key rotation strategy
- Add authentication for admin endpoints (/cache/clear)
- Monitor OpenAI usage and set billing alerts

## OpenAI Configuration

**Current Model**: `gpt-4-turbo-preview`

**Settings**:
- Temperature: 0.7 (balanced creativity)
- Max Tokens: 2000 (sufficient for MCQ + all explanations)
- Response Format: JSON mode (enforced)

**Costs** (approximate):
- Input: ~$0.01 per 1K tokens
- Output: ~$0.03 per 1K tokens
- Average MCQ: ~500-800 tokens total
- **~$0.02-0.04 per MCQ**

## Integration with Flutter

### Example HTTP Client (Dart)

```dart
import 'package:dio/dio.dart';

class MCQService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://localhost:8787/api',
    connectTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 30),
  ));

  Future<Map<String, dynamic>> generateMCQ(String subject, {int choices = 4}) async {
    try {
      final response = await _dio.post('/generate-mcq', data: {
        'subject': subject,
        'choices': choices,
      });
      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 429) {
        // Implement exponential backoff
        await Future.delayed(Duration(seconds: 5));
        return generateMCQ(subject, choices: choices);
      }
      throw Exception('Failed to generate MCQ: ${e.message}');
    }
  }

  Future<List<dynamic>> generateMCQBatch(
    String subject, {
    int choices = 4,
    int count = 5
  }) async {
    final response = await _dio.post('/generate-mcq-batch', data: {
      'subject': subject,
      'choices': choices,
      'count': count,
    });
    return response.data['items'];
  }
}
```

## Testing

### Manual Testing

```bash
# Health check
curl http://localhost:8787/api/health

# Generate MCQ
curl -X POST http://localhost:8787/api/generate-mcq \
  -H "Content-Type: application/json" \
  -d '{"subject": "AP Physics 1", "choices": 4}'

# Generate batch
curl -X POST http://localhost:8787/api/generate-mcq-batch \
  -H "Content-Type: application/json" \
  -d '{"subject": "APUSH", "choices": 4, "count": 3}'
```

### Unit Tests (TODO)

```bash
npm test
```

## Project Structure

```
server/
├── src/
│   ├── index.ts          # Express app & API routes
│   ├── openai.ts         # OpenAI integration & schema
│   └── cache.ts          # LRU cache implementation
├── dist/                 # Compiled JavaScript (generated)
├── .env                  # Environment variables (DO NOT COMMIT)
├── .env.example          # Template for .env
├── package.json          # Dependencies
├── tsconfig.json         # TypeScript config
└── README.md            # This file
```

## Development Workflow

### Hot Reload Development
```bash
npm run dev  # Uses tsx watch mode
```

### Debugging
- Logs use Pino with pretty printing
- Set `LOG_LEVEL=debug` in `.env` for verbose logging
- Check OpenAI API dashboard for usage/errors

### Common Issues

**"OPENAI_API_KEY not configured"**
- Check `.env` file exists and has valid key
- Restart server after changing `.env`

**Rate limit errors (429)**
- Wait 60 seconds between batches
- Implement client-side backoff
- Consider pre-warming cache during off-peak times

**OpenAI timeout/errors**
- Check OpenAI status: https://status.openai.com
- Verify API key has credits
- Check network connectivity

## Monitoring & Observability

**Metrics to Track**:
- Request rate per endpoint
- Cache hit rate
- OpenAI API latency
- Error rate by type
- Token usage & costs

**Recommended Tools**:
- Application: Pino logs + log aggregator (ELK, CloudWatch)
- OpenAI: Platform dashboard for usage/costs
- Uptime: Health check endpoint monitoring

## Deployment

### Environment Variables for Production
```bash
OPENAI_API_KEY=sk-...              # Your API key
PORT=8787                          # Or use cloud provider's PORT
LOG_LEVEL=info                     # Production logging
CORS_ORIGIN=https://your-app.com   # Your Flutter web domain
```

### Deployment Platforms
- **Railway**: `railway up` (automatic detection)
- **Render**: Connect repo, auto-build
- **Fly.io**: `fly deploy`
- **Heroku**: `git push heroku main`

### Docker (Optional)
```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
RUN npm run build
CMD ["npm", "start"]
```

## License

MIT

## Support

For issues or questions:
1. Check logs: `npm run dev` shows detailed errors
2. Verify `.env` configuration
3. Test OpenAI key: https://platform.openai.com/playground
4. Check OpenAI status page
