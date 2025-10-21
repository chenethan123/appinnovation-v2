# Supabase Setup Guide - Cross-Device Sync

## ✅ Step 1: Run Database Schema

### 1.1 Open Supabase SQL Editor
1. Go to: https://supabase.com/dashboard/project/dsknaaziujrfavhaschj/sql
2. Click "New Query"

### 1.2 Copy and Run Schema
1. Open the file: `server/supabase_schema.sql`
2. Copy **ALL** the SQL code
3. Paste it into Supabase SQL Editor
4. Click **"Run"** button

### 1.3 Verify Tables Created
You should see these tables created:
- ✅ users
- ✅ subjects
- ✅ questions
- ✅ quiz_sessions
- ✅ quiz_answers
- ✅ courses
- ✅ units

---

## ✅ Step 2: Get Supabase Credentials

### 2.1 Get Project URL
1. Go to: https://supabase.com/dashboard/project/dsknaaziujrfavhaschj/settings/api
2. Copy **"Project URL"**
   - Should be: `https://dsknaaziujrfavhaschj.supabase.co`

### 2.2 Get API Keys
1. On same page, copy:
   - **anon/public key** (for Flutter app)
   - **service_role key** (for backend server - KEEP SECRET!)

### 2.3 Update Configuration Files

**Update `server/.env`:**
```bash
SUPABASE_URL=https://dsknaaziujrfavhaschj.supabase.co
SUPABASE_ANON_KEY=your_anon_key_here
SUPABASE_SERVICE_KEY=your_service_role_key_here
```

**Update `lib/config/api_config.dart`:**
```dart
class ApiConfig {
  // Supabase configuration
  static const String supabaseUrl = 'https://dsknaaziujrfavhaschj.supabase.co';
  static const String supabaseAnonKey = 'your_anon_key_here';
  
  // Existing OpenAI config
  static const String openAiApiKey = 'sk-proj-...';
}
```

---

## ✅ Step 3: Enable Supabase Authentication

### 3.1 Enable Email Auth
1. Go to: https://supabase.com/dashboard/project/dsknaaziujrfavhaschj/auth/providers
2. Make sure **"Email"** provider is enabled
3. Configure:
   - ✅ Enable email provider
   - ✅ Confirm email: Optional (disable for development)
   - ✅ Secure email change: Optional

### 3.2 Configure Email Templates (Optional)
1. Go to: https://supabase.com/dashboard/project/dsknaaziujrfavhaschj/auth/templates
2. Customize email templates if needed

---

## ✅ Step 4: Test Database Connection

### 4.1 Test with SQL Query
Run this in Supabase SQL Editor:
```sql
-- Test query
SELECT 
  tablename 
FROM 
  pg_tables 
WHERE 
  schemaname = 'public';
```

You should see all 7 tables listed!

### 4.2 Test Row Level Security
Run this to verify RLS is enabled:
```sql
SELECT 
  tablename,
  rowsecurity 
FROM 
  pg_tables 
WHERE 
  schemaname = 'public' 
  AND rowsecurity = true;
```

---

## ✅ Step 5: Create Test User

### 5.1 Using Supabase Dashboard
1. Go to: https://supabase.com/dashboard/project/dsknaaziujrfavhaschj/auth/users
2. Click "Add user"
3. Choose "Create new user"
4. Enter email and password
5. Click "Create user"

### 5.2 Using SQL (Alternative)
```sql
-- This will be done through Flutter app signup
-- But you can test manually here
INSERT INTO users (email, password_hash, display_name) 
VALUES (
  'test@example.com',
  crypt('testpassword123', gen_salt('bf')),  -- bcrypt hash
  'Test User'
);
```

---

## ✅ Step 6: Update Flutter App

### 6.1 Add Supabase Package
```bash
cd /Users/ethanchen/Desktop/formula_quizzer/formulaquizzeraccounts
flutter pub add supabase_flutter
```

### 6.2 Initialize Supabase in Flutter
Update `lib/main.dart`:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:formula_quizzer/config/api_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: ApiConfig.supabaseUrl,
    anonKey: ApiConfig.supabaseAnonKey,
  );
  
  runApp(const ProviderScope(child: FormulaQuizzerApp()));
}

// Access Supabase client anywhere
final supabase = Supabase.instance.client;
```

---

## ✅ Step 7: Test Authentication Flow

### 7.1 Test Signup
```dart
// In Flutter app
final response = await supabase.auth.signUp(
  email: 'test@example.com',
  password: 'testpassword123',
);

if (response.user != null) {
  print('✅ User created: ${response.user!.id}');
}
```

### 7.2 Test Login
```dart
final response = await supabase.auth.signInWithPassword(
  email: 'test@example.com',
  password: 'testpassword123',
);

if (response.user != null) {
  print('✅ Login successful!');
  print('User ID: ${response.user!.id}');
  print('Access Token: ${response.session!.accessToken}');
}
```

### 7.3 Test Data Insert
```dart
// Insert a subject
final response = await supabase
  .from('subjects')
  .insert({
    'user_id': supabase.auth.currentUser!.id,
    'name': 'AP Calculus AB',
    'description': 'Advanced calculus',
    'color': '#6366f1',
  })
  .select()
  .single();

print('✅ Subject created: ${response['id']}');
```

---

## 🔒 Security Checklist

- ✅ Database URL configured
- ✅ API keys stored in `.env` file
- ✅ `.env` added to `.gitignore`
- ✅ Row Level Security (RLS) enabled on all tables
- ✅ Auth policies configured
- ✅ Service role key kept secret (never in Flutter app!)
- ✅ Only anon key used in Flutter app

---

## 🚀 Next Steps

After completing setup:

1. **Create Auth Service** (`lib/services/auth_service.dart`)
2. **Create Sync Service** (`lib/services/sync_service.dart`)
3. **Add Login Screen** (`lib/screens/auth_screen.dart`)
4. **Test Cross-Device Sync**:
   - Login on iPhone
   - Create subject
   - Login on iPad
   - Verify subject appears!

---

## 🐛 Troubleshooting

### "Row Level Security policy violation"
- Make sure you're logged in before querying data
- Verify RLS policies are created (Step 4.2)

### "Invalid JWT token"
- Token might be expired (expires after 1 hour)
- Re-login to get new token

### "Connection refused"
- Check SUPABASE_URL is correct
- Verify network connection
- Check Supabase project is active

### "Permission denied for table"
- Verify user_id matches auth.uid()
- Check RLS policies with: `SELECT * FROM pg_policies;`

---

## 📊 Monitoring

### Check User Activity
```sql
-- View recent users
SELECT email, created_at, last_login_at 
FROM users 
ORDER BY created_at DESC 
LIMIT 10;
```

### Check Sync Stats
```sql
-- View sync statistics per user
SELECT 
  u.email,
  COUNT(DISTINCT s.id) as subject_count,
  COUNT(DISTINCT q.id) as question_count,
  COUNT(DISTINCT qs.id) as quiz_count
FROM users u
LEFT JOIN subjects s ON s.user_id = u.id
LEFT JOIN questions q ON q.user_id = u.id
LEFT JOIN quiz_sessions qs ON qs.user_id = u.id
GROUP BY u.email;
```

---

## 💰 Cost Monitoring

**FREE Tier Limits:**
- Database: 500 MB
- Bandwidth: 5 GB
- Requests: 50K/day

**Check Usage:**
1. Go to: https://supabase.com/dashboard/project/dsknaaziujrfavhaschj/settings/billing
2. Monitor database size and API calls

---

**Your database is ready! Start building the sync features! 🎉**
