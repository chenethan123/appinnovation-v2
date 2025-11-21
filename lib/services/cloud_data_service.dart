import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../database/database_helper.dart';
import 'auth_service.dart';

/// Cloud-first data service - Supabase is the primary source of truth
/// Local SQLite is only used as a read-through cache for offline access
/// This prevents data leakage issues that can occur with local-first architecture
class CloudDataService {
  static final CloudDataService _instance = CloudDataService._internal();
  factory CloudDataService() => _instance;
  CloudDataService._internal();
  
  final _authService = AuthService();
  final _localDb = DatabaseHelper();
  
  // ============================================
  // SUBJECTS - Cloud First
  // ============================================
  
  /// Get all subjects for current user from Supabase (cloud-first)
  Future<List<Subject>> getAllSubjects() async {
    // Check if user is logged in AND userId is not null
    if (!_authService.isLoggedIn || _authService.userId == null) {
      print('⚠️ Not logged in or userId null - returning empty subjects');
      return [];
    }
    
    try {
      final userId = _authService.userId!;
      
      // Fetch from Supabase (primary source)
      final response = await supabase
        .from('subjects')
        .select('*')
        .eq('user_id', userId)
        .order('name', ascending: true);
      
      final subjects = (response as List)
        .map((json) => Subject.fromMap(json as Map<String, dynamic>))
        .toList();
      
      print('✅ Fetched ${subjects.length} subjects from cloud for user ${userId.substring(0, 8)}...');
      
      // Update local cache for offline access
      await _updateLocalCache(subjects);
      
      return subjects;
    } catch (e) {
      print('❌ Cloud fetch failed: $e - falling back to local cache');
      // Fallback to local cache if cloud fails (but only if we have a userId)
      if (_authService.userId != null) {
        return await _localDb.getAllSubjects();
      }
      return [];
    }
  }
  
  /// Create a new subject in Supabase (cloud-first)
  Future<int> createSubject(Subject subject) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to create subjects');
    }
    
    try {
      // Insert into Supabase first
      final response = await supabase
        .from('subjects')
        .insert({
          'user_id': _authService.userId,
          'name': subject.name,
          'description': subject.description,
          'color': subject.color,
          'is_active': subject.isActive,
          'total_questions': subject.totalQuestions,
          'correct_answers': subject.correctAnswers,
          'difficulty_weight': subject.difficultyWeight,
          'created_at': subject.createdAt.toIso8601String(),
          'updated_at': subject.updatedAt.toIso8601String(),
        })
        .select()
        .single();
      
      print('✅ Subject created in cloud: ${response['name']}');
      
      // Cache locally
      final cloudSubject = Subject.fromMap(response as Map<String, dynamic>);
      await _localDb.insertSubject(cloudSubject);
      
      // Return a valid local ID (use hash of cloud ID for now)
      return response['id'].hashCode.abs();
    } catch (e) {
      print('❌ Failed to create subject in cloud: $e');
      rethrow;
    }
  }
  
  /// Update subject in Supabase (cloud-first)
  Future<void> updateSubject(Subject subject) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to update subjects');
    }
    
    try {
      await supabase
        .from('subjects')
        .update({
          'name': subject.name,
          'description': subject.description,
          'color': subject.color,
          'is_active': subject.isActive,
          'total_questions': subject.totalQuestions,
          'correct_answers': subject.correctAnswers,
          'difficulty_weight': subject.difficultyWeight,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', _authService.userId!)
        .eq('name', subject.name);
      
      print('✅ Subject updated in cloud: ${subject.name}');
      
      // Update local cache
      await _localDb.updateSubject(subject);
    } catch (e) {
      print('❌ Failed to update subject in cloud: $e');
      rethrow;
    }
  }
  
  /// Delete subject from Supabase (cloud-first)
  Future<void> deleteSubject(int id) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to delete subjects');
    }
    
    try {
      // Get subject name first
      final subject = await _localDb.getSubjectById(id);
      if (subject == null) return;
      
      await supabase
        .from('subjects')
        .delete()
        .eq('user_id', _authService.userId!)
        .eq('name', subject.name);
      
      print('✅ Subject deleted from cloud: ${subject.name}');
      
      // Delete from local cache
      await _localDb.deleteSubject(id);
    } catch (e) {
      print('❌ Failed to delete subject from cloud: $e');
      rethrow;
    }
  }
  
  // ============================================
  // QUESTIONS - Cloud First
  // ============================================
  
  /// Get questions for a subject from Supabase (cloud-first)
  Future<List<Question>> getQuestionsForSubject(String subjectName) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Not logged in - returning empty questions');
      return [];
    }
    
    try {
      final response = await supabase
        .from('questions')
        .select('*')
        .eq('user_id', _authService.userId!)
        .eq('subject_name', subjectName)
        .order('created_at', ascending: false);
      
      final questions = (response as List)
        .map((json) => Question.fromMap(json as Map<String, dynamic>))
        .toList();
      
      print('✅ Fetched ${questions.length} questions from cloud');
      return questions;
    } catch (e) {
      print('❌ Cloud fetch failed for questions: $e');
      return [];
    }
  }
  
  /// Create question in Supabase (cloud-first)
  Future<void> createQuestion(Question question) async {
    if (!_authService.isLoggedIn) {
      throw Exception('Must be logged in to create questions');
    }
    
    try {
      await supabase
        .from('questions')
        .insert({
          'user_id': _authService.userId,
          'subject_id': question.subjectId,
          'subject_name': question.subjectName,
          'question_text': question.questionText,
          'correct_answer': question.correctAnswer,
          'explanation': question.explanation,
          'difficulty': question.difficulty,
          'created_at': question.createdAt.toIso8601String(),
        });
      
      print('✅ Question created in cloud');
      
      // Cache locally
      await _localDb.insertQuestion(question);
    } catch (e) {
      print('❌ Failed to create question in cloud: $e');
      rethrow;
    }
  }
  
  // ============================================
  // HELPER METHODS
  // ============================================
  
  /// Update local cache with cloud data
  Future<void> _updateLocalCache(List<Subject> subjects) async {
    try {
      for (var subject in subjects) {
        await _localDb.insertSubject(subject);
      }
    } catch (e) {
      print('⚠️ Failed to update local cache: $e');
    }
  }
  
  /// Clear all local cache (for logout)
  Future<void> clearLocalCache() async {
    try {
      await _localDb.clearAllData();
      print('✅ Local cache cleared');
    } catch (e) {
      print('❌ Failed to clear local cache: $e');
    }
  }
}
