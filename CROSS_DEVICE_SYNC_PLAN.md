# Cross-Device Sync Implementation Plan

**Goal**: Enable users to access same questions and profile from iPad, iPhone, Mac, etc.

## 🎯 Recommended Approach: Node.js + PostgreSQL + JWT

### Architecture Overview
```
Devices (iPhone/iPad/Mac) ↔ REST API (Node.js) ↔ PostgreSQL (Cloud)
         ↓
   Local SQLite Cache
   (offline-first)
```

## 📋 Implementation Steps

### Phase 1: Database Setup (1 hour)

**1.1 Choose Database Provider**
- **Supabase** (Recommended - FREE tier, PostgreSQL, built-in auth)
- Or Railway, Neon, Render

**1.2 Database Schema**
```sql
-- Users table
CREATE TABLE users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  email TEXT UNIQUE NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Subjects table (synced from devices)
CREATE TABLE subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT NOT NULL,
  is_active BOOLEAN DEFAULT true,
  total_questions INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  difficulty_weight REAL DEFAULT 0.5,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  device_id TEXT,  -- Track which device created it
  sync_version INTEGER DEFAULT 1  -- For conflict resolution
);

-- Questions table (synced)
CREATE TABLE questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT NOT NULL,
  difficulty TEXT NOT NULL,
  is_from_ai BOOLEAN DEFAULT false,
  source TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  sync_version INTEGER DEFAULT 1
);

-- Quiz sessions (synced)
CREATE TABLE quiz_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id),
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  score INTEGER NOT NULL,
  started_at TIMESTAMP NOT NULL,
  completed_at TIMESTAMP,
  device_id TEXT,
  sync_version INTEGER DEFAULT 1
);
```

### Phase 2: Backend API (2-3 hours)

**2.1 Install Dependencies**
```bash
cd server
npm install @supabase/supabase-js prisma @prisma/client jsonwebtoken bcrypt
```

**2.2 Key Endpoints**
```typescript
// Authentication
POST   /api/auth/register       // Create account
POST   /api/auth/login          // Login and get JWT token

// Sync Endpoints
GET    /api/sync/subjects       // Get all user's subjects
POST   /api/sync/subjects       // Upload subjects from device
PUT    /api/sync/subjects/:id   // Update subject
DELETE /api/sync/subjects/:id   // Delete subject

GET    /api/sync/questions      // Get all user's questions
POST   /api/sync/questions      // Upload questions

GET    /api/sync/sessions       // Get quiz history
POST   /api/sync/sessions       // Upload new session

// Full Sync (smart)
POST   /api/sync/full           // Upload local data + get latest from cloud
                                // Returns: { subjects, questions, sessions }
                                // Conflict resolution: server wins

// AI Generation (existing)
POST   /api/ai/generate-question // Generate question (as before)
```

**2.3 Sync Strategy**
```
On App Launch:
1. Check internet connection
2. If online + user logged in:
   - Send local changes to server (POST /api/sync/full)
   - Receive latest data from server
   - Merge with local SQLite (resolve conflicts)
   - Update UI

On Data Change (subject/question created):
1. Save to local SQLite immediately (offline-first)
2. Queue sync request
3. When online, send to server in background
4. On success, mark as synced

Conflict Resolution:
- Server timestamp wins (latest update)
- OR: Present conflict UI to user
```

### Phase 3: Flutter Client Updates (3-4 hours)

**3.1 Add Authentication**
```dart
// lib/services/auth_service.dart
class AuthService {
  Future<String?> register(String email, String password);
  Future<String?> login(String email, String password);
  Future<void> logout();
  String? getCurrentUserId();
}
```

**3.2 Add Sync Service**
```dart
// lib/services/sync_service.dart
class SyncService {
  // Upload local data to server
  Future<void> uploadSubjects(List<Subject> subjects);
  Future<void> uploadQuestions(List<Question> questions);
  
  // Download from server
  Future<List<Subject>> downloadSubjects();
  Future<List<Question>> downloadQuestions();
  
  // Full bi-directional sync
  Future<SyncResult> fullSync();
  
  // Automatic sync
  void startAutoSync(Duration interval); // Every 5 minutes
}
```

**3.3 Update Database Helper**
```dart
// lib/database/database_helper.dart
// Add sync tracking columns
ALTER TABLE subjects ADD COLUMN synced INTEGER DEFAULT 0;
ALTER TABLE subjects ADD COLUMN last_sync_at TEXT;
ALTER TABLE questions ADD COLUMN synced INTEGER DEFAULT 0;
```

**3.4 Add Login Screen**
```dart
// lib/screens/auth_screen.dart
class AuthScreen extends StatefulWidget {
  // Login/Register UI
  // Redirect to HomeScreen on success
}
```

### Phase 4: Deployment (1 hour)

**4.1 Deploy to Supabase**
```bash
# Create project at supabase.com (FREE)
# Get API URL and anon key
# Update Flutter config
```

**4.2 Deploy Backend to Railway**
```bash
# Create account at railway.app (FREE $5 credit/month)
railway login
railway init
railway up
# Get deployment URL
```

**4.3 Update Flutter Config**
```dart
// lib/config/api_config.dart
class ApiConfig {
  static const String supabaseUrl = 'https://xxx.supabase.co';
  static const String supabaseKey = 'your-anon-key';
  static const String backendUrl = 'https://your-app.railway.app';
}
```

## 🔐 Security Considerations

**JWT Authentication**
```typescript
// Middleware to verify user
export const requireAuth = (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  if (!token) return res.status(401).json({ error: 'Unauthorized' });
  
  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid token' });
  }
};
```

**Row Level Security (if using Supabase)**
```sql
-- Users can only see their own data
CREATE POLICY "Users can view own subjects"
  ON subjects FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subjects"
  ON subjects FOR INSERT
  WITH CHECK (auth.uid() = user_id);
```

## 📊 Cost Estimate

**FREE Tier (Sufficient to Start):**
- Supabase: 500MB database, 50K reads/day
- Railway: $5 credit/month (enough for small API)
- Total: $0-5/month

**Paid Tier (If Scaling):**
- Supabase Pro: $25/month (8GB database)
- Railway: ~$10-20/month
- Total: $35-45/month for 1000+ users

## 🎯 User Experience

**First Time Setup:**
1. User opens app → See "Login/Register" screen
2. Register with email/password
3. Existing local data gets uploaded to cloud
4. Done! Now accessible from any device

**On New Device:**
1. User installs app on iPad
2. Login with same email/password
3. All subjects, questions, progress sync automatically
4. Seamless experience!

**Offline Mode:**
- App works 100% offline (existing behavior)
- Changes queue up
- Auto-sync when internet available
- No data loss

## 🚀 Quick Start Commands

**Setup Supabase:**
```bash
# 1. Go to supabase.com
# 2. Create new project (FREE)
# 3. Run SQL schema (from above)
# 4. Get API URL and key
```

**Update Backend:**
```bash
cd server
npm install @supabase/supabase-js prisma
npx prisma init
# Edit prisma/schema.prisma with models
npx prisma generate
npm run dev
```

**Update Flutter:**
```bash
cd ..
flutter pub add supabase_flutter
flutter run
```

## 📝 Next Steps

**Immediate (Essential):**
1. ✅ Setup Supabase database
2. ✅ Implement authentication endpoints
3. ✅ Add sync endpoints
4. ✅ Update Flutter with auth + sync

**Later (Enhanced):**
- Conflict resolution UI
- Offline queue manager
- Real-time sync with WebSockets
- Share subjects with other users
- Collaborative quizzes

## 🔄 Migration Path

**For Existing Users:**
```dart
// First launch after update
if (await authService.isLoggedIn() == false) {
  // Show "Create Account" prompt
  // On signup, upload all local data to cloud
  await syncService.uploadAll();
}
```

---

**Estimated Total Time**: 7-10 hours for full implementation
**Difficulty**: Medium (requires backend + auth knowledge)
**Maintenance**: Low (serverless options require minimal upkeep)

**Ready to start? Begin with Phase 1! 🚀**
