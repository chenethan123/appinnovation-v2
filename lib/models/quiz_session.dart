class QuizSession {
  final int? id;
  final int subjectId;
  final int questionId;
  final String userAnswer;
  final bool isCorrect;
  final DateTime answeredAt;
  final int timeSpentSeconds;
  final String difficulty;

  QuizSession({
    this.id,
    required this.subjectId,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    required this.answeredAt,
    this.timeSpentSeconds = 0,
    this.difficulty = 'medium',
  });

  QuizSession copyWith({
    int? id,
    int? subjectId,
    int? questionId,
    String? userAnswer,
    bool? isCorrect,
    DateTime? answeredAt,
    int? timeSpentSeconds,
    String? difficulty,
  }) {
    return QuizSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      questionId: questionId ?? this.questionId,
      userAnswer: userAnswer ?? this.userAnswer,
      isCorrect: isCorrect ?? this.isCorrect,
      answeredAt: answeredAt ?? this.answeredAt,
      timeSpentSeconds: timeSpentSeconds ?? this.timeSpentSeconds,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect ? 1 : 0,
      'answered_at': answeredAt.toIso8601String(),
      'time_spent_seconds': timeSpentSeconds,
      'difficulty': difficulty,
    };
  }

  factory QuizSession.fromMap(Map<String, dynamic> map) {
    return QuizSession(
      id: map['id']?.toInt(),
      subjectId: map['subject_id']?.toInt() ?? 0,
      questionId: map['question_id']?.toInt() ?? 0,
      userAnswer: map['user_answer'] ?? '',
      isCorrect: (map['is_correct'] ?? 0) == 1,
      answeredAt: DateTime.tryParse(map['answered_at'] ?? '') ?? DateTime.now(),
      timeSpentSeconds: map['time_spent_seconds']?.toInt() ?? 0,
      difficulty: map['difficulty'] ?? 'medium',
    );
  }

  @override
  String toString() {
    return 'QuizSession(id: $id, subject: $subjectId, correct: $isCorrect)';
  }
}

class QuizSettings {
  final int? id;
  final int maxDailyQuizzes;
  final int startHour; // 24-hour format
  final int endHour; // 24-hour format
  final List<int> activeDays; // 0=Sunday, 1=Monday, etc.
  final bool notificationsEnabled;
  final DateTime updatedAt;

  QuizSettings({
    this.id,
    this.maxDailyQuizzes = 5,
    this.startHour = 9,
    this.endHour = 18,
    this.activeDays = const [1, 2, 3, 4, 5], // Monday to Friday
    this.notificationsEnabled = true,
    required this.updatedAt,
  });

  QuizSettings copyWith({
    int? id,
    int? maxDailyQuizzes,
    int? startHour,
    int? endHour,
    List<int>? activeDays,
    bool? notificationsEnabled,
    DateTime? updatedAt,
  }) {
    return QuizSettings(
      id: id ?? this.id,
      maxDailyQuizzes: maxDailyQuizzes ?? this.maxDailyQuizzes,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      activeDays: activeDays ?? this.activeDays,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'max_daily_quizzes': maxDailyQuizzes,
      'start_hour': startHour,
      'end_hour': endHour,
      'active_days': activeDays.join(','),
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory QuizSettings.fromMap(Map<String, dynamic> map) {
    return QuizSettings(
      id: map['id']?.toInt(),
      maxDailyQuizzes: map['max_daily_quizzes']?.toInt() ?? 5,
      startHour: map['start_hour']?.toInt() ?? 9,
      endHour: map['end_hour']?.toInt() ?? 18,
      activeDays: (map['active_days'] ?? '1,2,3,4,5')
          .toString()
          .split(',')
          .map((s) => int.tryParse(s.trim()) ?? 1)
          .toList(),
      notificationsEnabled: (map['notifications_enabled'] ?? 1) == 1,
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  bool isActiveToday() {
    final today = DateTime.now().weekday % 7; // Convert to 0=Sunday format
    return activeDays.contains(today);
  }

  bool isWithinActiveHours() {
    final now = DateTime.now();
    final currentHour = now.hour;
    return currentHour >= startHour && currentHour < endHour;
  }

  @override
  String toString() {
    return 'QuizSettings(daily: $maxDailyQuizzes, hours: $startHour-$endHour)';
  }
}
