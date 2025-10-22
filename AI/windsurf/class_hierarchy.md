# Class Hierarchy and Relationships

**FormulaQuizzer - Complete Class Structure**

---

## Inheritance Hierarchy

### Screens (UI Layer)

```
StatelessWidget
└── FormulaQuizzerApp (main.dart)

ConsumerStatefulWidget (Riverpod integration)
├── HomeScreen
├── SubjectsScreen
├── QuizScreen
├── ProgressScreen
├── SettingsScreen
├── SubjectSearchScreen
├── AuthScreen
├── MCQLoadingScreen
├── MCQQuizScreen
├── QuestionManagementScreen
└── UnitsManagementScreen

StatefulWidget (Non-Riverpod)
└── (None - all screens use Riverpod)
```

---

## State Notifiers (Riverpod)

```
StateNotifier<T>
├── SubjectNotifier extends StateNotifier<List<Subject>>
├── QuizNotifier extends StateNotifier<QuizState>
├── MCQQuizNotifier extends StateNotifier<MCQQuizState>
└── CourseNotifier extends StateNotifier<List<Course>>
```

**Provider Declarations**:
```dart
// Subject management
final subjectProvider = StateNotifierProvider<SubjectNotifier, List<Subject>>(
  (ref) => SubjectNotifier(),
);

// Quiz state
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(),
);

// MCQ quiz state
final mcqQuizProvider = StateNotifierProvider<MCQQuizNotifier, MCQQuizState>(
  (ref) => MCQQuizNotifier(),
);

// Course data
final courseProvider = StateNotifierProvider<CourseNotifier, List<Course>>(
  (ref) => CourseNotifier(),
);
```

---

## Models (Data Layer)

All models are **plain Dart classes** (no inheritance):

```
class Subject {
  int? id;
  String name;
  String description;
  String color;
  DateTime createdAt;
  DateTime updatedAt;
  bool isActive;
  int totalQuestions;
  int correctAnswers;
  double difficultyWeight;
}

class Question {
  int? id;
  int subjectId;
  String questionText;
  List<String> options;
  String correctAnswer;
  String explanation;
  String difficulty;
  DateTime createdAt;
  bool isFromAI;
  String? sourceUrl;
  String? source;
}

class QuizSession {
  int? id;
  int subjectId;
  int questionId;
  String userAnswer;
  bool isCorrect;
  DateTime answeredAt;
  int timeSpentSeconds;
  String difficulty;
}

class MCQ {
  String question;
  List<String> options;
  String correctAnswer;
  String explanation;
  String subject;
  int subjectId;
}

class Course {
  int? id;
  String courseId;
  String subjectName;
  String category;
  String? description;
  bool isCustom;
  DateTime createdAt;
}

class Unit {
  int? id;
  int subjectId;
  String name;
  String? description;
  int orderIndex;
  DateTime? startDate;
  DateTime? endDate;
  bool isCurrent;
  DateTime createdAt;
}
```

---

## State Classes

```
class QuizState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final int score;
  final bool isLoading;
  final String? error;
  final Subject? currentSubject;
  final Question? currentQuestion;
  final int totalQuestions;
}

class MCQQuizState {
  final MCQ? currentMCQ;
  final bool isLoading;
  final String? error;
  final int attemptCount;
  final bool hasAnswered;
  final String? userAnswer;
}
```

---

## Services (Singleton Pattern)

All services use the **Singleton Factory pattern**:

```dart
class ServiceName {
  static final ServiceName _instance = ServiceName._internal();
  factory ServiceName() => _instance;
  ServiceName._internal();
  
  // Service methods
}
```

**Service Classes**:
```
AuthService (singleton)
├── signUp()
├── signIn()
├── signOut()
├── currentUser
└── isLoggedIn

SyncService (singleton)
├── uploadSubjects()
├── uploadQuestions()
├── downloadSubjects()
├── downloadQuestions()
└── fullSync()

BackgroundSyncService (singleton)
├── startBackgroundSync()
├── stopBackgroundSync()
├── syncNow()
├── lastSyncTime
└── isSyncing

NotificationService (singleton)
├── initialize()
├── scheduleQuizNotifications()
├── cancelAllNotifications()
└── showQuizCompleteNotification()

OpenAIService (singleton)
├── generateMCQ()
└── generateMultipleMCQs()

CourseService (singleton)
├── loadDefaultCourses()
├── searchCourses()
└── getCoursesByCategory()

DatabaseHelper (singleton)
├── insertSubject()
├── getAllSubjects()
├── updateSubject()
├── deleteSubject()
├── insertQuestion()
├── getQuestionsBySubject()
├── insertQuizSession()
├── updateSubjectPerformance()
├── clearAllData()
└── (many more CRUD methods)
```

---

## Relationships and Dependencies

### SubjectProvider Dependencies

```
SubjectProvider
├── depends on → DatabaseHelper (data persistence)
├── depends on → SyncService (cloud sync)
└── used by → HomeScreen, SubjectsScreen, QuizScreen
```

**Methods**:
```dart
class SubjectNotifier extends StateNotifier<List<Subject>> {
  final DatabaseHelper _db = DatabaseHelper();
  final SyncService _syncService = SyncService();
  
  Future<void> loadSubjects();
  Future<void> addSubject(Subject subject);
  Future<void> updateSubject(Subject subject);
  Future<void> deleteSubject(int id);
  Future<void> toggleSubjectActive(int id);
}
```

---

### QuizProvider Dependencies

```
QuizProvider
├── depends on → DatabaseHelper (questions, sessions)
├── depends on → SubjectProvider (subject data)
└── used by → QuizScreen, HomeScreen (Quick Quiz)
```

**Methods**:
```dart
class QuizNotifier extends StateNotifier<QuizState> {
  final DatabaseHelper _db = DatabaseHelper();
  
  Future<void> startQuiz(int subjectId);
  Future<void> startQuickQuiz();
  Future<void> nextQuestion();
  void submitAnswer(String answer);
  void resetQuiz();
  void clearError();
}
```

---

### MCQProvider Dependencies

```
MCQQuizProvider
├── depends on → OpenAIService (AI generation)
├── depends on → DatabaseHelper (save questions)
└── used by → MCQLoadingScreen, MCQQuizScreen
```

**Methods**:
```dart
class MCQQuizNotifier extends StateNotifier<MCQQuizState> {
  final OpenAIService _openAI = OpenAIService();
  final DatabaseHelper _db = DatabaseHelper();
  
  Future<void> generateMCQ(String subjectName);
  void submitAnswer(String answer);
  void resetMCQ();
}
```

---

### AuthService Dependencies

```
AuthService
├── depends on → Supabase client (authentication)
├── depends on → DatabaseHelper (data clearing)
└── used by → AuthScreen, SettingsScreen
```

---

### SyncService Dependencies

```
SyncService
├── depends on → Supabase client (cloud storage)
├── depends on → AuthService (user identification)
├── depends on → DatabaseHelper (local data)
└── used by → SubjectProvider, BackgroundSyncService
```

---

### BackgroundSyncService Dependencies

```
BackgroundSyncService
├── depends on → AuthService (login status)
├── depends on → SyncService (sync operations)
└── used by → main.dart, AuthScreen, SettingsScreen
```

---

## Data Flow Diagram

```
User Input (UI)
      ↓
[ConsumerWidget Screen]
      ↓
   ref.read(provider.notifier).method()
      ↓
[StateNotifier]
      ↓
[Service Layer] ← → [External APIs]
      ↓           (OpenAI, Supabase)
[DatabaseHelper]
      ↓
   SQLite Database
      ↓
State Change (rebuild UI)
```

---

## Object Relationships

### Subject → Questions (One-to-Many)

```dart
// One subject has many questions
Subject subject = await db.getSubjectById(1);
List<Question> questions = await db.getQuestionsBySubject(subject.id!);
```

### Subject → QuizSessions (One-to-Many)

```dart
// One subject has many quiz sessions
Subject subject = await db.getSubjectById(1);
List<QuizSession> sessions = await db.getQuizSessionsBySubject(subject.id!);
```

### Subject → Units (One-to-Many)

```dart
// One subject has many units/chapters
Subject subject = await db.getSubjectById(1);
List<Unit> units = await db.getUnitsBySubject(subject.id!);
```

### Question → QuizSessions (One-to-Many)

```dart
// One question can be answered multiple times
Question question = await db.getQuestionById(1);
List<QuizSession> attempts = await db.getQuizSessionsByQuestion(question.id!);
```

---

## Composition Patterns

### Screen Composition

```dart
class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Composed widgets
  Widget _buildQuickQuizCard() { }
  Widget _buildSubjectsList() { }
  Widget _buildPerformanceChart() { }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column([
        _buildQuickQuizCard(),
        _buildSubjectsList(),
        _buildPerformanceChart(),
      ]),
    );
  }
}
```

---

## Utility Classes

```
class StemHasher {
  static String hashQuestion(String text);
  static bool areQuestionsSimilar(String q1, String q2);
}

class ApiConfig {
  static const String openaiApiKey = '...';
  static const String supabaseUrl = '...';
  static const String supabaseAnonKey = '...';
  static const bool enableSync = true;
}
```

---

## Third-Party Integrations

### Supabase Client

```dart
import 'package:supabase_flutter/supabase_flutter.dart';

final supabase = Supabase.instance.client;

// Used by:
// - AuthService
// - SyncService
// - main.dart (initialization)
```

### OpenAI (via HTTP)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// Used by:
// - OpenAIService
```

### Flutter Local Notifications

```dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin;

// Used by:
// - NotificationService
```

---

## Navigation Structure

```
MaterialApp
└── Scaffold with BottomNavigationBar
    ├── Tab 0: HomeScreen
    ├── Tab 1: SubjectsScreen
    ├── Tab 2: QuizScreen
    ├── Tab 3: ProgressScreen
    └── Tab 4: SettingsScreen

Navigation Routes:
HomeScreen → QuizScreen (subject selected)
QuizScreen → QuestionManagementScreen
SubjectsScreen → SubjectSearchScreen
SubjectsScreen → UnitsManagementScreen
QuizScreen → MCQLoadingScreen → MCQQuizScreen
SettingsScreen → AuthScreen (logout)
```

---

## Type Relationships

### Difficulty Levels
```dart
enum (represented as String)
- 'easy'
- 'medium'
- 'hard'
```

### Question Types
```dart
// Implicit (no enum)
- Multiple Choice (MCQ)
- True/False
- Fill-in-blank
```

### Sync Status
```dart
class SyncResult {
  final bool success;
  final String message;
  final int subjectsCount;
  final int questionsCount;
}
```

---

## Lifecycle Management

### App Lifecycle
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Supabase
  await Supabase.initialize(...);
  
  // 2. Initialize Notifications
  await NotificationService().initialize();
  
  // 3. Load Default Courses
  await CourseService().loadDefaultCourses();
  
  // 4. Auto-sync if logged in
  if (AuthService().isLoggedIn) {
    SyncService().fullSync();
    BackgroundSyncService().startBackgroundSync();
  }
  
  runApp(ProviderScope(child: FormulaQuizzerApp()));
}
```

### Provider Lifecycle
```dart
// Providers are created lazily on first access
// They persist for the app lifetime
// StateNotifier notifies listeners on state changes
```

### Screen Lifecycle
```dart
class _ScreenState extends ConsumerState<Screen> {
  @override
  void initState() {
    super.initState();
    // Load initial data
    Future.microtask(() => ref.read(provider.notifier).loadData());
  }
  
  @override
  void dispose() {
    // Clean up
    super.dispose();
  }
}
```

---

## Memory Management

### Singleton Services
- Created once, live for app lifetime
- No disposal needed
- Minimal memory footprint

### Providers
- Cached by Riverpod
- Auto-dispose when no listeners
- Can be explicitly reset if needed

### Database Connection
- Single connection per app
- Reused for all queries
- Closed on app termination

### Large Assets
- Courses JSON loaded once on startup
- Question data loaded per-subject (lazy)
- Images/assets loaded on-demand
