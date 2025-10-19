/**
 * API Service
 * Handles all HTTP requests to FormulaQuizzer Server
 * With offline support and error handling
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/subject.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';

class ApiService {
  static final ApiService instance = ApiService._init();
  ApiService._init();

  // ==================== HEALTH CHECK ====================

  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.healthEndpoint))
          .timeout(ApiConfig.connectTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ApiConfig.log('Health check: ${data['status']}');
        return data['status'] == 'healthy';
      }
      return false;
    } catch (e) {
      ApiConfig.log('Health check failed: $e');
      return false;
    }
  }

  // ==================== SUBJECTS ====================

  Future<List<Subject>> getAllSubjects() async {
    try {
      final response = await http
          .get(Uri.parse(ApiConfig.subjectsEndpoint))
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final subjects = (data['data'] as List)
            .map((json) => Subject.fromJson(json))
            .toList();
        ApiConfig.log('Fetched ${subjects.length} subjects');
        return subjects;
      }
      throw Exception('Failed to load subjects: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error fetching subjects: $e');
      rethrow;
    }
  }

  Future<Subject> getSubjectById(int id) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.subjectsEndpoint}/$id'))
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return Subject.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to load subject: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error fetching subject $id: $e');
      rethrow;
    }
  }

  Future<Subject> createSubject({
    required String name,
    required String description,
    required String color,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.subjectsEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'description': description,
          'color': color,
        }),
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 201) {
        final subject = Subject.fromJson(json.decode(response.body));
        ApiConfig.log('Created subject: ${subject.name}');
        return subject;
      }
      throw Exception('Failed to create subject: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error creating subject: $e');
      rethrow;
    }
  }

  Future<Subject> updateSubject(int id, Map<String, dynamic> updates) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.subjectsEndpoint}/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(updates),
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        return Subject.fromJson(json.decode(response.body));
      }
      throw Exception('Failed to update subject: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error updating subject $id: $e');
      rethrow;
    }
  }

  Future<void> deleteSubject(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('${ApiConfig.subjectsEndpoint}/$id'))
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 204) {
        ApiConfig.log('Deleted subject $id');
        return;
      }
      throw Exception('Failed to delete subject: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error deleting subject $id: $e');
      rethrow;
    }
  }

  // ==================== QUESTIONS ====================

  Future<List<Question>> getQuestionsBySubjectId(int subjectId) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.questionsEndpoint}?subject_id=$subjectId'))
          .timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['data'] as List)
            .map((json) => Question.fromJson(json))
            .toList();
      }
      throw Exception('Failed to load questions: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error fetching questions for subject $subjectId: $e');
      rethrow;
    }
  }

  // ==================== AI GENERATION ====================

  Future<Question> generateQuestion({
    required int subjectId,
    String difficulty = 'medium',
    int numChoices = 4,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.aiEndpoint}/generate-question'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subject_id': subjectId,
          'difficulty': difficulty,
          'num_choices': numChoices,
        }),
      ).timeout(const Duration(seconds: 30)); // AI calls take longer

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ApiConfig.log('Generated AI question (${data['generation_time_ms']}ms, cache: ${data['cache_hit']})');
        return Question.fromJson(data);
      }
      throw Exception('Failed to generate question: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error generating question: $e');
      rethrow;
    }
  }

  Future<List<Question>> generateQuestionsBatch({
    required int subjectId,
    required int count,
    String difficulty = 'medium',
    int numChoices = 4,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.aiEndpoint}/generate-questions-batch'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subject_id': subjectId,
          'count': count,
          'difficulty': difficulty,
          'num_choices': numChoices,
        }),
      ).timeout(const Duration(minutes: 2)); // Batch can take time

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final questions = (data['questions'] as List)
            .map((json) => Question.fromJson(json))
            .toList();
        ApiConfig.log('Generated ${questions.length} AI questions (${data['total_generation_time_ms']}ms)');
        return questions;
      }
      throw Exception('Failed to generate questions: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error generating questions batch: $e');
      rethrow;
    }
  }

  // ==================== QUIZ ====================

  Future<QuizSession> startQuiz({
    required int subjectId,
    required int numQuestions,
    String? difficulty,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.quizEndpoint}/start'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'subject_id': subjectId,
          'num_questions': numQuestions,
          if (difficulty != null) 'difficulty': difficulty,
        }),
      ).timeout(const Duration(seconds: 60)); // May need to generate questions

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ApiConfig.log('Started quiz session: ${data['session_id']}');
        return QuizSession.fromJson(data);
      }
      throw Exception('Failed to start quiz: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error starting quiz: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitAnswer({
    required String sessionId,
    required int questionId,
    required String userAnswer,
    int? timeSpentSeconds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.quizEndpoint}/answer'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'session_id': sessionId,
          'question_id': questionId,
          'user_answer': userAnswer,
          if (timeSpentSeconds != null) 'time_spent_seconds': timeSpentSeconds,
        }),
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'is_correct': data['is_correct'],
          'correct_answer': data['correct_answer'],
          'explanation': data['explanation'],
        };
      }
      throw Exception('Failed to submit answer: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error submitting answer: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> completeQuiz(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.quizEndpoint}/complete'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'session_id': sessionId}),
      ).timeout(ApiConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ApiConfig.log('Completed quiz: ${data['score']}/${data['total_questions']}');
        return data;
      }
      throw Exception('Failed to complete quiz: ${response.statusCode}');
    } catch (e) {
      ApiConfig.log('Error completing quiz: $e');
      rethrow;
    }
  }
}
