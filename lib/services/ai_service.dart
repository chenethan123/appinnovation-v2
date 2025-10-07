import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/mcq.dart';
import '../config/api_config.dart';
import 'enhanced_question_service.dart';

class AIService {

  /// Generate a single MCQ using the backend
  /// Returns null if backend is unavailable (use fallback instead)
  Future<MCQ?> generateMCQ({
    required String subject,
    int choices = 4,
  }) async {
    try {
      print('Calling API: ${ApiConfig.generateMcqEndpoint}');
      
      final response = await http.post(
        Uri.parse(ApiConfig.generateMcqEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subject': subject,
          'choices': choices,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return MCQ.fromJson(data);
      } else {
        print('MCQ Generation Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (error) {
      print('MCQ Generation Exception: $error');
      print('Backend unavailable. Use fallback questions or deploy backend.');
      return null;
    }
  }

  /// Generate multiple MCQs for batch pre-warming
  Future<List<MCQ>> generateMCQBatch({
    required String subject,
    int choices = 4,
    int count = 5,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.generateMcqBatchEndpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'subject': subject,
          'choices': choices,
          'count': count,
        }),
      ).timeout(ApiConfig.timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List;
        return items.map((item) => MCQ.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        print('MCQ Batch Error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (error) {
      print('MCQ Batch Exception: $error');
      return [];
    }
  }

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.healthEndpoint),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (error) {
      print('Health check failed: $error');
      print('Backend not available at: ${ApiConfig.baseUrl}');
      return false;
    }
  }

  /// Legacy method for old FastAPI backend (no longer used)
  /// Use generateMCQ() instead for ChatGPT-powered questions
  @Deprecated('Use generateMCQ() for ChatGPT-powered MCQs')
  Future<Map<String, dynamic>?> generateQuestion({
    required String subject,
    String difficulty = 'medium',
  }) async {
    print('Warning: generateQuestion() is deprecated. Use generateMCQ() instead.');
    // Old FastAPI backend is no longer available
    // Return null to trigger fallback in calling code
    return null;
  }

  /// Legacy method for old FastAPI backend (no longer used)
  /// Use generateMCQBatch() instead for ChatGPT-powered questions
  @Deprecated('Use generateMCQBatch() for ChatGPT-powered MCQs')
  Future<List<Map<String, dynamic>>> generateMultipleQuestions({
    required String subject,
    String difficulty = 'medium',
    int count = 5,
  }) async {
    print('Warning: generateMultipleQuestions() is deprecated. Use generateMCQBatch() instead.');
    // Old FastAPI backend is no longer available
    // Return empty list to trigger fallback in calling code
    return [];
  }

  // Fallback method that returns sample questions when AI service is unavailable
  // Note: This is for the legacy Question format, not the new MCQ format
  Map<String, dynamic> getFallbackQuestion(String subject) {
    final fallbackQuestions = {
      'Mathematics': {
        'question': 'What is the quadratic formula?',
        'options': [
          'x = (-b ± √(b²-4ac)) / 2a',
          'x = (-b ± √(b²+4ac)) / 2a',
          'x = (b ± √(b²-4ac)) / 2a',
          'x = (-b ± √(b²-4ac)) / a'
        ],
        'correct_answer': 'x = (-b ± √(b²-4ac)) / 2a',
        'explanation': 'The quadratic formula is used to solve equations of the form ax² + bx + c = 0. It provides the roots of any quadratic equation. AI-generated, educational purpose only.',
        'difficulty': 'medium'
      },
      'Physics': {
        'question': 'What is Newton\'s second law of motion?',
        'options': [
          'F = ma',
          'F = mv',
          'F = m/a',
          'F = a/m'
        ],
        'correct_answer': 'F = ma',
        'explanation': 'Newton\'s second law states that the force acting on an object equals its mass times its acceleration (F = ma). This fundamental principle describes the relationship between force, mass, and acceleration. AI-generated, educational purpose only.',
        'difficulty': 'medium'
      },
      'Chemistry': {
        'question': 'What is the chemical formula for water?',
        'options': [
          'H2O',
          'H2O2',
          'HO2',
          'H3O'
        ],
        'correct_answer': 'H2O',
        'explanation': 'Water consists of two hydrogen atoms bonded to one oxygen atom, giving it the chemical formula H2O. This is one of the most important compounds for life on Earth. AI-generated, educational purpose only.',
        'difficulty': 'easy'
      },
    };

    return fallbackQuestions[subject] ?? fallbackQuestions['Mathematics']!;
  }
}
