# FormulaQuizzer - Project Overview

**Last Updated**: October 22, 2025  
**Branch**: workingServer  
**Framework**: Flutter 3.x  
**State Management**: Riverpod  

---

## Project Purpose

FormulaQuizzer is an educational quiz application designed to help students study and master various subjects through:
- AI-generated questions powered by OpenAI GPT
- Adaptive learning algorithms
- Cross-device synchronization via Supabase
- Local-first architecture with offline support
- Course-based organization (AP courses, custom subjects)

---

## Key Features

### 1. **Subject Management**
- Unlimited custom subjects with color coding
- AP course presets with standardized IDs
- Subject-specific performance tracking
- Active/inactive toggling
- Units/chapters organization within subjects

### 2. **Question Generation**
- **AI-Generated**: OpenAI GPT-4 integration with novelty enforcement
- **Scraped Content**: Web scraping from educational resources
- **Manual Entry**: Custom question creation
- **Import System**: Bulk question import support
- Multiple question types: MCQ, True/False, Fill-in-blank

### 3. **Quiz System**
- **Quick Quiz**: Adaptive algorithm prioritizes weaker subjects
- **Subject Quiz**: Focused practice on specific subjects
- **MCQ Mode**: Full-screen AI question generation
- Progress tracking with detailed analytics
- Performance-based difficulty adjustment

### 4. **Cross-Device Sync**
- Supabase backend for cloud storage
- Real-time synchronization
- Account-based data isolation
- Auto-sync on login, logout, data changes
- Background sync every 5 minutes
- Offline-first with graceful degradation

### 5. **Local Notifications**
- Scheduled quiz reminders
- Configurable time slots (start/end hours)
- Active days selection (weekdays, weekends)
- Daily quiz limits

---

## Technology Stack

### Core Framework
- **Flutter**: Cross-platform mobile/desktop app framework
- **Dart**: Primary programming language

### State Management
- **Riverpod 2.x**: Modern reactive state management
- Provider pattern for dependency injection

### Database
- **SQLite (sqflite)**: Local database for offline-first storage
- **Supabase**: PostgreSQL cloud database with real-time sync
- Row-Level Security (RLS) for multi-tenant data isolation

### AI/ML
- **OpenAI API**: GPT-4 for question generation
- Custom novelty enforcement using STEM hashing
- Retry logic with exponential backoff

### Authentication
- **Supabase Auth**: Email/password authentication
- Session management with token refresh
- Logout with local data clearing

### UI/UX
- **Material 3**: Modern design system
- Responsive layouts for mobile/tablet/desktop
- Custom widgets for subject cards, quiz interfaces
- Loading screens with retry mechanisms

### Notifications
- **flutter_local_notifications**: Cross-platform local notifications
- **timezone**: Time zone aware scheduling

### Charts & Analytics
- **fl_chart**: Performance tracking visualizations
- Subject accuracy charts
- Progress over time graphs

### Data Persistence
- **shared_preferences**: Settings and simple key-value storage
- **path_provider**: File system access

---

## Project Structure

```
lib/
├── config/           # API keys and configuration
├── data/            # Static data (AP subjects, question banks)
├── database/        # SQLite database helpers
├── models/          # Data models (Subject, Question, etc.)
├── providers/       # Riverpod state management
├── screens/         # UI screens
├── services/        # Business logic services
├── utils/           # Utility functions
└── widgets/         # Reusable UI components
```

---

## Development Workflow

### Running the App
```bash
flutter run -d macos           # macOS
flutter run -d "DEVICE_ID"     # iOS Simulator
flutter run                    # Default device
```

### Hot Reload
- Press `r` for hot reload
- Press `R` for hot restart
- Press `q` to quit

### Key Scripts
- `start_app.sh`: Automated startup with server checks
- `fix_ap_ids.py`: Data migration script for AP course IDs

---

## Current Status (workingServer Branch)

### ✅ Implemented
- Complete subject management system
- AI question generation with OpenAI
- Cross-device sync with Supabase
- Authentication system
- Local notifications
- Progress tracking and analytics
- Course/units organization
- Offline-first architecture

### 🚧 In Progress
- Quiz session sync (UUID/integer ID mismatch)
- Enhanced question scraping
- Advanced analytics features

### 🔮 Planned
- Social features (leaderboards, sharing)
- Spaced repetition algorithm
- Export/import functionality
- Teacher/student mode

---

## Critical Architectural Decisions

### 1. Local-First Design
- SQLite as primary data store
- Supabase sync is optional
- App fully functional offline
- Sync happens in background

### 2. Account Isolation
- Each user's data stored separately in cloud
- Local data cleared on logout
- Fresh data download on login
- No data mixing between accounts

### 3. Adaptive Learning
- `difficulty_weight` tracks subject performance
- Algorithm prioritizes weaker subjects
- Weighted random selection for balanced learning

### 4. AI Integration
- Novelty enforcement prevents duplicate questions
- STEM-based hashing for content deduplication
- Graceful fallback to local questions on API failure
- Educational disclaimers on all AI content

### 5. State Management
- Riverpod providers for clean separation
- Async data loading with loading states
- Error handling at provider level
- Mounted checks before setState() calls

---

## API Keys Required

### OpenAI (Required for AI questions)
- File: `lib/config/api_config.dart`
- Variable: `openaiApiKey`
- Get key: https://platform.openai.com/api-keys

### Supabase (Required for sync)
- File: `lib/config/api_config.dart`
- Variables: `supabaseUrl`, `supabaseAnonKey`
- Get credentials: https://supabase.com/dashboard

---

## Performance Requirements

- Database queries: < 100ms
- UI responsiveness: 60fps target
- App startup: < 3 seconds
- Question generation: < 10 seconds (with retries)
- Sync operations: Non-blocking, background execution

---

## Testing Strategy

- Manual testing on iOS/macOS/Android
- Integration tests for critical flows
- Database migration tests
- Sync conflict resolution tests
- API failure scenarios

---

## Known Issues

1. **Quiz Session Sync**: Local SQLite uses integer IDs, Supabase uses UUIDs
   - Temporary solution: Sync disabled for quiz sessions
   - Future: Migrate to UUID-based local IDs

2. **Provider Modification**: Fixed by using `addPostFrameCallback()`
   - Issue: Modifying provider during build phase
   - Solution: Delay modifications until after build

3. **Large Dataset**: AP course data included in assets
   - Consideration: Lazy loading for performance
   - Alternative: On-demand download from server

---

## Documentation Files

Refer to project root for additional documentation:
- `FORMULAQUIZZERACCOUNTS_ARCHITECTURE.md`: Detailed architecture
- `SUPABASE_SETUP_GUIDE.md`: Cloud sync setup
- `STARTUP_GUIDE.md`: Developer getting started guide
- `DOCUMENTATION_INDEX.md`: Complete documentation index
