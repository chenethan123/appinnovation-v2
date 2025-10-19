/**
 * Database Helper
 * SQLite database for offline-first functionality
 * Syncs with server when online
 */

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../models/course.dart';
import '../models/unit.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('formula_quizzer.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Subjects table
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
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

    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        question_text TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        explanation TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        is_from_ai INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Quiz sessions table
    await db.execute('''
      CREATE TABLE quiz_sessions (
        id TEXT PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        score INTEGER NOT NULL DEFAULT 0,
        total_questions INTEGER NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // Quiz answers table
    await db.execute('''
      CREATE TABLE quiz_answers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        session_id TEXT NOT NULL,
        question_id INTEGER NOT NULL,
        user_answer TEXT NOT NULL,
        is_correct INTEGER NOT NULL,
        time_spent_seconds INTEGER NOT NULL DEFAULT 0,
        answered_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES quiz_sessions (id) ON DELETE CASCADE,
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
      )
    ''');

    // Courses table (for autocomplete)
    await db.execute('''
      CREATE TABLE courses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        course_id TEXT NOT NULL UNIQUE,
        subject_name TEXT NOT NULL,
        category TEXT NOT NULL,
        description TEXT,
        is_custom INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Units table (for subject organization)
    await db.execute('''
      CREATE TABLE units (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        order_index INTEGER NOT NULL,
        start_date TEXT,
        end_date TEXT,
        is_current INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    print('✅ Database created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add courses table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS courses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          course_id TEXT NOT NULL UNIQUE,
          subject_name TEXT NOT NULL,
          category TEXT NOT NULL,
          description TEXT,
          is_custom INTEGER NOT NULL DEFAULT 0
        )
      ''');

      // Add units table
      await db.execute('''
        CREATE TABLE IF NOT EXISTS units (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          subject_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          order_index INTEGER NOT NULL,
          start_date TEXT,
          end_date TEXT,
          is_current INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL,
          FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
        )
      ''');
      
      print('✅ Database upgraded to version $newVersion');
    }
  }

  // ==================== SUBJECTS ====================

  Future<int> insertSubject(Subject subject) async {
    final db = await database;
    return await db.insert('subjects', subject.toMap());
  }

  Future<List<Subject>> getAllSubjects() async {
    final db = await database;
    final result = await db.query('subjects', orderBy: 'name ASC');
    return result.map((map) => Subject.fromMap(map)).toList();
  }

  Future<Subject?> getSubjectByName(String name) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Subject.fromMap(maps.first);
  }

  Future<Subject?> getSubjectById(int id) async {
    final db = await database;
    final result = await db.query('subjects', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Subject.fromMap(result.first);
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
    return await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== QUESTIONS ====================

  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert('questions', question.toMap());
  }

  Future<List<Question>> getQuestionsBySubjectId(int subjectId) async {
    final db = await database;
    final result = await db.query(
      'questions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
    );
    return result.map((map) => Question.fromMap(map)).toList();
  }

  Future<Question?> getQuestionById(int id) async {
    final db = await database;
    final result = await db.query('questions', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return Question.fromMap(result.first);
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    return await db.update(
      'questions',
      question.toMap(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== QUIZ SESSIONS ====================

  Future<void> insertQuizSession(QuizSession session) async {
    final db = await database;
    await db.insert('quiz_sessions', session.toMap());
  }

  Future<List<QuizSession>> getAllQuizSessions() async {
    final db = await database;
    final result = await db.query('quiz_sessions', orderBy: 'started_at DESC');
    return result.map((map) => QuizSession.fromMap(map)).toList();
  }

  Future<QuizSession?> getQuizSessionById(String id) async {
    final db = await database;
    final result = await db.query('quiz_sessions', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return QuizSession.fromMap(result.first);
  }

  Future<int> updateQuizSession(QuizSession session) async {
    final db = await database;
    return await db.update(
      'quiz_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  // ==================== QUIZ ANSWERS ====================

  Future<int> insertQuizAnswer(QuizAnswer answer) async {
    final db = await database;
    return await db.insert('quiz_answers', answer.toMap());
  }

  Future<List<QuizAnswer>> getAnswersBySessionId(String sessionId) async {
    final db = await database;
    final result = await db.query(
      'quiz_answers',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return result.map((map) => QuizAnswer.fromMap(map)).toList();
  }

  // ==================== COURSES ====================

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
      where: 'course_id LIKE ? OR subject_name LIKE ? OR category LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'course_id ASC',
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
        conflictAlgorithm: ConflictAlgorithm.replace,
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

  // ==================== UNITS ====================

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

  // ==================== UTILITIES ====================

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('quiz_answers');
    await db.delete('quiz_sessions');
    await db.delete('questions');
    await db.delete('subjects');
    print('🗑️ All data cleared');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
