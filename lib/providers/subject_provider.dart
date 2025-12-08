import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../services/cloud_data_service.dart';
import '../services/auth_service.dart';

class SubjectNotifier extends StateNotifier<AsyncValue<List<Subject>>> {
  SubjectNotifier() : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  final CloudDataService _cloudService = CloudDataService();
  final AuthService _authService = AuthService();

  Future<void> loadSubjects() async {
    try {
      print('🔄 LOAD SUBJECTS CALLED - Fetching from cloud...');
      state = const AsyncValue.loading();
      
      // Wait for auth to be ready (max 3 seconds)
      int attempts = 0;
      while ((_authService.userId == null || !_authService.isLoggedIn) && attempts < 6) {
        await Future.delayed(const Duration(milliseconds: 500));
        attempts++;
      }
      
      // CLOUD-FIRST: Fetch from Supabase with automatic user_id filtering
      final subjects = await _cloudService.getAllSubjects();
      state = AsyncValue.data(subjects);
      
      print('📊 Loaded ${subjects.length} subjects for user ${_authService.userId?.substring(0, 8) ?? "unknown"}');
      for (var subject in subjects) {
        print('   - ${subject.name}: TOTAL=${subject.totalQuestions}, CORRECT=${subject.correctAnswers} (${((subject.correctAnswers / (subject.totalQuestions > 0 ? subject.totalQuestions : 1)) * 100).toStringAsFixed(1)}%)');
      }
    } catch (error, stackTrace) {
      print('❌ Error loading subjects: $error');
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Must be logged in to add subjects');
      }
      
      // CLOUD-FIRST: Create in Supabase with automatic user_id validation
      await _cloudService.createSubject(subject);
      await loadSubjects(); // Refresh from cloud
      print('✅ Subject added to cloud with user_id: ${_authService.userId}');
    } catch (error) {
      final errorMsg = error.toString();
      
      // Handle duplicate subject error with friendly message
      if (errorMsg.contains('duplicate key') || errorMsg.contains('unique constraint')) {
        print('⚠️  Subject "${subject.name}" already exists');
        throw Exception('You already have a subject named "${subject.name}"');
      }
      
      print('❌ Error adding subject: $error');
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Must be logged in to update subjects');
      }
      
      // CLOUD-FIRST: Update in Supabase with automatic user_id validation
      await _cloudService.updateSubject(subject);
      await loadSubjects(); // Refresh from cloud
      print('✅ Subject updated in cloud');
    } catch (error) {
      print('❌ Error updating subject: $error');
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Must be logged in to delete subjects');
      }
      
      // CLOUD-FIRST: Delete from Supabase with automatic user_id validation
      await _cloudService.deleteSubject(id);
      await loadSubjects(); // Refresh from cloud
      print('✅ Subject deleted from cloud');
    } catch (error) {
      print('❌ Error deleting subject: $error');
      rethrow;
    }
  }

  Future<void> toggleSubjectActive(int id) async {
    try {
      if (!_authService.isLoggedIn) {
        throw Exception('Must be logged in to toggle subject');
      }
      
      // Find subject in current state
      final subjects = state.value ?? [];
      final subject = subjects.where((s) => s.id == id).firstOrNull;
      
      if (subject != null) {
        final updatedSubject = subject.copyWith(
          isActive: !subject.isActive,
          updatedAt: DateTime.now(),
        );
        await _cloudService.updateSubject(updatedSubject);
        await loadSubjects();
      }
    } catch (error) {
      print('❌ Error toggling subject: $error');
      rethrow;
    }
  }

  List<Subject> getActiveSubjects() {
    return state.when(
      data: (subjects) => subjects.where((s) => s.isActive).toList(),
      loading: () => [],
      error: (_, __) => [],
    );
  }

  // Get subjects sorted by adaptive priority for quiz selection
  List<Subject> getSubjectsForQuiz() {
    final activeSubjects = getActiveSubjects();
    activeSubjects.sort((a, b) => b.adaptivePriority.compareTo(a.adaptivePriority));
    return activeSubjects;
  }
}

final subjectProvider = StateNotifierProvider<SubjectNotifier, AsyncValue<List<Subject>>>((ref) {
  return SubjectNotifier();
});

// Provider for active subjects only
final activeSubjectsProvider = Provider<List<Subject>>((ref) {
  final subjectsAsync = ref.watch(subjectProvider);
  return subjectsAsync.when(
    data: (subjects) => subjects.where((s) => s.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

// Provider for subjects sorted by quiz priority
final quizSubjectsProvider = Provider<List<Subject>>((ref) {
  final activeSubjects = ref.watch(activeSubjectsProvider);
  final sortedSubjects = List<Subject>.from(activeSubjects);
  sortedSubjects.sort((a, b) => b.adaptivePriority.compareTo(a.adaptivePriority));
  return sortedSubjects;
});
