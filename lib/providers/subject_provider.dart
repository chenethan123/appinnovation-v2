import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../database/database_helper.dart';

class SubjectNotifier extends StateNotifier<AsyncValue<List<Subject>>> {
  SubjectNotifier() : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadSubjects() async {
    try {
      state = const AsyncValue.loading();
      final subjects = await _db.getAllSubjects();
      state = AsyncValue.data(subjects);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> addSubject(Subject subject) async {
    try {
      await _db.insertSubject(subject);
      await loadSubjects(); // Refresh the list
    } catch (error) {
      // Handle error - could emit error state or show notification
      rethrow;
    }
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      await _db.updateSubject(subject);
      await loadSubjects(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      await _db.deleteSubject(id);
      await loadSubjects(); // Refresh the list
    } catch (error) {
      rethrow;
    }
  }

  Future<void> toggleSubjectActive(int id) async {
    try {
      final subject = await _db.getSubjectById(id);
      if (subject != null) {
        final updatedSubject = subject.copyWith(
          isActive: !subject.isActive,
          updatedAt: DateTime.now(),
        );
        await _db.updateSubject(updatedSubject);
        await loadSubjects();
      }
    } catch (error) {
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
