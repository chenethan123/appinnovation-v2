# 🚀 Quick Start - API Testing Guide

**Goal**: Test your Supabase database and API using curl commands  
**Time**: 10 minutes  
**Prerequisites**: Terminal access

---

## ⚡ **3-Step Quick Start**

### **Step 1: Fix Authentication (Choose One)**

#### **Option A: Reset Passwords via Supabase Dashboard** (EASIEST)
1. Open https://supabase.com/dashboard
2. Select your project: `dsknaaziujrfavhaschj`
3. Go to: **Authentication** → **Users**
4. Find `testing@gmail.com` → Click **"..."** → **"Reset Password"**
5. Set password: `password123`
6. Repeat for `ethan@gmail.com`

#### **Option B: Use Your Actual Passwords**
1. Edit `AI/windsurf/curl_tests.sh`
2. Change lines 13-14:
   ```bash
   USER1_PASSWORD="YOUR_ACTUAL_PASSWORD_FOR_TESTING"
   USER2_PASSWORD="YOUR_ACTUAL_PASSWORD_FOR_ETHAN"
   ```

---

### **Step 2: Run Database Cleanup**

```bash
# Copy this SQL and run in Supabase SQL Editor:
cd /Users/ethanchen/Desktop/formula_quizzer/formulaquizzeraccounts
cat AI/windsurf/cleanup_database.sql
```

Then paste into: https://supabase.com/dashboard → SQL Editor → New Query

---

### **Step 3: Run Tests**

```bash
cd /Users/ethanchen/Desktop/formula_quizzer/formulaquizzeraccounts
./AI/windsurf/curl_tests.sh
```

**Expected Output**:
```
🎉 ALL TESTS PASSED!
✅ Cross-user isolation is working correctly
✅ RLS policies are functioning as expected
✅ Database is production-ready

Tests Run:    16
Tests Passed: 16
Tests Failed: 0
Pass Rate:    100%
```

---

## 📝 **Individual curl Commands** (Manual Testing)

If you want to test manually, here are the key commands:

### **1. Authenticate User**

```bash
# Get your access token
TOKEN=$(curl -s -X POST \
  "https://dsknaaziujrfavhaschj.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs" \
  -H "Content-Type: application/json" \
  -d '{"email":"testing@gmail.com","password":"password123"}' | grep -o '"access_token":"[^"]*"' | cut -d'"' -f4)

echo "Token: $TOKEN"
```

### **2. Create a Subject**

```bash
# Get your user ID first
USER_ID=$(curl -s -X POST \
  "https://dsknaaziujrfavhaschj.supabase.co/auth/v1/token?grant_type=password" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Content-Type: application/json" \
  -d '{"email":"testing@gmail.com","password":"password123"}' | grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)

# Create subject
curl -X POST \
  "https://dsknaaziujrfavhaschj.supabase.co/rest/v1/subjects" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Prefer: return=representation" \
  -d "{
    \"user_id\": \"$USER_ID\",
    \"name\": \"Test Math\",
    \"description\": \"Math for testing\",
    \"color\": \"#FF5722\",
    \"is_active\": true,
    \"total_questions\": 0,
    \"correct_answers\": 0,
    \"difficulty_weight\": 0.5,
    \"created_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\",
    \"updated_at\": \"$(date -u +%Y-%m-%dT%H:%M:%S.000Z)\"
  }"
```

### **3. Read Your Subjects**

```bash
curl -X GET \
  "https://dsknaaziujrfavhaschj.supabase.co/rest/v1/subjects?select=*" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRza25hYXppdWpyZmF2aGFzY2hqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA5MjczMDIsImV4cCI6MjA3NjUwMzMwMn0.4dZun66--TR5BSvGIPUtVBgEkSO9mPfZIjckDsvI_Fs" \
  -H "Authorization: Bearer $TOKEN" | jq '.'
```

### **4. Update a Subject**

```bash
curl -X PATCH \
  "https://dsknaaziujrfavhaschj.supabase.co/rest/v1/subjects?name=eq.Test%20Math" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"description":"Updated description","total_questions":10}'
```

### **5. Delete a Subject**

```bash
curl -X DELETE \
  "https://dsknaaziujrfavhaschj.supabase.co/rest/v1/subjects?name=eq.Test%20Math" \
  -H "apikey: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -H "Authorization: Bearer $TOKEN"
```

---

## 🧪 **Test Scenarios to Verify**

### **Scenario 1: User Isolation** ✅
```bash
# Login as User 1, create subjects
# Login as User 2, verify you DON'T see User 1's subjects
# Expected: Each user sees only their own data
```

### **Scenario 2: Security** ✅
```bash
# Try to read subjects without authentication
# Expected: Empty array [] (RLS blocks access)
```

### **Scenario 3: Cross-User Modification** ✅
```bash
# User 1 creates subject
# User 2 tries to modify User 1's subject
# Expected: Blocked by RLS
```

---

## 📊 **What Each Test Verifies**

| Test # | What It Tests | Why It Matters |
|--------|---------------|----------------|
| 1-2 | Authentication works | Users can login |
| 3-5 | Subject creation | Basic CRUD works |
| 6 | User can read own data | Data retrieval works |
| 7 | **Cross-user isolation** | **CRITICAL: No data leaks** |
| 8 | Subject creation User 2 | Multi-user support |
| 9-10 | Complete isolation | **CRITICAL: Each user isolated** |
| 11-12 | **Unauthorized access blocked** | **CRITICAL: Security works** |
| 13 | Update operations | CRUD complete |
| 14-15 | Delete operations | CRUD complete |
| 16 | Final state verification | Data integrity |

---

## ⚠️ **Common Issues & Fixes**

### **Issue**: "Invalid login credentials"
**Fix**: Reset passwords in Supabase Dashboard (see Step 1, Option A)

### **Issue**: "Empty JWT is sent in Authorization header"
**Fix**: Authentication failed. Check Step 1.

### **Issue**: Tests pass but show 0 subjects
**Fix**: Run cleanup SQL first (Step 2)

### **Issue**: curl: command not found
**Fix**: Install curl: `brew install curl`

### **Issue**: jq: command not found
**Fix**: Install jq: `brew install jq` (optional, for pretty JSON)

---

## 🎯 **Success Criteria**

After running tests, you should see:

✅ **16/16 tests passed**  
✅ **0 tests failed**  
✅ **100% pass rate**  
✅ **"ALL TESTS PASSED!" message**  
✅ **"Cross-user isolation is working correctly"**  
✅ **"Database is production-ready"**

---

## 📁 **Test Files Location**

All test files are in: `/Users/ethanchen/Desktop/formula_quizzer/formulaquizzeraccounts/AI/windsurf/`

- `curl_tests.sh` - Main test suite
- `setup_test_users.sh` - Create test users
- `cleanup_database.sql` - Clean database
- `CURL_TEST_RESULTS.md` - Detailed results
- `COMPREHENSIVE_TEST_SUMMARY.md` - Full analysis

---

## 🚀 **After Tests Pass**

Once all 16 tests pass:

1. ✅ Database is verified working
2. ✅ Cross-user isolation confirmed
3. ✅ Security verified
4. ✅ Ready for Flutter app testing
5. ✅ Ready for production deployment

---

**That's it! Just fix authentication and run the test script. You'll have complete confidence in your database and API! 🎉**
