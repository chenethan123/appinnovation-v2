import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcq.dart';
import '../services/api_service.dart';

// Import MCQOption from mcq.dart
import '../models/mcq.dart' show MCQOption;

/// State for the MCQ quiz session
class MCQQuizState {
  final MCQ? currentMCQ;
  final List<MCQ> questionQueue;
  final int currentQuestionIndex;
  final String? currentSubject;
  final String? userAnswer;
  final bool isAnswered;
  final bool isLoading;
  final String? error;
  final bool timerActive;
  final DateTime? nextQuizTime;

  MCQQuizState({
    this.currentMCQ,
    this.questionQueue = const [],
    this.currentQuestionIndex = 0,
    this.currentSubject,
    this.userAnswer,
    this.isAnswered = false,
    this.isLoading = false,
    this.error,
    this.timerActive = false,
    this.nextQuizTime,
  });

  MCQQuizState copyWith({
    MCQ? currentMCQ,
    List<MCQ>? questionQueue,
    int? currentQuestionIndex,
    String? currentSubject,
    String? userAnswer,
    bool? isAnswered,
    bool? isLoading,
    String? error,
    bool? timerActive,
    DateTime? nextQuizTime,
    bool clearMCQ = false,
    bool clearQueue = false,
    bool clearError = false,
  }) {
    return MCQQuizState(
      currentMCQ: clearMCQ ? null : (currentMCQ ?? this.currentMCQ),
      questionQueue: clearQueue ? [] : (questionQueue ?? this.questionQueue),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      currentSubject: currentSubject ?? this.currentSubject,
      userAnswer: userAnswer ?? this.userAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      timerActive: timerActive ?? this.timerActive,
      nextQuizTime: nextQuizTime ?? this.nextQuizTime,
    );
  }
  
  bool get hasMoreQuestions => currentQuestionIndex < questionQueue.length - 1;
  int get totalQuestions => questionQueue.length;
  int get currentQuestionNumber => questionQueue.isEmpty ? 0 : currentQuestionIndex + 1;
}

/// Provider for MCQ quiz management - connects to SERVER
class MCQQuizNotifier extends StateNotifier<MCQQuizState> {
  final ApiService _apiService;

  MCQQuizNotifier(this._apiService) : super(MCQQuizState());

  /// Generate MCQ by calling SERVER API
  Future<void> generateMCQ(String subject, {String? difficulty, int questionCount = 1}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      currentSubject: subject,
    );

    try {
      // Call server to generate question via AI
      final question = await _apiService.generateQuestion(
        subjectId: 1, // TODO: Get actual subject ID
        difficulty: difficulty ?? 'medium',
      );

      if (question != null) {
        // Convert Question to MCQ format
        // Convert List<String> options to List<MCQOption>
        final mcqOptions = question.options.asMap().entries.map((entry) {
          final letter = String.fromCharCode(65 + entry.key); // 0='A', 1='B', etc.
          return MCQOption(letter: letter, text: entry.value);
        }).toList();
        
        // Get correct option letter (correctAnswer is 0-based index as String)
        final correctIndex = int.tryParse(question.correctAnswer) ?? 0;
        final correctLetter = String.fromCharCode(65 + correctIndex);
        
        final mcq = MCQ(
          id: question.id.toString(),
          subject: subject,
          stem: question.questionText,
          options: mcqOptions,
          correctOption: correctLetter,
          explanationCorrect: question.explanation ?? 'No explanation available',
          explanationsByOption: {}, // Server doesn't provide per-option explanations
          difficulty: question.difficulty,
          sourceHint: 'AI Generated',
        );

        if (!mounted) return;
        state = state.copyWith(
          currentMCQ: mcq,
          questionQueue: [mcq],
          currentQuestionIndex: 0,
          isLoading: false,
          clearError: true,
        );
      } else {
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to generate question from server',
        );
      }
    } catch (e) {
      print('❌ Error generating MCQ: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
    }
  }

  /// Generate random MCQ from any subject
  Future<void> generateRandomMCQ({String? difficulty}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      // For now, just show an error - will implement later
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Random MCQ generation not yet implemented.\n\nPlease select a specific subject from the Quiz tab.',
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: 'Error: $e',
      );
    }
  }

  /// Submit answer (synchronous for now)
  void submitAnswer(String answer) {
    if (!mounted) return;
    state = state.copyWith(
      userAnswer: answer,
      isAnswered: true,
    );
  }

  /// Move to next question
  void nextQuestion() {
    if (!mounted) return;
    if (state.hasMoreQuestions) {
      final nextIndex = state.currentQuestionIndex + 1;
      state = state.copyWith(
        currentMCQ: state.questionQueue[nextIndex],
        currentQuestionIndex: nextIndex,
        userAnswer: null,
        isAnswered: false,
      );
    }
  }

  /// Reset quiz
  void reset() {
    if (!mounted) return;
    state = MCQQuizState();
  }

  /// Timer functions (simplified - no actual timer for now)
  void startTimer({int minMinutes = 5, int maxMinutes = 15}) {
    if (!mounted) return;
    state = state.copyWith(timerActive: true);
  }

  void stopTimer() {
    if (!mounted) return;
    state = state.copyWith(timerActive: false);
  }

  /// Check if the submitted answer is correct
  bool isCorrectAnswer() {
    if (state.currentMCQ == null || state.userAnswer == null) return false;
    return state.userAnswer == state.currentMCQ!.correctOption;
  }

  /// Get explanation for current answer
  String getExplanation() {
    if (state.currentMCQ == null) return '';
    if (state.userAnswer == null) return state.currentMCQ!.explanationCorrect;
    
    // Return correct explanation
    return state.currentMCQ!.explanationCorrect;
  }

  /// Move to next question in the queue
  void moveToNextQuestion() {
    nextQuestion();
  }
}

/// Provider instances
final mcqQuizProvider = StateNotifierProvider<MCQQuizNotifier, MCQQuizState>((ref) {
  final apiService = ApiService.instance;
  return MCQQuizNotifier(apiService);
});

/// Provider for time until next quiz (simplified)
final timeUntilNextQuizProvider = StreamProvider<Duration?>((ref) async* {
  while (true) {
    await Future.delayed(const Duration(seconds: 1));
    yield null; // No timer implementation yet
  }
});
