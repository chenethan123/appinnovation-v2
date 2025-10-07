import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question.dart';
import '../models/quiz_session.dart';
import '../models/subject.dart';
import '../database/database_helper.dart';
import '../database/question_database.dart';
import '../services/ai_service.dart';
import '../services/enhanced_question_service.dart';
import '../data/question_bank.dart';
import '../data/subject_specific_questions.dart';

class QuizState {
  final Question? currentQuestion;
  final Subject? currentSubject;
  final bool isLoading;
  final String? error;
  final int questionsAnswered;
  final int correctAnswers;
  final DateTime? sessionStartTime;
  final int currentQuestionIndex;
  final int totalQuestions;

  QuizState({
    this.currentQuestion,
    this.currentSubject,
    this.isLoading = false,
    this.error,
    this.questionsAnswered = 0,
    this.correctAnswers = 0,
    this.sessionStartTime,
    this.currentQuestionIndex = 0,
    this.totalQuestions = 10,
  });

  QuizState copyWith({
    Question? currentQuestion,
    Subject? currentSubject,
    bool? isLoading,
    String? error,
    int? questionsAnswered,
    int? correctAnswers,
    DateTime? sessionStartTime,
    int? currentQuestionIndex,
    int? totalQuestions,
  }) {
    return QuizState(
      currentQuestion: currentQuestion ?? this.currentQuestion,
      currentSubject: currentSubject ?? this.currentSubject,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      questionsAnswered: questionsAnswered ?? this.questionsAnswered,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      totalQuestions: totalQuestions ?? this.totalQuestions,
    );
  }

  double get accuracy {
    if (questionsAnswered == 0) return 0.0;
    return (correctAnswers / questionsAnswered) * 100;
  }
}

class QuizNotifier extends StateNotifier<QuizState> {
  QuizNotifier() : super(QuizState());

  final DatabaseHelper _db = DatabaseHelper();
  final QuestionDatabase _questionDb = QuestionDatabase();
  final AIService _aiService = AIService();
  final EnhancedQuestionService _enhancedQuestionService = EnhancedQuestionService();

  Future<void> startQuiz({Subject? specificSubject}) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        sessionStartTime: DateTime.now(),
        questionsAnswered: 0,
        correctAnswers: 0,
        currentQuestionIndex: 0,
        totalQuestions: 10,
      );

      Subject? selectedSubject = specificSubject;
      
      if (selectedSubject == null) {
        // Use adaptive learning to select subject
        selectedSubject = await _selectSubjectForQuiz();
      }

      if (selectedSubject == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'No active subjects available for quiz',
        );
        return;
      }

      await _loadQuestionForSubject(selectedSubject);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: error.toString(),
      );
    }
  }

  Future<Subject?> _selectSubjectForQuiz() async {
    final subjects = await _db.getActiveSubjects();
    if (subjects.isEmpty) return null;

    // Weighted random selection based on adaptive priority
    final totalWeight = subjects.fold<double>(
      0.0,
      (sum, subject) => sum + subject.adaptivePriority,
    );

    if (totalWeight == 0) return subjects.first;

    final random = DateTime.now().millisecondsSinceEpoch % 1000 / 1000.0;
    double currentWeight = 0.0;

    for (final subject in subjects) {
      currentWeight += subject.adaptivePriority / totalWeight;
      if (random <= currentWeight) {
        return subject;
      }
    }

    return subjects.first;
  }

  Future<void> _loadQuestionForSubject(Subject subject) async {
    try {
      Question? question;
      
      // First try to get question from new question database
      question = await _questionDb.getRandomQuestionForSubject(subject.name);
      
      if (question == null) {
        // Try by subject ID if name doesn't work
        final questions = await _questionDb.getQuestionsBySubjectId(subject.id!);
        if (questions.isNotEmpty) {
          question = questions.first;
        }
      }
      
      if (question == null) {
        // Use subject-specific questions first
        question = SubjectSpecificQuestions.getRandomQuestionForSubject(subject.name, subject.id!);
      }
      
      if (question == null) {
        // Fallback to question bank
        question = QuestionBank.getRandomQuestionForSubject(subject.name, subject.id!);
      }
      
      if (question == null) {
        // Try cached questions from old database
        question = await _db.getRandomQuestionForSubject(subject.id!);
      }

      if (question != null) {
        state = state.copyWith(
          currentQuestion: question,
          currentSubject: subject,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'No questions available for ${subject.name}. Try importing questions first.',
        );
      }
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load question: $error',
      );
    }
  }

  Question _generateFallbackQuestion(Subject subject) {
    final subjectName = subject.name.toLowerCase();
    
    // Curriculum-aligned questions by subject
    final fallbackQuestions = {
      'mathematics': [
        {
          'question': 'Solve for x: 2x + 5 = 13',
          'options': ['x = 3', 'x = 4', 'x = 5', 'x = 6'],
          'correct': 'x = 4',
          'explanation': 'Subtract 5 from both sides: 2x = 8, then divide by 2: x = 4'
        },
        {
          'question': 'What is the slope of the line y = 3x + 2?',
          'options': ['2', '3', '5', '1'],
          'correct': '3',
          'explanation': 'In the form y = mx + b, the coefficient of x (m) is the slope.'
        },
      ],
      'algebra': [
        {
          'question': 'Factor: x² - 9',
          'options': ['(x-3)(x-3)', '(x+3)(x-3)', '(x+9)(x-1)', 'Cannot be factored'],
          'correct': '(x+3)(x-3)',
          'explanation': 'This is a difference of squares: a² - b² = (a+b)(a-b)'
        },
      ],
      'physics': [
        {
          'question': 'An object at rest will stay at rest unless acted upon by what?',
          'options': ['Gravity', 'An unbalanced force', 'Friction', 'Momentum'],
          'correct': 'An unbalanced force',
          'explanation': 'This is Newton\'s First Law of Motion (Law of Inertia).'
        },
        {
          'question': 'What is the formula for kinetic energy?',
          'options': ['KE = mv', 'KE = ½mv²', 'KE = mgh', 'KE = Fd'],
          'correct': 'KE = ½mv²',
          'explanation': 'Kinetic energy equals one-half mass times velocity squared.'
        },
      ],
      'ap physics 1': [
        {
          'question': 'A ball is thrown horizontally. What is the initial vertical velocity?',
          'options': ['0 m/s', '9.8 m/s', 'Same as horizontal velocity', 'Cannot be determined'],
          'correct': '0 m/s',
          'explanation': 'In projectile motion, horizontal throws start with zero vertical velocity.'
        },
      ],
      'chemistry': [
        {
          'question': 'How many electrons can the first energy level hold?',
          'options': ['2', '8', '18', '32'],
          'correct': '2',
          'explanation': 'The first energy level (n=1) can hold a maximum of 2 electrons.'
        },
        {
          'question': 'What type of bond forms between Na and Cl?',
          'options': ['Covalent', 'Ionic', 'Metallic', 'Hydrogen'],
          'correct': 'Ionic',
          'explanation': 'Na loses an electron to Cl, forming an ionic bond between Na⁺ and Cl⁻.'
        },
      ],
      'biology': [
        {
          'question': 'What is the powerhouse of the cell?',
          'options': ['Nucleus', 'Mitochondria', 'Ribosome', 'Chloroplast'],
          'correct': 'Mitochondria',
          'explanation': 'Mitochondria produce ATP, the cell\'s main energy currency.'
        },
      ],
    };

    // Find matching questions for the subject
    List<Map<String, dynamic>> subjectQuestions = [];
    
    // Try exact match first
    if (fallbackQuestions.containsKey(subjectName)) {
      subjectQuestions = fallbackQuestions[subjectName]!;
    } else {
      // Try partial matches for common subjects
      for (String key in fallbackQuestions.keys) {
        if (subjectName.contains(key) || key.contains(subjectName)) {
          subjectQuestions = fallbackQuestions[key]!;
          break;
        }
      }
    }
    
    // Default to mathematics if no match found
    if (subjectQuestions.isEmpty) {
      subjectQuestions = fallbackQuestions['mathematics']!;
    }
    
    // Select a random question from the available ones
    final random = DateTime.now().millisecondsSinceEpoch % subjectQuestions.length;
    final questionData = subjectQuestions[random];

    return Question(
      subjectId: subject.id!,
      questionText: questionData['question']!.toString(),
      options: questionData['options'] as List<String>,
      correctAnswer: questionData['correct']!.toString(),
      explanation: '${questionData['explanation']} (Educational content only)',
      difficulty: 'medium',
      createdAt: DateTime.now(),
      isFromAI: false,
      source: 'Curriculum-Aligned Question',
    );
  }

  void resetQuiz() {
    state = QuizState();
  }

  Future<void> submitAnswer(String userAnswer) async {
    final currentQuestion = state.currentQuestion;
    final currentSubject = state.currentSubject;
    
    if (currentQuestion == null || currentSubject == null) return;

    try {
      final isCorrect = userAnswer == currentQuestion.correctAnswer;
      
      // Update statistics
      final newQuestionsAnswered = state.questionsAnswered + 1;
      final newCorrectAnswers = state.correctAnswers + (isCorrect ? 1 : 0);
      final newQuestionIndex = state.currentQuestionIndex + 1;
      
      // Save quiz session to database only if question has an ID
      if (currentQuestion.id != null) {
        final session = QuizSession(
          subjectId: currentSubject.id!,
          questionId: currentQuestion.id!,
          userAnswer: userAnswer,
          isCorrect: isCorrect,
          answeredAt: DateTime.now(),
        );
        
        await _db.insertQuizSession(session);
        
        // Update question statistics in new database
        await _questionDb.updateQuestionStats(
          currentQuestion.id!,
          isCorrect,
          5.0, // Default response time
        );
      }
      
      // Update subject statistics
      await _db.updateSubjectStats(
        currentSubject.id!,
        newQuestionsAnswered,
        newCorrectAnswers,
      );
      
      state = state.copyWith(
        questionsAnswered: newQuestionsAnswered,
        correctAnswers: newCorrectAnswers,
        currentQuestionIndex: newQuestionIndex,
      );
      
      // Load next question if not at the end
      if (newQuestionIndex < state.totalQuestions) {
        await _loadQuestionForSubject(currentSubject);
      }
      
    } catch (error) {
      print('Error submitting answer: $error');
    }
  }

  Future<void> nextQuestion() async {
    if (state.currentSubject != null) {
      await _loadQuestionForSubject(state.currentSubject!);
    }
  }

  void endQuiz() {
    state = QuizState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  return QuizNotifier();
});

// Provider for quiz settings
class QuizSettingsNotifier extends StateNotifier<AsyncValue<QuizSettings>> {
  QuizSettingsNotifier() : super(const AsyncValue.loading()) {
    loadSettings();
  }

  final DatabaseHelper _db = DatabaseHelper();

  Future<void> loadSettings() async {
    try {
      state = const AsyncValue.loading();
      final settings = await _db.getQuizSettings();
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      print('Error loading quiz settings: $error');
      // Provide fallback settings if database fails
      final fallbackSettings = QuizSettings(updatedAt: DateTime.now());
      state = AsyncValue.data(fallbackSettings);
    }
  }

  Future<void> updateSettings(QuizSettings settings) async {
    try {
      await _db.updateQuizSettings(settings);
      state = AsyncValue.data(settings);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}

final quizSettingsProvider = StateNotifierProvider<QuizSettingsNotifier, AsyncValue<QuizSettings>>((ref) {
  return QuizSettingsNotifier();
});

// Provider for today's quiz count
final todayQuizCountProvider = FutureProvider<int>((ref) async {
  final db = DatabaseHelper();
  final sessions = await db.getTodaysQuizSessions();
  return sessions.length;
});
