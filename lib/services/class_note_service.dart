import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/class_note.dart';
import '../models/question.dart';
import 'auth_service.dart';
import 'package:dart_openai/dart_openai.dart';

/// Service for managing user-uploaded class notes and generating questions from them
class ClassNoteService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthService _authService = AuthService();

  // ============================================
  // CLASS NOTE CRUD OPERATIONS
  // ============================================

  /// Get all class notes for the current user
  Future<List<ClassNote>> getAllClassNotes() async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to access class notes');
    }

    try {
      final response = await _supabase
          .from('class_notes')
          .select('*')
          .eq('user_id', _authService.userId!)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClassNote.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching class notes: $e');
      rethrow;
    }
  }

  /// Get class notes for a specific subject
  Future<List<ClassNote>> getClassNotesBySubject(String subjectName) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to access class notes');
    }

    try {
      final response = await _supabase
          .from('class_notes')
          .select('*')
          .eq('user_id', _authService.userId!)
          .eq('subject_name', subjectName)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ClassNote.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching class notes for $subjectName: $e');
      rethrow;
    }
  }

  /// Get a single class note by ID
  Future<ClassNote?> getClassNoteById(String noteId) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to access class notes');
    }

    try {
      final response = await _supabase
          .from('class_notes')
          .select('*')
          .eq('id', noteId)
          .eq('user_id', _authService.userId!)
          .single();

      return ClassNote.fromMap(response as Map<String, dynamic>);
    } catch (e) {
      print('❌ Error fetching class note $noteId: $e');
      return null;
    }
  }

  /// Create a new class note
  Future<String> createClassNote(ClassNote note) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to create class notes');
    }

    try {
      final response = await _supabase
          .from('class_notes')
          .insert({
            'user_id': _authService.userId,
            'subject_name': note.subjectName,
            'title': note.title,
            'content': note.content,
            'file_name': note.fileName,
            'file_size': note.fileSize,
            'is_active': true,
            'question_count': 0,
          })
          .select('id')
          .single();

      final noteId = response['id'] as String;
      print('✅ Class note created: ${note.title} (ID: $noteId)');
      return noteId;
    } catch (e) {
      print('❌ Error creating class note: $e');
      rethrow;
    }
  }

  /// Update an existing class note
  Future<void> updateClassNote(ClassNote note) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to update class notes');
    }

    if (note.id == null) {
      throw Exception('Note ID is required for update');
    }

    try {
      await _supabase
          .from('class_notes')
          .update({
            'subject_name': note.subjectName,
            'title': note.title,
            'content': note.content,
            'file_name': note.fileName,
            'file_size': note.fileSize,
            'is_active': note.isActive,
            'question_count': note.questionCount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', note.id!)
          .eq('user_id', _authService.userId!);

      print('✅ Class note updated: ${note.title}');
    } catch (e) {
      print('❌ Error updating class note: $e');
      rethrow;
    }
  }

  /// Delete a class note (soft delete - marks as inactive)
  Future<void> deleteClassNote(String noteId) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to delete class notes');
    }

    try {
      await _supabase
          .from('class_notes')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', noteId)
          .eq('user_id', _authService.userId!);

      print('✅ Class note deleted: $noteId');
    } catch (e) {
      print('❌ Error deleting class note: $e');
      rethrow;
    }
  }

  /// Permanently delete a class note
  Future<void> permanentlyDeleteClassNote(String noteId) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to delete class notes');
    }

    try {
      await _supabase
          .from('class_notes')
          .delete()
          .eq('id', noteId)
          .eq('user_id', _authService.userId!);

      print('✅ Class note permanently deleted: $noteId');
    } catch (e) {
      print('❌ Error permanently deleting class note: $e');
      rethrow;
    }
  }

  // ============================================
  // QUESTION GENERATION FROM CLASS NOTES
  // ============================================

  /// Generate questions from a class note using ChatGPT
  /// Returns a list of generated questions
  Future<List<Map<String, dynamic>>> generateQuestionsFromNote({
    required String noteId,
    required String noteContent,
    required String subjectName,
    int questionCount = 5,
    String difficulty = 'medium',
  }) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to generate questions');
    }

    try {
      print('🤖 Generating $questionCount questions from class note...');

      // Create a specialized prompt for class note-based questions
      final prompt = '''
You are an expert educator creating quiz questions based on student class notes.

Subject: $subjectName
Difficulty: $difficulty

Class Notes:
"""
$noteContent
"""

Generate exactly $questionCount multiple-choice questions based ONLY on the content in these class notes. Each question should:
1. Test understanding of key concepts from the notes
2. Have 4 answer options (A, B, C, D)
3. Include a clear explanation referencing the notes
4. Be at $difficulty difficulty level

Format your response as a JSON array with this structure:
[
  {
    "question": "Question text here?",
    "options": ["A) Option 1", "B) Option 2", "C) Option 3", "D) Option 4"],
    "correct_answer": "A) Option 1",
    "explanation": "Explanation referencing the class notes",
    "difficulty": "$difficulty"
  }
]

IMPORTANT: 
- Questions must be directly answerable from the provided notes
- Do not add external knowledge not in the notes
- Return ONLY the JSON array, no additional text
''';

      // Call OpenAI API
      final chatCompletion = await OpenAI.instance.chat.create(
        model: 'gpt-4o-mini',
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(
                'You are an expert educator who creates high-quality quiz questions from class notes.',
              ),
            ],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(prompt),
            ],
          ),
        ],
        temperature: 0.7,
        maxTokens: 2000,
      );

      // Extract and parse response
      final responseText = chatCompletion.choices.first.message.content?.first.text ?? '';
      print('📝 Raw AI response: ${responseText.substring(0, responseText.length > 200 ? 200 : responseText.length)}...');

      // Clean the response (remove markdown code blocks if present)
      String cleanedJson = responseText.trim();
      if (cleanedJson.startsWith('```json')) {
        cleanedJson = cleanedJson.replaceFirst('```json', '').trim();
      }
      if (cleanedJson.startsWith('```')) {
        cleanedJson = cleanedJson.replaceFirst('```', '').trim();
      }
      if (cleanedJson.endsWith('```')) {
        cleanedJson = cleanedJson.substring(0, cleanedJson.length - 3).trim();
      }

      // Parse JSON
      final List<dynamic> jsonResponse = [];
      try {
        final parsed = parseJson(cleanedJson);
        if (parsed is List) {
          jsonResponse.addAll(parsed);
        }
      } catch (e) {
        print('❌ JSON parse error: $e');
        print('Failed JSON: $cleanedJson');
        throw Exception('Failed to parse AI response as JSON');
      }

      if (jsonResponse.isEmpty) {
        throw Exception('No questions generated from AI response');
      }

      print('✅ Generated ${jsonResponse.length} questions from class notes');
      return jsonResponse.cast<Map<String, dynamic>>();
    } catch (e) {
      print('❌ Error generating questions from note: $e');
      rethrow;
    }
  }

  /// Helper method to parse JSON (handles both dart:convert and dynamic parsing)
  dynamic parseJson(String jsonString) {
    // Try standard JSON parsing first
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      // If that fails, try a more lenient approach
      print('⚠️ Standard JSON parse failed, trying lenient parse: $e');
      rethrow;
    }
  }

  /// Increment the question count for a class note
  Future<void> incrementQuestionCount(String noteId, int increment) async {
    if (!_authService.isLoggedIn) return;

    try {
      // Get current note
      final note = await getClassNoteById(noteId);
      if (note == null) return;

      // Update question count
      await _supabase
          .from('class_notes')
          .update({
            'question_count': note.questionCount + increment,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', noteId)
          .eq('user_id', _authService.userId!);

      print('✅ Question count updated for note $noteId: +$increment');
    } catch (e) {
      print('❌ Error updating question count: $e');
    }
  }

  /// Get questions generated from a specific class note
  Future<List<Question>> getQuestionsFromNote(String noteId) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to access questions');
    }

    try {
      final response = await _supabase
          .from('questions')
          .select('*')
          .eq('user_id', _authService.userId!)
          .eq('class_note_id', noteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => Question.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('❌ Error fetching questions for note $noteId: $e');
      rethrow;
    }
  }
}

// Import for JSON parsing
import 'dart:convert';
