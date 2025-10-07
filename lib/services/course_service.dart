import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/course.dart';
import '../database/database_helper.dart';

class CourseService {
  final DatabaseHelper _db = DatabaseHelper();

  /// Load courses from JSON file and import into database
  Future<void> loadDefaultCourses() async {
    try {
      // Check if courses already loaded
      final hasData = await _db.hasCoursesData();
      if (hasData) {
        print('✅ Courses already loaded in database');
        return;
      }

      print('📚 Loading default courses from JSON...');
      
      // Load JSON file from assets
      final String jsonString = await rootBundle.loadString('assets/courses.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      // Parse courses
      final List<dynamic> coursesJson = jsonData['courses'] as List<dynamic>;
      final List<Course> courses = coursesJson
          .map((json) => Course.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Bulk insert into database
      await _db.bulkInsertCourses(courses);
      
      print('✅ Loaded ${courses.length} default courses into database');
    } catch (e) {
      print('❌ Error loading default courses: $e');
      // Don't throw - app should work even if course loading fails
    }
  }

  /// Get all courses
  Future<List<Course>> getAllCourses() async {
    return await _db.getAllCourses();
  }

  /// Search courses by query
  Future<List<Course>> searchCourses(String query) async {
    if (query.isEmpty) {
      return await _db.getAllCourses();
    }
    return await _db.searchCourses(query);
  }

  /// Get courses by category
  Future<List<Course>> getCoursesByCategory(String category) async {
    return await _db.getCoursesByCategory(category);
  }

  /// Add custom course
  Future<int> addCustomCourse({
    required String courseId,
    required String subjectName,
    required String category,
    String description = '',
  }) async {
    final course = Course(
      courseId: courseId,
      subjectName: subjectName,
      category: category,
      description: description,
      isCustom: true,
    );
    return await _db.insertCourse(course);
  }

  /// Update course
  Future<int> updateCourse(Course course) async {
    return await _db.updateCourse(course);
  }

  /// Delete course
  Future<int> deleteCourse(int id) async {
    return await _db.deleteCourse(id);
  }

  /// Get available categories
  Future<List<String>> getCategories() async {
    final courses = await _db.getAllCourses();
    final categories = courses.map((c) => c.category).toSet().toList();
    categories.sort();
    return categories;
  }
}
