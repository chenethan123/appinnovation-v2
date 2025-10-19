/**
 * Quiz Session Model
 * Matches server API QuizSession schema
 */

import 'question.dart';

class QuizSession {
  final String id;
  final int subjectId;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int score;
  final int totalQuestions;
  final List<Question> questions;

  QuizSession({
    required this.id,
    required this.subjectId,
    required this.startedAt,
    this.completedAt,
    this.score = 0,
    required this.totalQuestions,
    this.questions = const [],
  });

  double get accuracy {
    if (totalQuestions == 0) return 0.0;
    return (score / totalQuestions) * 100;
  }

  bool get isCompleted => completedAt != null;

  QuizSession copyWith({
    String? id,
    int? subjectId,
    DateTime? startedAt,
    DateTime? completedAt,
    int? score,
    int? totalQuestions,
    List<Question>? questions,
  }) {
    return QuizSession(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      questions: questions ?? this.questions,
    );
  }

  factory QuizSession.fromJson(Map<String, dynamic> json) {
    return QuizSession(
      id: json['sessionId'] as String? ?? json['session_id'] as String? ?? json['id'] as String,
      subjectId: json['subjectId'] as int? ?? json['subject_id'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String? ?? json['started_at'] as String),
      completedAt: json['completedAt'] != null || json['completed_at'] != null
          ? DateTime.parse(json['completedAt'] as String? ?? json['completed_at'] as String)
          : null,
      score: json['score'] as int? ?? 0,
      totalQuestions: json['totalQuestions'] as int? ?? json['total_questions'] as int? ?? 0,
      questions: json['questions'] != null
          ? (json['questions'] as List).map((q) => Question.fromJson(q)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'startedAt': startedAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'score': score,
      'totalQuestions': totalQuestions,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'score': score,
      'total_questions': totalQuestions,
    };
  }

  factory QuizSession.fromMap(Map<String, dynamic> map) {
    return QuizSession(
      id: map['id'] as String,
      subjectId: map['subject_id'] as int,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: map['completed_at'] != null ? DateTime.parse(map['completed_at'] as String) : null,
      score: map['score'] as int? ?? 0,
      totalQuestions: map['total_questions'] as int,
    );
  }

  @override
  String toString() {
    return 'QuizSession(id: $id, score: $score/$totalQuestions, accuracy: ${accuracy.toStringAsFixed(1)}%)';
  }
}

class QuizAnswer {
  final String sessionId;
  final int questionId;
  final String userAnswer;
  final bool isCorrect;
  final int timeSpentSeconds;
  final DateTime answeredAt;

  QuizAnswer({
    required this.sessionId,
    required this.questionId,
    required this.userAnswer,
    required this.isCorrect,
    this.timeSpentSeconds = 0,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  factory QuizAnswer.fromJson(Map<String, dynamic> json) {
    return QuizAnswer(
      sessionId: json['sessionId'] as String? ?? json['session_id'] as String,
      questionId: json['questionId'] as int? ?? json['question_id'] as int,
      userAnswer: json['userAnswer'] as String? ?? json['user_answer'] as String,
      isCorrect: json['isCorrect'] as bool? ?? json['is_correct'] as bool,
      timeSpentSeconds: json['timeSpentSeconds'] as int? ?? json['time_spent_seconds'] as int? ?? 0,
      answeredAt: DateTime.tryParse(json['answeredAt']?.toString() ?? json['answered_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'questionId': questionId,
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'timeSpentSeconds': timeSpentSeconds,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'session_id': sessionId,
      'question_id': questionId,
      'user_answer': userAnswer,
      'is_correct': isCorrect ? 1 : 0,
      'time_spent_seconds': timeSpentSeconds,
      'answered_at': answeredAt.toIso8601String(),
    };
  }

  factory QuizAnswer.fromMap(Map<String, dynamic> map) {
    return QuizAnswer(
      sessionId: map['session_id'] as String,
      questionId: map['question_id'] as int,
      userAnswer: map['user_answer'] as String,
      isCorrect: (map['is_correct'] ?? 0) == 1,
      timeSpentSeconds: map['time_spent_seconds'] as int? ?? 0,
      answeredAt: DateTime.tryParse(map['answered_at'] ?? '') ?? DateTime.now(),
    );
  }
}
