## Frontend (Flutter) Quick Map

### Entry
- `lib/main.dart`: initializes Supabase (if enabled), notifications, loads default courses, starts background sync.

### Models (`lib/models`)
- `mcq.dart`: AI MCQ structure returned by backend.
- `question.dart`, `quiz_session.dart`, `subject.dart`, `course.dart`, `unit.dart`.

### Database (`lib/database`)
- `database_helper.dart`: SQLite access utilities.
- `question_database.dart`: MCQ/question persistence and analytics queries.

### Providers (`lib/providers`)
- `mcq_provider.dart`: MCQ generation/selection state.
- `quiz_provider.dart`: quiz flow/session.
- `subject_provider.dart`, `course_provider.dart`.

### Services (`lib/services`)
- `ai_service.dart`: calls backend `generate-mcq`, `generate-mcq-batch`, health check.
- `openai_service.dart` / `openai_service_novel.dart`: direct OpenAI flows for specific features.
- `notification_service.dart`: local notifications.
- `sync_service.dart`, `background_sync_service.dart`: Supabase-based cross-device sync.
- `course_service.dart`, `course_units_service.dart`, `enhanced_question_service.dart`.

### Screens (`lib/screens`)
- `auth_screen.dart` → login/signup → then `home_screen.dart`.
- `mcq_quiz_screen.dart`, `quiz_screen.dart`, `mcq_loading_screen.dart`.
- `subjects_screen.dart`, `subject_search_screen.dart`, `progress_screen.dart`, `settings_screen.dart`.

### Widgets (`lib/widgets`)
- `quick_quiz_card.dart`, `timer_quiz_card.dart`, `stats_overview_card.dart`, `subject_card.dart`.

### Config (`lib/config/api_config.dart`)
- `baseUrl`, `healthEndpoint`, `generateMcqEndpoint`, `generateMcqBatchEndpoint`, `timeout`, `enableSync`, `supabaseUrl`, `supabaseAnonKey`.

### Notable flow snippets
- `AIService.generateMCQ(subject, choices, difficulty)` → returns `MCQ?` (null on failure for graceful fallback).
- `AIService.generateMCQBatch(...)` → returns `List<MCQ>`; used for pre-warming cache.


