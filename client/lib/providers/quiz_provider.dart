/**
 * Quiz Provider
 * State management for quiz sessions
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/quiz_session.dart';
import '../models/question.dart';
import '../services/api_service.dart';
import '../database/database_helper.dart';

class QuizState {
  final QuizSession? currentSession;
  final int currentQuestionIndex;
  final Map<int, String> userAnswers;
  final Map<int, bool> results;
  final bool isLoading;

  QuizState({
    this.currentSession,
    this.currentQuestionIndex = 0,
    Map<int, String>? userAnswers,
    Map<int, bool>? results,
    this.isLoading = false,
  })  : userAnswers = userAnswers ?? {},
        results = results ?? {};

  QuizState copyWith({
    QuizSession? currentSession,
    int? currentQuestionIndex,
    Map<int, String>? userAnswers,
    Map<int, bool>? results,
    bool? isLoading,
  }) {
    return QuizState(
      currentSession: currentSession ?? this.currentSession,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      userAnswers: userAnswers ?? this.userAnswers,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  Question? get currentQuestion {
    if (currentSession == null || currentSession!.questions.isEmpty) return null;
    if (currentQuestionIndex >= currentSession!.questions.length) return null;
    return currentSession!.questions[currentQuestionIndex];
  }

  bool get hasMoreQuestions {
    if (currentSession == null) return false;
    return currentQuestionIndex < currentSession!.questions.length - 1;
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState());

  // Overload 1: By subject name (for widgets)
  Future<void> startQuiz(String subjectName, {int numQuestions = 5, String? difficulty}) async {
    state = state.copyWith(isLoading: true);
    
    try {
      // Get subject ID from database
      final subject = await DatabaseHelper.instance.getSubjectByName(subjectName);
      if (subject == null || subject.id == null) {
        throw Exception('Subject not found: $subjectName');
      }
      
      await startQuizById(
        subjectId: subject.id!,
        numQuestions: numQuestions,
        difficulty: difficulty,
      );
    } catch (e) {
      print('Error starting quiz by name: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  // Overload 2: By subject ID (for direct API calls)
  Future<void> startQuizById({
    required int subjectId,
    required int numQuestions,
    String? difficulty,
  }) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final session = await ApiService.instance.startQuiz(
        subjectId: subjectId,
        numQuestions: numQuestions,
        difficulty: difficulty,
      );
      
      // Save to local database
      await DatabaseHelper.instance.insertQuizSession(session);
      
      state = QuizState(
        currentSession: session,
        currentQuestionIndex: 0,
        userAnswers: {},
        results: {},
        isLoading: false,
      );
    } catch (e) {
      print('Error starting quiz: $e');
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> submitAnswer(String answer) async {
    if (state.currentSession == null || state.currentQuestion == null) {
      throw Exception('No active quiz session');
    }

    try {
      final result = await ApiService.instance.submitAnswer(
        sessionId: state.currentSession!.id,
        questionId: state.currentQuestion!.id!,
        userAnswer: answer,
      );

      // Update state with answer and result
      final newAnswers = Map<int, String>.from(state.userAnswers);
      final newResults = Map<int, bool>.from(state.results);
      newAnswers[state.currentQuestionIndex] = answer;
      newResults[state.currentQuestionIndex] = result['is_correct'];

      state = state.copyWith(
        userAnswers: newAnswers,
        results: newResults,
      );

      return result;
    } catch (e) {
      print('Error submitting answer: $e');
      rethrow;
    }
  }

  void nextQuestion() {
    if (state.hasMoreQuestions) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  Future<Map<String, dynamic>> completeQuiz() async {
    if (state.currentSession == null) {
      throw Exception('No active quiz session');
    }

    try {
      final result = await ApiService.instance.completeQuiz(state.currentSession!.id);
      
      // Update local session
      final updatedSession = state.currentSession!.copyWith(
        completedAt: DateTime.now(),
        score: result['score'],
      );
      await DatabaseHelper.instance.updateQuizSession(updatedSession);
      
      // Reset state
      state = QuizState();
      
      return result;
    } catch (e) {
      print('Error completing quiz: $e');
      rethrow;
    }
  }

  void reset() {
    state = QuizState();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});
