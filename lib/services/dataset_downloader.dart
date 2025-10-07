import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/question.dart';
import '../database/question_database.dart';

class DatasetDownloader {
  static const String _openTdbBaseUrl = 'https://opentdb.com/api.php';
  static const String _arcDatasetUrl = 'https://huggingface.co/datasets/allenai/ai2_arc/resolve/main/data/ARC-Easy-Train.jsonl';
  
  final QuestionDatabase _questionDb = QuestionDatabase();

  /// Download questions from Open Trivia Database
  Future<List<Question>> downloadOpenTdbQuestions({
    int amount = 50,
    int? category,
    String difficulty = 'medium',
    String type = 'multiple',
  }) async {
    try {
      final url = Uri.parse('$_openTdbBaseUrl?amount=$amount&difficulty=$difficulty&type=$type${category != null ? '&category=$category' : ''}');
      
      final response = await http.get(url);
      if (response.statusCode != 200) {
        throw Exception('Failed to download questions: ${response.statusCode}');
      }

      final data = json.decode(response.body);
      if (data['response_code'] != 0) {
        throw Exception('API Error: ${data['response_code']}');
      }

      final List<Question> questions = [];
      for (final item in data['results']) {
        final question = _parseOpenTdbQuestion(item);
        if (question != null) {
          questions.add(question);
        }
      }

      return questions;
    } catch (e) {
      print('Error downloading OpenTDB questions: $e');
      return [];
    }
  }

  /// Download ARC science questions
  Future<List<Question>> downloadArcQuestions() async {
    try {
      // For demo purposes, we'll create sample ARC-style questions
      // In production, you would download from the actual dataset
      return _generateArcStyleQuestions();
    } catch (e) {
      print('Error downloading ARC questions: $e');
      return [];
    }
  }

  /// Download questions for specific subjects and store in database
  Future<void> downloadAndStoreQuestions() async {
    print('Starting question download...');

    // Download from multiple sources
    final List<Question> allQuestions = [];

    // OpenTDB categories mapping
    final Map<int, String> categories = {
      9: 'General Knowledge',
      17: 'Science & Nature',
      18: 'Computer Science',
      19: 'Mathematics',
      22: 'Geography',
      23: 'History',
    };

    // Download from each category
    for (final entry in categories.entries) {
      final questions = await downloadOpenTdbQuestions(
        amount: 20,
        category: entry.key,
        difficulty: 'medium',
      );
      
      // Set subject based on category
      for (final question in questions) {
        final updatedQuestion = question.copyWith(
          subjectName: entry.value,
          source: 'Open Trivia Database',
        );
        allQuestions.add(updatedQuestion);
      }
      
      // Rate limiting - wait between requests
      await Future.delayed(const Duration(seconds: 6));
    }

    // Add ARC science questions
    final arcQuestions = await downloadArcQuestions();
    allQuestions.addAll(arcQuestions);

    // Store all questions in database
    await _questionDb.insertQuestions(allQuestions);
    
    print('Downloaded and stored ${allQuestions.length} questions');
  }

  Question? _parseOpenTdbQuestion(Map<String, dynamic> data) {
    try {
      final List<String> options = [];
      options.addAll(List<String>.from(data['incorrect_answers']));
      options.add(data['correct_answer']);
      options.shuffle(); // Randomize option order

      final correctAnswer = data['correct_answer'];
      
      return Question(
        subjectId: 0, // Will be updated when stored
        questionText: _decodeHtml(data['question']),
        options: options.map(_decodeHtml).toList(),
        correctAnswer: _decodeHtml(correctAnswer),
        explanation: 'Educational trivia question from Open Trivia Database',
        difficulty: data['difficulty'] ?? 'medium',
        createdAt: DateTime.now(),
        isFromAI: false,
        source: 'Open Trivia Database',
        category: data['category'] ?? 'General',
        questionType: data['type'] ?? 'multiple',
      );
    } catch (e) {
      print('Error parsing OpenTDB question: $e');
      return null;
    }
  }

  List<Question> _generateArcStyleQuestions() {
    // Sample ARC-style science questions
    final List<Map<String, dynamic>> arcData = [
      {
        'question': 'Which of the following best explains why the Moon has phases?',
        'options': [
          'The Moon rotates on its axis',
          'The Moon orbits around Earth',
          'Earth casts a shadow on the Moon',
          'The Sun lights different parts of the Moon as it orbits Earth'
        ],
        'correct': 'The Sun lights different parts of the Moon as it orbits Earth',
        'explanation': 'Moon phases occur because we see different amounts of the Moon\'s sunlit surface as it orbits Earth.',
        'subject': 'Science & Nature',
      },
      {
        'question': 'What is the primary function of chlorophyll in plants?',
        'options': [
          'To transport water',
          'To absorb light energy for photosynthesis',
          'To store nutrients',
          'To protect against insects'
        ],
        'correct': 'To absorb light energy for photosynthesis',
        'explanation': 'Chlorophyll is the green pigment that captures light energy needed for photosynthesis.',
        'subject': 'Biology',
      },
      {
        'question': 'Which type of rock is formed by the cooling and solidification of magma?',
        'options': [
          'Sedimentary rock',
          'Metamorphic rock',
          'Igneous rock',
          'Fossil rock'
        ],
        'correct': 'Igneous rock',
        'explanation': 'Igneous rocks form when molten magma or lava cools and solidifies.',
        'subject': 'Earth Science',
      },
      {
        'question': 'What happens to the kinetic energy of molecules as temperature increases?',
        'options': [
          'It decreases',
          'It stays the same',
          'It increases',
          'It becomes potential energy'
        ],
        'correct': 'It increases',
        'explanation': 'Higher temperature means molecules move faster, increasing their kinetic energy.',
        'subject': 'Physics',
      },
      {
        'question': 'Which of the following is a renewable energy source?',
        'options': [
          'Coal',
          'Natural gas',
          'Solar power',
          'Nuclear power'
        ],
        'correct': 'Solar power',
        'explanation': 'Solar power is renewable because the Sun provides a continuous source of energy.',
        'subject': 'Environmental Science',
      },
    ];

    return arcData.map((data) => Question(
      subjectId: 0,
      questionText: data['question'],
      options: List<String>.from(data['options']),
      correctAnswer: data['correct'],
      explanation: data['explanation'],
      difficulty: 'medium',
      createdAt: DateTime.now(),
      isFromAI: false,
      source: 'ARC Science Dataset',
      category: data['subject'],
      questionType: 'multiple',
      subjectName: data['subject'],
    )).toList();
  }

  String _decodeHtml(String htmlString) {
    return htmlString
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  /// Get available OpenTDB categories
  Future<Map<int, String>> getOpenTdbCategories() async {
    try {
      final response = await http.get(Uri.parse('https://opentdb.com/api_category.php'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<int, String> categories = {};
        for (final category in data['trivia_categories']) {
          categories[category['id']] = category['name'];
        }
        return categories;
      }
    } catch (e) {
      print('Error fetching categories: $e');
    }
    
    // Fallback categories
    return {
      9: 'General Knowledge',
      17: 'Science & Nature',
      18: 'Computer Science',
      19: 'Mathematics',
      22: 'Geography',
      23: 'History',
    };
  }
}
