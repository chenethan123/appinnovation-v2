# FormulaQuizzer - Windsurf Documentation

**Complete technical documentation for the FormulaQuizzer project**

Created: October 22, 2025  
Branch: workingServer  
Last Updated: October 22, 2025  

---

## 📚 Documentation Index

### Essential Documents

1. **[Project Overview](./project_overview.md)**
   - Project purpose and goals
   - Key features overview
   - Technology stack
   - Current status and roadmap
   - Performance requirements
   - API keys required

2. **[Architecture](./architecture.md)**
   - System architecture layers
   - State management (Riverpod)
   - Service layer details
   - Data layer (models, database)
   - Data flow examples
   - Security measures

3. **[Class Hierarchy](./class_hierarchy.md)**
   - Complete class structure
   - Inheritance relationships
   - State notifiers and providers
   - Model classes
   - Service singletons
   - Object relationships
   - Memory management

4. **[Key Features](./key_features.md)**
   - Cross-device synchronization
   - AI question generation
   - Adaptive learning algorithm
   - Local notifications
   - Course and unit organization
   - Progress tracking
   - Offline-first architecture
   - Question management
   - User authentication
   - Theme and UI customization

5. **[API Reference](./api_reference.md)**
   - Database API (DatabaseHelper)
   - Sync Service API
   - Auth Service API
   - Background Sync Service API
   - OpenAI Service API
   - Notification Service API
   - Course Service API
   - Provider APIs
   - Error handling
   - Response types

6. **[Common Tasks](./common_tasks.md)**
   - Setup tasks
   - Adding new features
   - Data management
   - Testing workflows
   - Debugging techniques
   - Performance optimization
   - Deployment procedures

7. **[Troubleshooting](./troubleshooting.md)**
   - Build and setup issues
   - Database problems
   - Sync failures
   - Authentication errors
   - AI generation issues
   - UI and state problems
   - Notification issues
   - Performance problems
   - Deployment issues
   - Debug commands

---

## 🚀 Quick Start

### For New Developers

```bash
# 1. Clone and setup
git clone https://github.com/chenethan123/appinnovation-v2.git
cd appinnovation-v2
git checkout workingServer
flutter pub get

# 2. Configure API keys
# Edit lib/config/api_config.dart

# 3. Run the app
flutter run -d macos
```

**Read Next**: [Project Overview](./project_overview.md) → [Architecture](./architecture.md)

### For Adding Features

1. Read [Common Tasks - Adding a New Feature](./common_tasks.md#adding-a-new-feature)
2. Check [Architecture](./architecture.md) for patterns
3. Review [API Reference](./api_reference.md) for available methods
4. Test thoroughly before committing

### For Debugging

1. Check [Troubleshooting](./troubleshooting.md) for common issues
2. Review [Common Tasks - Debugging](./common_tasks.md#debugging-tasks)
3. Use debug commands from [Troubleshooting - Debug Commands](./troubleshooting.md#debug-commands)

---

## 🏗️ Project Structure

```
FormulaQuizzer/
├── lib/
│   ├── config/              # API keys and configuration
│   │   └── api_config.dart
│   ├── data/               # Static data (AP subjects, question banks)
│   │   ├── ap_subjects.dart
│   │   └── question_bank.dart
│   ├── database/           # SQLite database helpers
│   │   ├── database_helper.dart
│   │   └── question_database.dart
│   ├── models/             # Data models
│   │   ├── subject.dart
│   │   ├── question.dart
│   │   ├── quiz_session.dart
│   │   ├── mcq.dart
│   │   ├── course.dart
│   │   └── unit.dart
│   ├── providers/          # Riverpod state management
│   │   ├── subject_provider.dart
│   │   ├── quiz_provider.dart
│   │   ├── mcq_provider.dart
│   │   └── course_provider.dart
│   ├── screens/            # UI screens
│   │   ├── home_screen.dart
│   │   ├── subjects_screen.dart
│   │   ├── quiz_screen.dart
│   │   ├── progress_screen.dart
│   │   ├── settings_screen.dart
│   │   ├── auth_screen.dart
│   │   ├── mcq_loading_screen.dart
│   │   └── mcq_quiz_screen.dart
│   ├── services/           # Business logic services
│   │   ├── auth_service.dart
│   │   ├── sync_service.dart
│   │   ├── background_sync_service.dart
│   │   ├── openai_service.dart
│   │   ├── notification_service.dart
│   │   └── course_service.dart
│   ├── utils/              # Utility functions
│   │   └── stem_hasher.dart
│   ├── widgets/            # Reusable UI components
│   └── main.dart           # App entry point
├── assets/                 # Static assets
│   └── courses.json
├── server/                 # Backend resources
│   └── supabase_schema.sql
└── AI/windsurf/           # This documentation
```

---

## 🎯 Key Concepts

### Local-First Design
- **Primary**: SQLite local database
- **Secondary**: Supabase cloud sync (optional)
- **Principle**: App works completely offline
- **Sync**: Background sync when online

### Account Isolation
- Each user's data completely separate
- Local data cleared on logout
- Fresh download on login
- RLS policies enforce separation

### Adaptive Learning
- `difficultyWeight` tracks subject performance
- Algorithm prioritizes weaker subjects
- Weighted random selection
- Performance updates after each quiz

### Novelty Enforcement
- STEM-based hashing prevents duplicates
- Recent questions sent to AI as context
- Explicit prompts for different questions
- Fallback to local questions on failure

---

## 📊 Architecture at a Glance

```
┌─────────────────────────────────────┐
│         UI Layer (Screens)          │
│   Home, Quiz, Progress, Settings    │
└──────────────┬──────────────────────┘
               │ ref.watch/read
┌──────────────▼──────────────────────┐
│      State Management (Riverpod)     │
│  SubjectProvider, QuizProvider, etc. │
└──────────────┬──────────────────────┘
               │ async calls
┌──────────────▼──────────────────────┐
│     Services (Business Logic)        │
│  Auth, Sync, OpenAI, Notifications   │
└────┬─────────────────────────────┬──┘
     │                             │
┌────▼─────────┐          ┌────────▼────┐
│   SQLite     │          │   Supabase  │
│   (Local)    │  ←sync→  │   (Cloud)   │
└──────────────┘          └─────────────┘
```

---

## 🔑 Critical Files

### Configuration
- **`lib/config/api_config.dart`**: API keys and feature flags
  - OpenAI API key
  - Supabase URL and anon key
  - Enable/disable sync

### Entry Point
- **`lib/main.dart`**: App initialization
  - Supabase setup
  - Notification init
  - Course loading
  - Auto-sync trigger

### Core Services
- **`lib/services/auth_service.dart`**: Authentication
- **`lib/services/sync_service.dart`**: Cloud synchronization
- **`lib/services/openai_service.dart`**: AI question generation

### Database
- **`lib/database/database_helper.dart`**: Local data storage
- **`server/supabase_schema.sql`**: Cloud database schema

### State Management
- **`lib/providers/subject_provider.dart`**: Subject CRUD
- **`lib/providers/quiz_provider.dart`**: Quiz logic

---

## 🛠️ Development Workflow

### Making Changes

1. **Create feature branch**
   ```bash
   git checkout -b feature/my-feature
   ```

2. **Make changes following patterns**
   - Check [Architecture](./architecture.md) for patterns
   - Use [API Reference](./api_reference.md) for existing methods
   - Follow [Common Tasks](./common_tasks.md) for new features

3. **Test thoroughly**
   - Manual testing on target platforms
   - Check sync functionality
   - Verify offline mode
   - Test account isolation

4. **Commit and push**
   ```bash
   git add .
   git commit -m "Add feature: description"
   git push origin feature/my-feature
   ```

5. **Create pull request**
   - Describe changes clearly
   - Reference related issues
   - Request review

### Code Style

```dart
// Use const constructors where possible
const MyWidget({super.key});

// Check mounted before setState
if (!mounted) return;
setState(() {});

// Use descriptive names
final activeSubjects = subjects.where((s) => s.isActive).toList();

// Add comments for complex logic
// Calculate difficulty weight using weighted moving average
final newWeight = isCorrect ? ...;

// Use async/await properly
Future<void> loadData() async {
  try {
    final data = await fetchData();
    if (!mounted) return;
    setState(() => _data = data);
  } catch (e) {
    print('Error: $e');
  }
}
```

---

## 📈 Performance Guidelines

### Database
- Add indexes for frequently queried columns
- Limit result sets with WHERE clauses
- Use pagination for large datasets
- Close connections when done

### API Calls
- Batch operations when possible
- Implement retry with exponential backoff
- Cache responses appropriately
- Handle errors gracefully

### UI
- Use const constructors
- Avoid rebuilds in build()
- Lazy load heavy data
- Optimize images and assets

### Memory
- Dispose controllers in dispose()
- Cancel subscriptions
- Clear large lists when not needed
- Use weak references where appropriate

---

## 🔒 Security Best Practices

1. **Never commit API keys** - Use environment variables or gitignored files
2. **Implement RLS** - All Supabase tables must have Row-Level Security
3. **Clear data on logout** - Prevent data leakage between accounts
4. **Validate inputs** - Check user inputs before database operations
5. **Use HTTPS only** - All external API calls over secure connections
6. **Handle tokens securely** - Don't log or expose JWT tokens
7. **Implement rate limiting** - Prevent API abuse
8. **Sanitize user content** - Prevent injection attacks

---

## 📝 Coding Standards

### Flutter/Dart
- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter analyze` before committing
- Format code with `flutter format`
- Use meaningful variable names
- Add documentation comments for public APIs

### Riverpod
- Keep providers focused and single-purpose
- Use StateNotifier for complex state
- Implement copyWith for state classes
- Handle errors at provider level

### Database
- Use transactions for multi-step operations
- Add indexes for foreign keys
- Implement proper migrations
- Test schema changes thoroughly

---

## 🚨 Important Notes

### Sync System
- **Quiz sessions sync is disabled** due to UUID/integer ID mismatch
- Will be fixed in future version with UUID migration

### Email Confirmation
- **Must be disabled in Supabase** for testing
- Or implement email confirmation flow

### API Keys
- **OpenAI key required** for AI question generation
- **Supabase credentials required** for cloud sync
- App works offline without these keys

### Data Isolation
- **Critical**: Each account must have separate data
- Always filter by user_id in cloud queries
- Clear local data on logout

---

## 📞 Support and Resources

### Internal Documentation
- See project root for additional docs:
  - `FORMULAQUIZZERACCOUNTS_ARCHITECTURE.md`
  - `SUPABASE_SETUP_GUIDE.md`
  - `STARTUP_GUIDE.md`
  - `DOCUMENTATION_INDEX.md`

### External Resources
- [Flutter Docs](https://flutter.dev/docs)
- [Riverpod Docs](https://riverpod.dev)
- [Supabase Docs](https://supabase.com/docs)
- [OpenAI API Docs](https://platform.openai.com/docs)

### Getting Help
1. Check [Troubleshooting](./troubleshooting.md)
2. Search existing issues on GitHub
3. Review similar implementations in codebase
4. Ask team members or create GitHub issue

---

## 🎓 Learning Path

### New to Project
1. Read [Project Overview](./project_overview.md)
2. Study [Architecture](./architecture.md)
3. Explore [Class Hierarchy](./class_hierarchy.md)
4. Try [Common Tasks](./common_tasks.md) examples

### Ready to Contribute
1. Review [API Reference](./api_reference.md)
2. Check [Key Features](./key_features.md) for patterns
3. Follow [Common Tasks](./common_tasks.md) workflows
4. Use [Troubleshooting](./troubleshooting.md) when stuck

### Mastering the Codebase
1. Understand adaptive learning algorithm
2. Master sync conflict resolution
3. Optimize database queries
4. Implement new features end-to-end

---

## 📅 Version History

### October 22, 2025 (workingServer branch)
- ✅ Cross-device sync with Supabase
- ✅ Account isolation with data clearing
- ✅ Auto-sync on login, logout, data changes
- ✅ Background sync every 5 minutes
- ✅ Fixed provider modification errors
- ✅ Disabled quiz session sync (temporary)
- ✅ Complete documentation created

### Earlier Versions
- AI question generation with OpenAI
- Adaptive learning algorithm
- Local notifications
- Course/unit organization
- Progress tracking
- Offline-first architecture

---

**This documentation is a living resource. Keep it updated as the project evolves!**

For questions or suggestions about this documentation, please contact the development team or create an issue.

---

*Generated for Windsurf AI Assistant - Complete project analysis and reference*
