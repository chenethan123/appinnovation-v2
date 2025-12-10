import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/class_note.dart';
import '../services/class_note_service.dart';

// Provider for ClassNoteService
final classNoteServiceProvider = Provider((ref) => ClassNoteService());

// Provider for all class notes
final classNotesProvider = StateNotifierProvider<ClassNoteNotifier, AsyncValue<List<ClassNote>>>((ref) {
  return ClassNoteNotifier(ref.read(classNoteServiceProvider));
});

// Provider for class notes filtered by subject
final classNotesBySubjectProvider = FutureProvider.family<List<ClassNote>, String>((ref, subjectName) async {
  final service = ref.read(classNoteServiceProvider);
  return await service.getClassNotesBySubject(subjectName);
});

/// State notifier for managing class notes
class ClassNoteNotifier extends StateNotifier<AsyncValue<List<ClassNote>>> {
  final ClassNoteService _service;

  ClassNoteNotifier(this._service) : super(const AsyncValue.loading()) {
    loadClassNotes();
  }

  /// Load all class notes for the current user
  Future<void> loadClassNotes() async {
    state = const AsyncValue.loading();
    try {
      final notes = await _service.getAllClassNotes();
      state = AsyncValue.data(notes);
      print('📚 Loaded ${notes.length} class notes');
    } catch (error, stackTrace) {
      print('❌ Error loading class notes: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Create a new class note
  Future<String?> createNote({
    required String subjectName,
    required String title,
    required String content,
    String? fileName,
    int? fileSize,
  }) async {
    try {
      final note = ClassNote(
        userId: '', // Service will set this
        subjectName: subjectName,
        title: title,
        content: content,
        fileName: fileName,
        fileSize: fileSize,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final noteId = await _service.createClassNote(note);
      
      // Reload notes after creation
      await loadClassNotes();
      
      print('✅ Note created successfully: $title');
      return noteId;
    } catch (e) {
      print('❌ Error creating note: $e');
      return null;
    }
  }

  /// Update an existing class note
  Future<bool> updateNote(ClassNote note) async {
    try {
      await _service.updateClassNote(note);
      
      // Reload notes after update
      await loadClassNotes();
      
      print('✅ Note updated successfully: ${note.title}');
      return true;
    } catch (e) {
      print('❌ Error updating note: $e');
      return false;
    }
  }

  /// Delete a class note (soft delete)
  Future<bool> deleteNote(String noteId) async {
    try {
      await _service.deleteClassNote(noteId);
      
      // Reload notes after deletion
      await loadClassNotes();
      
      print('✅ Note deleted successfully');
      return true;
    } catch (e) {
      print('❌ Error deleting note: $e');
      return false;
    }
  }

  /// Generate questions from a class note
  Future<List<Map<String, dynamic>>?> generateQuestions({
    required String noteId,
    required String noteContent,
    required String subjectName,
    int questionCount = 5,
    String difficulty = 'medium',
  }) async {
    try {
      print('🤖 Generating $questionCount questions from note...');
      
      final questions = await _service.generateQuestionsFromNote(
        noteId: noteId,
        noteContent: noteContent,
        subjectName: subjectName,
        questionCount: questionCount,
        difficulty: difficulty,
      );
      
      // Increment question count for this note
      if (questions.isNotEmpty) {
        await _service.incrementQuestionCount(noteId, questions.length);
        await loadClassNotes(); // Reload to show updated count
      }
      
      print('✅ Generated ${questions.length} questions successfully');
      return questions;
    } catch (e) {
      print('❌ Error generating questions: $e');
      return null;
    }
  }

  /// Get a specific note by ID
  Future<ClassNote?> getNoteById(String noteId) async {
    try {
      return await _service.getClassNoteById(noteId);
    } catch (e) {
      print('❌ Error fetching note: $e');
      return null;
    }
  }

  /// Refresh notes
  Future<void> refresh() async {
    await loadClassNotes();
  }
}
