import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course.dart';
import '../services/course_service.dart';

final courseServiceProvider = Provider<CourseService>((ref) => CourseService());

final coursesProvider = FutureProvider<List<Course>>((ref) async {
  final service = ref.read(courseServiceProvider);
  return await service.getAllCourses();
});

final categoriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(courseServiceProvider);
  return await service.getCategories();
});

final courseSearchProvider = StateNotifierProvider<CourseSearchNotifier, AsyncValue<List<Course>>>((ref) {
  return CourseSearchNotifier(ref.read(courseServiceProvider));
});

class CourseSearchNotifier extends StateNotifier<AsyncValue<List<Course>>> {
  final CourseService _service;

  CourseSearchNotifier(this._service) : super(const AsyncValue.loading()) {
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    state = const AsyncValue.loading();
    try {
      final courses = await _service.getAllCourses();
      state = AsyncValue.data(courses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> search(String query) async {
    state = const AsyncValue.loading();
    try {
      final courses = await _service.searchCourses(query);
      state = AsyncValue.data(courses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> filterByCategory(String category) async {
    state = const AsyncValue.loading();
    try {
      final courses = await _service.getCoursesByCategory(category);
      state = AsyncValue.data(courses);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> reset() async {
    await _loadInitial();
  }
}
