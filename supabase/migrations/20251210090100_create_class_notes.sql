-- ============================================
-- CREATE CLASS_NOTES TABLE
-- ============================================
-- This migration creates a table to store user-uploaded class notes
-- that can be used to generate customized questions
-- ============================================

-- Create class_notes table
CREATE TABLE IF NOT EXISTS class_notes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  subject_name TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  file_name TEXT,
  file_size INTEGER,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  question_count INTEGER DEFAULT 0, -- Track how many questions generated from this note
  CONSTRAINT class_notes_user_title_unique UNIQUE(user_id, title)
);

-- Create index on user_id and subject_name for faster queries
CREATE INDEX idx_class_notes_user_id ON class_notes(user_id);
CREATE INDEX idx_class_notes_subject_name ON class_notes(subject_name);
CREATE INDEX idx_class_notes_user_subject ON class_notes(user_id, subject_name);

-- Enable RLS
ALTER TABLE class_notes ENABLE ROW LEVEL SECURITY;

-- RLS Policies for class_notes
CREATE POLICY "Users can view their own class_notes"
ON class_notes
FOR SELECT
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own class_notes"
ON class_notes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own class_notes"
ON class_notes
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own class_notes"
ON class_notes
FOR DELETE
USING (auth.uid() = user_id);

-- ============================================
-- ADD CLASS_NOTE_ID TO QUESTIONS TABLE
-- ============================================
-- Link questions to the class notes they were generated from

ALTER TABLE questions 
ADD COLUMN IF NOT EXISTS class_note_id UUID REFERENCES class_notes(id) ON DELETE SET NULL;

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_questions_class_note_id ON questions(class_note_id);

-- Add a flag to indicate if question is from class notes vs general AI
ALTER TABLE questions
ADD COLUMN IF NOT EXISTS source_type TEXT DEFAULT 'ai_generated' 
CHECK (source_type IN ('ai_generated', 'class_notes', 'imported', 'manual'));

-- ============================================
-- VERIFICATION
-- ============================================

COMMENT ON TABLE class_notes IS 'Stores user-uploaded class notes for customized question generation';
COMMENT ON COLUMN class_notes.content IS 'Full text content of the class notes';
COMMENT ON COLUMN class_notes.question_count IS 'Number of questions generated from this note';
COMMENT ON COLUMN questions.class_note_id IS 'Links question to source class note if applicable';
COMMENT ON COLUMN questions.source_type IS 'Indicates origin of question: ai_generated, class_notes, imported, or manual';

-- ✅ Class notes table and question linking created successfully
