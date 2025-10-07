import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/mcq.dart';
import '../models/subject.dart';
import '../models/quiz_session.dart';
import '../services/ai_service.dart';
import '../services/openai_service.dart';
import '../services/openai_service_novel.dart';
import '../config/api_config.dart';
import '../database/database_helper.dart';
import 'subject_provider.dart';

/// State for the MCQ quiz session
class MCQQuizState {
  final MCQ? currentMCQ;
  final String? userAnswer;
  final bool isAnswered;
  final bool isLoading;
  final String? error;
  final bool timerActive;
  final DateTime? nextQuizTime;

  MCQQuizState({
    this.currentMCQ,
    this.userAnswer,
    this.isAnswered = false,
    this.isLoading = false,
    this.error,
    this.timerActive = false,
    this.nextQuizTime,
  });

  MCQQuizState copyWith({
    MCQ? currentMCQ,
    String? userAnswer,
    bool? isAnswered,
    bool? isLoading,
    String? error,
    bool? timerActive,
    DateTime? nextQuizTime,
    bool clearMCQ = false,
    bool clearError = false,
  }) {
    return MCQQuizState(
      currentMCQ: clearMCQ ? null : (currentMCQ ?? this.currentMCQ),
      userAnswer: userAnswer ?? this.userAnswer,
      isAnswered: isAnswered ?? this.isAnswered,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      timerActive: timerActive ?? this.timerActive,
      nextQuizTime: nextQuizTime ?? this.nextQuizTime,
    );
  }
}

/// Provider for MCQ quiz management
class MCQQuizNotifier extends StateNotifier<MCQQuizState> {
  final AIService _aiService;
  final OpenAIService _openAIService = OpenAIService();
  final OpenAIServiceNovel _novelService = OpenAIServiceNovel();
  final DatabaseHelper _db = DatabaseHelper();
  final Ref _ref;
  Timer? _quizTimer;
  final Random _random = Random();
  String? _currentSubjectName; // Track current subject for logging
  int? _currentSubjectId; // Track subject ID for novelty

  MCQQuizNotifier(this._aiService, this._ref) : super(MCQQuizState()) {
    // Initialize OpenAI if using direct integration
    if (ApiConfig.useDirectOpenAI && ApiConfig.hasOpenAIKey) {
      OpenAIService.initialize(ApiConfig.openAIApiKey);
      OpenAIServiceNovel.initialize(ApiConfig.openAIApiKey);
      print('✅ Direct OpenAI integration with novelty enforcement enabled');
    }
  }

  /// Generate MCQ for a specific subject with novelty enforcement
  Future<void> generateMCQ(String subject) async {
    state = state.copyWith(isLoading: true, clearError: true, clearMCQ: true);
    _currentSubjectName = subject; // Track for completion logging

    try {
      // Get subject from database to retrieve ID for deduplication
      final subjects = await _db.getSubjectByName(subject);
      final subjectId = subjects?.id;
      
      if (subjectId == null) {
        print('⚠️ Subject not found in database: $subject');
        if (!mounted) return;
        state = state.copyWith(
          isLoading: false,
          error: 'Subject "$subject" not found.\n\nPlease add this subject first.',
        );
        return;
      }
      
      _currentSubjectId = subjectId; // Track for logging
      
      MCQ? mcq;
      
      // Use direct OpenAI integration if enabled
      if (ApiConfig.useDirectOpenAI) {
        if (!ApiConfig.hasOpenAIKey) {
          if (!mounted) return;
          state = state.copyWith(
            isLoading: false,
            error: 'OpenAI API key not configured.\n\n'
                   'Please update lib/config/api_config.dart\n'
                   'with your OpenAI API key.\n\n'
                   'Get your key from:\n'
                   'https://platform.openai.com/api-keys',
          );
          return;
        }
        
        print('🎉 Using novel OpenAI service with deduplication...');
        mcq = await _novelService.generateMCQ(
          subject: subject,
          subjectId: subjectId,
          choices: 4,
        );
        
      } else {
        // Use backend server
        print('📡 Using backend server...');
        final isHealthy = await _aiService.checkHealth();
        
        if (!isHealthy) {
          if (!mounted) return;
          state = state.copyWith(
            isLoading: false,
            error: 'Backend server not available.\n\n'
                   'To use backend mode:\n'
                   '1. Deploy backend to Railway\n'
                   '2. Update api_config.dart\n\n'
                   'Or switch to Direct OpenAI mode:\n'
                   'Set useDirectOpenAI = true in api_config.dart',
          );
          return;
        }
        
        mcq = await _aiService.generateMCQ(subject: subject, choices: 4);
      }

      if (!mounted) return;

      if (mcq != null) {
        state = state.copyWith(
          currentMCQ: mcq,
          isLoading: false,
          isAnswered: false,
          userAnswer: null,
          clearError: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to generate question.\n\n'
                 'This may be due to:\n'
                 '• OpenAI API rate limits\n'
                 '• Network issues\n'
                 '• Invalid API response\n\n'
                 'Please try again in a moment.',
        );
      }
    } on RateLimitException catch (e) {
      // Rate limit - friendly message with retry suggestion
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: '⏳ ChatGPT API Busy\n\n'
               'The AI service is currently experiencing high demand.\n\n'
               '💡 What you can do:\n'
               '• Wait 1-2 minutes and try again\n'
               '• Use the regular Quiz feature instead\n\n'
               'The AI Quiz will work again once the rate limit clears.',
      );
    } on AuthenticationException catch (e) {
      // Auth error - configuration issue
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: '🔑 API Configuration Error\n\n'
               'The OpenAI API key is invalid or missing.\n\n'
               '🛠️ Fix:\n'
               '1. Get a valid API key from:\n'
               '   platform.openai.com/api-keys\n'
               '2. Update lib/config/api_config.dart\n'
               '3. Restart the app\n\n'
               'For now, use the regular Quiz feature.',
      );
    } on NetworkException catch (e) {
      // Network error - connection issue
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: '📡 Connection Error\n\n'
               'Unable to connect to OpenAI services.\n\n'
               '💡 Check:\n'
               '• Your internet connection\n'
               '• Firewall settings\n'
               '• VPN configuration\n\n'
               'Try again when your connection is stable.',
      );
    } on GenerationException catch (e) {
      // Generation failed after retries
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: '⚠️ Question Generation Failed\n\n'
               'Unable to generate a question after multiple attempts.\n\n'
               '💡 Try:\n'
               '• Wait a moment and try again\n'
               '• Use the regular Quiz feature\n'
               '• Check if OpenAI services are online\n\n'
               'This is usually temporary.',
      );
    } catch (e) {
      // Unknown error - generic handling
      if (!mounted) return;
      final errorMsg = e.toString();
      String friendlyError = '❌ Unexpected Error\n\n';
      
      if (errorMsg.contains('OpenAI not initialized')) {
        friendlyError += 'The AI service is not properly configured.\n\n'
                        'Please check lib/config/api_config.dart\n'
                        'and ensure your OpenAI API key is set.';
      } else {
        friendlyError += 'Something went wrong while generating the question.\n\n'
                        '💡 What to try:\n'
                        '• Use the regular Quiz feature\n'
                        '• Wait a moment and try again\n'
                        '• Restart the app if the issue persists';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: friendlyError,
      );
    }
  }

  /// Generate MCQ for a random subject from active subjects
  Future<void> generateRandomMCQ() async {
    final subjects = _ref.read(activeSubjectsProvider);

    if (subjects.isEmpty) {
      state = state.copyWith(error: 'No active subjects available');
      return;
    }

    // Pick random subject
    final randomSubject = subjects[_random.nextInt(subjects.length)];
    await generateMCQ(randomSubject.name);
  }

  /// Submit user's answer and log completion
  Future<void> submitAnswer(String answer) async {
    if (state.currentMCQ == null || _currentSubjectName == null) return;

    final mcq = state.currentMCQ!;
    final isCorrect = mcq.isCorrect(answer);

    state = state.copyWith(
      userAnswer: answer,
      isAnswered: true,
    );

    // Log completion to database
    try {
      // Get subject from database
      final subjects = await _db.getAllSubjects();
      final subject = subjects.firstWhere(
        (s) => s.name == _currentSubjectName,
        orElse: () => throw Exception('Subject not found'),
      );

      // Create quiz session with MCQ metadata
      final session = QuizSession(
        subjectId: subject.id!,
        questionId: mcq.id.hashCode, // Use MCQ id hash as question id
        userAnswer: answer,
        isCorrect: isCorrect,
        answeredAt: DateTime.now(),
        timeSpentSeconds: 0, // MCQ doesn't track time yet
        difficulty: mcq.difficulty,
      );

      // Save to database
      await _db.insertQuizSession(session);
      print('✅ MCQ completion logged: ${mcq.subject}, correct: $isCorrect');

      // Update subject accuracy
      await _updateSubjectAccuracy(subject.id!, isCorrect);

      // Refresh subjects to show updated accuracy
      _ref.read(subjectProvider.notifier).loadSubjects();
      
    } catch (e) {
      print('⚠️ Error logging MCQ completion: $e');
      // Don't fail the submission if logging fails
    }
  }

  /// Get the appropriate explanation based on user's answer
  String? getExplanation() {
    if (state.currentMCQ == null || !state.isAnswered || state.userAnswer == null) {
      return null;
    }

    final mcq = state.currentMCQ!;
    final isCorrect = mcq.isCorrect(state.userAnswer!);

    if (isCorrect) {
      return mcq.explanationCorrect;
    } else {
      return mcq.getExplanationForOption(state.userAnswer!);
    }
  }

  /// Check if user's answer is correct
  bool? isCorrectAnswer() {
    if (state.currentMCQ == null || state.userAnswer == null) {
      return null;
    }
    return state.currentMCQ!.isCorrect(state.userAnswer!);
  }

  /// Start timer-based quiz generation
  void startTimer({int minMinutes = 5, int maxMinutes = 15}) {
    if (state.timerActive) return;

    state = state.copyWith(timerActive: true);
    _scheduleNextQuiz(minMinutes, maxMinutes);
  }

  /// Stop timer-based quiz generation
  void stopTimer() {
    _quizTimer?.cancel();
    _quizTimer = null;
    state = state.copyWith(timerActive: false, nextQuizTime: null);
  }

  /// Schedule the next quiz at a random interval
  void _scheduleNextQuiz(int minMinutes, int maxMinutes) {
    _quizTimer?.cancel();

    // Calculate random delay between min and max minutes
    final interval = minMinutes + _random.nextInt(maxMinutes - minMinutes + 1);
    final nextTime = DateTime.now().add(Duration(minutes: interval));
    
    state = state.copyWith(nextQuizTime: nextTime);
    print('⏰ Next automated quiz in $interval minutes');
    
    _quizTimer = Timer(Duration(minutes: interval), () {
      generateRandomMCQ();
      _scheduleNextQuiz(minMinutes, maxMinutes);
    });
  }

  /// Update subject accuracy after quiz completion
  Future<void> _updateSubjectAccuracy(int subjectId, bool isCorrect) async {
    try {
      // Get subject to update counters
      final subject = await _db.getSubjectById(subjectId);
      if (subject == null) return;
      
      // Increment counters
      final newTotalQuestions = subject.totalQuestions + 1;
      final newCorrectAnswers = subject.correctAnswers + (isCorrect ? 1 : 0);
      
      // Update subject with new counts
      final updatedSubject = subject.copyWith(
        totalQuestions: newTotalQuestions,
        correctAnswers: newCorrectAnswers,
        updatedAt: DateTime.now(),
      );
      
      await _db.updateSubject(updatedSubject);
      
      final newAccuracy = (newCorrectAnswers / newTotalQuestions) * 100;
      print('📊 Subject accuracy updated: ${subject.name} -> ${newAccuracy.toStringAsFixed(1)}%');
    } catch (e) {
      print('⚠️ Error updating subject accuracy: $e');
    }
  }

  /// Reset the current quiz
  void resetQuiz() {
    state = MCQQuizState(timerActive: state.timerActive, nextQuizTime: state.nextQuizTime);
  }

  @override
  void dispose() {
    _quizTimer?.cancel();
    super.dispose();
  }
}

/// Provider for MCQ quiz state
final mcqQuizProvider = StateNotifierProvider<MCQQuizNotifier, MCQQuizState>((ref) {
  return MCQQuizNotifier(AIService(), ref);
});

/// Provider for time remaining until next quiz
final timeUntilNextQuizProvider = StreamProvider<Duration?>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) {
    final nextQuizTime = ref.watch(mcqQuizProvider).nextQuizTime;
    if (nextQuizTime == null) return null;

    final now = DateTime.now();
    if (nextQuizTime.isBefore(now)) return Duration.zero;

    return nextQuizTime.difference(now);
  });
});
