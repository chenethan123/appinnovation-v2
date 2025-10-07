import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';

class QuestionDatabase {
  static final QuestionDatabase _instance = QuestionDatabase._internal();
  factory QuestionDatabase() => _instance;
  QuestionDatabase._internal();

  static const int _version = 1;
  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'questions.db');

    return await openDatabase(
      path,
      version: _version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create questions table with comprehensive schema
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER,
        subject_name TEXT,
        question_text TEXT NOT NULL,
        options TEXT NOT NULL,
        correct_answer TEXT NOT NULL,
        explanation TEXT,
        difficulty TEXT DEFAULT 'medium',
        category TEXT,
        question_type TEXT DEFAULT 'multiple',
        source TEXT,
        is_from_ai INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        tags TEXT,
        metadata TEXT
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_questions_subject_id ON questions(subject_id)');
    await db.execute('CREATE INDEX idx_questions_subject_name ON questions(subject_name)');
    await db.execute('CREATE INDEX idx_questions_difficulty ON questions(difficulty)');
    await db.execute('CREATE INDEX idx_questions_category ON questions(category)');
    await db.execute('CREATE INDEX idx_questions_source ON questions(source)');

    // Create question_stats table for analytics
    await db.execute('''
      CREATE TABLE question_stats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER NOT NULL,
        times_asked INTEGER DEFAULT 0,
        times_correct INTEGER DEFAULT 0,
        last_asked TEXT,
        average_response_time REAL DEFAULT 0.0,
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
      )
    ''');

    // Create subject_question_mapping table
    await db.execute('''
      CREATE TABLE subject_question_mapping (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subject_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        weight REAL DEFAULT 1.0,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (question_id) REFERENCES questions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('CREATE INDEX idx_mapping_subject_id ON subject_question_mapping(subject_id)');
    await db.execute('CREATE INDEX idx_mapping_question_id ON subject_question_mapping(question_id)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades here
    if (oldVersion < newVersion) {
      // Add any new columns or tables for future versions
    }
  }

  /// Insert a single question
  Future<int> insertQuestion(Question question) async {
    final db = await database;
    
    try {
      final questionId = await db.insert('questions', {
        'subject_id': question.subjectId,
        'subject_name': question.subjectName,
        'question_text': question.questionText,
        'options': question.options.join('|||'), // Use delimiter for storage
        'correct_answer': question.correctAnswer,
        'explanation': question.explanation,
        'difficulty': question.difficulty,
        'category': question.category,
        'question_type': question.questionType,
        'source': question.source,
        'is_from_ai': question.isFromAI ? 1 : 0,
        'created_at': question.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // Initialize stats for the question
      await db.insert('question_stats', {
        'question_id': questionId,
        'times_asked': 0,
        'times_correct': 0,
        'last_asked': null,
        'average_response_time': 0.0,
      });

      return questionId;
    } catch (e) {
      print('Error inserting question: $e');
      rethrow;
    }
  }

  /// Insert multiple questions efficiently
  Future<void> insertQuestions(List<Question> questions) async {
    final db = await database;
    
    await db.transaction((txn) async {
      for (final question in questions) {
        try {
          final questionId = await txn.insert('questions', {
            'subject_id': question.subjectId,
            'subject_name': question.subjectName,
            'question_text': question.questionText,
            'options': question.options.join('|||'),
            'correct_answer': question.correctAnswer,
            'explanation': question.explanation,
            'difficulty': question.difficulty,
            'category': question.category,
            'question_type': question.questionType,
            'source': question.source,
            'is_from_ai': question.isFromAI ? 1 : 0,
            'created_at': question.createdAt.toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });

          // Initialize stats
          await txn.insert('question_stats', {
            'question_id': questionId,
            'times_asked': 0,
            'times_correct': 0,
            'last_asked': null,
            'average_response_time': 0.0,
          });
        } catch (e) {
          print('Error inserting question: ${question.questionText} - $e');
        }
      }
    });
  }

  /// Get questions by subject name
  Future<List<Question>> getQuestionsBySubject(String subjectName, {int? limit}) async {
    final db = await database;
    
    final maps = await db.query(
      'questions',
      where: 'subject_name = ? OR category = ?',
      whereArgs: [subjectName, subjectName],
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return maps.map((map) => _questionFromMap(map)).toList();
  }

  /// Get questions by subject ID
  Future<List<Question>> getQuestionsBySubjectId(int subjectId, {int? limit}) async {
    final db = await database;
    
    final maps = await db.query(
      'questions',
      where: 'subject_id = ?',
      whereArgs: [subjectId],
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return maps.map((map) => _questionFromMap(map)).toList();
  }

  /// Get random question for subject
  Future<Question?> getRandomQuestionForSubject(String subjectName) async {
    final questions = await getQuestionsBySubject(subjectName, limit: 1);
    return questions.isNotEmpty ? questions.first : null;
  }

  /// Get questions by difficulty
  Future<List<Question>> getQuestionsByDifficulty(String difficulty, {int? limit}) async {
    final db = await database;
    
    final maps = await db.query(
      'questions',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return maps.map((map) => _questionFromMap(map)).toList();
  }

  /// Get questions by category
  Future<List<Question>> getQuestionsByCategory(String category, {int? limit}) async {
    final db = await database;
    
    final maps = await db.query(
      'questions',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'RANDOM()',
      limit: limit,
    );

    return maps.map((map) => _questionFromMap(map)).toList();
  }

  /// Search questions by text
  Future<List<Question>> searchQuestions(String query, {int? limit}) async {
    final db = await database;
    
    final maps = await db.query(
      'questions',
      where: 'question_text LIKE ? OR explanation LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return maps.map((map) => _questionFromMap(map)).toList();
  }

  /// Get question statistics
  Future<Map<String, dynamic>> getQuestionStats(int questionId) async {
    final db = await database;
    
    final maps = await db.query(
      'question_stats',
      where: 'question_id = ?',
      whereArgs: [questionId],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return {};
  }

  /// Update question statistics
  Future<void> updateQuestionStats(int questionId, bool wasCorrect, double responseTime) async {
    final db = await database;
    
    await db.transaction((txn) async {
      // Get current stats
      final currentStats = await txn.query(
        'question_stats',
        where: 'question_id = ?',
        whereArgs: [questionId],
      );

      if (currentStats.isNotEmpty) {
        final stats = currentStats.first;
        final timesAsked = (stats['times_asked'] as int) + 1;
        final timesCorrect = (stats['times_correct'] as int) + (wasCorrect ? 1 : 0);
        final avgResponseTime = ((stats['average_response_time'] as double) + responseTime) / 2;

        await txn.update(
          'question_stats',
          {
            'times_asked': timesAsked,
            'times_correct': timesCorrect,
            'last_asked': DateTime.now().toIso8601String(),
            'average_response_time': avgResponseTime,
          },
          where: 'question_id = ?',
          whereArgs: [questionId],
        );
      }
    });
  }

  /// Get database statistics
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;
    
    final totalQuestions = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions')
    ) ?? 0;

    final subjectCounts = await db.rawQuery('''
      SELECT subject_name, COUNT(*) as count 
      FROM questions 
      WHERE subject_name IS NOT NULL 
      GROUP BY subject_name
    ''');

    final difficultyCounts = await db.rawQuery('''
      SELECT difficulty, COUNT(*) as count 
      FROM questions 
      GROUP BY difficulty
    ''');

    return {
      'total_questions': totalQuestions,
      'subjects': subjectCounts.length,
      'easy_questions': difficultyCounts.where((row) => row['difficulty'] == 'easy').length,
      'medium_questions': difficultyCounts.where((row) => row['difficulty'] == 'medium').length,
      'hard_questions': difficultyCounts.where((row) => row['difficulty'] == 'hard').length,
    };
  }

  /// Get all unique subject names
  Future<List<String>> getAllSubjectNames() async {
    final db = await database;
    
    final maps = await db.rawQuery('''
      SELECT DISTINCT subject_name 
      FROM questions 
      WHERE subject_name IS NOT NULL 
      ORDER BY subject_name
    ''');

    return maps.map((map) => map['subject_name'] as String).toList();
  }

  /// Get all unique categories
  Future<List<String>> getAllCategories() async {
    final db = await database;
    
    final maps = await db.rawQuery('''
      SELECT DISTINCT category 
      FROM questions 
      WHERE category IS NOT NULL 
      ORDER BY category
    ''');

    return maps.map((map) => map['category'] as String).toList();
  }

  /// Delete question
  Future<void> deleteQuestion(int questionId) async {
    final db = await database;
    await db.delete('questions', where: 'id = ?', whereArgs: [questionId]);
  }

  /// Clear all questions
  Future<void> clearAllQuestions() async {
    final db = await database;
    await db.delete('questions');
    await db.delete('question_stats');
    await db.delete('subject_question_mapping');
  }

  Question _questionFromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'],
      subjectId: map['subject_id'] ?? 0,
      subjectName: map['subject_name'],
      questionText: map['question_text'],
      options: (map['options'] as String).split('|||'),
      correctAnswer: map['correct_answer'],
      explanation: map['explanation'],
      difficulty: map['difficulty'] ?? 'medium',
      category: map['category'],
      questionType: map['question_type'] ?? 'multiple',
      source: map['source'],
      isFromAI: (map['is_from_ai'] as int) == 1,
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
