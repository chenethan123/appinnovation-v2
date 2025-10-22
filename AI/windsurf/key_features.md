# Key Features and Implementation Details

**FormulaQuizzer - Feature Documentation**

---

## 1. Cross-Device Synchronization

### Overview
Real-time data synchronization across multiple devices using Supabase as the cloud backend.

### Implementation

**Components**:
- `SyncService`: Handles upload/download operations
- `BackgroundSyncService`: Manages periodic syncing
- `AuthService`: Provides user authentication context

**Sync Flow**:
```
Login → Download cloud data → Replace local data
Data change → Upload to cloud (if logged in)
Every 5 minutes → Background sync
Logout → Clear local data
```

**Key Files**:
- `lib/services/sync_service.dart`
- `lib/services/background_sync_service.dart`
- `lib/services/auth_service.dart`

**Auto-Sync Triggers**:
```dart
// 1. On app launch (main.dart)
if (ApiConfig.enableSync && AuthService().isLoggedIn) {
  SyncService().fullSync();
  BackgroundSyncService().startBackgroundSync();
}

// 2. On data changes (subject_provider.dart)
Future<void> addSubject(Subject subject) async {
  await _db.insertSubject(subject);
  await _autoSync(); // Uploads to cloud
  await loadSubjects();
}

// 3. On login (auth_screen.dart)
await _syncService.downloadSubjects();
await _syncService.downloadQuestions();
BackgroundSyncService().startBackgroundSync();

// 4. Periodic background (background_sync_service.dart)
Timer.periodic(Duration(minutes: 5), (_) {
  _performSync();
});
```

**Account Isolation**:
```dart
// Each user's data is completely separate
// Logout clears ALL local data
Future<void> signOut() async {
  await DatabaseHelper().clearAllData(); // Delete subjects, questions, sessions
  await supabase.auth.signOut();
}

// Login downloads only the user's data
Future<void> downloadSubjects() async {
  final userId = _authService.userId;
  final response = await supabase
    .from('subjects')
    .select()
    .eq('user_id', userId); // RLS ensures only user's data
  
  // Replace local subjects with cloud data
  for (var subject in response) {
    await _db.insertSubject(Subject.fromSupabase(subject));
  }
}
```

**Conflict Resolution**:
- Cloud data takes precedence on download
- Duplicate detection using STEM hashing
- Last-write-wins strategy

---

## 2. AI Question Generation

### Overview
OpenAI GPT-4 integration for generating high-quality educational questions with novelty enforcement.

### Implementation

**Components**:
- `OpenAIService`: Direct API integration
- `MCQProvider`: State management for MCQ generation
- `StemHasher`: Question deduplication utility

**Generation Flow**:
```
User selects subject
    ↓
MCQLoadingScreen shown
    ↓
OpenAIService.generateMCQ() called
    ↓
GPT-4 generates question + options + explanation
    ↓
STEM hash computed for novelty check
    ↓
Question saved to database
    ↓
Navigate to MCQQuizScreen
```

**Key Files**:
- `lib/services/openai_service.dart`
- `lib/providers/mcq_provider.dart`
- `lib/utils/stem_hasher.dart`
- `lib/screens/mcq_loading_screen.dart`
- `lib/screens/mcq_quiz_screen.dart`

**Novelty Enforcement**:
```dart
// STEM Hashing (utils/stem_hasher.dart)
static String hashQuestion(String text) {
  // 1. Lowercase and clean text
  text = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
  
  // 2. Extract STEM words (important keywords)
  final words = text.split(' ').where((w) => w.length > 3).toSet();
  
  // 3. Sort and create hash
  final stemWords = words.toList()..sort();
  return stemWords.join('|');
}

// Novelty Check in OpenAI prompt
final systemPrompt = '''
You are an expert educational content creator.
Generate a question about $subject that is DIFFERENT from these recent questions:
${recentQuestions.map((q) => '- ${q.questionText}').join('\n')}

DO NOT generate questions similar to the above.
''';
```

**Retry Logic**:
```dart
int maxRetries = 3;
int attempt = 0;

while (attempt < maxRetries) {
  try {
    attempt++;
    final response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: {'Authorization': 'Bearer $apiKey'},
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      return parseMCQ(response);
    }
  } catch (e) {
    if (attempt >= maxRetries) rethrow;
    await Future.delayed(Duration(seconds: 2 * attempt)); // Exponential backoff
  }
}
```

**Educational Disclaimers**:
```dart
// All AI questions marked with disclaimer
final disclaimer = '''
⚠️ AI-Generated Question
This question was created by ChatGPT. While we strive for accuracy, 
please verify important information with official sources.
''';
```

---

## 3. Adaptive Learning Algorithm

### Overview
Intelligent subject selection that prioritizes weaker subjects based on performance.

### Implementation

**Difficulty Weight System**:
```dart
class Subject {
  double difficultyWeight; // 0.0 to 1.0
  // 0.0 = mastered (easy)
  // 1.0 = struggling (hard)
}

// Updated after each question
Future<void> updateSubjectPerformance(int subjectId, bool isCorrect) async {
  final subject = await getSubjectById(subjectId);
  
  // Weighted moving average
  const learningRate = 0.1;
  final newWeight = isCorrect
    ? subject.difficultyWeight * (1 - learningRate) // Decrease weight
    : subject.difficultyWeight + (1 - subject.difficultyWeight) * learningRate; // Increase weight
  
  await updateSubject(subject.copyWith(difficultyWeight: newWeight));
}
```

**Quick Quiz Algorithm**:
```dart
Future<void> startQuickQuiz() async {
  final subjects = await _db.getAllSubjects()
    .where((s) => s.isActive && s.totalQuestions > 0);
  
  if (subjects.isEmpty) {
    state = state.copyWith(error: 'No subjects available');
    return;
  }
  
  // Weighted random selection
  final totalWeight = subjects.fold<double>(
    0, (sum, s) => sum + s.difficultyWeight
  );
  
  double random = Random().nextDouble() * totalWeight;
  Subject? selectedSubject;
  
  for (var subject in subjects) {
    random -= subject.difficultyWeight;
    if (random <= 0) {
      selectedSubject = subject;
      break;
    }
  }
  
  selectedSubject ??= subjects.first; // Fallback
  
  // Load questions for selected subject
  await startQuiz(selectedSubject.id!);
}
```

**Performance Tracking**:
```dart
class Subject {
  int totalQuestions; // Total attempts
  int correctAnswers; // Correct attempts
  
  double get accuracy => totalQuestions > 0 
    ? correctAnswers / totalQuestions 
    : 0.0;
}
```

---

## 4. Local Notifications

### Overview
Scheduled quiz reminders with configurable time slots and active days.

### Implementation

**Components**:
- `NotificationService`: Notification scheduling and management
- Settings screen for configuration

**Key Files**:
- `lib/services/notification_service.dart`
- `lib/screens/settings_screen.dart`

**Scheduling Logic**:
```dart
Future<void> scheduleQuizNotifications() async {
  final settings = await _db.getQuizSettings();
  
  if (!settings.notificationsEnabled) return;
  
  // Cancel existing notifications
  await cancelAllNotifications();
  
  // Schedule for each active day
  for (int day in settings.activeDays) {
    // Generate random time within configured hours
    final hour = settings.startHour + 
      Random().nextInt(settings.endHour - settings.startHour);
    final minute = Random().nextInt(60);
    
    await _notificationsPlugin.zonedSchedule(
      day, // Notification ID
      'Time for a Quiz! 📚',
      'Practice your subjects and improve your knowledge',
      _nextInstanceOfDayAndTime(day, hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'quiz_reminders',
          'Quiz Reminders',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }
}
```

**Settings Configuration**:
```dart
class QuizSettings {
  int maxDailyQuizzes; // e.g., 5
  int startHour;       // e.g., 9 AM
  int endHour;         // e.g., 6 PM
  List<int> activeDays; // e.g., [1,2,3,4,5] for weekdays
  bool notificationsEnabled;
}
```

---

## 5. Course and Unit Organization

### Overview
Hierarchical organization of subjects into courses and units for structured learning.

### Implementation

**Structure**:
```
Course (e.g., AP Calculus AB)
└── Subject (User's instance)
    └── Units (Chapters/Topics)
        └── Questions
```

**Course Data**:
```json
// assets/courses.json
{
  "courses": [
    {
      "courseId": "AP-CALC-AB",
      "subjectName": "AP Calculus AB",
      "category": "Mathematics",
      "description": "Differential and integral calculus"
    }
  ]
}
```

**Units Management**:
```dart
class Unit {
  int subjectId;
  String name;
  String? description;
  int orderIndex;
  DateTime? startDate;
  DateTime? endDate;
  bool isCurrent; // Current unit being studied
}

// Set current unit
Future<void> setCurrentUnit(int subjectId, int unitId) async {
  // Unset all current units for subject
  await db.update('units',
    {'is_current': 0},
    where: 'subject_id = ?',
    whereArgs: [subjectId],
  );
  
  // Set specified unit as current
  await db.update('units',
    {'is_current': 1},
    where: 'id = ?',
    whereArgs: [unitId],
  );
}
```

**Course Search**:
```dart
Future<List<Course>> searchCourses(String query) async {
  return await db.query('courses',
    where: 'course_id LIKE ? OR subject_name LIKE ?',
    whereArgs: ['%$query%', '%$query%'],
    orderBy: 'course_id ASC',
    limit: 50,
  );
}
```

---

## 6. Progress Tracking and Analytics

### Overview
Detailed performance analytics with visualizations and insights.

### Implementation

**Key Metrics**:
```dart
Future<Map<String, dynamic>> getSubjectAnalytics(int subjectId) async {
  final sessions = await getQuizSessionsBySubject(subjectId);
  
  return {
    'totalAttempts': sessions.length,
    'correctCount': sessions.where((s) => s.isCorrect).length,
    'accuracy': sessions.isEmpty ? 0.0 
      : sessions.where((s) => s.isCorrect).length / sessions.length,
    'averageTimeSeconds': sessions.isEmpty ? 0 
      : sessions.map((s) => s.timeSpentSeconds).reduce((a, b) => a + b) / sessions.length,
    'recentStreak': _calculateStreak(sessions),
    'lastAttempt': sessions.isEmpty ? null : sessions.last.answeredAt,
  };
}
```

**Visualizations**:
```dart
// Using fl_chart package
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: accuracyOverTime.map((point) => 
          FlSpot(point.x, point.y)
        ).toList(),
        isCurved: true,
        color: Colors.blue,
      ),
    ],
  ),
);
```

**Performance Insights**:
```dart
// Subject performance comparison
final subjects = await getAllSubjects();
subjects.sort((a, b) => b.accuracy.compareTo(a.accuracy));

final strongest = subjects.first; // Highest accuracy
final weakest = subjects.last;   // Lowest accuracy

// Recent trends
final recentSessions = await getRecentSessions(days: 7);
final improvement = _calculateTrend(recentSessions);
```

---

## 7. Offline-First Architecture

### Overview
App fully functional without internet connection, with optional cloud sync.

### Implementation

**Local Database Priority**:
```dart
// All operations go to local database first
Future<void> addSubject(Subject subject) async {
  // 1. Save locally (always works)
  await _db.insertSubject(subject);
  
  // 2. Sync to cloud (optional, may fail)
  try {
    if (ApiConfig.enableSync && _authService.isLoggedIn) {
      await _syncService.uploadSubjects();
    }
  } catch (e) {
    print('⚠️ Sync failed but data saved locally: $e');
    // Continue - local data is safe
  }
  
  // 3. Update UI
  await loadSubjects();
}
```

**Graceful Degradation**:
```dart
// AI question generation with fallback
Future<void> generateMCQ(String subject) async {
  try {
    // Try AI generation
    final mcq = await _openAI.generateMCQ(subject: subject);
    state = MCQQuizState(currentMCQ: mcq);
  } catch (e) {
    // Fallback to local questions
    final localQuestions = await _db.getQuestionsBySubject(subjectId);
    if (localQuestions.isNotEmpty) {
      final question = localQuestions[Random().nextInt(localQuestions.length)];
      state = MCQQuizState(currentMCQ: MCQ.fromQuestion(question));
    } else {
      state = MCQQuizState(error: 'Unable to generate question');
    }
  }
}
```

**Sync Status Indicators**:
```dart
// Show sync status in UI
Widget _buildSyncStatus() {
  final lastSync = BackgroundSyncService().lastSyncTime;
  final isSyncing = BackgroundSyncService().isSyncing;
  
  if (isSyncing) {
    return Text('Syncing...', style: TextStyle(color: Colors.blue));
  } else if (lastSync == null) {
    return Text('Never synced', style: TextStyle(color: Colors.grey));
  } else {
    final timeSince = DateTime.now().difference(lastSync);
    return Text('Synced ${_formatTimeSince(timeSince)} ago');
  }
}
```

---

## 8. Question Management System

### Overview
Comprehensive question CRUD with import, export, and organization features.

### Implementation

**Question CRUD**:
```dart
// Create
Future<int> insertQuestion(Question question) async {
  return await db.insert('questions', question.toMap());
}

// Read
Future<List<Question>> getQuestionsBySubject(int subjectId) async {
  final maps = await db.query('questions',
    where: 'subject_id = ?',
    whereArgs: [subjectId],
  );
  return maps.map((m) => Question.fromMap(m)).toList();
}

// Update
Future<int> updateQuestion(Question question) async {
  return await db.update('questions', question.toMap(),
    where: 'id = ?',
    whereArgs: [question.id],
  );
}

// Delete
Future<int> deleteQuestion(int id) async {
  return await db.delete('questions',
    where: 'id = ?',
    whereArgs: [id],
  );
}
```

**Bulk Operations**:
```dart
Future<void> importQuestionsFromJSON(String json) async {
  final data = jsonDecode(json) as List;
  
  for (var item in data) {
    final question = Question(
      subjectId: item['subject_id'],
      questionText: item['question'],
      options: List<String>.from(item['options']),
      correctAnswer: item['correct_answer'],
      explanation: item['explanation'],
      difficulty: item['difficulty'] ?? 'medium',
    );
    
    await insertQuestion(question);
  }
}
```

---

## 9. User Authentication

### Overview
Secure authentication with Supabase Auth supporting email/password login.

### Implementation

**Auth Flow**:
```dart
// Sign Up
Future<AuthResponse> signUp(String email, String password) async {
  final response = await supabase.auth.signUp(
    email: email,
    password: password,
  );
  
  if (response.user != null) {
    // Upload existing local data to cloud
    await _syncService.uploadSubjects();
    await _syncService.uploadQuestions();
  }
  
  return response;
}

// Sign In
Future<AuthResponse> signIn(String email, String password) async {
  final response = await supabase.auth.signInWithPassword(
    email: email,
    password: password,
  );
  
  if (response.user != null) {
    // Download user's cloud data
    await _syncService.downloadSubjects();
    await _syncService.downloadQuestions();
  }
  
  return response;
}

// Sign Out
Future<void> signOut() async {
  // Clear local data for security
  await DatabaseHelper().clearAllData();
  await supabase.auth.signOut();
}
```

**Session Management**:
```dart
bool get hasValidSession {
  final session = supabase.auth.currentSession;
  if (session == null) return false;
  
  final expiresAt = session.expiresAt;
  if (expiresAt == null) return false;
  
  return DateTime.now().isBefore(
    DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
  );
}
```

---

## 10. Theme and UI Customization

### Overview
Material 3 theming with subject-specific color coding.

### Implementation

**Theme Configuration**:
```dart
ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.indigo,
    brightness: Brightness.light,
  ),
  cardTheme: CardTheme(
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
)
```

**Subject Colors**:
```dart
final subjectColors = [
  '#6366f1', // Indigo
  '#ec4899', // Pink
  '#8b5cf6', // Purple
  '#10b981', // Green
  '#f59e0b', // Amber
  '#ef4444', // Red
  '#3b82f6', // Blue
  '#06b6d4', // Cyan
];

// Color selection
Color getSubjectColor(String colorHex) {
  return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
}
```

**Responsive Design**:
```dart
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isMobile = screenWidth < 600;
  final isTablet = screenWidth >= 600 && screenWidth < 1200;
  
  return GridView.count(
    crossAxisCount: isMobile ? 1 : isTablet ? 2 : 3,
    children: subjects.map((s) => SubjectCard(subject: s)).toList(),
  );
}
```
