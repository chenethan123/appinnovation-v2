# Quick Reference Cheat Sheet

**FormulaQuizzer - Essential Information at a Glance**

---

## 🚀 Quick Commands

```bash
# Development
flutter run -d macos                    # Run on macOS
flutter run -d "DEVICE_ID"             # Run on specific device
flutter clean && flutter pub get        # Clean and rebuild
flutter analyze                         # Analyze code
flutter format lib/                     # Format code

# Debugging
flutter run -v                          # Verbose output
flutter devices                         # List available devices
flutter doctor                          # Check setup

# Git
git checkout workingServer              # Switch to main branch
git checkout -b feature/name            # Create feature branch
git add -A && git commit -m "msg"      # Commit changes
git push -u origin branch-name          # Push new branch
```

---

## 📁 Key Files Quick Access

```
lib/config/api_config.dart              # API keys
lib/main.dart                           # App entry point
lib/database/database_helper.dart       # Local database
lib/services/auth_service.dart          # Authentication
lib/services/sync_service.dart          # Cloud sync
lib/services/openai_service.dart        # AI generation
lib/providers/subject_provider.dart     # Subject state
lib/providers/quiz_provider.dart        # Quiz state
server/supabase_schema.sql              # Cloud schema
```

---

## 🗄️ Database Quick Reference

### Common Queries

```dart
// Subjects
final subjects = await DatabaseHelper().getAllSubjects();
final subject = await DatabaseHelper().getSubjectById(id);
await DatabaseHelper().insertSubject(subject);
await DatabaseHelper().updateSubject(subject);
await DatabaseHelper().deleteSubject(id);

// Questions
final questions = await DatabaseHelper().getQuestionsBySubject(subjectId);
await DatabaseHelper().insertQuestion(question);

// Quiz Sessions
await DatabaseHelper().insertQuizSession(session);
await DatabaseHelper().updateSubjectPerformance(subjectId, isCorrect);

// Cleanup
await DatabaseHelper().clearAllData(); // On logout
```

### Database Version
```dart
static const int _version = 9; // Current version
```

---

## 🔐 Authentication Quick Reference

```dart
// Sign Up
await AuthService().signUp(email, password);

// Sign In
await AuthService().signIn(email, password);

// Sign Out (clears local data)
await AuthService().signOut();

// Check Status
bool loggedIn = AuthService().isLoggedIn;
String? userId = AuthService().userId;
User? user = AuthService().currentUser;
```

---

## 🔄 Sync Quick Reference

```dart
// Upload
await SyncService().uploadSubjects();
await SyncService().uploadQuestions();

// Download
await SyncService().downloadSubjects();
await SyncService().downloadQuestions();

// Full Sync
SyncResult result = await SyncService().fullSync();

// Background Sync
BackgroundSyncService().startBackgroundSync(); // Auto every 5 min
BackgroundSyncService().stopBackgroundSync();
BackgroundSyncService().syncNow(); // Force now
```

---

## 🤖 AI Generation Quick Reference

```dart
// Generate Single MCQ
final mcq = await OpenAIService().generateMCQ(
  subject: 'Calculus',
  subjectId: 1,
  difficulty: 'medium', // 'easy', 'medium', 'hard'
  choices: 4,
);

// Generate Multiple
final mcqs = await OpenAIService().generateMultipleMCQs(
  subject: 'Physics',
  subjectId: 2,
  count: 5,
);

// Convert to Question
final question = mcq.toQuestion();
await DatabaseHelper().insertQuestion(question);
```

---

## 🎨 Provider Patterns

### Watching State
```dart
// In Widget build()
final subjects = ref.watch(subjectProvider);
final quizState = ref.watch(quizProvider);
```

### Reading (One-time)
```dart
// In callbacks
ref.read(subjectProvider.notifier).loadSubjects();
ref.read(quizProvider.notifier).startQuiz(id);
```

### Listening to Changes
```dart
// In initState or build
ref.listen<QuizState>(quizProvider, (previous, next) {
  if (next.error != null) {
    showErrorDialog(next.error!);
  }
});
```

---

## 🎯 Common Patterns

### Async Loading Pattern
```dart
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(myProvider.notifier).loadData();
  });
}
```

### Safe setState Pattern
```dart
Future<void> loadData() async {
  final data = await fetchData();
  if (!mounted) return; // Always check
  setState(() {
    _data = data;
  });
}
```

### Error Handling Pattern
```dart
try {
  await operation();
  print('✅ Success');
} catch (e) {
  print('❌ Error: $e');
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## 🔔 Notification Quick Reference

```dart
// Initialize
await NotificationService().initialize();

// Schedule Based on Settings
await NotificationService().scheduleQuizNotifications();

// Cancel All
await NotificationService().cancelAllNotifications();

// Show Immediate
await NotificationService().showQuizCompleteNotification(
  score: 8,
  total: 10,
  subjectName: 'Math',
);
```

---

## 📊 Model Structures

### Subject
```dart
Subject(
  id: 1, // Auto-generated
  name: 'Calculus',
  description: 'Differential and integral calculus',
  color: '#6366f1',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
  isActive: true,
  totalQuestions: 0,
  correctAnswers: 0,
  difficultyWeight: 0.5, // 0.0 to 1.0
)
```

### Question
```dart
Question(
  id: 1,
  subjectId: 1,
  questionText: 'What is the derivative of x^2?',
  options: ['2x', 'x', '2', 'x^2'],
  correctAnswer: '2x',
  explanation: 'The power rule...',
  difficulty: 'medium', // 'easy', 'medium', 'hard'
  createdAt: DateTime.now(),
  isFromAI: true,
  sourceUrl: null,
  source: 'OpenAI GPT-4',
)
```

### MCQ
```dart
MCQ(
  question: 'What is 2 + 2?',
  options: ['3', '4', '5', '6'],
  correctAnswer: '4',
  explanation: 'Basic addition...',
  subject: 'Math',
  subjectId: 1,
)
```

---

## 🎨 UI Components

### Loading State
```dart
if (state.isLoading) {
  return const Center(child: CircularProgressIndicator());
}
```

### Error State
```dart
if (state.error != null) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.error_outline, size: 64, color: Colors.red),
        Text(state.error!),
        FilledButton(
          onPressed: () => retry(),
          child: Text('Retry'),
        ),
      ],
    ),
  );
}
```

### Empty State
```dart
if (subjects.isEmpty) {
  return Center(
    child: Column(
      children: [
        Icon(Icons.inbox_outlined, size: 64),
        Text('No subjects yet'),
        FilledButton(
          onPressed: () => addSubject(),
          child: Text('Add Subject'),
        ),
      ],
    ),
  );
}
```

---

## 🐛 Debug Helpers

### Print with Context
```dart
print('🔍 [ClassName.methodName]');
print('   Variable: $value');
print('   State: ${state.toString()}');
```

### Measure Performance
```dart
final stopwatch = Stopwatch()..start();
await operation();
stopwatch.stop();
print('⏱️ Took ${stopwatch.elapsedMilliseconds}ms');
```

### Conditional Logging
```dart
if (ApiConfig.debugMode) {
  print('🐛 Debug: $info');
}
```

---

## 🔧 Configuration Flags

```dart
// lib/config/api_config.dart

class ApiConfig {
  // API Keys
  static const String openaiApiKey = 'sk-...';
  static const String supabaseUrl = 'https://...';
  static const String supabaseAnonKey = 'eyJ...';
  
  // Features
  static const bool enableSync = true;
  static const bool debugMode = false;
  
  // AI Settings
  static const String aiModel = 'gpt-4';
  static const int maxRetries = 3;
  
  // Sync Settings
  static const Duration syncInterval = Duration(minutes: 5);
}
```

---

## 📏 Code Quality Checklist

Before committing:
- [ ] Code formatted (`flutter format lib/`)
- [ ] No analyzer warnings (`flutter analyze`)
- [ ] Mounted checks before setState
- [ ] Try-catch around async operations
- [ ] Meaningful variable names
- [ ] Comments for complex logic
- [ ] Error handling implemented
- [ ] Tested on target platform
- [ ] No console.log/print statements in production code

---

## 🚨 Critical Don'ts

```dart
// ❌ DON'T: Modify provider in build
@override
Widget build(BuildContext context) {
  ref.read(provider.notifier).loadData(); // BAD!
  return Container();
}

// ✅ DO: Load in initState
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(provider.notifier).loadData();
  });
}

// ❌ DON'T: Forget mounted check
setState(() {
  _data = newData; // BAD if widget disposed
});

// ✅ DO: Check mounted
if (!mounted) return;
setState(() {
  _data = newData;
});

// ❌ DON'T: Commit API keys
static const String apiKey = 'sk-actual-key'; // BAD!

// ✅ DO: Use gitignored config
static const String apiKey = ApiConfig.openaiApiKey;

// ❌ DON'T: Block UI thread
final data = heavyOperation(); // BAD!

// ✅ DO: Use async/await
final data = await heavyOperation();
```

---

## 🎯 Testing Shortcuts

### Test Sync
```dart
// 1. Login
await AuthService().signIn('test@test.com', 'password');

// 2. Add data
await SubjectProvider().addSubject(Subject(...));

// 3. Check Supabase dashboard

// 4. Logout and login different user
await AuthService().signOut();
await AuthService().signIn('other@test.com', 'password');

// 5. Verify no data mixing
final subjects = await DatabaseHelper().getAllSubjects();
assert(subjects.isEmpty || subjects.every((s) => s.ownedByCurrentUser));
```

### Test AI
```dart
// Quick test
final mcq = await OpenAIService().generateMCQ(
  subject: 'Test',
  subjectId: 1,
);
print(mcq.question);
```

### Test Offline
```bash
# Turn off WiFi
# Use app
# Verify everything works
# Turn on WiFi
# Verify auto-sync
```

---

## 📞 Emergency Fixes

### Database Corrupted
```dart
final dbPath = await getDatabasesPath();
await deleteDatabase(join(dbPath, 'formula_quizzer.db'));
// Restart app
```

### Sync Broken
```dart
// Force full re-sync
await DatabaseHelper().clearAllData();
await SyncService().downloadSubjects();
await SyncService().downloadQuestions();
```

### Provider Stuck
```dart
// Reset provider state
ref.invalidate(subjectProvider);
```

---

## 🎓 Architecture Summary

```
UI (Screens/Widgets)
    ↓ ref.watch/read
Providers (Riverpod StateNotifier)
    ↓ method calls
Services (Business Logic)
    ↓ CRUD operations
Database (SQLite + Supabase)
```

**Key Principle**: Local-first, sync-optional, account-isolated

---

**Save this file for quick reference during development!**
