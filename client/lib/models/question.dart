class Question {
  final int? id;
  final int subjectId;
  final String? subjectName;
  final String questionText;
  final List<String> options;
  final String correctAnswer;
  final String explanation;
  final String difficulty; // 'easy', 'medium', 'hard'
  final String? category;
  final String questionType; // 'multiple', 'true_false', 'fill_blank'
  final DateTime createdAt;
  final bool isFromAI;
  final String? sourceUrl; // Optional reference URL
  final String? source; // Source name (e.g., "Khan Academy", "Project Euler")

  Question({
    this.id,
    required this.subjectId,
    this.subjectName,
    required this.questionText,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    this.difficulty = 'medium',
    this.category,
    this.questionType = 'multiple',
    required this.createdAt,
    this.isFromAI = true,
    this.sourceUrl,
    this.source,
  });

  Question copyWith({
    int? id,
    int? subjectId,
    String? subjectName,
    String? questionText,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    String? difficulty,
    String? category,
    String? questionType,
    DateTime? createdAt,
    bool? isFromAI,
    String? sourceUrl,
    String? source,
  }) {
    return Question(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      subjectName: subjectName ?? this.subjectName,
      questionText: questionText ?? this.questionText,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      difficulty: difficulty ?? this.difficulty,
      category: category ?? this.category,
      questionType: questionType ?? this.questionType,
      createdAt: createdAt ?? this.createdAt,
      isFromAI: isFromAI ?? this.isFromAI,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'question_text': questionText,
      'options': options.join('|'), // Store as pipe-separated string
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'category': category,
      'question_type': questionType,
      'created_at': createdAt.toIso8601String(),
      'is_from_ai': isFromAI ? 1 : 0,
      'source_url': sourceUrl,
      'source': source,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id']?.toInt(),
      subjectId: map['subject_id']?.toInt() ?? 0,
      subjectName: map['subject_name'],
      questionText: map['question_text'] ?? '',
      options: (map['options'] ?? '').split('|').where((s) => s.isNotEmpty).toList(),
      correctAnswer: map['correct_answer'] ?? '',
      explanation: map['explanation'] ?? '',
      difficulty: map['difficulty'] ?? 'medium',
      category: map['category'],
      questionType: map['question_type'] ?? 'multiple',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      isFromAI: (map['is_from_ai'] ?? 1) == 1,
      sourceUrl: map['source_url'],
      source: map['source'],
    );
  }

  // Convert from AI API response
  factory Question.fromAIResponse(Map<String, dynamic> json, int subjectId) {
    return Question(
      subjectId: subjectId,
      questionText: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      correctAnswer: json['correct_answer'] ?? '',
      explanation: json['explanation'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      createdAt: DateTime.now(),
      isFromAI: true,
    );
  }

  // Convert from JSON (for API)
  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id']?.toInt(),
      subjectId: json['subjectId'] as int? ?? json['subject_id'] as int,
      subjectName: json['subjectName'] as String? ?? json['subject_name'] as String?,
      questionText: json['questionText'] as String? ?? json['question_text'] as String,
      options: (json['options'] as List).map((e) => e.toString()).toList(),
      correctAnswer: json['correctAnswer'] as String? ?? json['correct_answer'] as String,
      explanation: json['explanation'] as String,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String?,
      questionType: json['questionType'] as String? ?? json['question_type'] as String? ?? 'multiple',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ?? DateTime.now(),
      isFromAI: json['isFromAI'] as bool? ?? json['is_from_ai'] as bool? ?? false,
      sourceUrl: json['sourceUrl'] as String? ?? json['source_url'] as String?,
      source: json['source'] as String?,
    );
  }

  // Convert to JSON (for API)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subjectId': subjectId,
      'subjectName': subjectName,
      'questionText': questionText,
      'options': options,
      'correctAnswer': correctAnswer,
      'explanation': explanation,
      'difficulty': difficulty,
      'category': category,
      'questionType': questionType,
      'createdAt': createdAt.toIso8601String(),
      'isFromAI': isFromAI,
      'sourceUrl': sourceUrl,
      'source': source,
    };
  }

  @override
  String toString() {
    return 'Question(id: $id, subject: $subjectId, difficulty: $difficulty)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && 
           other.id == id && 
           other.questionText == questionText;
  }

  @override
  int get hashCode => id.hashCode ^ questionText.hashCode;
}
