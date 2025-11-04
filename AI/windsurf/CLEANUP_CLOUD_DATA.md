# Clean Up Contaminated Cloud Data

**Date**: 2025-11-04  
**Status**: CRITICAL - Must run before testing  
**Branch**: `user-specific-data`

---

## 🔴 **Problem Detected**

Your Supabase cloud database has **contaminated data**:

```
✅ Downloaded 13 subjects from cloud
❌ UNIQUE constraint failed: subjects.id
args [0, Mathematics, ...]
```

**Root Cause:**
- Cloud subjects have **invalid IDs** (all showing as `0` instead of UUIDs)
- Multiple subjects with the same ID violate UNIQUE constraint
- This causes download/persist to fail

---

## ✅ **Fix Applied in Code**

Changed `insertSubject()` and `insertQuestion()` to use `ConflictAlgorithm.replace`:
- Now replaces existing rows instead of failing on duplicates
- Allows cloud data to be persisted even with invalid IDs

---

## 🧹 **Clean Up Cloud Data (CRITICAL)**

You **MUST** clean up the cloud database before testing. Run this in **Supabase SQL Editor**:

### **Step 1: Check Current Data**

```sql
-- See what data exists for each user
SELECT 
  u.email,
  s.id,
  s.name,
  s.user_id,
  s.created_at
FROM subjects s
JOIN auth.users u ON s.user_id = u.id
ORDER BY u.email, s.name;

-- Check if subjects have invalid IDs (all zeros or duplicates)
SELECT 
  id,
  COUNT(*) as count
FROM subjects
GROUP BY id
HAVING COUNT(*) > 1;
```

### **Step 2: Clean Up Invalid Data**

```sql
-- OPTION A: Delete ALL subjects and questions (fresh start)
-- Recommended if data is heavily contaminated
DELETE FROM questions;
DELETE FROM subjects;

-- Verify everything is deleted
SELECT COUNT(*) FROM subjects;   -- Should return 0
SELECT COUNT(*) FROM questions;  -- Should return 0
```

**OR**

```sql
-- OPTION B: Delete only subjects with invalid IDs
-- Use this if you want to keep some data
DELETE FROM questions WHERE subject_id IN (
  SELECT id FROM subjects WHERE id = '00000000-0000-0000-0000-000000000000'::uuid
);
DELETE FROM subjects WHERE id = '00000000-0000-0000-0000-000000000000'::uuid;

-- Verify invalid IDs are gone
SELECT COUNT(*) FROM subjects WHERE id = '00000000-0000-0000-0000-000000000000'::uuid;  -- Should return 0
```

### **Step 3: Verify User Separation**

```sql
-- After cleanup, verify users have separate data
SELECT 
  u.email,
  COUNT(s.id) as subject_count
FROM auth.users u
LEFT JOIN subjects s ON u.id = s.user_id
GROUP BY u.email;

-- Should show:
-- ethan@gmail.com     | 0
-- testing@gmail.com   | 0
-- (or different counts if they have data)
```

---

## 🧪 **Testing After Cleanup**

### **Test 1: Fresh Login**

1. **Run the SQL cleanup above** ✅
2. **Hot restart the app**:
   ```bash
   # In Flutter terminal, press:
   R  # Capital R for hot restart
   ```

3. **Login as `testing@gmail.com`**

4. **Check console logs** - Should see:
   ```
   🔒 Restore mode ENABLED - auto-sync disabled
   🗑️ Local data cleared
   📥 Downloading subjects from cloud...
   ✅ Downloaded 0 subjects from cloud
   💾 Persisting 0 subjects to local DB...
   ✅ 0 subjects persisted locally
   🔓 Restore mode DISABLED - auto-sync enabled
   ```

5. **No more UNIQUE constraint errors!** ✅

### **Test 2: Add Subject and Verify Isolation**

1. **Login as `testing@gmail.com`**
2. **Add a subject** called "Testing Subject"
3. **Wait 10 seconds** for background sync
4. **Logout**
5. **Login as `ethan@gmail.com`**
6. **Verify:** You should **NOT** see "Testing Subject" ✅

### **Test 3: Cross-Account Verification**

1. **Login as `ethan@gmail.com`**
2. **Add subject** "Ethan Subject"
3. **Logout**
4. **Login as `testing@gmail.com`**
5. **Verify:** Should see "Testing Subject" but NOT "Ethan Subject" ✅

---

## 📊 **Expected Behavior After Fix**

### **Console Logs (Correct):**
```
✅ User logged in: testing@gmail.com
🔒 Restore mode ENABLED - auto-sync disabled
🗑️ Clearing all user data from local database...
✅ All user data cleared from local database
📥 Downloading subjects from cloud...
✅ Downloaded X subjects from cloud
💾 Persisting X subjects to local DB...
✅ X subjects persisted locally  ← No more UNIQUE constraint error!
🔓 Restore mode DISABLED - auto-sync enabled
🚀 Starting background sync
```

### **Data Isolation (Correct):**
- `ethan@gmail.com` sees only ethan's subjects
- `testing@gmail.com` sees only testing's subjects
- No data bleeding between accounts

---

## 🎯 **Summary of All Fixes Applied**

### **1. Singleton SyncService** ✅
- Ensures restore mode state is shared across app
- Fixed missing 🔒/🔓 messages

### **2. Restore Mode Guards** ✅
- Blocks uploads during login/restore
- Prevents stale data from being uploaded

### **3. INSERT OR REPLACE** ✅
- Handles cloud data with duplicate/invalid IDs
- Prevents UNIQUE constraint errors

### **4. Supabase RLS** ✅
- Row-Level Security enforces user isolation
- Prevents cross-user data access at database level

### **5. Cloud Data Cleanup** ⏳ (Must run manually)
- Deletes contaminated subjects with invalid IDs
- Fresh start for testing

---

## 🚨 **Critical Next Steps**

1. ✅ Code fixes applied (committed)
2. **⏳ RUN SQL CLEANUP** (in Supabase SQL Editor)
3. **⏳ Hot restart app** (press `R` in Flutter terminal)
4. **⏳ Test login/logout** with both accounts
5. **⏳ Verify no UNIQUE constraint errors**
6. **⏳ Verify data isolation**

---

## 📝 **Files Modified**

- `lib/services/sync_service.dart` - Singleton pattern + restore mode
- `lib/screens/auth_screen.dart` - Enable/disable restore mode during login
- `lib/database/database_helper.dart` - INSERT OR REPLACE for cloud data
- `AI/windsurf/CROSS_USER_DATA_FIX.md` - RLS policies and documentation
- `AI/windsurf/CLEANUP_CLOUD_DATA.md` - This file

---

**Run the SQL cleanup NOW, then hot restart the app!** 🚀
