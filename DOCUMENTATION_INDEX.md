# FormulaQuizzerAccounts - Complete Documentation Index

**Last Updated**: October 20, 2025  
**Version**: 1.0.0  
**Purpose**: Master reference for all documentation - READ THIS FIRST before making changes

---

## 📚 Documentation Navigation

### 🚀 Getting Started (Start Here!)
1. **[README.md](./README.md)** - Project overview, quick start, features
2. **[QUICK_START.md](./QUICK_START.md)** - Fast 5-minute setup guide
3. **[STARTUP_GUIDE.md](./STARTUP_GUIDE.md)** - Complete setup and usage walkthrough
4. **[SETUP_API_KEY.md](./SETUP_API_KEY.md)** - OpenAI API key configuration guide

### 🏗️ Architecture & Design (For Developers)
5. **[ARCHITECTURE.md](./ARCHITECTURE.md)** - Core architecture principles and structure
6. **[FORMULAQUIZZERACCOUNTS_ARCHITECTURE.md](./FORMULAQUIZZERACCOUNTS_ARCHITECTURE.md)** - Comprehensive system architecture
7. **[DEVELOPMENT_WORKFLOW.md](./DEVELOPMENT_WORKFLOW.md)** - Development best practices

### ✨ Feature Documentation
8. **[INTEGRATION_COMPLETE.md](./INTEGRATION_COMPLETE.md)** - ChatGPT integration details
9. **[NOVELTY_SYSTEM_IMPLEMENTATION.md](./NOVELTY_SYSTEM_IMPLEMENTATION.md)** - Question novelty enforcement
10. **[COURSE_DATABASE_GUIDE.md](./COURSE_DATABASE_GUIDE.md)** - Course autocomplete system
11. **[UNITS_SYSTEM_COMPLETE.md](./UNITS_SYSTEM_COMPLETE.md)** - Unit organization system
12. **[QUIZ_TAB_INTEGRATION.md](./QUIZ_TAB_INTEGRATION.md)** - Quiz tab implementation
13. **[FULL_SCREEN_LOADING_IMPLEMENTATION.md](./FULL_SCREEN_LOADING_IMPLEMENTATION.md)** - Loading screens
14. **[AP_FILTER_IMPLEMENTATION.md](./AP_FILTER_IMPLEMENTATION.md)** - AP course filtering

### 🐛 Bug Fixes & Updates
15. **[BUG_FIX_SUMMARY.md](./BUG_FIX_SUMMARY.md)** - History of bug fixes
16. **[SUBJECT_VERIFICATION_UPDATE.md](./SUBJECT_VERIFICATION_UPDATE.md)** - Subject validation changes

### 🚀 Deployment
17. **[PRODUCTION_DEPLOYMENT.md](./PRODUCTION_DEPLOYMENT.md)** - Production deployment guide

---

## 🗺️ Quick Reference Guide

### For New Developers
**Read in this order:**
1. README.md - Understand what the app does
2. QUICK_START.md - Get it running locally
3. FORMULAQUIZZERACCOUNTS_ARCHITECTURE.md - Understand the full system
4. ARCHITECTURE.md - Learn core principles
5. DEVELOPMENT_WORKFLOW.md - Follow development standards

### For Feature Development
**Before adding a feature:**
1. Check ARCHITECTURE.md for design principles
2. Review INTEGRATION_COMPLETE.md for existing patterns
3. Follow DEVELOPMENT_WORKFLOW.md standards
4. Update documentation after implementation

### For Bug Fixes
**Before fixing a bug:**
1. Check BUG_FIX_SUMMARY.md for similar issues
2. Review ARCHITECTURE.md for affected systems
3. Test with guidance from STARTUP_GUIDE.md
4. Document fix in BUG_FIX_SUMMARY.md

### For Deployment
**Before deploying:**
1. Read PRODUCTION_DEPLOYMENT.md completely
2. Verify SETUP_API_KEY.md configuration
3. Test with STARTUP_GUIDE.md procedures
4. Follow deployment checklist

---

## 🎯 System Overview

### What is FormulaQuizzerAccounts?
An **offline-first educational quiz app** with:
- ✅ Unlimited subject creation
- ✅ AI-powered question generation (ChatGPT)
- ✅ 1000+ predefined courses with autocomplete
- ✅ Adaptive learning algorithms
- ✅ Timer-based automatic quizzes
- ✅ Progress tracking and analytics
- ✅ Local SQLite database (no cloud required)

### Key Technologies
- **Frontend**: Flutter + Riverpod
- **Database**: SQLite (offline-first)
- **AI**: OpenAI GPT-4 Turbo (direct integration)
- **Backend**: Node.js + TypeScript (optional for development)
- **UI**: Material 3 Design

### Architecture Type
**Offline-First with Optional Cloud**
- App works 100% offline with cached data
- AI features require internet but have fallbacks
- Optional backend server for development testing
- Direct OpenAI API integration in production

---

## 📂 Project Structure Reference

```
formulaquizzeraccounts/
├── lib/                              # Flutter application
│   ├── config/                       # API configuration
│   │   └── api_config.dart          # OpenAI & backend URLs
│   ├── data/                         # Static data
│   │   ├── ap_subjects.dart         # AP course definitions
│   │   ├── question_bank.dart       # Fallback questions
│   │   └── subject_specific_questions.dart
│   ├── database/                     # SQLite layer
│   │   └── database_helper.dart     # CRUD + analytics
│   ├── models/                       # Data models (6 models)
│   │   ├── subject.dart             # Subject with adaptive learning
│   │   ├── question.dart            # Question with AI fields
│   │   ├── quiz_session.dart        # Quiz tracking
│   │   ├── mcq.dart                 # AI MCQ model
│   │   ├── course.dart              # Course autocomplete
│   │   └── unit.dart                # Unit organization
│   ├── providers/                    # Riverpod state (5 providers)
│   │   ├── subject_provider.dart    # Subject CRUD
│   │   ├── quiz_provider.dart       # Quiz sessions
│   │   ├── mcq_provider.dart        # AI quiz generation
│   │   ├── course_provider.dart     # Course search
│   │   └── quiz_settings_provider.dart
│   ├── screens/                      # UI screens (11 screens)
│   │   ├── home_screen.dart         # 5-tab navigation
│   │   ├── subjects_screen.dart     # Subject management
│   │   ├── progress_screen.dart     # Analytics
│   │   ├── settings_screen.dart     # App settings
│   │   ├── quiz_screen.dart         # Regular quiz
│   │   ├── mcq_quiz_screen.dart     # AI quiz
│   │   ├── mcq_loading_screen.dart  # AI generation loading
│   │   ├── add_subject_screen.dart  # Create subjects
│   │   ├── subject_search_screen.dart # Search
│   │   ├── question_management_screen.dart
│   │   └── units_management_screen.dart
│   ├── services/                     # Business logic (7 services)
│   │   ├── ai_service.dart          # Direct OpenAI integration
│   │   ├── api_service.dart         # Backend API (optional)
│   │   ├── enhanced_question_service.dart # Multi-source scraping
│   │   ├── question_scraper_service.dart # Educational sites
│   │   ├── course_service.dart      # Course CRUD
│   │   ├── course_units_service.dart # Unit auto-populate
│   │   └── notification_service.dart # Local notifications
│   ├── utils/                        # Utilities
│   │   └── stem_hasher.dart         # Question deduplication
│   ├── widgets/                      # Reusable UI (7 widgets)
│   │   ├── subject_card.dart
│   │   ├── quick_quiz_card.dart
│   │   ├── timer_quiz_card.dart
│   │   ├── stats_overview_card.dart
│   │   ├── test_notification_card.dart
│   │   ├── difficulty_selector_dialog.dart
│   │   └── course_autocomplete.dart
│   └── main.dart                     # App entry point
│
├── server/                           # Node.js backend (optional)
│   ├── src/
│   │   ├── index.ts                 # Express server
│   │   ├── openai.ts                # OpenAI integration
│   │   └── cache.ts                 # LRU cache
│   ├── package.json
│   └── .env                         # API keys
│
├── assets/                           # Static assets
│   └── courses.json                 # 1000+ course definitions
│
├── data/                             # Data files
│   └── course_units.json            # Unit templates
│
├── scripts/                          # Utility scripts
│   └── fix_ap_ids.py                # Course ID fixer
│
├── start_app.sh                      # One-command startup
└── pubspec.yaml                      # Flutter dependencies
```

---

## 🔄 Data Flow Architecture

### 1. Subject Creation Flow
```
User Input (Add Subject Screen)
    ↓
CourseAutocomplete → Search 1000+ courses
    ↓
SubjectProvider.createSubject()
    ↓
DatabaseHelper.insertSubject() → SQLite
    ↓
CourseUnitsService.autoPopulateUnits() (if available)
    ↓
UI Update → Subject list refreshes
```

### 2. AI Quiz Generation Flow
```
User Taps "AI Quiz (ChatGPT)"
    ↓
MCQProvider.generateQuiz()
    ↓
Check novelty system (avoid duplicates)
    ↓
AIService.generateMCQ() → Direct OpenAI API call
    ↓
Retry logic with exponential backoff (if rate limited)
    ↓
Response: MCQ with option-specific explanations
    ↓
DatabaseHelper.insertQuestion() → Cache locally
    ↓
Navigate to MCQQuizScreen
    ↓
User answers → Immediate feedback + explanation
    ↓
DatabaseHelper.saveQuizSession() → Update stats
```

### 3. Timer Quiz Flow
```
User Starts Timer (TimerQuizCard)
    ↓
MCQProvider.startTimerQuiz(interval: 5-60 min)
    ↓
Timer fires at random interval
    ↓
Pick random active subject (adaptive weighting)
    ↓
Generate AI question (same as manual flow)
    ↓
Show notification (or direct quiz if app open)
    ↓
User takes quiz
    ↓
Repeat until timer stopped
```

### 4. Offline Fallback Flow
```
AI Service Called
    ↓
Check Internet Connection
    ↓
IF Offline OR API Error:
    → EnhancedQuestionService.getQuestion()
    → Try educational site scrapers
    → Fallback to question_bank.dart
    → Show "Offline Mode" indicator
    ↓
IF Online:
    → Direct OpenAI API call
    → Cache result for offline use
```

---

## 💾 Database Schema (SQLite Version 2)

### subjects Table
```sql
CREATE TABLE subjects (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  description TEXT NOT NULL,
  color TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  total_questions INTEGER NOT NULL DEFAULT 0,
  correct_answers INTEGER NOT NULL DEFAULT 0,
  difficulty_weight REAL NOT NULL DEFAULT 0.5
)
```

### questions Table
```sql
CREATE TABLE questions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subject_id INTEGER NOT NULL,
  question_text TEXT NOT NULL,
  options TEXT NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  category TEXT,
  is_from_ai INTEGER NOT NULL DEFAULT 0,
  source TEXT,
  source_url TEXT,
  FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
)
```

### quiz_sessions Table
```sql
CREATE TABLE quiz_sessions (
  id TEXT PRIMARY KEY,
  subject_id INTEGER NOT NULL,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  score INTEGER NOT NULL,
  started_at TEXT NOT NULL,
  completed_at TEXT,
  FOREIGN KEY (subject_id) REFERENCES subjects (id)
)
```

### quiz_answers Table
```sql
CREATE TABLE quiz_answers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT NOT NULL,
  question_id INTEGER NOT NULL,
  user_answer TEXT NOT NULL,
  is_correct INTEGER NOT NULL,
  answered_at TEXT NOT NULL,
  FOREIGN KEY (session_id) REFERENCES quiz_sessions (id),
  FOREIGN KEY (question_id) REFERENCES questions (id)
)
```

### courses Table
```sql
CREATE TABLE courses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  course_id TEXT NOT NULL UNIQUE,
  subject_name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  is_custom INTEGER NOT NULL DEFAULT 0
)
```

### units Table
```sql
CREATE TABLE units (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  subject_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL,
  start_date TEXT,
  end_date TEXT,
  is_current INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
)
```

---

## 🎯 Key Features

### ✅ Implemented Features
1. **Unlimited Subjects**: Create any subject with custom colors
2. **AI Question Generation**: ChatGPT-powered MCQs with explanations
3. **Course Autocomplete**: 1000+ predefined courses (AP, IB, college)
4. **Unit Organization**: Break subjects into units with scheduling
5. **Timer Quizzes**: Auto-generate quizzes at intervals
6. **Adaptive Learning**: Prioritizes weaker subjects
7. **Progress Tracking**: Detailed analytics per subject
8. **Offline Mode**: Works without internet (with fallbacks)
9. **Novelty System**: Avoids duplicate questions
10. **Multi-Source Questions**: Scrapes educational sites
11. **AP Course Filtering**: Easy AP course selection
12. **Full-Screen Loading**: Beautiful loading experience

### 🔄 Optional Features (Requires Setup)
1. **Backend Server**: Node.js server for development testing
2. **Cloud Deployment**: Deploy backend to Railway/Render
3. **Real-Time Sync**: Cross-device synchronization (future)

---

## 🛠️ Development Standards

### Code Quality Rules
1. ✅ Always add `if (!mounted) return;` before `setState()`
2. ✅ Use try-catch for all async operations
3. ✅ Implement loading states and error messages
4. ✅ Dispose controllers in `dispose()`
5. ✅ Use `const` constructors where possible
6. ✅ Handle offline mode gracefully
7. ✅ Validate user inputs before database operations
8. ✅ Include educational disclaimers on AI content

### State Management (Riverpod)
- Use `StateNotifier` for complex state
- Use `Consumer` for reactive UI
- Use `ref.read()` for one-time actions
- Use `ref.watch()` for continuous listening

### Database Operations
- All queries must complete < 100ms
- Use transactions for multi-step operations
- Implement proper error handling
- Cache frequently accessed data
- Clean up old data automatically

### API Calls
- Always implement retry logic with exponential backoff
- Set reasonable timeouts (10-30 seconds)
- Fall back to local data when offline
- Log API calls for debugging
- Never expose raw errors to users

---

## 🚀 Running the App

### Development Mode (with backend)
```bash
./start_app.sh
```
Starts both backend and Flutter app

### Production Mode (direct API)
```bash
flutter run -d macos
```
Uses direct OpenAI integration (no backend needed)

### Build for Release
```bash
# macOS
flutter build macos --release

# iOS
flutter build ios --release

# Android
flutter build apk --release
```

---

## 📊 Project Statistics

```
Code Files:
  - 48 Dart files
  - 6 Models
  - 11 Screens
  - 7 Widgets
  - 7 Services
  - 5 Providers
  - 1 Database Helper

Database:
  - Version: 2
  - Tables: 6
  - Indexes: Multiple for performance

Documentation:
  - 17 Markdown files
  - This index file
  - Comprehensive coverage

Dependencies:
  - 17 Flutter packages
  - 7 Node.js packages (backend)
```

---

## ⚠️ Critical Information

### Before Making Changes
1. **Read relevant documentation** from this index
2. **Check ARCHITECTURE.md** for design principles
3. **Follow DEVELOPMENT_WORKFLOW.md** standards
4. **Test with STARTUP_GUIDE.md** procedures
5. **Update documentation** after changes

### Common Mistakes to Avoid
❌ Forgetting `if (!mounted)` before `setState()`  
❌ Not handling offline mode  
❌ Skipping error handling in async operations  
❌ Exposing raw API errors to users  
❌ Not implementing retry logic for API calls  
❌ Breaking the offline-first architecture  
❌ Not updating documentation after changes

### Performance Targets
- Database queries: < 100ms
- AI generation: < 5000ms (with retries)
- UI responsiveness: 60 FPS
- App startup: < 2 seconds
- Memory usage: < 200MB

---

## 🆘 Troubleshooting

### App Won't Build
1. Run `flutter clean`
2. Run `flutter pub get`
3. Check STARTUP_GUIDE.md for platform-specific issues

### Backend Won't Start
1. Check Node.js is installed: `node --version`
2. Run `npm install` in server directory
3. Verify .env file exists with API key

### AI Features Not Working
1. Check internet connection
2. Verify OpenAI API key in config/api_config.dart
3. Check API usage limits at platform.openai.com
4. Review error logs in console

### Database Issues
1. App stores data in SQLite locally
2. Clear app data to reset database
3. Check database version in database_helper.dart
4. Migration happens automatically

---

## 📞 Support & Resources

### Documentation Files
- All documentation in this repository
- Start with README.md for overview
- Use this index for navigation

### External Resources
- OpenAI API Docs: https://platform.openai.com/docs
- Flutter Docs: https://docs.flutter.dev
- Riverpod Docs: https://riverpod.dev

### Quick Links
- OpenAI API Keys: https://platform.openai.com/api-keys
- OpenAI Usage: https://platform.openai.com/usage
- Flutter SDK: https://flutter.dev/docs/get-started/install

---

## 🎓 Educational Disclaimer

All AI-generated questions and explanations are for **educational purposes only**. Always verify critical information with authoritative sources.

---

## 📄 License

MIT License - See project root for details

---

**Last Updated**: October 20, 2025  
**Maintained By**: Development Team  
**Status**: ✅ Production Ready

---

## 🗺️ Next Steps

### For New Developers:
1. Read README.md
2. Follow QUICK_START.md
3. Study FORMULAQUIZZERACCOUNTS_ARCHITECTURE.md
4. Review DEVELOPMENT_WORKFLOW.md

### For Feature Work:
1. Check existing feature documentation
2. Follow architecture patterns
3. Implement with testing
4. Update relevant docs

### For Deployment:
1. Read PRODUCTION_DEPLOYMENT.md
2. Configure SETUP_API_KEY.md
3. Test thoroughly
4. Deploy with confidence

**This index is your starting point for everything! 🚀**
