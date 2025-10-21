-- FormulaQuizzer Cross-Device Sync Database Schema
-- Run this in Supabase SQL Editor: https://supabase.com/dashboard/project/dsknaaziujrfavhaschj/sql

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Note: We use Supabase's built-in auth.users table for user management
-- No need to create a custom users table

-- ============================================
-- Subjects Table (Synced across devices)
-- ============================================
CREATE TABLE IF NOT EXISTS subjects (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  color TEXT NOT NULL DEFAULT '#6366f1',
  is_active BOOLEAN DEFAULT true,
  total_questions INTEGER DEFAULT 0,
  correct_answers INTEGER DEFAULT 0,
  difficulty_weight REAL DEFAULT 0.5,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  device_id TEXT,
  sync_version INTEGER DEFAULT 1,
  CONSTRAINT unique_user_subject UNIQUE(user_id, name)
);

CREATE INDEX idx_subjects_user_id ON subjects(user_id);
CREATE INDEX idx_subjects_is_active ON subjects(is_active);
CREATE INDEX idx_subjects_updated_at ON subjects(updated_at);

-- ============================================
-- Questions Table (Synced across devices)
-- ============================================
CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  options JSONB NOT NULL,
  correct_answer TEXT NOT NULL,
  explanation TEXT NOT NULL,
  difficulty TEXT NOT NULL CHECK (difficulty IN ('easy', 'medium', 'hard')),
  category TEXT,
  is_from_ai BOOLEAN DEFAULT false,
  source TEXT,
  source_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  device_id TEXT,
  sync_version INTEGER DEFAULT 1
);

CREATE INDEX idx_questions_user_id ON questions(user_id);
CREATE INDEX idx_questions_subject_id ON questions(subject_id);
CREATE INDEX idx_questions_difficulty ON questions(difficulty);
CREATE INDEX idx_questions_created_at ON questions(created_at);

-- ============================================
-- Quiz Sessions Table (Synced across devices)
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_sessions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id UUID REFERENCES subjects(id) ON DELETE SET NULL,
  total_questions INTEGER NOT NULL,
  correct_answers INTEGER NOT NULL,
  score INTEGER NOT NULL,
  started_at TIMESTAMP WITH TIME ZONE NOT NULL,
  completed_at TIMESTAMP WITH TIME ZONE,
  device_id TEXT,
  sync_version INTEGER DEFAULT 1
);

CREATE INDEX idx_quiz_sessions_user_id ON quiz_sessions(user_id);
CREATE INDEX idx_quiz_sessions_subject_id ON quiz_sessions(subject_id);
CREATE INDEX idx_quiz_sessions_started_at ON quiz_sessions(started_at);

-- ============================================
-- Quiz Answers Table
-- ============================================
CREATE TABLE IF NOT EXISTS quiz_answers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id UUID NOT NULL REFERENCES quiz_sessions(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES questions(id) ON DELETE CASCADE,
  user_answer TEXT NOT NULL,
  is_correct BOOLEAN NOT NULL,
  answered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_quiz_answers_user_id ON quiz_answers(user_id);
CREATE INDEX idx_quiz_answers_session_id ON quiz_answers(session_id);
CREATE INDEX idx_quiz_answers_question_id ON quiz_answers(question_id);

-- ============================================
-- Courses Table (Predefined courses)
-- ============================================
CREATE TABLE IF NOT EXISTS courses (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  course_id TEXT NOT NULL UNIQUE,
  subject_name TEXT NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  is_custom BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_courses_course_id ON courses(course_id);
CREATE INDEX idx_courses_category ON courses(category);
CREATE INDEX idx_courses_subject_name ON courses(subject_name);

-- ============================================
-- Units Table (Subject organization)
-- ============================================
CREATE TABLE IF NOT EXISTS units (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_id UUID NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  description TEXT,
  order_index INTEGER NOT NULL,
  start_date TIMESTAMP WITH TIME ZONE,
  end_date TIMESTAMP WITH TIME ZONE,
  is_current BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  sync_version INTEGER DEFAULT 1
);

CREATE INDEX idx_units_user_id ON units(user_id);
CREATE INDEX idx_units_subject_id ON units(subject_id);
CREATE INDEX idx_units_order_index ON units(order_index);

-- ============================================
-- Row Level Security (RLS) Policies
-- ============================================

-- Enable RLS on all tables
ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE quiz_answers ENABLE ROW LEVEL SECURITY;
ALTER TABLE units ENABLE ROW LEVEL SECURITY;

-- Subjects policies
CREATE POLICY "Users can view own subjects" ON subjects
  FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own subjects" ON subjects
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own subjects" ON subjects
  FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own subjects" ON subjects
  FOR DELETE USING (auth.uid()::text = user_id::text);

-- Questions policies
CREATE POLICY "Users can view own questions" ON questions
  FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own questions" ON questions
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own questions" ON questions
  FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own questions" ON questions
  FOR DELETE USING (auth.uid()::text = user_id::text);

-- Quiz sessions policies
CREATE POLICY "Users can view own sessions" ON quiz_sessions
  FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own sessions" ON quiz_sessions
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own sessions" ON quiz_sessions
  FOR UPDATE USING (auth.uid()::text = user_id::text);

-- Quiz answers policies
CREATE POLICY "Users can view own answers" ON quiz_answers
  FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own answers" ON quiz_answers
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

-- Units policies
CREATE POLICY "Users can view own units" ON units
  FOR SELECT USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can insert own units" ON units
  FOR INSERT WITH CHECK (auth.uid()::text = user_id::text);

CREATE POLICY "Users can update own units" ON units
  FOR UPDATE USING (auth.uid()::text = user_id::text);

CREATE POLICY "Users can delete own units" ON units
  FOR DELETE USING (auth.uid()::text = user_id::text);

-- Courses are public (read-only)
CREATE POLICY "Anyone can view courses" ON courses
  FOR SELECT USING (true);

-- ============================================
-- Functions for updated_at timestamp
-- ============================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create triggers for updated_at
CREATE TRIGGER update_subjects_updated_at BEFORE UPDATE ON subjects
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- Sample Data (Optional - for testing)
-- ============================================

-- Insert some sample courses (you can skip this if you already have courses)
-- INSERT INTO courses (course_id, subject_name, category, description) VALUES
--   ('AP-CALC-AB', 'AP Calculus AB', 'Mathematics', 'Advanced Placement Calculus AB'),
--   ('AP-PHYS-1', 'AP Physics 1', 'Science', 'Algebra-based physics'),
--   ('AP-CHEM', 'AP Chemistry', 'Science', 'Advanced chemistry course');

-- ============================================
-- Useful Views (Optional)
-- ============================================

-- View for subject statistics
CREATE OR REPLACE VIEW subject_stats AS
SELECT 
  s.id,
  s.user_id,
  s.name,
  s.total_questions,
  s.correct_answers,
  CASE 
    WHEN s.total_questions > 0 
    THEN ROUND((s.correct_answers::numeric / s.total_questions::numeric * 100), 2)
    ELSE 0 
  END as accuracy_percentage,
  COUNT(DISTINCT qs.id) as quiz_count,
  MAX(qs.started_at) as last_quiz_at
FROM subjects s
LEFT JOIN quiz_sessions qs ON s.id = qs.subject_id
GROUP BY s.id, s.user_id, s.name, s.total_questions, s.correct_answers;

-- ============================================
-- Database Setup Complete!
-- ============================================

-- Next Steps:
-- 1. Run this SQL in Supabase SQL Editor
-- 2. Verify tables created successfully
-- 3. Test authentication with Supabase Auth
-- 4. Connect Flutter app to Supabase
