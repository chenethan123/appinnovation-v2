-- ============================================
-- COURSE CATALOG TABLE - SCHEMA CREATION
-- ============================================
-- This creates a centralized course catalog that all users can browse
-- Users select from this catalog to create their own subjects
-- 
-- Run this first, then run the seed data script
-- ============================================

-- Drop existing table if it exists (optional - comment out for production)
DROP TABLE IF EXISTS course_catalog CASCADE;

-- Create course_catalog table
CREATE TABLE course_catalog (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id TEXT NOT NULL UNIQUE,
  subject_name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT true,
  display_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_course_catalog_course_id ON course_catalog(course_id);
CREATE INDEX idx_course_catalog_category ON course_catalog(category);
CREATE INDEX idx_course_catalog_subject_name ON course_catalog(subject_name);
CREATE INDEX idx_course_catalog_is_active ON course_catalog(is_active);
CREATE INDEX idx_course_catalog_display_order ON course_catalog(display_order);

-- Enable Row Level Security
ALTER TABLE course_catalog ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view active courses" ON course_catalog;
DROP POLICY IF EXISTS "Service role can insert courses" ON course_catalog;
DROP POLICY IF EXISTS "Service role can update courses" ON course_catalog;
DROP POLICY IF EXISTS "Service role can delete courses" ON course_catalog;

-- RLS Policies: Public read, admin/service role write
-- All authenticated users can view active courses
CREATE POLICY "Anyone can view active courses" ON course_catalog
  FOR SELECT 
  USING (is_active = true);

-- Only service role can insert new courses (admin access)
CREATE POLICY "Service role can insert courses" ON course_catalog
  FOR INSERT 
  WITH CHECK (auth.role() = 'service_role');

-- Only service role can update courses (admin access)
CREATE POLICY "Service role can update courses" ON course_catalog
  FOR UPDATE 
  USING (auth.role() = 'service_role');

-- Only service role can delete courses (admin access)
CREATE POLICY "Service role can delete courses" ON course_catalog
  FOR DELETE 
  USING (auth.role() = 'service_role');

-- Create trigger for updated_at timestamp
CREATE OR REPLACE FUNCTION update_course_catalog_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_course_catalog_updated_at ON course_catalog;

CREATE TRIGGER update_course_catalog_updated_at 
  BEFORE UPDATE ON course_catalog
  FOR EACH ROW 
  EXECUTE FUNCTION update_course_catalog_updated_at();

-- Create view for easy querying by category
CREATE OR REPLACE VIEW course_catalog_by_category AS
SELECT 
  category,
  COUNT(*) as course_count,
  array_agg(subject_name ORDER BY subject_name) as courses
FROM course_catalog
WHERE is_active = true
GROUP BY category
ORDER BY category;

-- ============================================
-- VERIFICATION QUERIES
-- ============================================

-- Verify table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'course_catalog'
ORDER BY ordinal_position;

-- Verify RLS is enabled
SELECT 
  tablename,
  rowsecurity as "RLS Enabled"
FROM pg_tables
WHERE schemaname = 'public' AND tablename = 'course_catalog';

-- Verify policies exist (should be 4)
SELECT 
  policyname,
  cmd as command,
  qual as using_expression
FROM pg_policies
WHERE tablename = 'course_catalog'
ORDER BY policyname;

-- ✅ SCHEMA CREATION COMPLETE
-- Next: Run supabase_course_catalog_seed.sql to populate with 127 courses
