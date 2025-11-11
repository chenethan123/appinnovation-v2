# Cross-User Isolation Test Plan

**Date**: 2025-11-11  
**Purpose**: Comprehensive testing of cross-user data isolation fixes  
**Branch**: `user-specific-data`

---

## 🧪 **Test Setup**

### **Prerequisites**
1. Clean Supabase database (run SQL cleanup)
2. Uninstall app from simulator (reset local DBs)
3. Two test accounts:
   - `testing@gmail.com`
   - `ethan@gmail.com`

---

## 📋 **Test Cases**

### **Test 1: Fresh Login - Empty Account**
**Purpose**: Verify new user starts with empty state

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 1.1 | Login as `testing@gmail.com` | Console shows `🔄 Database reopened for user: {userId}` | ⏳ |
| 1.2 | Check subjects list | Should be empty (0 subjects) | ⏳ |
| 1.3 | Check console | `🔒 Restore mode ENABLED` → `✅ 0 subjects persisted` → `🔓 Restore mode DISABLED` | ⏳ |
| 1.4 | Verify DB file | File created: `formula_quizzer_{userId}.db` | ⏳ |

---

### **Test 2: Add Subjects - Single User**
**Purpose**: Verify subject creation and persistence

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 2.1 | Add subject "Testing Math" | Subject appears in list | ⏳ |
| 2.2 | Check console | `✅ Subject added and syncing to cloud...` | ⏳ |
| 2.3 | Wait 5 seconds | Background sync uploads to cloud | ⏳ |
| 2.4 | Add subject "Testing Physics" | Subject appears in list | ⏳ |
| 2.5 | Check subject count | Should show 2 subjects | ⏳ |

---

### **Test 3: Logout and Re-Login - Same User**
**Purpose**: Verify data persists across sessions

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 3.1 | Logout from `testing@gmail.com` | Console shows `🔄 Database reopened for user: offline` | ⏳ |
| 3.2 | Login as `testing@gmail.com` again | Console shows `🔄 Database reopened for user: {userId}` | ⏳ |
| 3.3 | Check subjects | Should see "Testing Math" and "Testing Physics" (2 subjects) | ⏳ |
| 3.4 | Check console | `✅ 2 subjects persisted` during restore | ⏳ |

---

### **Test 4: Cross-User Isolation - Different Account**
**Purpose**: Verify users CANNOT see each other's data

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 4.1 | Logout from `testing@gmail.com` | User logged out | ⏳ |
| 4.2 | Login as `ethan@gmail.com` | Console shows different userId | ⏳ |
| 4.3 | Check subjects | Should be EMPTY (0 subjects) ❌ NOT see Testing's subjects | ⏳ |
| 4.4 | Verify DB file | Different file: `formula_quizzer_{different_userId}.db` | ⏳ |
| 4.5 | Add subject "Ethan Chemistry" | Subject appears | ⏳ |
| 4.6 | Check subject count | Should show 1 subject (only Ethan's) | ⏳ |

---

### **Test 5: Back to Original User**
**Purpose**: Verify first user still has their data intact

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 5.1 | Logout from `ethan@gmail.com` | User logged out | ⏳ |
| 5.2 | Login as `testing@gmail.com` | Console shows original userId | ⏳ |
| 5.3 | Check subjects | Should see "Testing Math" and "Testing Physics" (2 subjects) | ⏳ |
| 5.4 | Verify | Should NOT see "Ethan Chemistry" | ⏳ |

---

### **Test 6: Cloud Data Verification**
**Purpose**: Verify cloud database has correct user isolation

**Run in Supabase SQL Editor:**
```sql
-- Check subjects per user
SELECT 
  u.email,
  s.name as subject_name,
  s.user_id
FROM subjects s
JOIN auth.users u ON s.user_id = u.id
ORDER BY u.email, s.name;
```

| Expected Result | Pass/Fail |
|-----------------|-----------|
| `testing@gmail.com` - "Testing Math" | ⏳ |
| `testing@gmail.com` - "Testing Physics" | ⏳ |
| `ethan@gmail.com` - "Ethan Chemistry" | ⏳ |
| NO cross-contamination (each user has ONLY their subjects) | ⏳ |

---

### **Test 7: MCQ Generation with Subjects**
**Purpose**: Verify subject creation from MCQ generation

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 7.1 | Login as `testing@gmail.com` | Logged in | ⏳ |
| 7.2 | Generate MCQ for "Biology" course | Subject auto-created if not exists | ⏳ |
| 7.3 | Check console | `📝 Subject not found, creating: Biology` | ⏳ |
| 7.4 | Check console | `userId: {current_user_id}` in subject creation | ⏳ |
| 7.5 | Verify subject has userId | Subject.userId is set | ⏳ |

---

### **Test 8: Offline Mode**
**Purpose**: Verify app works without login

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 8.1 | Logout from all accounts | No user logged in | ⏳ |
| 8.2 | Check DB file | Uses `formula_quizzer_offline.db` | ⏳ |
| 8.3 | Add subject "Offline Test" | Subject created locally | ⏳ |
| 8.4 | Check sync | No cloud sync attempts | ⏳ |

---

### **Test 9: Background Sync During Restore**
**Purpose**: Verify restore mode prevents contamination

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 9.1 | Login as `testing@gmail.com` | Restore begins | ⏳ |
| 9.2 | Watch console during restore | `🔒 Restore mode ENABLED` appears FIRST | ⏳ |
| 9.3 | Check for auto-sync | `⏭️ Skipping upload - restore mode active` during restore | ⏳ |
| 9.4 | After restore completes | `🔓 Restore mode DISABLED` then sync starts | ⏳ |

---

### **Test 10: Question Upload/Download**
**Purpose**: Verify questions are properly isolated

| Step | Action | Expected Result | Pass/Fail |
|------|--------|----------------|-----------|
| 10.1 | Login as `testing@gmail.com` | Logged in | ⏳ |
| 10.2 | Generate questions for "Testing Math" | Questions created | ⏳ |
| 10.3 | Check console | `subject_name: Testing Math` in upload | ⏳ |
| 10.4 | Verify no `subject_id` error | No UUID FK constraint errors | ⏳ |
| 10.5 | Logout and login as `ethan@gmail.com` | Different user | ⏳ |
| 10.6 | Check questions | Should NOT see Testing's questions | ⏳ |

---

## 🎯 **Success Criteria**

### **✅ Must Pass All:**
- [ ] Each user has separate DB file
- [ ] Users cannot see each other's subjects
- [ ] Restore mode prevents auto-sync contamination
- [ ] Cloud data is properly filtered by user_id
- [ ] userId is set on all new subjects
- [ ] Questions use subject_name (not invalid subject_id)
- [ ] Background sync respects restore mode
- [ ] Data persists across logout/login

### **⚠️ Known Limitations:**
- Quiz sessions not yet synced (expected)
- Offline mode doesn't sync (expected)

---

## 🐛 **Issues to Watch For**

1. **Sync Loop**: Infinite "Skipping sync - already in progress"
2. **UNIQUE Constraint**: "subjects.id" errors
3. **Data Bleeding**: User A sees User B's subjects
4. **Empty After Login**: User logs in, sees 0 subjects when they should have data
5. **UUID Errors**: Question upload fails with FK constraint
6. **Restore Contamination**: Old data uploaded during restore

---

## 📊 **Test Results Table**

| Test Case | Status | Notes | Issues Found |
|-----------|--------|-------|--------------|
| Test 1: Fresh Login | ⏳ | | |
| Test 2: Add Subjects | ⏳ | | |
| Test 3: Re-Login Same User | ⏳ | | |
| Test 4: Cross-User Isolation | ⏳ | CRITICAL | |
| Test 5: Back to Original | ⏳ | CRITICAL | |
| Test 6: Cloud Verification | ⏳ | CRITICAL | |
| Test 7: MCQ Generation | ⏳ | | |
| Test 8: Offline Mode | ⏳ | | |
| Test 9: Restore Mode | ⏳ | CRITICAL | |
| Test 10: Question Isolation | ⏳ | | |

---

## 🔧 **Pre-Test Cleanup**

Run these commands before starting tests:

### **1. Clean Supabase**
```sql
DELETE FROM quiz_answers;
DELETE FROM quiz_sessions;
DELETE FROM questions;
DELETE FROM subjects;

-- Verify clean
SELECT COUNT(*) FROM subjects;  -- Should return 0
```

### **2. Uninstall App**
- Long-press app icon on simulator
- Click "Delete App"
- This removes all local DB files

### **3. Rebuild App**
```bash
flutter clean
flutter pub get
flutter run -d 9DE19C5E-6CDF-4903-8244-32E864302C6A
```

---

## 📝 **Test Execution Log**

Will be filled during testing...
