import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../database/database_helper.dart';
import 'auth_service.dart';

/// Sync service for uploading/downloading data between local SQLite and Supabase cloud
/// Implements offline-first architecture with bi-directional sync
class SyncService {
  // Singleton pattern to ensure restore mode state is shared
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();
  
  final _authService = AuthService();
  final _db = DatabaseHelper();
  
  /// Restore mode flag - prevents auto-sync during login/restore to avoid data contamination
  bool _restoreMode = false;
  bool get isRestoreMode => _restoreMode;
  void setRestoreMode(bool value) {
    _restoreMode = value;
    print(value ? '🔒 Restore mode ENABLED - auto-sync disabled' : '🔓 Restore mode DISABLED - auto-sync enabled');
  }
  
  /// Upload subjects to cloud with timestamp-based conflict resolution
  Future<void> uploadSubjects() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot upload subjects: User not logged in');
      return;
    }
    
    // CRITICAL: Don't upload during restore mode to prevent data contamination
    if (_restoreMode) {
      print('⏭️ Skipping upload subjects - restore mode active');
      return;
    }
    
    try {
      final subjects = await _db.getAllSubjects();
      print('📤 Uploading ${subjects.length} subjects...');
      
      // Get existing cloud subjects with timestamps for conflict resolution
      final cloudResponse = await supabase
        .from('subjects')
        .select('name, updated_at')
        .eq('user_id', _authService.userId!);
      
      final cloudTimestamps = <String, DateTime>{};
      for (var item in cloudResponse) {
        final name = item['name'] as String;
        final updatedAt = DateTime.tryParse(item['updated_at'] ?? '');
        if (updatedAt != null) {
          cloudTimestamps[name] = updatedAt;
        }
      }
      
      int uploaded = 0;
      for (var subject in subjects) {
        // Check if cloud version is newer (conflict resolution)
        final cloudTimestamp = cloudTimestamps[subject.name];
        if (cloudTimestamp != null && 
            subject.updatedAt.isBefore(cloudTimestamp)) {
          print('⏭️ Skipping ${subject.name} - cloud version is newer');
          continue;
        }
        
        await supabase.from('subjects').upsert({
          'user_id': _authService.userId,
          'name': subject.name,
          'description': subject.description,
          'color': subject.color,
          'is_active': subject.isActive,
          'total_questions': subject.totalQuestions,
          'correct_answers': subject.correctAnswers,
          'difficulty_weight': subject.difficultyWeight,
          'updated_at': subject.updatedAt.toIso8601String(), // Use actual timestamp
        }, onConflict: 'user_id,name');
        uploaded++;
      }
      
      print('✅ $uploaded/${subjects.length} subjects uploaded to cloud');
    } catch (e) {
      print('❌ Upload subjects error: $e');
      rethrow;
    }
  }
  
  /// Download subjects from cloud (returns list only, doesn't persist)
  Future<List<Subject>> downloadSubjects() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot download subjects: User not logged in');
      return [];
    }
    
    try {
      print('📥 Downloading subjects from cloud...');
      
      final response = await supabase
        .from('subjects')
        .select()
        .eq('user_id', _authService.userId!);
      
      final subjects = <Subject>[];
      
      for (var data in response) {
        final subject = Subject(
          id: 0, // Will be auto-assigned by local DB
          name: data['name'] ?? '',
          description: data['description'] ?? '',
          color: data['color'] ?? '#6366f1',
          isActive: data['is_active'] ?? true,
          totalQuestions: data['total_questions'] ?? 0,
          correctAnswers: data['correct_answers'] ?? 0,
          difficultyWeight: (data['difficulty_weight'] ?? 0.5).toDouble(),
          createdAt: DateTime.parse(data['created_at']),
          updatedAt: DateTime.parse(data['updated_at']),
        );
        
        subjects.add(subject);
      }
      
      print('✅ Downloaded ${subjects.length} subjects from cloud');
      return subjects;
    } catch (e) {
      print('❌ Download subjects error: $e');
      rethrow;
    }
  }
  
  /// Download subjects from cloud AND persist to local database
  Future<List<Subject>> downloadSubjectsAndPersist() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot download subjects: User not logged in');
      return [];
    }
    
    try {
      // Download from cloud
      final cloudSubjects = await downloadSubjects();
      
      // Persist each subject to local database
      print('💾 Persisting ${cloudSubjects.length} subjects to local DB...');
      for (final subject in cloudSubjects) {
        await _db.insertSubject(subject);
      }
      
      // Return subjects with their new local IDs
      final localSubjects = await _db.getAllSubjects();
      print('✅ ${localSubjects.length} subjects persisted locally');
      return localSubjects;
    } catch (e) {
      print('❌ Download and persist subjects error: $e');
      rethrow;
    }
  }
  
  /// Upload questions to cloud
  Future<void> uploadQuestions() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot upload questions: User not logged in');
      return;
    }
    
    // CRITICAL: Don't upload during restore mode to prevent data contamination
    if (_restoreMode) {
      print('⏭️ Skipping upload questions - restore mode active');
      return;
    }
    
    try {
      final subjects = await _db.getAllSubjects();
      int totalQuestions = 0;
      
      print('📤 Uploading questions...');
      
      for (var subject in subjects) {
        final questions = await _db.getQuestionsBySubject(subject.id!);
        
        for (var question in questions) {
          await supabase.from('questions').upsert({
            'user_id': _authService.userId,
            'subject_id': subject.id.toString(), // Legacy field
            'subject_name': subject.name, // ADD: Stable mapping by name
            'question_text': question.questionText,
            'options': question.options,
            'correct_answer': question.correctAnswer,
            'explanation': question.explanation,
            'difficulty': question.difficulty,
            'category': question.category,
            'is_from_ai': question.isFromAI,
            'source': question.source,
            'source_url': question.sourceUrl,
          });
          totalQuestions++;
        }
      }
      
      print('✅ $totalQuestions questions uploaded to cloud');
    } catch (e) {
      print('❌ Upload questions error: $e');
      rethrow;
    }
  }
  
  /// Download questions from cloud (doesn't persist, returns list)
  Future<List<Question>> downloadQuestions() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot download questions: User not logged in');
      return [];
    }
    
    try {
      print('📥 Downloading questions from cloud...');
      
      final response = await supabase
        .from('questions')
        .select()
        .eq('user_id', _authService.userId!);
      
      // Get local subjects for mapping
      final subjects = await _db.getAllSubjects();
      final subjectsByName = { for (var s in subjects) s.name: s };
      
      final questions = <Question>[];
      int skipped = 0;
      
      for (var data in response) {
        // Map by subject_name (stable) instead of subject_id (fragile)
        final subjectName = data['subject_name'] as String?;
        final subject = subjectName != null ? subjectsByName[subjectName] : null;
        
        if (subject == null) {
          print('⚠️ Skipping question - subject not found: $subjectName');
          skipped++;
          continue; // Skip questions for non-existent subjects
        }
        
        final question = Question(
          id: 0, // Auto-assigned
          subjectId: subject.id!,
          questionText: data['question_text'],
          options: List<String>.from(data['options'] ?? []),
          correctAnswer: data['correct_answer'],
          explanation: data['explanation'],
          difficulty: data['difficulty'],
          category: data['category'],
          createdAt: DateTime.tryParse(data['created_at'] ?? '') ?? DateTime.now(),
          isFromAI: data['is_from_ai'] ?? false,
          source: data['source'],
          sourceUrl: data['source_url'],
        );
        
        questions.add(question);
      }
      
      print('✅ Downloaded ${questions.length} questions from cloud');
      if (skipped > 0) {
        print('⚠️ Skipped $skipped questions (subject not found)');
      }
      return questions;
    } catch (e) {
      print('❌ Download questions error: $e');
      rethrow;
    }
  }
  
  /// Download questions from cloud AND persist to local database
  Future<void> downloadQuestionsAndPersist({required List<Subject> subjects}) async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot download questions: User not logged in');
      return;
    }
    
    try {
      // Download questions from cloud
      final questions = await downloadQuestions();
      
      // Persist each question to local database
      print('💾 Persisting ${questions.length} questions to local DB...');
      for (final question in questions) {
        await _db.insertQuestion(question);
      }
      
      print('✅ ${questions.length} questions persisted locally');
    } catch (e) {
      print('❌ Download and persist questions error: $e');
      rethrow;
    }
  }
  
  /// Upload quiz sessions to cloud
  /// Note: Disabled temporarily due to UUID/integer ID mismatch
  Future<void> uploadQuizSessions() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot upload quiz sessions: User not logged in');
      return;
    }
    
    // Skip quiz session sync for now (local IDs don't match cloud UUIDs)
    print('⏭️ Skipping quiz session sync (not yet implemented)');
    return;
  }
  
  /// Full bi-directional sync (download first, then upload)
  /// Cloud is source of truth - download and persist first, then upload local changes
  Future<SyncResult> fullSync() async {
    if (!_authService.isLoggedIn) {
      print('⚠️ Cannot sync: User not logged in');
      return SyncResult(success: false, message: 'User not logged in');
    }
    
    try {
      print('🔄 Starting full sync...');
      
      // CRITICAL FIX: Download and persist FIRST (cloud is source of truth)
      // This ensures local DB always has latest cloud data
      final cloudSubjects = await downloadSubjectsAndPersist();
      await downloadQuestionsAndPersist(subjects: cloudSubjects);
      print('✅ Cloud data downloaded and persisted: ${cloudSubjects.length} subjects');
      
      // Then upload any local changes (with timestamp conflict resolution)
      // uploadSubjects() will skip if cloud version is newer
      await uploadSubjects();
      await uploadQuestions();
      await uploadQuizSessions();
      print('✅ Local changes uploaded to cloud');
      
      print('✅ Full sync completed successfully!');
      return SyncResult(
        success: true,
        message: 'Synced ${cloudSubjects.length} subjects',
        subjectCount: cloudSubjects.length,
      );
    } catch (e) {
      print('❌ Full sync error: $e');
      return SyncResult(
        success: false,
        message: 'Sync failed: $e',
      );
    }
  }
  
  /// Auto-sync on app launch
  Future<void> syncOnLaunch() async {
    if (_authService.isLoggedIn) {
      print('🚀 Auto-sync on launch...');
      await fullSync();
    } else {
      print('⚠️ Skipping auto-sync: User not logged in');
    }
  }
  
  /// Check if sync is needed (compare local vs cloud)
  Future<bool> needsSync() async {
    if (!_authService.isLoggedIn) return false;
    
    try {
      // Simple check: compare local subject count vs cloud
      final localSubjects = await _db.getAllSubjects();
      final cloudResponse = await supabase
        .from('subjects')
        .select('id')
        .eq('user_id', _authService.userId!);
      
      return localSubjects.length != cloudResponse.length;
    } catch (e) {
      print('❌ Check sync error: $e');
      return false;
    }
  }
  
  /// Clear all cloud data (for testing/reset)
  Future<void> clearCloudData() async {
    if (!_authService.isLoggedIn) return;
    
    try {
      print('🗑️ Clearing cloud data...');
      
      await supabase
        .from('quiz_sessions')
        .delete()
        .eq('user_id', _authService.userId!);
      
      await supabase
        .from('questions')
        .delete()
        .eq('user_id', _authService.userId!);
      
      await supabase
        .from('subjects')
        .delete()
        .eq('user_id', _authService.userId!);
      
      print('✅ Cloud data cleared');
    } catch (e) {
      print('❌ Clear cloud data error: $e');
      rethrow;
    }
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final String message;
  final int subjectCount;
  final int questionCount;
  final int sessionCount;
  
  SyncResult({
    required this.success,
    required this.message,
    this.subjectCount = 0,
    this.questionCount = 0,
    this.sessionCount = 0,
  });
}
