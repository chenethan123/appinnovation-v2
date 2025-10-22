# System Architecture

**FormulaQuizzer - Technical Architecture Documentation**

---

## Architecture Overview

FormulaQuizzer follows a **layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│         Presentation Layer (UI)              │
│  - Screens (ConsumerWidget/StatefulWidget)  │
│  - Widgets (Reusable Components)            │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│      State Management Layer (Riverpod)       │
│  - Providers (SubjectProvider, QuizProvider) │
│  - Notifiers (StateNotifier pattern)        │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│         Business Logic Layer (Services)      │
│  - AIService, SyncService, AuthService      │
│  - NotificationService, CourseService       │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│         Data Layer (Models & Database)       │
│  - Models (Subject, Question, etc.)         │
│  - DatabaseHelper (SQLite)                  │
│  - Supabase Client (Cloud sync)             │
└─────────────────────────────────────────────┘
```

---

## Layer Details

### 1. Presentation Layer

**Responsibility**: User interface and user interactions

**Components**:
- **Screens**: Full-page views (HomeScreen, QuizScreen, etc.)
- **Widgets**: Reusable UI components (SubjectCard, QuickQuizCard)
- **Navigation**: MaterialApp with bottom navigation bar

**Key Patterns**:
- `ConsumerWidget` for Riverpod integration
- `StatefulWidget` for local state (forms, animations)
- `PopScope` for back button handling
- Mounted checks before `setState()`

**Example**:
```dart
class HomeScreen extends ConsumerStatefulWidget {
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider);
    // UI code
  }
}
```

---

### 2. State Management Layer (Riverpod)

**Responsibility**: Managing application state and data flow

**Key Providers**:

#### SubjectProvider
```dart
final subjectProvider = StateNotifierProvider<SubjectNotifier, List<Subject>>(
  (ref) => SubjectNotifier(),
);
```
- Manages all subjects
- CRUD operations with auto-sync
- Performance tracking updates

#### QuizProvider
```dart
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>(
  (ref) => QuizNotifier(),
);
```
- Quiz session management
- Question navigation
- Answer checking and scoring

#### MCQProvider
```dart
final mcqQuizProvider = StateNotifierProvider<MCQQuizNotifier, MCQQuizState>(
  (ref) => MCQQuizNotifier(),
);
```
- AI-generated MCQ management
- Loading states
- Error handling

#### CourseProvider
```dart
final courseProvider = StateNotifierProvider<CourseNotifier, List<Course>>(
  (ref) => CourseNotifier(),
);
```
- Course autocomplete data
- Search functionality
- Category filtering

**State Pattern**:
```dart
class QuizState {
  final List<Question> questions;
  final int currentQuestionIndex;
  final int score;
  final bool isLoading;
  final String? error;
  final Subject? currentSubject;
}
```

---

### 3. Business Logic Layer (Services)

**Responsibility**: Core business operations and external integrations

#### Authentication Service (`auth_service.dart`)
```dart
class AuthService {
  Future<AuthResponse> signUp(String email, String password);
  Future<AuthResponse> signIn(String email, String password);
  Future<void> signOut(); // Clears local data
  User? get currentUser;
  bool get isLoggedIn;
  String? get userId;
}
```

**Key Features**:
- Supabase Auth integration
- Session management
- Automatic data clearing on logout

---

#### Sync Service (`sync_service.dart`)
```dart
class SyncService {
  // Upload operations
  Future<void> uploadSubjects();
  Future<void> uploadQuestions();
  Future<void> uploadQuizSessions(); // Currently disabled
  
  // Download operations
  Future<void> downloadSubjects();
  Future<void> downloadQuestions();
  
  // Full sync
  Future<SyncResult> fullSync();
}
```

**Sync Strategy**:
1. Upload local changes to cloud
2. Download cloud changes to local
3. Conflict resolution: Cloud data takes precedence
4. Duplicate detection: STEM-based hash comparison

---

#### Background Sync Service (`background_sync_service.dart`)
```dart
class BackgroundSyncService {
  void startBackgroundSync(); // Every 5 minutes
  void stopBackgroundSync();
  Future<void> syncNow();
  DateTime? get lastSyncTime;
  bool get isSyncing;
}
```

**Sync Triggers**:
- App launch (if logged in)
- User login
- Data changes (subjects, questions)
- Periodic timer (5 minutes)

---

#### AI Service (`openai_service.dart`)
```dart
class OpenAIService {
  Future<MCQ> generateMCQ({
    required String subject,
    required int subjectId,
    String difficulty = 'medium',
    int choices = 4,
  });
  
  Future<List<MCQ>> generateMultipleMCQs({
    required String subject,
    required int subjectId,
    int count = 5,
  });
}
```

**Features**:
- GPT-4 integration
- Novelty enforcement (STEM hashing)
- Retry logic with exponential backoff
- Educational disclaimers
- Fallback to local questions on failure

---

#### Notification Service (`notification_service.dart`)
```dart
class NotificationService {
  Future<void> initialize();
  Future<void> scheduleQuizNotifications();
  Future<void> cancelAllNotifications();
  Future<void> showQuizCompleteNotification();
}
```

**Features**:
- Local notifications
- Timezone-aware scheduling
- Configurable time slots
- Active days selection

---

#### Course Service (`course_service.dart`)
```dart
class CourseService {
  Future<void> loadDefaultCourses();
  Future<List<Course>> searchCourses(String query);
  Future<List<Course>> getCoursesByCategory(String category);
}
```

**Data Source**: `assets/courses.json`

---

### 4. Data Layer

#### Models

**Subject Model** (`models/subject.dart`)
```dart
class Subject {
  final int? id;
  final String name;
  final String description;
  final String color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int totalQuestions;
  final int correctAnswers;
  final double difficultyWeight; // 0.0 to 1.0
  
  Map<String, dynamic> toMap();
  factory Subject.fromMap(Map<String, dynamic> map);
  Map<String, dynamic> toSupabase();
  factory Subject.fromSupabase(Map<String, dynamic> map);
}
```

**Question Model** (`models/question.dart`)
```dart
class Question {
  final int? id;
  final int subjectId;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String difficulty;
  final DateTime createdAt;
  final bool isFromAI;
  final String? sourceUrl;
  final String? source;
  
  Map<String, dynamic> toMap();
  factory Question.fromMap(Map<String, dynamic> map);
}
```

**MCQ Model** (`models/mcq.dart`)
```dart
class MCQ {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String subject;
  final int subjectId;
  
  Question toQuestion();
}
```

**Quiz Session Model** (`models/quiz_session.dart`)
```dart
class QuizSession {
  final int? id;
  final int subjectId;
  final int questionId;
  final String userAnswer;
  final bool isCorrect;
  final DateTime answeredAt;
  final int timeSpentSeconds;
  final String difficulty;
}
```

**Course Model** (`models/course.dart`)
```dart
class Course {
  final int? id;
  final String courseId; // e.g., "AP-CALC-AB"
  final String subjectName;
  final String category;
  final String? description;
  final bool isCustom;
  final DateTime createdAt;
}
```

**Unit Model** (`models/unit.dart`)
```dart
class Unit {
  final int? id;
  final int subjectId;
  final String name;
  final String? description;
  final int orderIndex;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent;
  final DateTime createdAt;
}
```

---

#### Database (SQLite)

**DatabaseHelper** (`database/database_helper.dart`)

**Tables**:
1. **subjects**: Subject information and performance
2. **questions**: Question bank
3. **quiz_sessions**: Individual quiz attempts
4. **quiz_settings**: App settings
5. **courses**: Course autocomplete data
6. **units**: Subject organization

**Key Methods**:
```dart
// CRUD Operations
Future<int> insertSubject(Subject subject);
Future<List<Subject>> getAllSubjects();
Future<int> updateSubject(Subject subject);
Future<int> deleteSubject(int id);

// Performance Tracking
Future<void> updateSubjectPerformance(int subjectId, bool isCorrect);
Future<Map<String, dynamic>> getSubjectAnalytics(int subjectId);

// Data Clearing
Future<void> clearAllData(); // Called on logout
```

**Schema Version**: 9  
**Database File**: `formula_quizzer.db`

---

#### Cloud Database (Supabase)

**Schema** (`server/supabase_schema.sql`)

**Tables**:
1. **subjects**: User subjects (references `auth.users`)
2. **questions**: User questions
3. **quiz_sessions**: Quiz attempts
4. **quiz_answers**: Individual answers
5. **courses**: Shared course data
6. **units**: Subject units

**Row-Level Security (RLS)**:
```sql
CREATE POLICY "Users can view own subjects" ON subjects
  FOR SELECT USING (auth.uid()::text = user_id::text);
  
CREATE POLICY "Users can insert own subjects" ON subjects
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
```

**Indexes**:
- `idx_subjects_user_id`: Fast user subject lookup
- `idx_questions_subject_id`: Question filtering
- `idx_quiz_sessions_user_id`: User session history

---

## Data Flow Examples

### Creating a Subject with Auto-Sync

```
1. User enters subject details in UI
   ↓
2. SubjectProvider.addSubject() called
   ↓
3. DatabaseHelper.insertSubject() saves locally
   ↓
4. If user logged in: SyncService.uploadSubjects()
   ↓
5. Supabase insert with user_id
   ↓
6. UI updates via Riverpod state change
```

### Taking a Quiz

```
1. User selects "Quick Quiz" from home
   ↓
2. QuizProvider.startQuickQuiz() called
   ↓
3. Adaptive algorithm selects subject
   ↓
4. DatabaseHelper.getQuestionsBySubject()
   ↓
5. Questions shuffled and presented
   ↓
6. User answers → QuizProvider.submitAnswer()
   ↓
7. DatabaseHelper.insertQuizSession() logs attempt
   ↓
8. DatabaseHelper.updateSubjectPerformance() updates stats
   ↓
9. UI shows results and next question
```

### AI Question Generation

```
1. User taps subject in Quiz tab
   ↓
2. Navigate to MCQLoadingScreen
   ↓
3. addPostFrameCallback triggers generation
   ↓
4. MCQProvider.generateMCQ(subject)
   ↓
5. OpenAIService.generateMCQ() API call
   ↓
6. Novelty check via STEM hashing
   ↓
7. MCQ saved to database
   ↓
8. Navigate to MCQQuizScreen with question
```

### Login and Sync

```
1. User enters credentials in AuthScreen
   ↓
2. AuthService.signIn() authenticates
   ↓
3. Wait 500ms for auth completion
   ↓
4. SyncService.downloadSubjects() from cloud
   ↓
5. DatabaseHelper replaces local subjects
   ↓
6. SyncService.downloadQuestions()
   ↓
7. BackgroundSyncService.startBackgroundSync()
   ↓
8. Navigate to HomeScreen
   ↓
9. SubjectProvider loads subjects
```

### Logout and Data Clearing

```
1. User taps "Logout" in Settings
   ↓
2. Confirmation dialog shown
   ↓
3. BackgroundSyncService.stopBackgroundSync()
   ↓
4. AuthService.signOut() called
   ↓
5. DatabaseHelper.clearAllData() deletes:
   - All subjects
   - All questions
   - All quiz sessions
   - Quiz settings
   (Courses preserved as shared data)
   ↓
6. Supabase auth session cleared
   ↓
7. Navigate to AuthScreen
```

---

## Error Handling Strategy

### Provider Level
```dart
try {
  // Operation
} catch (e) {
  state = state.copyWith(
    error: e.toString(),
    isLoading: false,
  );
  rethrow;
}
```

### Service Level
```dart
try {
  final result = await operation();
  print('✅ Success: $result');
  return result;
} catch (e) {
  print('❌ Error: $e');
  rethrow;
}
```

### UI Level
```dart
if (quizState.error != null) {
  return ErrorView(error: quizState.error!);
}
```

---

## Performance Optimizations

1. **Lazy Loading**: Questions loaded per-subject, not all at once
2. **Indexed Database**: All foreign keys indexed
3. **Async Operations**: All DB operations non-blocking
4. **Cached Providers**: Riverpod caches provider data
5. **Background Sync**: Non-blocking, doesn't freeze UI
6. **Debouncing**: Search operations debounced
7. **Pagination**: Large lists paginated where needed

---

## Security Measures

1. **RLS Policies**: Users can only access their own data
2. **API Key Security**: Never hardcoded in version control
3. **Session Management**: Tokens automatically refreshed
4. **Data Isolation**: Complete separation between accounts
5. **Logout Clearing**: All local data removed on logout
6. **HTTPS Only**: All API calls over secure connections

---

## Testing Considerations

### Unit Tests
- Model serialization/deserialization
- Business logic in services
- State management logic

### Integration Tests
- Database CRUD operations
- Sync conflict resolution
- Authentication flow

### Widget Tests
- Screen rendering
- User interactions
- Navigation flows

### Manual Testing
- Cross-device sync
- Offline functionality
- API failure scenarios
- Account switching
