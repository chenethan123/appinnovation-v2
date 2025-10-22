# Troubleshooting Guide

**FormulaQuizzer - Common Issues and Solutions**

---

## Build and Setup Issues

### Issue: Flutter command not found

```bash
# Symptoms
zsh: command not found: flutter

# Solution
# 1. Install Flutter from https://flutter.dev
# 2. Add to PATH in ~/.zshrc:
export PATH="$PATH:/path/to/flutter/bin"

# 3. Verify installation
flutter doctor
```

### Issue: Pod install fails on macOS/iOS

```bash
# Symptoms
Error: CocoaPods not installed

# Solution 1: Install CocoaPods
sudo gem install cocoapods

# Solution 2: Update pods
cd ios
pod install --repo-update
cd ..

# Solution 3: Clean and reinstall
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
```

### Issue: Build fails with "No such module"

```bash
# Symptoms
Error: No such module 'supabase_flutter'

# Solution
# 1. Clean project
flutter clean

# 2. Get dependencies
flutter pub get

# 3. For iOS/macOS
cd ios && pod install && cd ..

# 4. Rebuild
flutter run
```

---

## Database Issues

### Issue: Database schema mismatch

```dart
// Symptoms
SqliteException: no such table: subjects

// Solution: Increment version and add migration
static const int _version = 10; // Increment

Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
  if (oldVersion < 10) {
    // Add missing table or column
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');
  }
}

// Nuclear option: Delete database
final dbPath = await getDatabasesPath();
await deleteDatabase(join(dbPath, 'formula_quizzer.db'));
```

### Issue: Duplicate subjects after sync

```dart
// Symptoms
Same subject appears multiple times

// Solution: Clear local data before download
Future<void> downloadSubjects() async {
  // Clear existing subjects first
  await _db.database.then((db) => db.delete('subjects'));
  
  // Then download from cloud
  final response = await supabase.from('subjects').select();
  // ...
}
```

### Issue: Foreign key constraint violation

```sql
-- Symptoms
SqliteException: FOREIGN KEY constraint failed

-- Solution: Delete in correct order
-- 1. Delete quiz_sessions first (references questions)
DELETE FROM quiz_sessions WHERE question_id = ?;

-- 2. Then delete questions (references subjects)
DELETE FROM questions WHERE subject_id = ?;

-- 3. Finally delete subject
DELETE FROM subjects WHERE id = ?;

-- Or use CASCADE
CREATE TABLE questions (
  id INTEGER PRIMARY KEY,
  subject_id INTEGER REFERENCES subjects(id) ON DELETE CASCADE
);
```

---

## Sync Issues

### Issue: Data not syncing to cloud

```dart
// Symptoms
Subjects created but not appearing in Supabase

// Debugging steps:
// 1. Check if user is logged in
print('Logged in: ${AuthService().isLoggedIn}');
print('User ID: ${AuthService().userId}');

// 2. Check sync enabled
print('Sync enabled: ${ApiConfig.enableSync}');

// 3. Check for errors
try {
  await SyncService().uploadSubjects();
} catch (e) {
  print('Sync error: $e');
}

// 4. Check Supabase credentials
print('URL: ${ApiConfig.supabaseUrl}');
print('Key: ${ApiConfig.supabaseAnonKey.substring(0, 10)}...');

// Common fixes:
// - Verify API keys in api_config.dart
// - Check RLS policies in Supabase
// - Ensure user_id matches auth.uid()
```

### Issue: Row-Level Security blocking access

```sql
-- Symptoms
PostgrestException: new row violates row-level security policy

-- Solution: Check RLS policies
-- In Supabase SQL Editor:

-- View existing policies
SELECT * FROM pg_policies WHERE tablename = 'subjects';

-- Drop incorrect policy
DROP POLICY IF EXISTS "policy_name" ON subjects;

-- Create correct policy
CREATE POLICY "Users can insert own subjects" ON subjects
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- Verify policy works
-- Try inserting as authenticated user
```

### Issue: Wrong user's data appearing

```dart
// Symptoms
After login, seeing another user's subjects

// Solution: Ensure data cleared on logout
Future<void> signOut() async {
  // MUST clear local data first
  await DatabaseHelper().clearAllData();
  
  // Then sign out
  await supabase.auth.signOut();
}

// And ensure download filters by user_id
Future<void> downloadSubjects() async {
  final response = await supabase
    .from('subjects')
    .select()
    .eq('user_id', _authService.userId!); // CRITICAL
  
  // ...
}
```

---

## Authentication Issues

### Issue: Email not confirmed error

```
AuthApiException: Email not confirmed

// Solution: Disable email confirmation
// 1. Go to Supabase Dashboard
// 2. Authentication → Providers
// 3. Find Email provider
// 4. Uncheck "Confirm email"
// 5. Save

// Or implement email confirmation flow
```

### Issue: Invalid credentials on login

```dart
// Symptoms
AuthApiException: Invalid login credentials

// Debugging:
// 1. Verify email/password correct
// 2. Check if user exists in Supabase Dashboard
// 3. Try password reset

await AuthService().resetPassword('user@example.com');

// 4. Check for typos in email
final email = emailController.text.trim().toLowerCase();
```

### Issue: Session expired

```dart
// Symptoms
Sync fails with 401 Unauthorized

// Solution: Check session validity
if (!AuthService().hasValidSession) {
  // Session expired, re-authenticate
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (_) => AuthScreen()),
  );
}

// Or refresh session automatically
final session = await supabase.auth.refreshSession();
```

---

## AI Generation Issues

### Issue: OpenAI API key invalid

```dart
// Symptoms
HttpException: 401 Unauthorized

// Solution:
// 1. Verify API key in api_config.dart
// 2. Check key hasn't expired
// 3. Verify billing enabled at platform.openai.com
// 4. Test key with curl:

curl https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4","messages":[{"role":"user","content":"test"}]}'
```

### Issue: Rate limit exceeded

```dart
// Symptoms
HttpException: 429 Too Many Requests

// Solution: Implement exponential backoff
int attempt = 0;
int maxRetries = 5;

while (attempt < maxRetries) {
  try {
    return await _generateMCQ();
  } catch (e) {
    if (e.toString().contains('429')) {
      attempt++;
      final delay = Duration(seconds: pow(2, attempt).toInt());
      await Future.delayed(delay);
    } else {
      rethrow;
    }
  }
}

// Or upgrade OpenAI plan for higher limits
```

### Issue: AI generates duplicate questions

```dart
// Symptoms
Same or very similar questions generated repeatedly

// Solution: Improve novelty enforcement
// 1. Increase recent questions window
final recentQuestions = await _db.getQuestionsBySubject(
  subjectId,
  limit: 20, // Increase from 10
);

// 2. Make prompt more explicit
final systemPrompt = '''
CRITICAL: Generate a COMPLETELY DIFFERENT question.
Do NOT create variations of these topics:
${recentQuestions.map((q) => '- ${q.questionText}').join('\n')}

Requirements:
- Different concept/topic
- Different wording
- Different approach
''';

// 3. Verify with STEM hashing
final hash = StemHasher.hashQuestion(newQuestion);
final existingHashes = recentQuestions.map(
  (q) => StemHasher.hashQuestion(q.questionText)
).toSet();

if (existingHashes.contains(hash)) {
  // Regenerate
}
```

---

## UI and State Issues

### Issue: Provider modification during build

```dart
// Symptoms
Unhandled Exception: Tried to modify a provider while the widget tree was building

// Solution: Delay modifications
@override
void initState() {
  super.initState();
  // Don't call provider methods directly
  // Use addPostFrameCallback instead
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(myProvider.notifier).loadData();
  });
}

// Or use Future.microtask
@override
void initState() {
  super.initState();
  Future.microtask(() {
    ref.read(myProvider.notifier).loadData();
  });
}
```

### Issue: setState called after dispose

```dart
// Symptoms
setState() called after dispose()

// Solution: Check mounted before setState
if (!mounted) return;

setState(() {
  // Update state
});

// For async operations
Future<void> loadData() async {
  final data = await fetchData();
  
  if (!mounted) return; // Check before setState
  
  setState(() {
    _data = data;
  });
}
```

### Issue: Infinite rebuild loop

```dart
// Symptoms
UI constantly rebuilding, app freezes

// Bad: Calling notifier in build
@override
Widget build(BuildContext context) {
  ref.read(provider.notifier).loadData(); // DON'T DO THIS
  return Container();
}

// Good: Load in initState or onPressed
@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ref.read(provider.notifier).loadData();
  });
}

// Or load on user action
FilledButton(
  onPressed: () {
    ref.read(provider.notifier).loadData();
  },
  child: Text('Load'),
);
```

---

## Notification Issues

### Issue: Notifications not showing

```dart
// Debugging:
// 1. Check permissions granted
final granted = await notificationsPlugin
  .resolvePlatformSpecificImplementation<
    IOSFlutterLocalNotificationsPlugin>()
  ?.requestPermissions(alert: true, sound: true);

print('Notifications permitted: $granted');

// 2. Check notifications enabled in settings
final settings = await getQuizSettings();
print('Notifications enabled: ${settings.notificationsEnabled}');

// 3. Test immediate notification
await NotificationService().showQuizCompleteNotification(
  score: 5,
  total: 10,
  subjectName: 'Test',
);

// 4. Check scheduled notifications
final pending = await notificationsPlugin.pendingNotificationRequests();
print('Pending notifications: ${pending.length}');
```

### Issue: Notifications at wrong time

```dart
// Solution: Check timezone configuration
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

// Initialize timezone
tz.initializeTimeZones();
tz.setLocalLocation(tz.getLocation('America/New_York'));

// Schedule with correct timezone
final scheduledDate = tz.TZDateTime.from(
  DateTime(2025, 1, 1, 9, 0), // 9 AM
  tz.local,
);
```

---

## Performance Issues

### Issue: Slow database queries

```dart
// Symptoms
App freezes when loading subjects/questions

// Solution 1: Add indexes
await db.execute('''
  CREATE INDEX IF NOT EXISTS idx_questions_subject_id 
  ON questions(subject_id)
''');

// Solution 2: Limit results
final questions = await db.query('questions',
  where: 'subject_id = ?',
  whereArgs: [subjectId],
  limit: 100, // Don't load all at once
);

// Solution 3: Paginate
int offset = 0;
int limit = 20;

final questions = await db.query('questions',
  offset: offset,
  limit: limit,
);

// Solution 4: Use background isolate for heavy operations
final subjects = await compute(_loadSubjects, db);
```

### Issue: Slow sync

```dart
// Symptoms
Sync takes very long time

// Solution 1: Batch operations
await supabase.from('subjects').upsert(
  subjects.map((s) => s.toSupabase()).toList(), // Batch insert
);

// Solution 2: Sync only changed data
await supabase.from('subjects').upsert(
  subjects.where((s) => s.updatedAt.isAfter(lastSync)).toList(),
);

// Solution 3: Compress large payloads
import 'dart:convert';
import 'package:archive/archive.dart';

final json = jsonEncode(subjects);
final compressed = GZipEncoder().encode(utf8.encode(json));
```

---

## Deployment Issues

### Issue: App rejected from App Store

```
// Common reasons:

// 1. Missing privacy policy
// Solution: Add privacy policy URL in Info.plist

// 2. Using placeholder content
// Solution: Replace all TODO/placeholder text

// 3. Crashes on launch
// Solution: Test on physical device, fix crashes

// 4. Requesting unnecessary permissions
// Solution: Remove unused permission requests
```

### Issue: Code signing errors

```bash
# Solution:
# 1. Open Xcode
open ios/Runner.xcworkspace

# 2. Select Runner target
# 3. Signing & Capabilities
# 4. Select your Team
# 5. Enable "Automatically manage signing"

# For macOS:
open macos/Runner.xcworkspace
# Follow same steps
```

---

## Debug Commands

### Useful Flutter Commands

```bash
# Check environment
flutter doctor -v

# Clean build
flutter clean

# Get dependencies
flutter pub get

# Run with verbose logging
flutter run -v

# Build for release
flutter build apk --release

# Analyze code
flutter analyze

# Format code
flutter format lib/

# Check for outdated packages
flutter pub outdated

# Upgrade packages
flutter pub upgrade

# List devices
flutter devices

# Hot reload
r

# Hot restart
R

# Quit
q
```

### Debugging Supabase

```bash
# Test connection
curl -X GET 'https://your-project.supabase.co/rest/v1/subjects' \
  -H "apikey: YOUR_ANON_KEY" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Check RLS
# In Supabase SQL Editor:
SELECT * FROM subjects WHERE user_id = 'YOUR_USER_ID';

# View auth users
SELECT * FROM auth.users;

# Check table structure
\d subjects

# View policies
SELECT * FROM pg_policies WHERE tablename = 'subjects';
```

### Debugging SQLite

```bash
# Install sqlite3
brew install sqlite3  # macOS

# Locate database
# macOS: ~/Library/Containers/com.example.app/Data/Library/Application Support/
# iOS Simulator: ~/Library/Developer/CoreSimulator/Devices/*/data/Containers/Data/Application/*/Library/Application Support/

# Open database
sqlite3 formula_quizzer.db

# View tables
.tables

# View schema
.schema subjects

# Query data
SELECT * FROM subjects;

# Exit
.quit
```

---

## Getting Help

### Resources

1. **Flutter Documentation**: https://flutter.dev/docs
2. **Riverpod Documentation**: https://riverpod.dev
3. **Supabase Documentation**: https://supabase.com/docs
4. **OpenAI API Documentation**: https://platform.openai.com/docs

### Logging Best Practices

```dart
// Use consistent emoji prefixes
print('✅ Success: Operation completed');
print('❌ Error: Something failed');
print('⚠️ Warning: Potential issue');
print('🔄 Loading: Operation in progress');
print('📤 Upload: Sending data');
print('📥 Download: Receiving data');
print('🔍 Debug: Detailed information');

// Include context
print('🔍 SubjectProvider.loadSubjects()');
print('   Subjects count: ${subjects.length}');
print('   Loading time: ${stopwatch.elapsed}');

// Log errors with stack traces
try {
  // Operation
} catch (e, stackTrace) {
  print('❌ Error in SyncService.uploadSubjects()');
  print('   Error: $e');
  print('   Stack: $stackTrace');
}
```

### Debug Mode Flags

```dart
// Add to api_config.dart
class ApiConfig {
  static const bool debugMode = true; // Set false for production
  static const bool verboseLogging = false;
  static const bool mockApiCalls = false;
}

// Use in code
if (ApiConfig.debugMode) {
  print('🔍 Debug info: ...');
}

if (ApiConfig.mockApiCalls) {
  return mockData();
}
```
