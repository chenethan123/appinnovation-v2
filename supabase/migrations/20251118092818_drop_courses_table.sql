-- ============================================
-- DROP UNUSED COURSES TABLE
-- ============================================
-- The 'courses' table is unused (0 API calls, 0 rows)
-- App uses local SQLite 'courses' table instead
-- New 'course_catalog' table replaces this functionality
-- ============================================

-- Drop the unused courses table
DROP TABLE IF EXISTS courses CASCADE;

-- Verify it's gone (should return no results)
SELECT tablename 
FROM pg_tables 
WHERE schemaname = 'public' AND tablename = 'courses';

-- ✅ courses table dropped successfully
