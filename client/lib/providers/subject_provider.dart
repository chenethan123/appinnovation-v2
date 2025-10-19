/**
 * Subject Provider
 * State management for subjects with server sync
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';

class SubjectNotifier extends StateNotifier<AsyncValue<List<Subject>>> {
  SubjectNotifier() : super(const AsyncValue.loading()) {
    loadSubjects();
  }

  Future<void> loadSubjects() async {
    try {
      // Try to load from server first
      try {
        final subjects = await ApiService.instance.getAllSubjects();
        
        // Save to local database
        for (final subject in subjects) {
          if (subject.id != null) {
            await DatabaseHelper.instance.insertSubject(subject);
          }
        }
        
        state = AsyncValue.data(subjects);
      } catch (e) {
        // If server fails, load from local database
        print('Server unavailable, loading from local database');
        final localSubjects = await DatabaseHelper.instance.getAllSubjects();
        state = AsyncValue.data(localSubjects);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> createSubject({
    required String name,
    required String description,
    required String color,
  }) async {
    try {
      final subject = await ApiService.instance.createSubject(
        name: name,
        description: description,
        color: color,
      );
      
      // Add to local database
      await DatabaseHelper.instance.insertSubject(subject);
      
      // Reload subjects
      await loadSubjects();
    } catch (e) {
      print('Error creating subject: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      await ApiService.instance.deleteSubject(id);
      await DatabaseHelper.instance.deleteSubject(id);
      await loadSubjects();
    } catch (e) {
      print('Error deleting subject: $e');
      rethrow;
    }
  }

  Future<void> refresh() => loadSubjects();

  Future<void> addSubject(Subject subject) async {
    await createSubject(
      name: subject.name,
      description: subject.description,
      color: subject.color,
    );
  }

  Future<void> updateSubject(Subject subject) async {
    try {
      // Update in local database
      await DatabaseHelper.instance.updateSubject(subject);
      
      // TODO: Update on server if available
      await loadSubjects();
    } catch (e) {
      print('Error updating subject: $e');
      rethrow;
    }
  }
}

final subjectProvider = StateNotifierProvider<SubjectNotifier, AsyncValue<List<Subject>>>((ref) {
  return SubjectNotifier();
});

/// Provider for active subjects only
final activeSubjectsProvider = Provider<List<Subject>>((ref) {
  final subjectsAsync = ref.watch(subjectProvider);
  return subjectsAsync.when(
    data: (subjects) => subjects.where((s) => s.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for today's quiz count
final todayQuizCountProvider = FutureProvider<int>((ref) async {
  // TODO: Implement actual count from quiz sessions
  final db = DatabaseHelper.instance;
  final sessions = await db.getAllQuizSessions();
  final today = DateTime.now();
  return sessions.where((session) {
    final sessionDate = session.startedAt;
    return sessionDate.year == today.year &&
           sessionDate.month == today.month &&
           sessionDate.day == today.day;
  }).length;
});
