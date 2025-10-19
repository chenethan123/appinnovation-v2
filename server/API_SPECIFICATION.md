# FormulaQuizzer Server API Specification

**Version:** 1.0.0  
**Base URL:** `http://localhost:3000/api/v1` (development)  
**Authentication:** Bearer token (API Key)

---

## Table of Contents

1. [Authentication](#authentication)
2. [Error Responses](#error-responses)
3. [Subjects API](#subjects-api)
4. [Questions API](#questions-api)
5. [AI Generation API](#ai-generation-api)
6. [Quiz Sessions API](#quiz-sessions-api)
7. [Analytics API](#analytics-api)
8. [Health & Monitoring](#health--monitoring)

---

## Authentication

All API endpoints (except `/health`) require authentication using an API key.

### Request Header
```http
Authorization: Bearer YOUR_API_KEY
```

### Example
```bash
curl -H "Authorization: Bearer sk_test_abc123..." \
     http://localhost:3000/api/v1/subjects
```

### Unauthorized Response (401)
```json
{
  "error": "unauthorized",
  "message": "Missing or invalid authorization header"
}
```

---

## Error Responses

### Standard Error Format

All errors follow this consistent format:

```json
{
  "error": "error_code",
  "message": "Human-readable error description",
  "timestamp": "2024-10-13T09:19:04-04:00",
  "path": "/api/v1/subjects",
  "details": {}  // Optional, only in development
}
```

### HTTP Status Codes

| Code | Meaning | Error Code |
|------|---------|------------|
| 400 | Bad Request | `validation_error`, `invalid_request` |
| 401 | Unauthorized | `unauthorized`, `invalid_api_key` |
| 403 | Forbidden | `forbidden` |
| 404 | Not Found | `not_found`, `resource_not_found` |
| 409 | Conflict | `conflict`, `duplicate_entry` |
| 429 | Too Many Requests | `rate_limit_exceeded` |
| 500 | Internal Server Error | `internal_server_error` |
| 503 | Service Unavailable | `ai_service_unavailable`, `database_unavailable` |

### Common Error Examples

```json
// Validation Error
{
  "error": "validation_error",
  "message": "Invalid input data",
  "details": {
    "name": "Name is required",
    "color": "Invalid hex color format"
  }
}

// Not Found
{
  "error": "not_found",
  "message": "Subject not found"
}

// Rate Limit
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Try again in 60 seconds.",
  "retryAfter": 60
}
```

---

## Subjects API

Manage educational subjects/topics.

### List Subjects

Retrieve a paginated list of subjects.

**Endpoint:** `GET /api/v1/subjects`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `page` | integer | No | 1 | Page number (1-indexed) |
| `page_size` | integer | No | 20 | Items per page (max 100) |
| `is_active` | boolean | No | - | Filter by active status |
| `sort_by` | string | No | `created_at` | Sort field: `name`, `created_at`, `accuracy` |
| `sort_order` | string | No | `desc` | Sort order: `asc`, `desc` |

**Example Request:**
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     "http://localhost:3000/api/v1/subjects?page=1&page_size=10&is_active=true"
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 1,
      "name": "AP Physics 1",
      "description": "College-level introductory physics",
      "color": "#2196F3",
      "created_at": "2024-10-13T09:00:00Z",
      "updated_at": "2024-10-13T09:00:00Z",
      "is_active": true,
      "total_questions": 50,
      "correct_answers": 35,
      "accuracy": 70.0,
      "difficulty_weight": 0.5
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 10,
    "total": 42,
    "total_pages": 5
  }
}
```

---

### Get Subject by ID

Retrieve details of a specific subject.

**Endpoint:** `GET /api/v1/subjects/:id`

**Path Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `id` | integer | Yes | Subject ID |

**Example Request:**
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     http://localhost:3000/api/v1/subjects/1
```

**Success Response (200):**
```json
{
  "id": 1,
  "name": "AP Physics 1",
  "description": "College-level introductory physics",
  "color": "#2196F3",
  "created_at": "2024-10-13T09:00:00Z",
  "updated_at": "2024-10-13T09:00:00Z",
  "is_active": true,
  "total_questions": 50,
  "correct_answers": 35,
  "accuracy": 70.0,
  "difficulty_weight": 0.5,
  "metadata": {
    "course_code": "AP-PHYS-1",
    "grade_level": "11-12"
  }
}
```

**Error Response (404):**
```json
{
  "error": "not_found",
  "message": "Subject not found"
}
```

---

### Create Subject

Create a new subject.

**Endpoint:** `POST /api/v1/subjects`

**Request Body:**

```json
{
  "name": "AP Physics 1",
  "description": "College-level introductory physics",
  "color": "#2196F3",
  "metadata": {
    "course_code": "AP-PHYS-1",
    "grade_level": "11-12"
  }
}
```

**Field Validation:**

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `name` | string | Yes | 1-255 chars, unique |
| `description` | string | Yes | 1-1000 chars |
| `color` | string | Yes | Hex format: `#RRGGBB` |
| `metadata` | object | No | JSON object |

**Example Request:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "AP Physics 1",
    "description": "College-level introductory physics",
    "color": "#2196F3"
  }' \
  http://localhost:3000/api/v1/subjects
```

**Success Response (201):**
```json
{
  "id": 1,
  "name": "AP Physics 1",
  "description": "College-level introductory physics",
  "color": "#2196F3",
  "created_at": "2024-10-13T09:00:00Z",
  "updated_at": "2024-10-13T09:00:00Z",
  "is_active": true,
  "total_questions": 0,
  "correct_answers": 0,
  "accuracy": 0.0,
  "difficulty_weight": 0.5,
  "metadata": null
}
```

**Error Response (409):**
```json
{
  "error": "conflict",
  "message": "Subject with this name already exists"
}
```

---

### Update Subject

Update an existing subject.

**Endpoint:** `PUT /api/v1/subjects/:id`

**Request Body:**
```json
{
  "name": "AP Physics 1 (Updated)",
  "description": "Updated description",
  "color": "#FF5722",
  "is_active": true,
  "difficulty_weight": 0.7
}
```

**Note:** All fields are optional. Only provided fields will be updated.

**Success Response (200):**
```json
{
  "id": 1,
  "name": "AP Physics 1 (Updated)",
  "description": "Updated description",
  "color": "#FF5722",
  "updated_at": "2024-10-13T10:00:00Z",
  ...
}
```

---

### Delete Subject

Delete a subject (soft delete by default).

**Endpoint:** `DELETE /api/v1/subjects/:id`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `hard_delete` | boolean | No | false | If true, permanently delete |

**Example Request:**
```bash
curl -X DELETE \
  -H "Authorization: Bearer YOUR_API_KEY" \
  http://localhost:3000/api/v1/subjects/1
```

**Success Response (204):**
No content (empty response body)

---

## Questions API

Manage quiz questions.

### List Questions

Retrieve questions with filtering options.

**Endpoint:** `GET /api/v1/questions`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `subject_id` | integer | No | - | Filter by subject |
| `difficulty` | string | No | - | Filter by difficulty: `easy`, `medium`, `hard` |
| `is_from_ai` | boolean | No | - | Filter AI-generated questions |
| `page` | integer | No | 1 | Page number |
| `page_size` | integer | No | 20 | Items per page |

**Example Request:**
```bash
curl -H "Authorization: Bearer YOUR_API_KEY" \
     "http://localhost:3000/api/v1/questions?subject_id=1&difficulty=medium"
```

**Success Response (200):**
```json
{
  "data": [
    {
      "id": 42,
      "subject_id": 1,
      "subject_name": "AP Physics 1",
      "question_text": "A block of mass 5kg is pushed...",
      "options": [
        "10 N",
        "25 N",
        "50 N",
        "100 N"
      ],
      "correct_answer": "25 N",
      "explanation": "Using F=ma with a=5m/s², F=5×5=25N",
      "difficulty": "medium",
      "category": "Newton's Laws",
      "question_type": "multiple_choice",
      "created_at": "2024-10-13T09:00:00Z",
      "is_from_ai": true,
      "source": "OpenAI GPT-4",
      "source_url": null
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 150,
    "total_pages": 8
  }
}
```

---

### Get Question by ID

**Endpoint:** `GET /api/v1/questions/:id`

**Success Response (200):**
```json
{
  "id": 42,
  "subject_id": 1,
  "subject_name": "AP Physics 1",
  "question_text": "A block of mass 5kg is pushed...",
  "options": ["10 N", "25 N", "50 N", "100 N"],
  "correct_answer": "25 N",
  "explanation": "Using F=ma with a=5m/s², F=5×5=25N",
  "difficulty": "medium",
  "category": "Newton's Laws",
  "question_type": "multiple_choice",
  "created_at": "2024-10-13T09:00:00Z",
  "is_from_ai": true,
  "source": "OpenAI GPT-4"
}
```

---

### Create Question (Manual)

Create a question manually (not AI-generated).

**Endpoint:** `POST /api/v1/questions`

**Request Body:**
```json
{
  "subject_id": 1,
  "question_text": "What is the formula for force?",
  "options": ["F=ma", "F=mv", "F=m/a", "F=a/m"],
  "correct_answer": "F=ma",
  "explanation": "Force equals mass times acceleration (Newton's Second Law)",
  "difficulty": "easy",
  "category": "Newton's Laws",
  "question_type": "multiple_choice"
}
```

**Field Validation:**

| Field | Type | Required | Constraints |
|-------|------|----------|-------------|
| `subject_id` | integer | Yes | Valid subject ID |
| `question_text` | string | Yes | 10-2000 chars |
| `options` | array | Yes | 2-5 strings |
| `correct_answer` | string | Yes | Must match one option |
| `explanation` | string | Yes | 10-1000 chars |
| `difficulty` | string | No | `easy`, `medium`, `hard` (default: `medium`) |
| `category` | string | No | Max 100 chars |
| `question_type` | string | No | `multiple_choice`, `true_false`, `fill_blank` |

**Success Response (201):**
```json
{
  "id": 43,
  "subject_id": 1,
  "question_text": "What is the formula for force?",
  ...
}
```

---

### Delete Question

**Endpoint:** `DELETE /api/v1/questions/:id`

**Success Response (204):**
No content

---

## AI Generation API

Generate questions using AI (OpenAI GPT-4).

### Generate Single Question

Generate one AI-powered question.

**Endpoint:** `POST /api/v1/ai/generate-question`

**Request Body:**
```json
{
  "subject_id": 1,
  "difficulty": "medium",
  "num_choices": 4,
  "category": "Newton's Laws"
}
```

**Field Validation:**

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `subject_id` | integer | Yes | - | Valid subject ID |
| `difficulty` | string | No | `medium` | `easy`, `medium`, `hard` |
| `num_choices` | integer | No | 4 | 2-5 |
| `category` | string | No | - | Max 100 chars |

**Example Request:**
```bash
curl -X POST \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "subject_id": 1,
    "difficulty": "medium",
    "num_choices": 4
  }' \
  http://localhost:3000/api/v1/ai/generate-question
```

**Success Response (200):**
```json
{
  "id": 44,
  "subject_id": 1,
  "subject_name": "AP Physics 1",
  "question_text": "A 2kg block slides down a frictionless incline...",
  "options": ["5 m/s", "10 m/s", "15 m/s", "20 m/s"],
  "correct_answer": "10 m/s",
  "explanation": "Using energy conservation: mgh = (1/2)mv²...",
  "difficulty": "medium",
  "category": "Energy",
  "question_type": "multiple_choice",
  "created_at": "2024-10-13T09:00:00Z",
  "is_from_ai": true,
  "source": "OpenAI GPT-4",
  "generation_time_ms": 1850,
  "tokens_used": 725,
  "cache_hit": false
}
```

**Error Response (503):**
```json
{
  "error": "ai_service_unavailable",
  "message": "OpenAI API is temporarily unavailable. Please try again."
}
```

---

### Generate Question Batch

Generate multiple questions at once (for cache pre-warming).

**Endpoint:** `POST /api/v1/ai/generate-batch`

**Request Body:**
```json
{
  "subject_id": 1,
  "count": 5,
  "difficulty": "medium",
  "num_choices": 4
}
```

**Field Validation:**

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `subject_id` | integer | Yes | - | Valid subject ID |
| `count` | integer | Yes | - | 1-20 |
| `difficulty` | string | No | `medium` | `easy`, `medium`, `hard` |
| `num_choices` | integer | No | 4 | 2-5 |

**Success Response (200):**
```json
{
  "items": [
    {
      "id": 45,
      "question_text": "Question 1...",
      ...
    },
    {
      "id": 46,
      "question_text": "Question 2...",
      ...
    }
  ],
  "count": 5,
  "total_tokens_used": 3500,
  "total_generation_time_ms": 8500,
  "estimated_cost_usd": 0.10
}
```

---

### Explain Answer

Get a detailed explanation for a specific answer option.

**Endpoint:** `POST /api/v1/ai/explain-answer`

**Request Body:**
```json
{
  "question_id": 42,
  "selected_answer": "10 N"
}
```

**Success Response (200):**
```json
{
  "question_id": 42,
  "selected_answer": "10 N",
  "is_correct": false,
  "explanation": "This answer is incorrect. The value 10 N is too small because it doesn't properly account for the mass. Using Newton's Second Law (F=ma), with m=5kg and a=5m/s², we get F=25N, not 10N.",
  "correct_answer": "25 N",
  "detailed_explanation": "Using F=ma with a=5m/s², F=5×5=25N"
}
```

---

## Quiz Sessions API

Track quiz-taking sessions and answers.

### Start Quiz Session

Begin a new quiz session.

**Endpoint:** `POST /api/v1/quiz/start`

**Request Body:**
```json
{
  "subject_id": 1,
  "num_questions": 10,
  "difficulty": "medium",
  "time_limit_seconds": 600
}
```

**Success Response (200):**
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "subject_id": 1,
  "subject_name": "AP Physics 1",
  "questions": [
    {
      "id": 42,
      "question_text": "A block of mass 5kg...",
      "options": ["10 N", "25 N", "50 N", "100 N"],
      "difficulty": "medium"
    }
  ],
  "num_questions": 10,
  "time_limit_seconds": 600,
  "started_at": "2024-10-13T09:00:00Z"
}
```

**Note:** `correct_answer` and `explanation` are NOT included in the response (revealed after submission).

---

### Submit Answer

Submit an answer to a question in the current session.

**Endpoint:** `POST /api/v1/quiz/answer`

**Request Body:**
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "question_id": 42,
  "user_answer": "25 N",
  "time_spent_seconds": 45
}
```

**Success Response (200):**
```json
{
  "question_id": 42,
  "user_answer": "25 N",
  "is_correct": true,
  "correct_answer": "25 N",
  "explanation": "Using F=ma with a=5m/s², F=5×5=25N",
  "time_spent_seconds": 45
}
```

---

### Complete Quiz Session

Finalize a quiz session and get results.

**Endpoint:** `POST /api/v1/quiz/complete`

**Request Body:**
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

**Success Response (200):**
```json
{
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "subject_id": 1,
  "subject_name": "AP Physics 1",
  "total_questions": 10,
  "correct_answers": 7,
  "accuracy": 70.0,
  "total_time_seconds": 420,
  "started_at": "2024-10-13T09:00:00Z",
  "completed_at": "2024-10-13T09:07:00Z",
  "questions_summary": [
    {
      "question_id": 42,
      "is_correct": true,
      "time_spent_seconds": 45
    }
  ]
}
```

---

### Get Quiz History

Retrieve past quiz sessions.

**Endpoint:** `GET /api/v1/quiz/history`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `subject_id` | integer | No | - | Filter by subject |
| `page` | integer | No | 1 | Page number |
| `page_size` | integer | No | 20 | Items per page |

**Success Response (200):**
```json
{
  "data": [
    {
      "session_id": "550e8400-e29b-41d4-a716-446655440000",
      "subject_id": 1,
      "subject_name": "AP Physics 1",
      "total_questions": 10,
      "correct_answers": 7,
      "accuracy": 70.0,
      "completed_at": "2024-10-13T09:07:00Z"
    }
  ],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 50,
    "total_pages": 3
  }
}
```

---

## Analytics API

Get performance analytics and progress tracking.

### Overview Statistics

Get overall performance statistics.

**Endpoint:** `GET /api/v1/analytics/overview`

**Success Response (200):**
```json
{
  "total_subjects": 10,
  "active_subjects": 8,
  "total_questions_answered": 500,
  "overall_accuracy": 72.5,
  "total_quiz_sessions": 50,
  "total_time_spent_seconds": 15000,
  "average_accuracy_by_difficulty": {
    "easy": 85.0,
    "medium": 70.0,
    "hard": 55.0
  },
  "strongest_subjects": [
    {
      "id": 1,
      "name": "AP Physics 1",
      "accuracy": 85.0
    }
  ],
  "weakest_subjects": [
    {
      "id": 5,
      "name": "AP Calculus BC",
      "accuracy": 55.0
    }
  ]
}
```

---

### Subject-Specific Analytics

**Endpoint:** `GET /api/v1/analytics/subject/:id`

**Success Response (200):**
```json
{
  "subject_id": 1,
  "subject_name": "AP Physics 1",
  "total_questions": 50,
  "correct_answers": 35,
  "accuracy": 70.0,
  "quiz_sessions_count": 5,
  "total_time_spent_seconds": 1800,
  "average_time_per_question": 36,
  "difficulty_breakdown": {
    "easy": { "total": 15, "correct": 13, "accuracy": 86.7 },
    "medium": { "total": 25, "correct": 18, "accuracy": 72.0 },
    "hard": { "total": 10, "correct": 4, "accuracy": 40.0 }
  },
  "category_breakdown": {
    "Newton's Laws": { "total": 20, "correct": 15, "accuracy": 75.0 },
    "Energy": { "total": 15, "correct": 10, "accuracy": 66.7 },
    "Momentum": { "total": 15, "correct": 10, "accuracy": 66.7 }
  }
}
```

---

### Progress Over Time

**Endpoint:** `GET /api/v1/analytics/progress`

**Query Parameters:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `subject_id` | integer | No | - | Filter by subject |
| `time_range` | string | No | `30d` | `7d`, `30d`, `90d`, `1y` |

**Success Response (200):**
```json
{
  "time_range": "30d",
  "data_points": [
    {
      "date": "2024-10-01",
      "questions_answered": 10,
      "accuracy": 70.0
    },
    {
      "date": "2024-10-02",
      "questions_answered": 15,
      "accuracy": 73.3
    }
  ],
  "trend": {
    "accuracy_change": "+5.2%",
    "questions_per_day_avg": 12.5,
    "consistency_score": 85.0
  }
}
```

---

## Health & Monitoring

### Health Check

Check if the service is healthy.

**Endpoint:** `GET /api/v1/health`

**Authentication:** Not required

**Success Response (200):**
```json
{
  "status": "ok",
  "timestamp": "2024-10-13T09:19:04-04:00",
  "version": "1.0.0",
  "uptime_seconds": 3600,
  "services": {
    "database": "ok",
    "redis": "ok",
    "openai": "ok"
  }
}
```

**Unhealthy Response (503):**
```json
{
  "status": "unhealthy",
  "timestamp": "2024-10-13T09:19:04-04:00",
  "services": {
    "database": "ok",
    "redis": "error",
    "openai": "ok"
  }
}
```

---

### Prometheus Metrics

**Endpoint:** `GET /api/v1/metrics`

**Authentication:** Not required (configure firewall rules to restrict access)

**Response:** Plain text Prometheus format

```
# HELP http_requests_total Total number of HTTP requests
# TYPE http_requests_total counter
http_requests_total{method="GET",endpoint="/api/v1/subjects",status="200"} 1234

# HELP http_request_duration_seconds HTTP request duration
# TYPE http_request_duration_seconds histogram
http_request_duration_seconds_bucket{le="0.1"} 500
http_request_duration_seconds_bucket{le="0.5"} 900

# HELP openai_api_calls_total Total OpenAI API calls
# TYPE openai_api_calls_total counter
openai_api_calls_total{status="success"} 450
openai_api_calls_total{status="error"} 12

# HELP cache_hit_rate Cache hit rate
# TYPE cache_hit_rate gauge
cache_hit_rate 0.72
```

---

## Rate Limiting

### Default Limits

- **Per IP Address**: 60 requests per minute
- **Per API Key**: 100 requests per minute
- **Burst**: 10 requests per second

### Rate Limit Headers

```http
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 45
X-RateLimit-Reset: 1697195944
```

### Rate Limit Exceeded Response (429)

```json
{
  "error": "rate_limit_exceeded",
  "message": "Too many requests. Try again in 42 seconds.",
  "retry_after": 42
}
```

### Best Practices

1. **Implement exponential backoff** on client side
2. **Monitor rate limit headers** in responses
3. **Use batch endpoints** to reduce request count
4. **Cache responses** on client side

---

## Pagination

All list endpoints support pagination with consistent parameters:

| Parameter | Type | Default | Max | Description |
|-----------|------|---------|-----|-------------|
| `page` | integer | 1 | - | Page number (1-indexed) |
| `page_size` | integer | 20 | 100 | Items per page |

**Response Format:**
```json
{
  "data": [...],
  "pagination": {
    "page": 1,
    "page_size": 20,
    "total": 150,
    "total_pages": 8,
    "has_next": true,
    "has_previous": false
  }
}
```

---

## Webhooks (Future Feature)

**Coming Soon:** Real-time notifications for events like:
- New question generated
- Quiz session completed
- Subject performance milestone reached

---

## API Versioning

Current version: `v1`

**URL Format:** `/api/v1/...`

Future versions will be released as `/api/v2/...` with backward compatibility maintained for at least 6 months.

---

## SDK & Client Libraries

**Coming Soon:**
- JavaScript/TypeScript SDK
- Dart/Flutter SDK
- Python SDK

---

## Support

For API support:
- Review this documentation
- Check server logs
- Test with `curl` examples
- Verify API key validity

---

**Last Updated:** 2024-10-13  
**API Version:** 1.0.0
