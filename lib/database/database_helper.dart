import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../models/course.dart';
import '../models/unit.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static const int _version = 9;
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'formula_quizzer.db');

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT NOT NULL,
        color TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        total_questions INTEGER NOT NULL DEFAULT 0,
        correct_answers INTEGER NOT NULL DEFAULT 0,
        difficulty_weight REAL NOT NULL DEFAULT 0.5
      )
    ''');

    // Create questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        explanation TEXT NOT NULL,
        difficulty TEXT DEFAULT 'medium',
        created_at TEXT NOT NULL,
        is_from_ai INTEGER DEFAULT 1,
        source_url TEXT,
        source TEXT,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Create quiz_sessions table
    await db.execute('''
      CREATE TABLE quiz_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        user_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        answered_at TEXT NOT NULL,
        time_spent_seconds INTEGER NOT NULL DEFAULT 0,
        difficulty TEXT NOT NULL DEFAULT 'medium',
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE,
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
      )
    ''');

    // Create quiz_settings table
    await db.execute('''
      CREATE TABLE quiz_settings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        max_daily_quizzes INTEGER NOT NULL DEFAULT 5,
        start_hour INTEGER NOT NULL DEFAULT 9,
        end_hour INTEGER NOT NULL DEFAULT 18,
        active_days TEXT NOT NULL DEFAULT '1,2,3,4,5',
        notifications_enabled INTEGER NOT NULL DEFAULT 1,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create courses table for autocomplete
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id TEXT NOT NULL UNIQUE,
        subject_name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create MCQ history table for deduplication
    await db.execute('''
      CREATE TABLE mcq_history (
        id TEXT PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        stem TEXT NOT NULL,
        stem_hash TEXT NOT NULL,
        correct_option TEXT NOT NULL,
        options TEXT NOT NULL,
        explanation_correct TEXT NOT NULL,
        explanations_by_option TEXT NOT NULL,
        difficulty TEXT,
        source_hint TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE,
        UNIQUE(subject_id, stem_hash)
      )
    ''');

    // Create MCQ completions table
    await db.execute('''
      CREATE TABLE mcq_completions (
        id TEXT PRIMARY KEY,
        mcq_id TEXT NOT NULL,
        subject_id INTEGER NOT NULL,
        picked_option TEXT NOT NULL,
        was_correct INTEGER NOT NULL,
        accuracy_after REAL NOT NULL,
        happened_at TEXT NOT NULL,
        FOREIGN KEY (mcq_id) REFERENCES mcq_history (id) ON DELETE CASCADE,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Create units table for subject units/topics
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        order_index INTEGER NOT NULL DEFAULT 0,
        start_date TEXT,
        end_date TEXT,
        is_current INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Insert default quiz settings
    await db.insert('quiz_settings', {
      'max_daily_quizzes': 5,
      'start_hour': 9,
      'end_hour': 18,
      'active_days': '1,2,3,4,5',
      'notifications_enabled': 1,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Insert starter subjects to ensure app has content
    final now = DateTime.now().toIso8601String();
    await db.insert('subjects', {
      'name': 'Mathematics',
      'description': 'Basic mathematics including algebra, geometry, and calculus',
      'color': '#2196F3',
      'is_active': 1,
      'total_questions': 0,
      'correct_answers': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('subjects', {
      'name': 'Physics',
      'description': 'Fundamental physics concepts and problem solving',
      'color': '#4CAF50',
      'is_active': 1,
      'total_questions': 0,
      'correct_answers': 0,
      'created_at': now,
      'updated_at': now,
    });

    await db.insert('subjects', {
      'name': 'Chemistry',
      'description': 'Chemical reactions, molecular structure, and laboratory techniques',
      'color': '#FF9800',
      'is_active': 1,
      'total_questions': 0,
      'correct_answers': 0,
      'created_at': now,
      'updated_at': now,
    });

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_questions_subject_id ON questions(subject_id)');
    await db.execute('CREATE INDEX idx_quiz_sessions_subject_id ON quiz_sessions(subject_id)');
    await db.execute('CREATE INDEX idx_quiz_sessions_answered_at ON quiz_sessions(answered_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add source column to questions table
      await db.execute('ALTER TABLE questions ADD COLUMN source TEXT');
    }
    if (oldVersion < 6) {
      // Clear existing subjects and add fresh ones
      await db.delete('subjects');
      final now = DateTime.now().toIso8601String();
      await db.insert('subjects', {
        'name': 'Mathematics',
        'description': 'Basic mathematics including algebra, geometry, and calculus',
        'color': '#2196F3',
        'is_active': 1,
        'total_questions': 0,
        'correct_answers': 0,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('subjects', {
        'name': 'Physics',
        'description': 'Fundamental physics concepts and problem solving',
        'color': '#4CAF50',
        'is_active': 1,
        'total_questions': 0,
        'correct_answers': 0,
        'created_at': now,
        'updated_at': now,
      });

      await db.insert('subjects', {
        'name': 'Chemistry',
        'description': 'Chemical reactions, molecular structure, and laboratory techniques',
        'color': '#FF9800',
        'is_active': 1,
        'total_questions': 0,
        'correct_answers': 0,
        'created_at': now,
        'updated_at': now,
      });
    }
    if (oldVersion < 7) {
      // Add courses table for autocomplete
      await db.execute('''
        CREATE TABLE IF NOT EXISTS courses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id TEXT NOT NULL UNIQUE,
          subject_name TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT NOT NULL,
          is_custom INTEGER NOT NULL DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 8) {
      // Add MCQ tracking tables for deduplication
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mcq_history (
          id TEXT PRIMARY KEY,
          subject_id INTEGER NOT NULL,
          stem TEXT NOT NULL,
          stem_hash TEXT NOT NULL,
          correct_option TEXT NOT NULL,
          options TEXT NOT NULL,
          explanation_correct TEXT NOT NULL,
          explanations_by_option TEXT NOT NULL,
          difficulty TEXT,
          source_hint TEXT,
          created_at TEXT NOT NULL,
          FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE,
          UNIQUE(subject_id, stem_hash)
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS mcq_completions (
          id TEXT PRIMARY KEY,
          mcq_id TEXT NOT NULL,
          subject_id INTEGER NOT NULL,
          picked_option TEXT NOT NULL,
          was_correct INTEGER NOT NULL,
          accuracy_after REAL NOT NULL,
          happened_at TEXT NOT NULL,
          FOREIGN KEY (mcq_id) REFERENCES mcq_history (id) ON DELETE CASCADE,
          FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
        )
      ''');
      
      // Add indexes for performance
      await db.execute('CREATE INDEX IF NOT EXISTS mcq_subject_created_idx ON mcq_history(subject_id, created_at DESC)');
      await db.execute('CREATE INDEX IF NOT EXISTS completions_subject_time_idx ON mcq_completions(subject_id, happened_at DESC)');
    }
    if (oldVersion < 9) {
      // Add units table for subject unit/topic tracking
      await db.execute('''
        CREATE TABLE IF NOT EXISTS units (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          order_index INTEGER NOT NULL DEFAULT 0,
          start_date TEXT,
          end_date TEXT,
          is_current INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
        )
      ''');
      
      // Add index for quick unit lookups
      await db.execute('CREATE INDEX IF NOT EXISTS units_subject_order_idx ON units(subject_id, order_index)');
    }
  }

  // Subject CRUD operations
  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    // Use INSERT OR REPLACE to handle subjects downloaded from cloud
    // This prevents UNIQUE constraint failures when cloud has duplicate/invalid IDs
    return await db.insert(
      'subjects', 
      subject.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final maps = await db.query('subjects', orderBy: 'name ASC');
    return maps.map((map) => Subject.fromMap(map)).toList();
  }

  Future<List<Subject>> getActiveSubjects() async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Subject.fromMap(map)).toList();
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    return maps.isNotEmpty ? Subject.fromMap(maps.first) : null;
  }

  Future<Subject?> getSubjectByName(String name) async {
    final db = await database;
    final maps = await db.query(
      'subjects',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return maps.isNotEmpty ? Subject.fromMap(maps.first) : null;
  }

  Future<int> updateSubject(Subject subject) async {
    final db = await database;
    return await db.update(
      'subjects',
      subject.toMap(),
      where: 'id = ?',
      whereArgs: [subject.id],
    );
  }

  Future<int> deleteSubject(int id) async {
    final db = await database;
    return await db.delete(
      'subjects',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Question CRUD operations
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    // Use INSERT OR REPLACE to handle questions downloaded from cloud
    // This prevents UNIQUE constraint failures when cloud has duplicate/invalid IDs
    return await db.insert(
      'questions', 
      question.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Question>> getQuestionsBySubject(int subjectId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  Future<Question?> getRandomQuestionForSubject(int subjectId) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'RANDOM()',
      limit: 1,
    );
    return maps.isNotEmpty ? Question.fromMap(maps.first) : null;
  }

  Future<int> getQuestionCountForSubject(int subjectId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE subject_id = ?',
      [subjectId],
    );
    return result.first['count'] as int;
  }

  // Quiz session CRUD operations
  Future<int> insertQuizSession(QuizSession session) async {
    final db = await database;
    final result = await db.insert('quiz_sessions', session.toMap());
    
    // Update subject statistics
    await _updateSubjectStats(session.subjectId);
    
    return result;
  }

  Future<void> updateSubjectStats(int subjectId, int totalQuestions, int correctAnswers) async {
    final db = await database;
    await db.update(
      'subjects',
      {
        'total_questions': totalQuestions,
        'correct_answers': correctAnswers,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [subjectId],
    );
  }

  Future<List<QuizSession>> getQuizSessionsBySubject(int subjectId) async {
    final db = await database;
    final maps = await db.query(
      'quiz_sessions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'answered_at DESC',
    );
    return maps.map((map) => QuizSession.fromMap(map)).toList();
  }

  Future<List<QuizSession>> getTodaysQuizSessions() async {
    final db = await database;
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    final maps = await db.query(
      'quiz_sessions',
      where: 'answered_at >= ? AND answered_at < ?',
      whereArgs: [startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'answered_at DESC',
    );
    return maps.map((map) => QuizSession.fromMap(map)).toList();
  }

  Future<void> _updateSubjectStats(int subjectId) async {
    final db = await database;
    
    // Get total questions and correct answers for this subject
    final result = await db.rawQuery('''
      SELECT 
        COUNT(*) as total,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct
      FROM quiz_sessions 
      WHERE subject_id = ?
    ''', [subjectId]);
    
    final total = result.first['total'] as int;
    final correct = result.first['correct'] as int;
    
    // Update subject with new stats
    await db.update(
      'subjects',
      {
        'total_questions': total,
        'correct_answers': correct,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [subjectId],
    );
  }

  // Quiz settings operations
  Future<QuizSettings> getQuizSettings() async {
    try {
      final db = await database;
      final maps = await db.query('quiz_settings', limit: 1);
      
      if (maps.isNotEmpty) {
        return QuizSettings.fromMap(maps.first);
      } else {
        // Create and return default settings if none exist
        final defaultSettings = QuizSettings(updatedAt: DateTime.now());
        await db.insert('quiz_settings', defaultSettings.toMap());
        return defaultSettings;
      }
    } catch (e) {
      print('Error getting quiz settings: $e');
      // Return default settings as fallback
      return QuizSettings(updatedAt: DateTime.now());
    }
  }

  Future<int> updateQuizSettings(QuizSettings settings) async {
    try {
      final db = await database;
      
      // Check if settings exist
      final existing = await db.query('quiz_settings', limit: 1);
      
      if (existing.isNotEmpty) {
        return await db.update(
          'quiz_settings',
          settings.toMap(),
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        return await db.insert('quiz_settings', settings.toMap());
      }
    } catch (e) {
      print('Error updating quiz settings: $e');
      return 0;
    }
  }

  // Analytics and reporting
  Future<Map<String, dynamic>> getSubjectAnalytics(int subjectId) async {
    final db = await database;
    
    // Get overall stats
    final overallResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as total_sessions,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as correct_sessions,
        AVG(time_spent_seconds) as avg_time
      FROM quiz_sessions 
      WHERE subject_id = ?
    ''', [subjectId]);
    
    // Get recent performance (last 7 days)
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentResult = await db.rawQuery('''
      SELECT 
        COUNT(*) as recent_sessions,
        SUM(CASE WHEN is_correct = 1 THEN 1 ELSE 0 END) as recent_correct
      FROM quiz_sessions 
      WHERE subject_id = ? AND answered_at >= ?
    ''', [subjectId, sevenDaysAgo.toIso8601String()]);
    
    final overall = overallResult.first;
    final recent = recentResult.first;
    
    return {
      'total_sessions': overall['total_sessions'] ?? 0,
      'correct_sessions': overall['correct_sessions'] ?? 0,
      'accuracy': (overall['total_sessions'] as int) > 0 
          ? ((overall['correct_sessions'] as int) / (overall['total_sessions'] as int)) * 100 
          : 0.0,
      'avg_time_seconds': overall['avg_time'] ?? 0.0,
      'recent_sessions': recent['recent_sessions'] ?? 0,
      'recent_correct': recent['recent_correct'] ?? 0,
      'recent_accuracy': (recent['recent_sessions'] as int) > 0 
          ? ((recent['recent_correct'] as int) / (recent['recent_sessions'] as int)) * 100 
          : 0.0,
    };
  }

  // Cleanup operations
  Future<void> deleteOldSessions({int daysToKeep = 30}) async {
    final db = await database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));
    
    await db.delete(
      'quiz_sessions',
      where: 'answered_at < ?',
      whereArgs: [cutoffDate.toIso8601String()],
    );
  }

  // Course CRUD operations for autocomplete
  Future<int> insertCourse(Course course) async {
    final db = await database;
    return await db.insert(
      'courses',
      course.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Course>> getAllCourses() async {
    final db = await database;
    final maps = await db.query('courses', orderBy: 'course_id ASC');
    return maps.map((map) => Course.fromMap(map)).toList();
  }

  Future<List<Course>> searchCourses(String query) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'course_id LIKE ? OR subject_name LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'course_id ASC',
      limit: 50,
    );
    return maps.map((map) => Course.fromMap(map)).toList();
  }

  Future<List<Course>> getCoursesByCategory(String category) async {
    final db = await database;
    final maps = await db.query(
      'courses',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'course_id ASC',
    );
    return maps.map((map) => Course.fromMap(map)).toList();
  }

  Future<int> updateCourse(Course course) async {
    final db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(int id) async {
    final db = await database;
    return await db.delete(
      'courses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> bulkInsertCourses(List<Course> courses) async {
    final db = await database;
    final batch = db.batch();
    
    for (final course in courses) {
      batch.insert(
        'courses',
        course.toMap(),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    
    await batch.commit(noResult: true);
  }

  Future<bool> hasCoursesData() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM courses');
    final count = Sqflite.firstIntValue(result) ?? 0;
    return count > 0;
  }

  // MCQ History methods for deduplication
  Future<List<String>> getRecentStems(int subjectId, {int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'mcq_history',
      columns: ['stem'],
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
    return maps.map((map) => map['stem'] as String).toList();
  }

  Future<List<String>> getRecentTopics(int subjectId, {int limit = 20}) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT DISTINCT source_hint 
      FROM mcq_history 
      WHERE subject_id = ? AND source_hint IS NOT NULL
      ORDER BY created_at DESC 
      LIMIT ?
    ''', [subjectId, limit]);
    return maps.map((map) => map['source_hint'] as String).toList();
  }

  Future<bool> stemExists(int subjectId, String stemHash) async {
    final db = await database;
    final result = await db.query(
      'mcq_history',
      where: 'subject_id = ? AND stem_hash = ?',
      whereArgs: [subjectId, stemHash],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<String?> insertMCQHistory(Map<String, dynamic> mcqData) async {
    final db = await database;
    try {
      await db.insert(
        'mcq_history',
        mcqData,
        conflictAlgorithm: ConflictAlgorithm.ignore, // Ignore duplicates
      );
      return mcqData['id'] as String;
    } catch (e) {
      print('❌ Error inserting MCQ history: $e');
      return null;
    }
  }

  Future<void> insertMCQCompletion(Map<String, dynamic> completionData) async {
    final db = await database;
    await db.insert('mcq_completions', completionData);
  }

  Future<Map<String, dynamic>?> getMCQById(String mcqId) async {
    final db = await database;
    final results = await db.query(
      'mcq_history',
      where: 'id = ?',
      whereArgs: [mcqId],
      limit: 1,
    );
    return results.isNotEmpty ? results.first : null;
  }

  Future<List<Map<String, dynamic>>> getMCQHistory(int subjectId, {int limit = 50}) async {
    final db = await database;
    return await db.query(
      'mcq_history',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  Future<List<Map<String, dynamic>>> getMCQCompletions(int subjectId, {int limit = 50}) async {
    final db = await database;
    return await db.query(
      'mcq_completions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'happened_at DESC',
      limit: limit,
    );
  }

  // Unit CRUD operations
  Future<int> insertUnit(Unit unit) async {
    final db = await database;
    return await db.insert('units', unit.toMap());
  }

  Future<List<Unit>> getUnitsForSubject(int subjectId) async {
    final db = await database;
    final maps = await db.query(
      'units',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => Unit.fromMap(map)).toList();
  }

  Future<Unit?> getCurrentUnit(int subjectId) async {
    final db = await database;
    final maps = await db.query(
      'units',
      where: 'subject_id = ? AND is_current = 1',
      whereArgs: [subjectId],
      limit: 1,
    );
    return maps.isNotEmpty ? Unit.fromMap(maps.first) : null;
  }

  Future<List<Unit>> getActiveUnits(int subjectId) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final maps = await db.query(
      'units',
      where: 'subject_id = ? AND (is_current = 1 OR (start_date <= ? AND end_date >= ?))',
      whereArgs: [subjectId, now, now],
      orderBy: 'order_index ASC',
    );
    return maps.map((map) => Unit.fromMap(map)).toList();
  }

  Future<int> updateUnit(Unit unit) async {
    final db = await database;
    return await db.update(
      'units',
      unit.toMap(),
      where: 'id = ?',
      whereArgs: [unit.id],
    );
  }

  Future<int> deleteUnit(int id) async {
    final db = await database;
    return await db.delete(
      'units',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setCurrentUnit(int subjectId, int unitId) async {
    final db = await database;
    // First, unset all current units for this subject
    await db.update(
      'units',
      {'is_current': 0},
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    // Then set the specified unit as current
    await db.update(
      'units',
      {'is_current': 1},
      where: 'id = ?',
      whereArgs: [unitId],
    );
  }

  /// Clear all user data (called on logout to prevent data leakage)
  Future<void> clearAllData() async {
    final db = await database;
    
    print('🗑️ Clearing all user data from local database...');
    
    // Delete all data from all tables except courses (shared data)
    await db.delete('quiz_sessions');
    await db.delete('questions');
    await db.delete('units');
    await db.delete('subjects');
    await db.delete('quiz_settings');
    
    print('✅ All user data cleared from local database');
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
