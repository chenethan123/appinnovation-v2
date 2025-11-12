-- =============================================================================
-- FormulaQuizzer Database Cleanup Script
-- Run this in Supabase SQL Editor BEFORE running curl tests
-- =============================================================================

-- Delete all data from tables (in correct order due to foreign keys)
DELETE FROM quiz_answers;
DELETE FROM quiz_sessions;
DELETE FROM questions;
DELETE FROM subjects;
DELETE FROM units;

-- Verify cleanup (all counts should be 0)
SELECT 
  'subjects' as table_name, COUNT(*) as count FROM subjects
UNION ALL
SELECT 'questions', COUNT(*) FROM questions
UNION ALL
SELECT 'quiz_sessions', COUNT(*) FROM quiz_sessions
UNION ALL
SELECT 'quiz_answers', COUNT(*) FROM quiz_answers
UNION ALL
SELECT 'units', COUNT(*) FROM units;

-- Expected output: All counts should be 0

-- Verify RLS is still enabled
SELECT 
  tablename, 
  rowsecurity as "RLS Enabled"
FROM pg_tables 
WHERE schemaname = 'public' 
  AND tablename IN ('subjects', 'questions', 'quiz_sessions', 'quiz_answers', 'courses', 'units')
ORDER BY tablename;

-- Expected: All tables should show 'true' for RLS Enabled

-- Verify users still exist
SELECT 
  email,
  id,
  created_at
FROM auth.users
ORDER BY email;

-- Expected: Should see your test users (testing@gmail.com, ethan@gmail.com)

-- Ready for curl tests!
