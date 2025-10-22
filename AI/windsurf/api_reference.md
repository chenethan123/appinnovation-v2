# API Reference

**FormulaQuizzer - Complete API Documentation**

---

## Database API (DatabaseHelper)

### Subject Operations

```dart
// Insert new subject
Future<int> insertSubject(Subject subject)
// Returns: subject ID

// Get all subjects
Future<List<Subject>> getAllSubjects()
// Returns: List of all subjects

// Get active subjects only
Future<List<Subject>> getActiveSubjects()
// Returns: List where isActive = true

// Get subject by ID
Future<Subject?> getSubjectById(int id)
// Returns: Subject or null if not found

// Update existing subject
Future<int> updateSubject(Subject subject)
// Returns: number of rows affected (1 if successful)

// Delete subject (cascade deletes questions)
Future<int> deleteSubject(int id)
// Returns: number of rows affected

// Toggle active status
Future<void> toggleSubjectActive(int id)
// Side effects: Updates isActive field

// Update performance after quiz
Future<void> updateSubjectPerformance(int subjectId, bool isCorrect)
// Side effects: Updates totalQuestions, correctAnswers, difficultyWeight

// Get subject analytics
Future<Map<String, dynamic>> getSubjectAnalytics(int subjectId)
// Returns: {totalAttempts, correctCount, accuracy, averageTimeSeconds, etc.}
```

### Question Operations

```dart
// Insert new question
Future<int> insertQuestion(Question question)
// Returns: question ID

// Get questions by subject
Future<List<Question>> getQuestionsBySubject(int subjectId)
// Returns: All questions for subject

// Get questions by difficulty
Future<List<Question>> getQuestionsByDifficulty(int subjectId, String difficulty)
// difficulty: 'easy', 'medium', 'hard'

// Get AI-generated questions only
Future<List<Question>> getAIQuestions(int subjectId)
// Returns: Questions where isFromAI = true

// Get random questions
Future<List<Question>> getRandomQuestions(int subjectId, int count)
// Returns: Shuffled list of up to 'count' questions

// Update question
Future<int> updateQuestion(Question question)
// Returns: number of rows affected

// Delete question
Future<int> deleteQuestion(int id)
// Returns: number of rows affected

// Check for duplicate question (STEM hash)
Future<bool> isDuplicateQuestion(String questionText, int subjectId)
// Returns: true if similar question exists
```

### Quiz Session Operations

```dart
// Insert quiz session (answer attempt)
Future<int> insertQuizSession(QuizSession session)
// Returns: session ID

// Get sessions by subject
Future<List<QuizSession>> getQuizSessionsBySubject(int subjectId)
// Returns: All quiz attempts for subject

// Get recent sessions
Future<List<QuizSession>> getRecentSessions({int days = 7})
// Returns: Sessions from last N days

// Get sessions by date range
Future<List<QuizSession>> getQuizSessionsByDateRange(
  DateTime startDate,
  DateTime endDate,
)
// Returns: Sessions within date range

// Delete old sessions (cleanup)
Future<void> deleteOldSessions({int daysToKeep = 30})
// Side effects: Deletes sessions older than N days
```

### Course Operations

```dart
// Insert course
Future<int> insertCourse(Course course)
// Returns: course ID

// Get all courses
Future<List<Course>> getAllCourses()
// Returns: All courses ordered by courseId

// Search courses
Future<List<Course>> searchCourses(String query)
// Returns: Courses matching query (courseId or subjectName)
// Limit: 50 results

// Get courses by category
Future<List<Course>> getCoursesByCategory(String category)
// Returns: Courses in specific category

// Get course by ID
Future<Course?> getCourseById(String courseId)
// Returns: Course or null
```

### Unit Operations

```dart
// Insert unit
Future<int> insertUnit(Unit unit)
// Returns: unit ID

// Get units by subject
Future<List<Unit>> getUnitsBySubject(int subjectId)
// Returns: Units ordered by orderIndex

// Get current unit
Future<Unit?> getCurrentUnit(int subjectId)
// Returns: Unit where isCurrent = true

// Get active units (date-based)
Future<List<Unit>> getActiveUnits(int subjectId)
// Returns: Units within date range or marked current

// Update unit
Future<int> updateUnit(Unit unit)
// Returns: number of rows affected

// Delete unit
Future<int> deleteUnit(int id)
// Returns: number of rows affected

// Set current unit
Future<void> setCurrentUnit(int subjectId, int unitId)
// Side effects: Unsets other units, sets specified as current
```

### Settings Operations

```dart
// Get quiz settings
Future<QuizSettings> getQuizSettings()
// Returns: Current settings or defaults

// Update quiz settings
Future<void> updateQuizSettings(QuizSettings settings)
// Side effects: Updates settings in database

// Get notification enabled status
Future<bool> getNotificationsEnabled()
// Returns: true if notifications enabled
```

### Utility Operations

```dart
// Clear all user data (logout)
Future<void> clearAllData()
// Side effects: Deletes all subjects, questions, quiz_sessions, units
// Note: Preserves courses (shared data)

// Close database connection
Future<void> close()
// Side effects: Closes SQLite connection
```

---

## Sync Service API

### Upload Operations

```dart
// Upload all subjects to cloud
Future<void> uploadSubjects()
// Requires: User logged in
// Side effects: Upserts subjects to Supabase
// Throws: PostgrestException on error

// Upload all questions to cloud
Future<void> uploadQuestions()
// Requires: User logged in
// Side effects: Upserts questions to Supabase
// Throws: PostgrestException on error

// Upload quiz sessions (currently disabled)
Future<void> uploadQuizSessions()
// Status: Disabled due to UUID/integer mismatch
// Returns immediately with skip message
```

### Download Operations

```dart
// Download subjects from cloud
Future<void> downloadSubjects()
// Requires: User logged in
// Side effects: Replaces local subjects with cloud data
// Throws: PostgrestException on error

// Download questions from cloud
Future<void> downloadQuestions()
// Requires: User logged in
// Side effects: Replaces local questions with cloud data
// Note: Checks for duplicates using STEM hash
// Throws: PostgrestException on error
```

### Full Sync

```dart
// Bi-directional sync (upload + download)
Future<SyncResult> fullSync()
// Returns: SyncResult {
//   bool success,
//   String message,
//   int subjectsCount,
//   int questionsCount,
// }
// Process: Upload local changes → Download cloud changes
// Throws: Exception on error
```

---

## Auth Service API

```dart
// Sign up new user
Future<AuthResponse> signUp(String email, String password)
// Returns: AuthResponse with user data
// Throws: AuthApiException on error

// Sign in existing user
Future<AuthResponse> signIn(String email, String password)
// Returns: AuthResponse with user data
// Throws: AuthApiException on error

// Sign out current user
Future<void> signOut()
// Side effects: Clears local data, signs out from Supabase
// Throws: Exception on error

// Get current user
User? get currentUser
// Returns: Current user or null

// Check if logged in
bool get isLoggedIn
// Returns: true if user session exists

// Get user ID
String? get userId
// Returns: User UUID or null

// Get user email
String? get userEmail
// Returns: User email or null

// Get auth state changes stream
Stream<AuthState> get authStateChanges
// Returns: Stream of auth state changes

// Send password reset email
Future<void> resetPassword(String email)
// Side effects: Sends reset email
// Throws: Exception on error

// Update password
Future<UserResponse> updatePassword(String newPassword)
// Requires: User logged in
// Throws: Exception on error

// Check if session is valid
bool get hasValidSession
// Returns: true if session not expired

// Get access token
String? get accessToken
// Returns: JWT access token or null
```

---

## Background Sync Service API

```dart
// Start background sync timer (5 minute intervals)
void startBackgroundSync()
// Side effects: Starts periodic timer

// Stop background sync timer
void stopBackgroundSync()
// Side effects: Cancels timer

// Force immediate sync
Future<void> syncNow()
// Requires: User logged in
// Side effects: Performs full sync immediately

// Get last sync time
DateTime? get lastSyncTime
// Returns: Timestamp of last successful sync

// Check if currently syncing
bool get isSyncing
// Returns: true if sync in progress

// Get time since last sync
Duration? getTimeSinceLastSync()
// Returns: Duration since last sync or null

// Get status message
String getStatusMessage()
// Returns: Human-readable sync status
// Examples: "Syncing...", "Synced 5m ago", "Never synced"
```

---

## OpenAI Service API

```dart
// Generate single MCQ
Future<MCQ> generateMCQ({
  required String subject,
  required int subjectId,
  String difficulty = 'medium',
  int choices = 4,
})
// Returns: MCQ with question, options, answer, explanation
// Throws: Exception on API error or network failure
// Note: Includes novelty enforcement

// Generate multiple MCQs
Future<List<MCQ>> generateMultipleMCQs({
  required String subject,
  required int subjectId,
  int count = 5,
  String difficulty = 'medium',
})
// Returns: List of MCQs
// Throws: Exception on API error
// Note: Sequential generation with progress logging
```

---

## Notification Service API

```dart
// Initialize notification service
Future<void> initialize()
// Side effects: Sets up notification channels
// Throws: Exception on initialization error

// Schedule quiz notifications
Future<void> scheduleQuizNotifications()
// Side effects: Schedules notifications based on settings
// Requires: Notifications enabled in settings

// Cancel all notifications
Future<void> cancelAllNotifications()
// Side effects: Clears all pending notifications

// Show quiz complete notification
Future<void> showQuizCompleteNotification({
  required int score,
  required int total,
  required String subjectName,
})
// Side effects: Shows immediate notification
```

---

## Course Service API

```dart
// Load default courses from JSON
Future<void> loadDefaultCourses()
// Side effects: Inserts courses from assets/courses.json
// Note: Only loads if database is empty

// Search courses
Future<List<Course>> searchCourses(String query)
// Returns: Courses matching search query

// Get courses by category
Future<List<Course>> getCoursesByCategory(String category)
// Returns: Courses in specified category
```

---

## Providers (Riverpod State Management)

### SubjectProvider

```dart
// Load all subjects
Future<void> loadSubjects()
// Side effects: Updates state with subjects from database

// Add new subject
Future<void> addSubject(Subject subject)
// Side effects: Inserts to DB, syncs to cloud, reloads state

// Update existing subject
Future<void> updateSubject(Subject subject)
// Side effects: Updates DB, syncs to cloud, reloads state

// Delete subject
Future<void> deleteSubject(int id)
// Side effects: Deletes from DB, syncs to cloud, reloads state

// Toggle subject active status
Future<void> toggleSubjectActive(int id)
// Side effects: Updates DB, syncs to cloud, reloads state

// State access
List<Subject> get state
// Returns: Current list of subjects
```

### QuizProvider

```dart
// Start quiz for specific subject
Future<void> startQuiz(int subjectId)
// Side effects: Loads questions, sets up quiz state

// Start quick quiz (adaptive selection)
Future<void> startQuickQuiz()
// Side effects: Selects subject based on difficulty weights

// Submit answer
void submitAnswer(String answer)
// Side effects: Records session, updates performance, moves to next

// Next question
Future<void> nextQuestion()
// Side effects: Advances to next question or shows results

// Reset quiz
void resetQuiz()
// Side effects: Clears quiz state

// Clear error
void clearError()
// Side effects: Clears error message

// State access
QuizState get state
// Returns: Current quiz state
```

### MCQProvider

```dart
// Generate new MCQ
Future<void> generateMCQ(String subjectName)
// Side effects: Calls OpenAI, saves to DB, updates state

// Submit answer
void submitAnswer(String answer)
// Side effects: Marks answer, shows explanation

// Reset MCQ
void resetMCQ()
// Side effects: Clears current MCQ state

// State access
MCQQuizState get state
// Returns: Current MCQ state
```

### CourseProvider

```dart
// Load all courses
Future<void> loadCourses()
// Side effects: Loads courses from database

// Search courses
Future<void> searchCourses(String query)
// Side effects: Filters courses by query

// Filter by category
Future<void> filterByCategory(String category)
// Side effects: Filters courses by category

// State access
List<Course> get state
// Returns: Current list of courses
```

---

## Error Handling

### Common Exceptions

```dart
// Database errors
SqliteException
  // Causes: Schema mismatch, constraint violation, disk full
  // Handling: Log error, show user-friendly message

// Network errors
SocketException
  // Causes: No internet connection, server unreachable
  // Handling: Fallback to local data, retry later

// Supabase errors
PostgrestException
  // Causes: Invalid query, RLS policy violation, server error
  // Handling: Log details, continue with local data

AuthApiException
  // Causes: Invalid credentials, email already exists
  // Handling: Show specific error message to user

// OpenAI errors
HttpException
  // Causes: API key invalid, rate limit, service unavailable
  // Handling: Retry with backoff, fallback to local questions
```

### Error Response Format

```dart
// Service methods throw exceptions
try {
  await syncService.uploadSubjects();
} catch (e) {
  if (e is PostgrestException) {
    print('Sync error: ${e.message}');
    // Handle gracefully - data safe locally
  }
}

// Providers capture errors in state
state = state.copyWith(
  error: e.toString(),
  isLoading: false,
);

// UI displays error messages
if (state.error != null) {
  return ErrorView(message: state.error!);
}
```

---

## Response Types

```dart
// Sync result
class SyncResult {
  final bool success;
  final String message;
  final int subjectsCount;
  final int questionsCount;
}

// Auth response (from Supabase)
class AuthResponse {
  final User? user;
  final Session? session;
}

// User (from Supabase)
class User {
  final String id;
  final String? email;
  final Map<String, dynamic> userMetadata;
}

// MCQ response
class MCQ {
  final String question;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String subject;
  final int subjectId;
}
```
