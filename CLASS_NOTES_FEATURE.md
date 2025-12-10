# Class Notes Feature - Documentation

## Overview

The Class Notes feature allows users to upload their personal class notes and generate customized quiz questions from them using AI. This enables highly personalized learning experiences tailored to each student's specific course material.

## Features

### 1. Upload Class Notes
- **Manual Entry**: Type or paste notes directly into the app
- **File Upload**: Upload `.txt`, `.md`, `.pdf`, `.doc`, `.docx` files (text files are automatically read)
- **Organization**: Notes are organized by subject
- **Metadata**: Track file size, creation date, and question count

### 2. AI-Powered Question Generation
- **ChatGPT Integration**: Uses GPT-4o-mini to generate questions based on note content
- **Customizable Parameters**:
  - Question count (3-10 questions)
  - Difficulty level (easy, medium, hard)
- **Context-Aware**: Questions are generated specifically from the provided notes, ensuring relevance

### 3. Question Management
- Generated questions are stored per user with proper isolation
- Questions are linked to their source class note via `class_note_id`
- Questions have a `source_type` field indicating they came from class notes
- Track how many questions were generated from each note

## Database Schema

### New Table: `class_notes`
```sql
CREATE TABLE class_notes (
  id UUID PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  subject_name TEXT NOT NULL,
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  file_name TEXT,
  file_size INTEGER,
  created_at TIMESTAMP WITH TIME ZONE,
  updated_at TIMESTAMP WITH TIME ZONE,
  is_active BOOLEAN DEFAULT true,
  question_count INTEGER DEFAULT 0
);
```

### Updates to `questions` Table
```sql
ALTER TABLE questions 
ADD COLUMN class_note_id UUID REFERENCES class_notes(id);

ALTER TABLE questions
ADD COLUMN source_type TEXT DEFAULT 'ai_generated' 
CHECK (source_type IN ('ai_generated', 'class_notes', 'imported', 'manual'));
```

## File Structure

### Models
- `lib/models/class_note.dart` - ClassNote data model
- `lib/models/question.dart` - Updated with class_note_id and source_type fields

### Services
- `lib/services/class_note_service.dart` - CRUD operations and AI question generation
  - `getAllClassNotes()` - Fetch all user's notes
  - `getClassNotesBySubject()` - Filter by subject
  - `createClassNote()` - Upload new note
  - `updateClassNote()` - Edit existing note
  - `deleteClassNote()` - Soft delete note
  - `generateQuestionsFromNote()` - AI question generation

### Providers (Riverpod)
- `lib/providers/class_note_provider.dart` - State management for class notes

### UI Screens
- `lib/screens/class_notes_screen.dart` - Main screen showing all notes
- `lib/screens/add_class_note_screen.dart` - Upload/create new note
- `lib/screens/class_note_detail_screen.dart` - View note details and generate questions

### Database Migrations
- `supabase/migrations/20251210090100_create_class_notes.sql` - Schema creation with RLS policies

## Security

### Row Level Security (RLS)
All class notes table operations are protected by RLS policies:
- Users can only view their own notes
- Users can only create notes with their own user_id
- Users can only update/delete their own notes
- Enforced at the database level via Supabase

### User Isolation
- All operations filter by `auth.uid()`
- Questions generated from notes are linked to both the note and the user
- No cross-user data leakage

## Usage Flow

### 1. Upload Class Notes
```
Home Screen → Class Notes → Add Note Button
1. Select subject from dropdown
2. Enter title
3. Either:
   - Upload file (txt, md, pdf, doc, docx)
   - Type/paste content manually
4. Save
```

### 2. Generate Questions
```
Class Notes → Select Note → Generate Questions Button
1. Choose number of questions (3-10)
2. Select difficulty (easy/medium/hard)
3. Click "Generate"
4. Questions are created and saved automatically
```

### 3. Take Quiz with Generated Questions
```
Home Screen → Subject Card → Generate MCQ
- Questions pool now includes both:
  - AI-generated general questions
  - Questions from your class notes
```

## AI Prompt Engineering

The AI question generation uses a specialized prompt that:
1. Emphasizes generating questions ONLY from provided notes
2. Prevents adding external knowledge not in the notes
3. Ensures questions are directly answerable from the content
4. Maintains specified difficulty level
5. Returns structured JSON for easy parsing

Example prompt structure:
```
Subject: [Subject Name]
Difficulty: [Difficulty Level]

Class Notes:
"""
[Note Content]
"""

Generate exactly N questions based ONLY on these notes...
[Detailed instructions]
```

## Dependencies Added

```yaml
dependencies:
  file_picker: ^6.1.1  # For file upload functionality
```

## API Integration

### OpenAI ChatGPT
- Model: `gpt-4o-mini`
- Temperature: 0.7 (balanced creativity)
- Max Tokens: 2000
- Format: JSON array of questions

### Supabase
- Real-time data sync
- User authentication
- Row-level security
- Cloud storage

## Future Enhancements

1. **OCR Support**: Automatically extract text from images/scanned notes
2. **PDF Text Extraction**: Better handling of PDF files
3. **Note Sharing**: Allow students to share notes with classmates
4. **Collaborative Notes**: Multiple users can contribute to shared notes
5. **Version Control**: Track changes to notes over time
6. **Tags & Categories**: Better organization with tags
7. **Search**: Full-text search across all notes
8. **Export**: Export questions to external formats (CSV, JSON, etc.)

## Testing

### Manual Testing Steps
1. Create a new note with sample content
2. Generate 5 medium difficulty questions
3. Verify questions are relevant to note content
4. Check that questions appear in quiz pool
5. Verify question count updates on note
6. Test file upload with .txt file
7. Test note deletion
8. Test with multiple subjects

### Database Testing
```bash
# Verify RLS policies
SELECT * FROM class_notes;  # Should only show your notes

# Check question linking
SELECT q.*, cn.title 
FROM questions q 
JOIN class_notes cn ON q.class_note_id = cn.id 
WHERE q.source_type = 'class_notes';
```

## Troubleshooting

### Common Issues

**1. File upload not working**
- Ensure file_picker dependency is installed: `flutter pub get`
- Check file permissions on device
- Only .txt and .md files auto-read content

**2. Questions not generating**
- Verify OpenAI API key is configured
- Check internet connection
- Ensure note content is at least 50 characters
- Review console logs for AI errors

**3. Questions not appearing in quiz**
- Refresh subject list
- Verify questions were saved to database
- Check that subject name matches exactly

**4. RLS policy errors**
- User must be authenticated
- Verify user_id is set correctly
- Check Supabase dashboard for policy issues

## Performance Considerations

- **Note Size**: Larger notes (>10KB) may take longer to process
- **Question Generation**: Takes 5-15 seconds depending on count
- **Caching**: Notes are cached locally after first fetch
- **Pagination**: Consider adding pagination if user has >100 notes

## Accessibility

- All screens support screen readers
- Proper semantic labels on buttons and form fields
- High contrast text for readability
- Clear error messages and validation feedback

## Compliance

- **User Data**: All notes stored encrypted in Supabase
- **Privacy**: Notes are never shared without explicit permission
- **GDPR**: Users can delete their notes at any time
- **Educational Use**: Questions are for personal learning only

---

**Created**: December 10, 2025  
**Branch**: `specific-tests`  
**Status**: Ready for testing and feedback
