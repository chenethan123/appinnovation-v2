import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/unit.dart';
import '../database/database_helper.dart';

class CourseUnitsService {
  static final CourseUnitsService _instance = CourseUnitsService._internal();
  factory CourseUnitsService() => _instance;
  CourseUnitsService._internal();

  final DatabaseHelper _db = DatabaseHelper();
  Map<String, List<Map<String, dynamic>>>? _courseUnitsData;

  /// Load course units from JSON file
  Future<void> loadCourseUnits() async {
    if (_courseUnitsData != null) return; // Already loaded

    try {
      final String jsonString = await rootBundle.loadString('data/course_units.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);
      
      _courseUnitsData = jsonData.map(
        (key, value) => MapEntry(
          key,
          (value as List).map((e) => e as Map<String, dynamic>).toList(),
        ),
      );
      
      print('✅ Loaded units for ${_courseUnitsData!.length} courses');
    } catch (e) {
      print('❌ Error loading course units: $e');
      _courseUnitsData = {};
    }
  }

  /// Check if units are available for a course
  bool hasUnitsFor(String courseName) {
    return _courseUnitsData?.containsKey(courseName) ?? false;
  }

  /// Get units for a course
  List<Map<String, dynamic>>? getUnitsFor(String courseName) {
    return _courseUnitsData?[courseName];
  }

  /// Automatically populate units for a subject if available
  Future<bool> autoPopulateUnits(int subjectId, String subjectName) async {
    await loadCourseUnits();
    
    if (!hasUnitsFor(subjectName)) {
      print('ℹ️  No default units available for: $subjectName');
      return false;
    }

    // Check if units already exist
    final existingUnits = await _db.getUnitsForSubject(subjectId);
    if (existingUnits.isNotEmpty) {
      print('ℹ️  Units already exist for: $subjectName');
      return false;
    }

    final unitsData = getUnitsFor(subjectName);
    if (unitsData == null || unitsData.isEmpty) return false;

    print('📚 Auto-populating ${unitsData.length} units for: $subjectName');

    for (final unitData in unitsData) {
      final unit = Unit(
        subjectId: subjectId,
        name: unitData['name'] as String,
        description: unitData['description'] as String?,
        orderIndex: unitData['order_index'] as int,
        isCurrent: false,
      );
      
      try {
        await _db.insertUnit(unit);
      } catch (e) {
        print('⚠️ Error inserting unit: $e');
      }
    }

    print('✅ Successfully populated units for: $subjectName');
    return true;
  }

  /// Get list of all courses with available units
  List<String> getAvailableCourses() {
    return _courseUnitsData?.keys.toList() ?? [];
  }

  /// Check if this is an AP course
  bool isAPCourse(String courseName) {
    return courseName.startsWith('AP ');
  }
}
