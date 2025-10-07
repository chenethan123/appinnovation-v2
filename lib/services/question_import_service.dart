import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import '../models/question.dart';
import '../database/question_database.dart';
import '../data/subject_specific_questions.dart';
import 'dataset_downloader.dart';

class QuestionImportService {
  final QuestionDatabase _questionDb = QuestionDatabase();
  final DatasetDownloader _downloader = DatasetDownloader();

  /// Import questions from multiple sources and populate the database
  Future<Map<String, dynamic>> importAllQuestions() async {
    final results = <String, dynamic>{
      'total_imported': 0,
      'sources': <String, int>{},
      'errors': <String>[],
    };

    try {
      // 1. Import from existing question bank
      final bankQuestions = await _importFromQuestionBank();
      results['sources']['Question Bank'] = bankQuestions.length;
      results['total_imported'] += bankQuestions.length;

      // 2. Download and import from Open Trivia Database
      try {
        await _downloader.downloadAndStoreQuestions();
        final triviaCount = await _getQuestionCountBySource('Open Trivia Database');
        results['sources']['Open Trivia Database'] = triviaCount;
        results['total_imported'] += triviaCount;
      } catch (e) {
        results['errors'].add('Open Trivia Database: $e');
      }

      // 3. Import sample educational datasets
      final educationalQuestions = await _importEducationalSamples();
      results['sources']['Educational Samples'] = educationalQuestions.length;
      results['total_imported'] += educationalQuestions.length;

      // 4. Import AP-style questions
      final apQuestions = await _importAPStyleQuestions();
      results['sources']['AP Style Questions'] = apQuestions.length;
      results['total_imported'] += apQuestions.length;

      print('Question import completed: ${results['total_imported']} total questions');
      return results;

    } catch (e) {
      results['errors'].add('General import error: $e');
      return results;
    }
  }

  /// Import questions from the subject-specific question bank
  Future<List<Question>> _importFromQuestionBank() async {
    try {
      // Import from the new subject_specific_questions.dart file
      final questions = <Question>[];
      final allSubjects = SubjectSpecificQuestions.getAllSubjects();

      for (final subjectName in allSubjects) {
        final subjectQuestions = SubjectSpecificQuestions.getQuestionsForSubject(subjectName, 0);
        questions.addAll(subjectQuestions);
      }

      await _questionDb.insertQuestions(questions);
      return questions;
    } catch (e) {
      print('Error importing subject-specific questions: $e');
      return [];
    }
  }

  /// Import educational sample questions
  Future<List<Question>> _importEducationalSamples() async {
    final questions = <Question>[];

    // Mathematics questions
    final mathQuestions = [
      {
        'question': 'What is the derivative of x²?',
        'options': ['2x', 'x²', '2', 'x'],
        'correct': '2x',
        'explanation': 'Using the power rule: d/dx(x²) = 2x¹ = 2x',
        'subject': 'Mathematics',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the integral of 2x?',
        'options': ['x²', 'x² + C', '2', '2x²'],
        'correct': 'x² + C',
        'explanation': 'The integral of 2x is x² + C, where C is the constant of integration',
        'subject': 'Mathematics',
        'difficulty': 'medium',
      },
      {
        'question': 'What is the quadratic formula?',
        'options': [
          'x = (-b ± √(b² - 4ac)) / 2a',
          'x = (-b ± √(b² + 4ac)) / 2a',
          'x = (b ± √(b² - 4ac)) / 2a',
          'x = (-b ± √(b² - 4ac)) / a'
        ],
        'correct': 'x = (-b ± √(b² - 4ac)) / 2a',
        'explanation': 'The quadratic formula solves ax² + bx + c = 0',
        'subject': 'Mathematics',
        'difficulty': 'easy',
      },
    ];

    // Physics questions
    final physicsQuestions = [
      {
        'question': 'What is Newton\'s second law of motion?',
        'options': ['F = ma', 'E = mc²', 'v = u + at', 'P = mv'],
        'correct': 'F = ma',
        'explanation': 'Newton\'s second law states that Force equals mass times acceleration',
        'subject': 'Physics',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the speed of light in vacuum?',
        'options': ['3 × 10⁸ m/s', '3 × 10⁶ m/s', '3 × 10¹⁰ m/s', '3 × 10⁴ m/s'],
        'correct': '3 × 10⁸ m/s',
        'explanation': 'The speed of light in vacuum is approximately 299,792,458 m/s or 3 × 10⁸ m/s',
        'subject': 'Physics',
        'difficulty': 'medium',
      },
    ];

    // Chemistry questions
    final chemistryQuestions = [
      {
        'question': 'What is the chemical symbol for gold?',
        'options': ['Go', 'Gd', 'Au', 'Ag'],
        'correct': 'Au',
        'explanation': 'Gold\'s chemical symbol is Au, from the Latin word "aurum"',
        'subject': 'Chemistry',
        'difficulty': 'easy',
      },
      {
        'question': 'What is Avogadro\'s number?',
        'options': ['6.022 × 10²³', '6.022 × 10²²', '6.022 × 10²⁴', '6.022 × 10²¹'],
        'correct': '6.022 × 10²³',
        'explanation': 'Avogadro\'s number is approximately 6.022 × 10²³ particles per mole',
        'subject': 'Chemistry',
        'difficulty': 'medium',
      },
    ];

    // Biology questions
    final biologyQuestions = [
      {
        'question': 'What is the powerhouse of the cell?',
        'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Endoplasmic reticulum'],
        'correct': 'Mitochondria',
        'explanation': 'Mitochondria produce ATP, the energy currency of cells',
        'subject': 'Biology',
        'difficulty': 'easy',
      },
      {
        'question': 'What is the process by which plants make food?',
        'options': ['Respiration', 'Photosynthesis', 'Digestion', 'Fermentation'],
        'correct': 'Photosynthesis',
        'explanation': 'Photosynthesis converts light energy into chemical energy (glucose)',
        'subject': 'Biology',
        'difficulty': 'easy',
      },
    ];

    // Convert all questions to Question objects
    final allSampleQuestions = [
      ...mathQuestions,
      ...physicsQuestions,
      ...chemistryQuestions,
      ...biologyQuestions,
    ];

    for (final questionData in allSampleQuestions) {
      final question = Question(
        subjectId: 0,
        subjectName: questionData['subject'] as String,
        questionText: questionData['question'] as String,
        options: List<String>.from(questionData['options'] as List),
        correctAnswer: questionData['correct'] as String,
        explanation: questionData['explanation'] as String,
        difficulty: questionData['difficulty'] as String,
        category: questionData['subject'] as String,
        questionType: 'multiple',
        source: 'Educational Samples',
        isFromAI: false,
        createdAt: DateTime.now(),
      );
      questions.add(question);
    }

    await _questionDb.insertQuestions(questions);
    return questions;
  }

  /// Import AP-style questions for various subjects
  Future<List<Question>> _importAPStyleQuestions() async {
    final questions = <Question>[];

    final apQuestions = [
      // AP Calculus
      {
        'question': 'Find the limit: lim(x→0) (sin x)/x',
        'options': ['0', '1', '∞', 'undefined'],
        'correct': '1',
        'explanation': 'This is a fundamental limit in calculus: lim(x→0) (sin x)/x = 1',
        'subject': 'AP Calculus AB',
        'difficulty': 'hard',
      },
      // AP Physics
      {
        'question': 'A ball is thrown horizontally from a cliff. Which statement is true about its motion?',
        'options': [
          'Horizontal velocity remains constant',
          'Vertical velocity remains constant',
          'Both velocities remain constant',
          'Both velocities change at the same rate'
        ],
        'correct': 'Horizontal velocity remains constant',
        'explanation': 'In projectile motion, horizontal velocity is constant (ignoring air resistance)',
        'subject': 'AP Physics 1',
        'difficulty': 'medium',
      },
      // AP Chemistry
      {
        'question': 'What is the electron configuration of oxygen?',
        'options': ['1s² 2s² 2p⁴', '1s² 2s² 2p⁶', '1s² 2s² 2p²', '1s² 2s⁴'],
        'correct': '1s² 2s² 2p⁴',
        'explanation': 'Oxygen has 8 electrons: 2 in 1s, 2 in 2s, and 4 in 2p orbitals',
        'subject': 'AP Chemistry',
        'difficulty': 'medium',
      },
      // AP Biology
      {
        'question': 'Which process occurs in the mitochondrial matrix?',
        'options': ['Glycolysis', 'Krebs cycle', 'Electron transport', 'Fermentation'],
        'correct': 'Krebs cycle',
        'explanation': 'The Krebs cycle (citric acid cycle) occurs in the mitochondrial matrix',
        'subject': 'AP Biology',
        'difficulty': 'medium',
      },
      // AP Computer Science
      {
        'question': 'What is the time complexity of binary search?',
        'options': ['O(n)', 'O(log n)', 'O(n²)', 'O(1)'],
        'correct': 'O(log n)',
        'explanation': 'Binary search eliminates half the search space each iteration',
        'subject': 'AP Computer Science A',
        'difficulty': 'medium',
      },
    ];

    for (final questionData in apQuestions) {
      final question = Question(
        subjectId: 0,
        subjectName: questionData['subject'] as String,
        questionText: questionData['question'] as String,
        options: List<String>.from(questionData['options'] as List),
        correctAnswer: questionData['correct'] as String,
        explanation: questionData['explanation'] as String,
        difficulty: questionData['difficulty'] as String,
        category: questionData['subject'] as String,
        questionType: 'multiple',
        source: 'AP Style Questions',
        isFromAI: false,
        createdAt: DateTime.now(),
      );
      questions.add(question);
    }

    await _questionDb.insertQuestions(questions);
    return questions;
  }

  /// Load question bank data (placeholder - would load from actual file)
  Future<Map<String, dynamic>> _loadQuestionBankData() async {
    // This would normally load from the question_bank.dart file
    // For now, return empty map as the file structure may vary
    return {};
  }

  /// Get count of questions by source
  Future<int> _getQuestionCountBySource(String source) async {
    final db = await _questionDb.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM questions WHERE source = ?',
      [source],
    );
    return result.first['count'] as int;
  }

  /// Clear all questions from database
  Future<void> clearAllQuestions() async {
    await _questionDb.clearAllQuestions();
  }

  /// Get import statistics
  Future<Map<String, dynamic>> getImportStats() async {
    return await _questionDb.getDatabaseStats();
  }
}
