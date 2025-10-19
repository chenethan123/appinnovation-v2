import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import '../models/question.dart';

class QuestionScraperService {
  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.5',
    'Accept-Encoding': 'gzip, deflate',
    'Connection': 'keep-alive',
  };

  // Educational website configurations
  static const Map<String, Map<String, dynamic>> _websiteConfigs = {
    'khan_academy': {
      'base_url': 'https://www.khanacademy.org',
      'subjects': ['math', 'physics', 'chemistry', 'biology'],
      'api_endpoint': '/api/internal/exercises',
    },
    'project_euler': {
      'base_url': 'https://projecteuler.net',
      'subjects': ['mathematics', 'computer_science'],
      'problem_range': [1, 800],
    },
    'isaac_physics': {
      'base_url': 'https://isaacphysics.org',
      'subjects': ['physics'],
      'api_endpoint': '/api/pages/questions',
    },
    'mathopolis': {
      'base_url': 'https://www.mathopolis.com',
      'subjects': ['mathematics'],
      'question_path': '/questions',
    },
    'thatquiz': {
      'base_url': 'https://www.thatquiz.org',
      'subjects': ['math', 'science'],
      'categories': ['arithmetic', 'algebra', 'geometry', 'trigonometry'],
    },
  };

  // College Board course mappings
  static const Map<String, List<String>> _collegeBoardCourses = {
    'AP Calculus AB': ['calculus', 'derivatives', 'integrals', 'limits'],
    'AP Calculus BC': ['calculus', 'series', 'parametric', 'polar'],
    'AP Physics 1': ['mechanics', 'waves', 'electricity'],
    'AP Physics 2': ['thermodynamics', 'fluid_mechanics', 'optics'],
    'AP Physics C Mechanics': ['advanced_mechanics', 'rotational_motion'],
    'AP Physics C E&M': ['electromagnetism', 'circuits', 'magnetic_fields'],
    'AP Chemistry': ['atomic_structure', 'bonding', 'thermochemistry'],
    'AP Biology': ['cell_biology', 'genetics', 'evolution'],
    'AP Statistics': ['probability', 'distributions', 'hypothesis_testing'],
    'Precalculus': ['functions', 'trigonometry', 'sequences'],
    'Algebra 1': ['linear_equations', 'polynomials', 'factoring'],
    'Algebra 2': ['quadratics', 'exponentials', 'logarithms'],
    'Geometry': ['proofs', 'area', 'volume', 'similarity'],
  };

  Future<List<Question>> scrapeQuestions({
    required String subject,
    required int subjectId,
    int count = 5,
    String difficulty = 'medium',
  }) async {
    final questions = <Question>[];
    
    try {
      // Try multiple sources for better coverage
      final sources = _getRelevantSources(subject);
      
      for (final source in sources) {
        if (questions.length >= count) break;
        
        final sourceQuestions = await _scrapeFromSource(
          source, 
          subject, 
          subjectId, 
          count - questions.length,
          difficulty,
        );
        questions.addAll(sourceQuestions);
      }
      
      // If we still need more questions, try College Board mapping
      if (questions.length < count) {
        final collegeBoardQuestions = await _scrapeCollegeBoardQuestions(
          subject, 
          subjectId, 
          count - questions.length,
        );
        questions.addAll(collegeBoardQuestions);
      }
      
    } catch (error) {
      print('Question scraping error: $error');
    }
    
    return questions;
  }

  List<String> _getRelevantSources(String subject) {
    final sources = <String>[];
    
    for (final entry in _websiteConfigs.entries) {
      final config = entry.value;
      final supportedSubjects = config['subjects'] as List<String>;
      
      if (supportedSubjects.any((s) => 
          subject.toLowerCase().contains(s) || 
          s.contains(subject.toLowerCase()))) {
        sources.add(entry.key);
      }
    }
    
    // Always include general sources
    sources.addAll(['khan_academy']);
    
    return sources.toSet().toList();
  }

  Future<List<Question>> _scrapeFromSource(
    String source, 
    String subject, 
    int subjectId, 
    int count,
    String difficulty,
  ) async {
    switch (source) {
      case 'khan_academy':
        return await _scrapeKhanAcademy(subject, subjectId, count);
      case 'project_euler':
        return await _scrapeProjectEuler(subjectId, count);
      case 'isaac_physics':
        return await _scrapeIsaacPhysics(subjectId, count);
      case 'mathopolis':
        return await _scrapeMathopolis(subjectId, count);
      case 'thatquiz':
        return await _scrapeThatQuiz(subject, subjectId, count);
      default:
        return [];
    }
  }

  Future<List<Question>> _scrapeKhanAcademy(String subject, int subjectId, int count) async {
    final questions = <Question>[];
    
    try {
      // Khan Academy has a public API for exercises
      final subjectPath = _mapSubjectToKhanPath(subject);
      final url = 'https://www.khanacademy.org/api/internal/exercises/$subjectPath';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final exercises = data['exercises'] as List? ?? [];
        
        for (int i = 0; i < min(exercises.length, count); i++) {
          final exercise = exercises[i];
          final question = _parseKhanAcademyQuestion(exercise, subjectId);
          if (question != null) questions.add(question);
        }
      }
    } catch (error) {
      print('Khan Academy scraping error: $error');
    }
    
    return questions;
  }

  Future<List<Question>> _scrapeProjectEuler(int subjectId, int count) async {
    final questions = <Question>[];
    
    try {
      final random = Random();
      final config = _websiteConfigs['project_euler']!;
      final range = config['problem_range'] as List<int>;
      
      for (int i = 0; i < count; i++) {
        final problemId = random.nextInt(range[1] - range[0]) + range[0];
        final url = '${config['base_url']}/problem=$problemId';
        
        final response = await http.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(_timeout);
        
        if (response.statusCode == 200) {
          final question = _parseProjectEulerProblem(response.body, subjectId, problemId);
          if (question != null) questions.add(question);
        }
        
        // Rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } catch (error) {
      print('Project Euler scraping error: $error');
    }
    
    return questions;
  }

  Future<List<Question>> _scrapeIsaacPhysics(int subjectId, int count) async {
    final questions = <Question>[];
    
    try {
      // Isaac Physics has an API for questions
      const url = 'https://isaacphysics.org/api/pages/questions';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questionPages = data['results'] as List? ?? [];
        
        for (int i = 0; i < min(questionPages.length, count); i++) {
          final questionData = questionPages[i];
          final question = _parseIsaacPhysicsQuestion(questionData, subjectId);
          if (question != null) questions.add(question);
        }
      }
    } catch (error) {
      print('Isaac Physics scraping error: $error');
    }
    
    return questions;
  }

  Future<List<Question>> _scrapeMathopolis(int subjectId, int count) async {
    final questions = <Question>[];
    
    try {
      const url = 'https://www.mathopolis.com/questions/random';
      
      for (int i = 0; i < count; i++) {
        final response = await http.get(
          Uri.parse(url),
          headers: _headers,
        ).timeout(_timeout);
        
        if (response.statusCode == 200) {
          final question = _parseMathopolisQuestion(response.body, subjectId);
          if (question != null) questions.add(question);
        }
        
        await Future.delayed(const Duration(milliseconds: 300));
      }
    } catch (error) {
      print('Mathopolis scraping error: $error');
    }
    
    return questions;
  }

  Future<List<Question>> _scrapeThatQuiz(String subject, int subjectId, int count) async {
    final questions = <Question>[];
    
    try {
      final category = _mapSubjectToThatQuizCategory(subject);
      final url = 'https://www.thatquiz.org/$category';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final parsedQuestions = _parseThatQuizQuestions(response.body, subjectId, count);
        questions.addAll(parsedQuestions);
      }
    } catch (error) {
      print('ThatQuiz scraping error: $error');
    }
    
    return questions;
  }

  Future<List<Question>> _scrapeCollegeBoardQuestions(String subject, int subjectId, int count) async {
    final questions = <Question>[];
    
    try {
      // Find matching College Board courses
      final matchingCourses = _collegeBoardCourses.entries
          .where((entry) => entry.key.toLowerCase().contains(subject.toLowerCase()) ||
                          entry.value.any((topic) => subject.toLowerCase().contains(topic)))
          .toList();
      
      for (final course in matchingCourses) {
        if (questions.length >= count) break;
        
        final courseQuestions = await _scrapeCollegeBoardCourse(
          course.key, 
          subjectId, 
          count - questions.length,
        );
        questions.addAll(courseQuestions);
      }
    } catch (error) {
      print('College Board scraping error: $error');
    }
    
    return questions;
  }

  Future<List<Question>> _scrapeCollegeBoardCourse(String courseName, int subjectId, int count) async {
    final questions = <Question>[];
    
    try {
      // College Board practice questions URL pattern
      final courseSlug = courseName.toLowerCase().replaceAll(' ', '-');
      final url = 'https://apcentral.collegeboard.org/courses/$courseSlug/exam/practice-questions';
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final parsedQuestions = _parseCollegeBoardQuestions(response.body, subjectId, courseName);
        questions.addAll(parsedQuestions.take(count));
      }
    } catch (error) {
      print('College Board course scraping error: $error');
    }
    
    return questions;
  }

  // Parsing helper methods
  String _mapSubjectToKhanPath(String subject) {
    final mapping = {
      'mathematics': 'math',
      'math': 'math',
      'algebra': 'algebra',
      'geometry': 'geometry',
      'calculus': 'calculus',
      'physics': 'physics',
      'chemistry': 'chemistry',
      'biology': 'biology',
    };
    
    return mapping[subject.toLowerCase()] ?? 'math';
  }

  String _mapSubjectToThatQuizCategory(String subject) {
    final mapping = {
      'mathematics': 'math',
      'math': 'math',
      'arithmetic': 'arithmetic',
      'algebra': 'algebra',
      'geometry': 'geometry',
      'physics': 'science',
      'chemistry': 'science',
      'science': 'science',
    };
    
    return mapping[subject.toLowerCase()] ?? 'math';
  }

  Question? _parseKhanAcademyQuestion(Map<String, dynamic> exercise, int subjectId) {
    try {
      final title = exercise['title'] ?? '';
      final description = exercise['description'] ?? '';
      
      // Khan Academy questions are often interactive, so we create a simplified version
      return Question(
        subjectId: subjectId,
        questionText: '$title: $description',
        options: ['A', 'B', 'C', 'D'], // Placeholder options
        correctAnswer: 'A', // Would need more complex parsing
        explanation: 'Khan Academy practice question. Visit khanacademy.org for interactive version. Educational content only.',
        difficulty: 'medium',
        createdAt: DateTime.now(),
        isFromAI: false,
        sourceUrl: exercise['url'],
      );
    } catch (error) {
      return null;
    }
  }

  Question? _parseProjectEulerProblem(String html, int subjectId, int problemId) {
    try {
      final document = parse(html);
      final problemText = document.querySelector('.problem_content')?.text ?? '';
      
      if (problemText.isNotEmpty) {
        return Question(
          subjectId: subjectId,
          questionText: problemText,
          options: ['Numerical Answer Required'], // Project Euler problems are computational
          correctAnswer: 'Numerical Answer Required',
          explanation: 'Project Euler computational problem. Requires programming/mathematical solution. Educational content only.',
          difficulty: 'hard',
          createdAt: DateTime.now(),
          isFromAI: false,
          sourceUrl: 'https://projecteuler.net/problem=$problemId',
        );
      }
    } catch (error) {
      return null;
    }
    return null;
  }

  Question? _parseIsaacPhysicsQuestion(Map<String, dynamic> questionData, int subjectId) {
    try {
      final title = questionData['title'] ?? '';
      final content = questionData['value'] ?? '';
      
      return Question(
        subjectId: subjectId,
        questionText: '$title\n$content',
        options: ['Multiple choice options would be parsed from content'],
        correctAnswer: 'Requires detailed parsing',
        explanation: 'Isaac Physics question. Visit isaacphysics.org for complete interactive version. Educational content only.',
        difficulty: 'medium',
        createdAt: DateTime.now(),
        isFromAI: false,
        sourceUrl: questionData['canonicalSourceFile'],
      );
    } catch (error) {
      return null;
    }
  }

  Question? _parseMathopolisQuestion(String html, int subjectId) {
    try {
      final document = parse(html);
      final questionText = document.querySelector('.question')?.text ?? '';
      final options = document.querySelectorAll('.option').map((e) => e.text).toList();
      
      if (questionText.isNotEmpty && options.isNotEmpty) {
        return Question(
          subjectId: subjectId,
          questionText: questionText,
          options: options,
          correctAnswer: options.first, // Would need correct answer parsing
          explanation: 'Mathopolis practice question. Educational content only.',
          difficulty: 'medium',
          createdAt: DateTime.now(),
          isFromAI: false,
          sourceUrl: 'https://www.mathopolis.com',
        );
      }
    } catch (error) {
      return null;
    }
    return null;
  }

  List<Question> _parseThatQuizQuestions(String html, int subjectId, int count) {
    final questions = <Question>[];
    
    try {
      final document = parse(html);
      final questionElements = document.querySelectorAll('.quiz-question');
      
      for (int i = 0; i < min(questionElements.length, count); i++) {
        final element = questionElements[i];
        final questionText = element.querySelector('.question-text')?.text ?? '';
        final options = element.querySelectorAll('.option').map((e) => e.text).toList();
        
        if (questionText.isNotEmpty) {
          questions.add(Question(
            subjectId: subjectId,
            questionText: questionText,
            options: options.isNotEmpty ? options : ['True', 'False'],
            correctAnswer: options.isNotEmpty ? options.first : 'True',
            explanation: 'ThatQuiz practice question. Educational content only.',
            difficulty: 'medium',
            createdAt: DateTime.now(),
            isFromAI: false,
            sourceUrl: 'https://www.thatquiz.org',
          ));
        }
      }
    } catch (error) {
      print('ThatQuiz parsing error: $error');
    }
    
    return questions;
  }

  List<Question> _parseCollegeBoardQuestions(String html, int subjectId, String courseName) {
    final questions = <Question>[];
    
    try {
      final document = parse(html);
      final questionElements = document.querySelectorAll('.practice-question');
      
      for (final element in questionElements) {
        final questionText = element.querySelector('.question-stem')?.text ?? '';
        final options = element.querySelectorAll('.answer-choice').map((e) => e.text).toList();
        
        if (questionText.isNotEmpty) {
          questions.add(Question(
            subjectId: subjectId,
            questionText: questionText,
            options: options.isNotEmpty ? options : ['A', 'B', 'C', 'D'],
            correctAnswer: options.isNotEmpty ? options.first : 'A',
            explanation: 'College Board $courseName practice question. Educational content only.',
            difficulty: 'medium',
            createdAt: DateTime.now(),
            isFromAI: false,
            sourceUrl: 'https://apcentral.collegeboard.org',
          ));
        }
      }
    } catch (error) {
      print('College Board parsing error: $error');
    }
    
    return questions;
  }

  // Fallback questions when scraping fails
  List<Question> getFallbackQuestions(String subject, int subjectId, int count) {
    final fallbackQuestions = {
      'mathematics': [
        {
          'question': 'What is the derivative of x²?',
          'options': ['2x', 'x', '2', 'x²'],
          'correct': '2x',
          'explanation': 'The derivative of x² is 2x using the power rule.',
        },
        {
          'question': 'What is the integral of 2x?',
          'options': ['x²', 'x² + C', '2', '2x²'],
          'correct': 'x² + C',
          'explanation': 'The integral of 2x is x² + C, where C is the constant of integration.',
        },
      ],
      'physics': [
        {
          'question': 'What is the unit of force?',
          'options': ['Newton', 'Joule', 'Watt', 'Pascal'],
          'correct': 'Newton',
          'explanation': 'The SI unit of force is the Newton (N), defined as kg⋅m/s².',
        },
      ],
      'chemistry': [
        {
          'question': 'What is the atomic number of Carbon?',
          'options': ['6', '12', '14', '8'],
          'correct': '6',
          'explanation': 'Carbon has 6 protons, giving it an atomic number of 6.',
        },
      ],
    };

    final subjectQuestions = fallbackQuestions[subject.toLowerCase()] ?? fallbackQuestions['mathematics']!;
    final questions = <Question>[];

    for (int i = 0; i < min(count, subjectQuestions.length); i++) {
      final q = subjectQuestions[i];
      questions.add(Question(
        subjectId: subjectId,
        questionText: q['question']!.toString(),
        options: q['options'] as List<String>,
        correctAnswer: q['correct']!.toString(),
        explanation: '${q['explanation']} Educational content only.',
        difficulty: 'medium',
        createdAt: DateTime.now(),
        isFromAI: false,
      ));
    }

    return questions;
  }
}
