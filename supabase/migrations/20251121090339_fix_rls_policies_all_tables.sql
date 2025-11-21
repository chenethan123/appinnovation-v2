-- ============================================
-- FIX RLS POLICIES FOR ALL USER TABLES
-- ============================================
-- This migration ensures all user tables have proper RLS policies
-- that automatically set user_id and enforce user isolation
-- ============================================

-- Enable RLS on all user tables
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if any (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their own subjects" ON subjects;
DROP POLICY IF EXISTS "Users can insert their own subjects" ON subjects;
DROP POLICY IF EXISTS "Users can update their own subjects" ON subjects;
DROP POLICY IF EXISTS "Users can delete their own subjects" ON subjects;

DROP POLICY IF EXISTS "Users can view their own questions" ON questions;
DROP POLICY IF EXISTS "Users can insert their own questions" ON questions;
DROP POLICY IF EXISTS "Users can update their own questions" ON questions;
DROP POLICY IF EXISTS "Users can delete their own questions" ON questions;

DROP POLICY IF EXISTS "Users can view their own quiz_sessions" ON quiz_sessions;
DROP POLICY IF EXISTS "Users can insert their own quiz_sessions" ON quiz_sessions;
DROP POLICY IF EXISTS "Users can update their own quiz_sessions" ON quiz_sessions;
DROP POLICY IF EXISTS "Users can delete their own quiz_sessions" ON quiz_sessions;

DROP POLICY IF EXISTS "Users can view their own quiz_answers" ON quiz_answers;
DROP POLICY IF EXISTS "Users can insert their own quiz_answers" ON quiz_answers;
DROP POLICY IF EXISTS "Users can update their own quiz_answers" ON quiz_answers;
DROP POLICY IF EXISTS "Users can delete their own quiz_answers" ON quiz_answers;

DROP POLICY IF EXISTS "Users can view their own units" ON units;
DROP POLICY IF EXISTS "Users can insert their own units" ON units;
DROP POLICY IF EXISTS "Users can update their own units" ON units;
DROP POLICY IF EXISTS "Users can delete their own units" ON units;

-- ============================================
-- SUBJECTS TABLE POLICIES
-- ============================================

-- SELECT: Users can only view their own subjects
CREATE POLICY "Users can view their own subjects"
ON subjects
FOR SELECT
USING (auth.uid() = user_id);

-- INSERT: Users can only insert subjects with their own user_id
-- The WITH CHECK clause automatically validates user_id matches authenticated user
CREATE POLICY "Users can insert their own subjects"
ON subjects
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can only update their own subjects
CREATE POLICY "Users can update their own subjects"
ON subjects
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can only delete their own subjects
CREATE POLICY "Users can delete their own subjects"
ON subjects
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- QUESTIONS TABLE POLICIES
-- ============================================

-- SELECT: Users can only view their own questions
CREATE POLICY "Users can view their own questions"
ON questions
FOR SELECT
USING (auth.uid() = user_id);

-- INSERT: Users can only insert questions with their own user_id
CREATE POLICY "Users can insert their own questions"
ON questions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can only update their own questions
CREATE POLICY "Users can update their own questions"
ON questions
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can only delete their own questions
CREATE POLICY "Users can delete their own questions"
ON questions
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- QUIZ_SESSIONS TABLE POLICIES
-- ============================================

-- SELECT: Users can only view their own quiz sessions
CREATE POLICY "Users can view their own quiz_sessions"
ON quiz_sessions
FOR SELECT
USING (auth.uid() = user_id);

-- INSERT: Users can only insert quiz sessions with their own user_id
CREATE POLICY "Users can insert their own quiz_sessions"
ON quiz_sessions
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can only update their own quiz sessions
CREATE POLICY "Users can update their own quiz_sessions"
ON quiz_sessions
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can only delete their own quiz sessions
CREATE POLICY "Users can delete their own quiz_sessions"
ON quiz_sessions
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- QUIZ_ANSWERS TABLE POLICIES
-- ============================================

-- SELECT: Users can only view their own quiz answers
CREATE POLICY "Users can view their own quiz_answers"
ON quiz_answers
FOR SELECT
USING (auth.uid() = user_id);

-- INSERT: Users can only insert quiz answers with their own user_id
CREATE POLICY "Users can insert their own quiz_answers"
ON quiz_answers
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can only update their own quiz answers
CREATE POLICY "Users can update their own quiz_answers"
ON quiz_answers
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can only delete their own quiz answers
CREATE POLICY "Users can delete their own quiz_answers"
ON quiz_answers
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- UNITS TABLE POLICIES
-- ============================================

-- SELECT: Users can only view their own units
CREATE POLICY "Users can view their own units"
ON units
FOR SELECT
USING (auth.uid() = user_id);

-- INSERT: Users can only insert units with their own user_id
CREATE POLICY "Users can insert their own units"
ON units
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- UPDATE: Users can only update their own units
CREATE POLICY "Users can update their own units"
ON units
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- DELETE: Users can only delete their own units
CREATE POLICY "Users can delete their own units"
ON units
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- VERIFICATION
-- ============================================

-- Verify RLS is enabled on all tables
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('subjects', 'questions', 'quiz_sessions', 'quiz_answers', 'units');

-- ✅ RLS policies configured for all user tables
