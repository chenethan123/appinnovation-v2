# Common Development Tasks

**FormulaQuizzer - Developer Workflows and Recipes**

---

## Setup Tasks

### Initial Project Setup

```bash
# 1. Clone repository
git clone https://github.com/chenethan123/appinnovation-v2.git
cd appinnovation-v2
git checkout workingServer

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure API keys
# Edit lib/config/api_config.dart
# Add your OpenAI API key and Supabase credentials

# 4. Run the app
flutter run -d macos  # or your preferred device
```

### Setting Up Supabase

```sql
-- 1. Go to https://supabase.com/dashboard
-- 2. Create new project
-- 3. Get URL and anon key from Settings → API
-- 4. Go to SQL Editor
-- 5. Run server/supabase_schema.sql

-- Drop existing tables if needed
DROP TABLE IF EXISTS quiz_answers CASCADE;
DROP TABLE IF EXISTS quiz_sessions CASCADE;
DROP TABLE IF EXISTS questions CASCADE;
DROP TABLE IF EXISTS units CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;

-- Then run the full schema from supabase_schema.sql
```

### Disabling Email Confirmation

```
1. Go to Supabase Dashboard → Authentication → Providers
2. Find "Email" provider
3. Uncheck "Confirm email"
4. Click Save
```

---

## Adding a New Feature

### Adding a New Screen

```dart
// 1. Create screen file
// lib/screens/my_new_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyNewScreen extends ConsumerStatefulWidget {
  const MyNewScreen({super.key});

  @override
  ConsumerState<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends ConsumerState<MyNewScreen> {
  @override
  void initState() {
    super.initState();
    // Load data after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myProvider.notifier).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProvider);
    
    return Scaffold(
      appBar: AppBar(title: const Text('My Feature')),
      body: state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : _buildContent(state),
    );
  }
  
  Widget _buildContent(MyState state) {
    // Build UI
  }
}

// 2. Add navigation
// In existing screen:
Navigator.of(context).push(
  MaterialPageRoute(builder: (context) => const MyNewScreen()),
);

// 3. Add to bottom navigation (if needed)
// In lib/main.dart or home_screen.dart:
final List<Widget> _screens = [
  const HomeScreen(),
  const SubjectsScreen(),
  const QuizScreen(),
  const ProgressScreen(),
  const MyNewScreen(), // Add here
  const SettingsScreen(),
];
```

### Adding a New Model

```dart
// 1. Create model file
// lib/models/my_model.dart

class MyModel {
  final int? id;
  final String name;
  final DateTime createdAt;
  
  MyModel({
    this.id,
    required this.name,
    required this.createdAt,
  });
  
  // SQLite serialization
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  factory MyModel.fromMap(Map<String, dynamic> map) {
    return MyModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
  
  // Supabase serialization (if syncing)
  Map<String, dynamic> toSupabase() {
    return {
      'user_id': userId, // Add user context
      'name': name,
      'created_at': createdAt.toIso8601String(),
    };
  }
  
  factory MyModel.fromSupabase(Map<String, dynamic> map) {
    return MyModel(
      id: null, // Local ID assigned by SQLite
      name: map['name'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
  
  // CopyWith for immutability
  MyModel copyWith({String? name, DateTime? createdAt}) {
    return MyModel(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// 2. Add to database schema
// In lib/database/database_helper.dart → _onCreate():

await db.execute('''
  CREATE TABLE my_models (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    created_at TEXT NOT NULL
  )
''');

// 3. Add CRUD operations to DatabaseHelper
Future<int> insertMyModel(MyModel model) async {
  final db = await database;
  return await db.insert('my_models', model.toMap());
}

Future<List<MyModel>> getAllMyModels() async {
  final db = await database;
  final maps = await db.query('my_models');
  return maps.map((m) => MyModel.fromMap(m)).toList();
}

// 4. Increment database version
static const int _version = 10; // Increment from 9 to 10

// 5. Add migration in _onUpgrade()
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 10) {
    await db.execute('''
      CREATE TABLE my_models (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }
}
```

### Adding a New Provider

```dart
// 1. Create provider file
// lib/providers/my_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_helper.dart';
import '../models/my_model.dart';

// State class
class MyState {
  final List<MyModel> items;
  final bool isLoading;
  final String? error;
  
  MyState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });
  
  MyState copyWith({
    List<MyModel>? items,
    bool? isLoading,
    String? error,
  }) {
    return MyState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Notifier
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(MyState());
  
  final DatabaseHelper _db = DatabaseHelper();
  
  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final items = await _db.getAllMyModels();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }
  
  Future<void> addItem(MyModel item) async {
    try {
      await _db.insertMyModel(item);
      await loadItems(); // Reload
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// Provider declaration
final myProvider = StateNotifierProvider<MyNotifier, MyState>(
  (ref) => MyNotifier(),
);

// 2. Use in widget
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myState = ref.watch(myProvider);
    
    if (myState.isLoading) {
      return const CircularProgressIndicator();
    }
    
    return ListView.builder(
      itemCount: myState.items.length,
      itemBuilder: (context, index) {
        final item = myState.items[index];
        return ListTile(title: Text(item.name));
      },
    );
  }
}
```

---

## Data Management Tasks

### Migrating Database Schema

```dart
// When you need to change database structure

// 1. Update table in _onCreate() for new installs
await db.execute('''
  CREATE TABLE subjects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    new_column TEXT  -- Add new column
  )
''');

// 2. Increment version number
static const int _version = 10; // Was 9

// 3. Add migration in _onUpgrade()
Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 10) {
    // Add new column to existing table
    await db.execute('ALTER TABLE subjects ADD COLUMN new_column TEXT');
  }
}

// 4. Test migration
// - Uninstall app
// - Reinstall with old version
// - Upgrade to new version
// - Verify data intact
```

### Adding Supabase Sync for New Table

```sql
-- 1. Add table to Supabase schema
CREATE TABLE IF NOT EXISTS my_models (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_my_models_user_id ON my_models(user_id);

-- 2. Add RLS policies
ALTER TABLE my_models ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own my_models" ON my_models
  FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own my_models" ON my_models
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);
```

```dart
// 3. Add sync methods to SyncService

Future<void> uploadMyModels() async {
  if (!_authService.isLoggedIn) return;
  
  final models = await _db.getAllMyModels();
  print('📤 Uploading ${models.length} models...');
  
  for (var model in models) {
    await supabase.from('my_models').upsert({
      'user_id': _authService.userId,
      ...model.toSupabase(),
    });
  }
  
  print('✅ Models uploaded');
}

Future<void> downloadMyModels() async {
  if (!_authService.isLoggedIn) return;
  
  final response = await supabase
    .from('my_models')
    .select()
    .eq('user_id', _authService.userId!);
  
  print('📥 Downloading ${response.length} models...');
  
  for (var data in response) {
    final model = MyModel.fromSupabase(data);
    await _db.insertMyModel(model);
  }
  
  print('✅ Models downloaded');
}

// 4. Add to fullSync()
Future<SyncResult> fullSync() async {
  try {
    await uploadSubjects();
    await uploadQuestions();
    await uploadMyModels(); // Add here
    
    await downloadSubjects();
    await downloadQuestions();
    await downloadMyModels(); // Add here
    
    return SyncResult(success: true, message: 'Synced successfully');
  } catch (e) {
    return SyncResult(success: false, message: e.toString());
  }
}
```

### Clearing Test Data

```dart
// During development, clear all data

// Option 1: Through Settings UI
// Settings → Clear All Data (if implemented)

// Option 2: Programmatically
await DatabaseHelper().clearAllData();

// Option 3: Delete database file
final dbPath = await getDatabasesPath();
final path = join(dbPath, 'formula_quizzer.db');
await deleteDatabase(path);

// Option 4: Fresh install
// Uninstall app completely and reinstall
```

---

## Testing Tasks

### Testing Sync

```dart
// Test account isolation

// 1. Create Account A
AuthService().signUp('usera@test.com', 'password');

// 2. Add subjects for Account A
SubjectProvider().addSubject(Subject(name: 'Math A'));
SubjectProvider().addSubject(Subject(name: 'Science A'));

// 3. Verify upload
// Check Supabase dashboard → subjects table

// 4. Logout
AuthService().signOut();

// 5. Verify local data cleared
final subjects = await DatabaseHelper().getAllSubjects();
assert(subjects.isEmpty);

// 6. Create Account B
AuthService().signUp('userb@test.com', 'password');

// 7. Verify Account B has no data
final subjectsB = await DatabaseHelper().getAllSubjects();
assert(subjectsB.isEmpty);

// 8. Add subjects for Account B
SubjectProvider().addSubject(Subject(name: 'Math B'));

// 9. Login back to Account A
AuthService().signOut();
AuthService().signIn('usera@test.com', 'password');

// 10. Verify Account A data restored
final subjectsA = await DatabaseHelper().getAllSubjects();
assert(subjectsA.any((s) => s.name == 'Math A'));
assert(!subjectsA.any((s) => s.name == 'Math B'));
```

### Testing AI Generation

```dart
// Test OpenAI integration

// 1. Verify API key configured
assert(ApiConfig.openaiApiKey.isNotEmpty);

// 2. Generate test question
final mcq = await OpenAIService().generateMCQ(
  subject: 'Calculus',
  subjectId: 1,
  difficulty: 'medium',
);

// 3. Verify response structure
assert(mcq.question.isNotEmpty);
assert(mcq.options.length == 4);
assert(mcq.options.contains(mcq.correctAnswer));
assert(mcq.explanation.isNotEmpty);

// 4. Test novelty enforcement
final mcq2 = await OpenAIService().generateMCQ(
  subject: 'Calculus',
  subjectId: 1,
);

// Questions should be different
assert(mcq.question != mcq2.question);

// 5. Test error handling
try {
  // Use invalid API key
  await OpenAIService().generateMCQ(subject: 'Test', subjectId: 1);
} catch (e) {
  // Should throw exception
  assert(e != null);
}
```

### Testing Offline Mode

```bash
# 1. Turn off WiFi/Airplane mode

# 2. Open app (should work)
flutter run

# 3. Create subject (should save locally)
# Verify in database

# 4. Try to generate AI question (should fail gracefully)
# Should show error or use fallback

# 5. Take quiz with existing questions (should work)

# 6. Turn WiFi back on

# 7. Sync should happen automatically
# Check background sync logs
```

---

## Debugging Tasks

### Viewing Database Contents

```bash
# Using sqflite_common_ffi (add to pubspec.yaml)
flutter pub add sqflite_common_ffi

# Create debug script
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  sqfliteFfiInit();
  
  final db = await databaseFactoryFfi.openDatabase('formula_quizzer.db');
  
  // Query subjects
  final subjects = await db.query('subjects');
  print('Subjects: $subjects');
  
  // Query questions
  final questions = await db.query('questions');
  print('Questions: $questions');
  
  await db.close();
}
```

### Debugging Sync Issues

```dart
// Add detailed logging to SyncService

Future<void> uploadSubjects() async {
  print('🔍 Starting subject upload');
  print('   User ID: ${_authService.userId}');
  print('   Logged in: ${_authService.isLoggedIn}');
  
  final subjects = await _db.getAllSubjects();
  print('   Local subjects: ${subjects.length}');
  
  for (var subject in subjects) {
    print('   Uploading: ${subject.name}');
    try {
      final data = subject.toSupabase();
      print('   Data: $data');
      
      await supabase.from('subjects').upsert(data);
      print('   ✅ Success');
    } catch (e) {
      print('   ❌ Error: $e');
      rethrow;
    }
  }
}
```

### Debugging Provider State

```dart
// Add logging to provider notifier

class SubjectNotifier extends StateNotifier<List<Subject>> {
  Future<void> loadSubjects() async {
    print('📊 Loading subjects');
    print('   Current state: ${state.length} subjects');
    
    final subjects = await _db.getAllSubjects();
    print('   Loaded from DB: ${subjects.length} subjects');
    
    state = subjects;
    print('   New state: ${state.length} subjects');
  }
}

// In widget, listen to changes
ref.listen<List<Subject>>(subjectProvider, (previous, next) {
  print('Provider changed: ${previous?.length} → ${next.length}');
});
```

---

## Performance Optimization Tasks

### Optimizing Database Queries

```dart
// Bad: Loading all data
final questions = await db.query('questions');

// Good: Add WHERE clause
final questions = await db.query('questions',
  where: 'subject_id = ?',
  whereArgs: [subjectId],
);

// Good: Add indexes
await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_questions_subject_id 
  ON questions(subject_id)
''');

// Good: Limit results
final recentSessions = await db.query('quiz_sessions',
  orderBy: 'answered_at DESC',
  limit: 100,
);
```

### Reducing API Calls

```dart
// Bad: Multiple calls in loop
for (var subject in subjects) {
  await uploadSubject(subject);
}

// Good: Batch upload
await supabase.from('subjects').upsert(
  subjects.map((s) => s.toSupabase()).toList(),
);
```

### Lazy Loading

```dart
// Load data only when needed

class SubjectsScreen extends ConsumerStatefulWidget {
  @override
  void initState() {
    super.initState();
    // Don't load in initState
  }
  
  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectProvider);
    
    // Load on first build
    if (subjects.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(subjectProvider.notifier).loadSubjects();
      });
    }
    
    // Build UI
  }
}
```

---

## Deployment Tasks

### Building for iOS

```bash
# 1. Update version in pubspec.yaml
version: 1.0.1+2

# 2. Build
flutter build ios --release

# 3. Open Xcode
open ios/Runner.xcworkspace

# 4. Archive and upload to App Store Connect
```

### Building for Android

```bash
# 1. Update version
version: 1.0.1+2

# 2. Build APK
flutter build apk --release

# 3. Build App Bundle
flutter build appbundle --release

# 4. Upload to Google Play Console
```

### Building for macOS

```bash
# 1. Build
flutter build macos --release

# 2. Create DMG
# Use create-dmg or similar tool

# 3. Sign and notarize
# Use Xcode signing
```
