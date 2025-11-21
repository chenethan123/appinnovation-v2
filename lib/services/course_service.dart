import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/course.dart';
import 'auth_service.dart';

class CourseService {
  final _authService = AuthService();

  /// Load courses from Supabase course_catalog (no longer needed - data already in cloud)
  Future<void> loadDefaultCourses({bool forceReload = false}) async {
    // This method kept for backwards compatibility but does nothing
    // Course catalog is now in Supabase and loaded on-demand
    print('✅ Course catalog loaded from cloud on-demand');
  }

  /// Get all courses from Supabase course_catalog
  Future<List<Course>> getAllCourses() async {
    try {
      if (!_authService.isLoggedIn) {
        print('⚠️ Not logged in - cannot fetch courses');
        return [];
      }

      final response = await supabase
        .from('course_catalog')
        .select('*')
        .eq('is_active', true)
        .order('display_order');

      final courses = (response as List).map((json) => Course(
        id: json['id'].hashCode.abs(), // Convert UUID to int for compatibility
        courseId: json['course_id'] as String,
        subjectName: json['subject_name'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        isCustom: false,
      )).toList();

      print('✅ Fetched ${courses.length} courses from Supabase');
      return courses;
    } catch (e) {
      print('❌ Error fetching courses from Supabase: $e');
      return [];
    }
  }

  /// Search courses by query
  Future<List<Course>> searchCourses(String query) async {
    if (query.isEmpty) {
      return await getAllCourses();
    }
    
    try {
      if (!_authService.isLoggedIn) {
        print('⚠️ Not logged in - cannot search courses');
        return [];
      }

      final response = await supabase
        .from('course_catalog')
        .select('*')
        .eq('is_active', true)
        .or('course_id.ilike.%$query%,subject_name.ilike.%$query%')
        .order('display_order');

      final courses = (response as List).map((json) => Course(
        id: json['id'].hashCode.abs(),
        courseId: json['course_id'] as String,
        subjectName: json['subject_name'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        isCustom: false,
      )).toList();

      return courses;
    } catch (e) {
      print('❌ Error searching courses: $e');
      return [];
    }
  }

  /// Get courses by category
  Future<List<Course>> getCoursesByCategory(String category) async {
    try {
      if (!_authService.isLoggedIn) {
        print('⚠️ Not logged in - cannot fetch courses');
        return [];
      }

      final response = await supabase
        .from('course_catalog')
        .select('*')
        .eq('is_active', true)
        .eq('category', category)
        .order('display_order');

      final courses = (response as List).map((json) => Course(
        id: json['id'].hashCode.abs(),
        courseId: json['course_id'] as String,
        subjectName: json['subject_name'] as String,
        category: json['category'] as String,
        description: json['description'] as String,
        isCustom: false,
      )).toList();

      return courses;
    } catch (e) {
      print('❌ Error fetching courses by category: $e');
      return [];
    }
  }

  /// Add custom course (not supported with cloud catalog)
  Future<int> addCustomCourse({
    required String courseId,
    required String subjectName,
    required String category,
    String description = '',
  }) async {
    print('⚠️ Custom courses not supported with cloud course_catalog');
    return 0;
  }

  /// Update course (not supported with cloud catalog)
  Future<int> updateCourse(Course course) async {
    print('⚠️ Course updates not supported - managed in Supabase');
    return 0;
  }

  /// Delete course (not supported with cloud catalog)
  Future<int> deleteCourse(int id) async {
    print('⚠️ Course deletion not supported - managed in Supabase');
    return 0;
  }

  /// Get available categories from Supabase
  Future<List<String>> getCategories() async {
    try {
      if (!_authService.isLoggedIn) {
        print('⚠️ Not logged in - cannot fetch categories');
        return [];
      }

      final response = await supabase
        .from('course_catalog')
        .select('category')
        .eq('is_active', true);

      final categories = (response as List)
        .map((json) => json['category'] as String)
        .toSet()
        .toList();
      
      categories.sort();
      return categories;
    } catch (e) {
      print('❌ Error fetching categories: $e');
      return [];
    }
  }
}
