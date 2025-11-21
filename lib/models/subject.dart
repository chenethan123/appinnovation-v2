class Subject {
  final int? id;
  final String? userId; // User ID for cloud sync and multi-user support
  final String name;
  final String description;
  final String color; // Hex color code
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int totalQuestions;
  final int correctAnswers;
  final double difficultyWeight; // For adaptive learning (0.0 - 1.0)

  Subject({
    this.id,
    this.userId,
    required this.name,
    required this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.difficultyWeight = 0.5,
  });

  // Calculate accuracy percentage
  double get accuracy {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }

  // For adaptive learning - subjects with lower accuracy get higher priority
  double get adaptivePriority {
    final baseAccuracy = accuracy / 100;
    final invertedAccuracy = 1.0 - baseAccuracy;
    return (invertedAccuracy * difficultyWeight).clamp(0.1, 1.0);
  }

  Subject copyWith({
    int? id,
    String? userId,
    String? name,
    String? description,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? totalQuestions,
    int? correctAnswers,
    double? difficultyWeight,
  }) {
    return Subject(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      correctAnswers: correctAnswers ?? this.correctAnswers,
      difficultyWeight: difficultyWeight ?? this.difficultyWeight,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'difficulty_weight': difficultyWeight,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    // Handle both UUID (from Supabase) and integer (from local SQLite)
    int? idValue;
    if (map['id'] != null) {
      if (map['id'] is int) {
        idValue = map['id'];
      } else if (map['id'] is String) {
        // Convert UUID string to integer hash for compatibility
        idValue = map['id'].hashCode.abs();
      }
    }
    
    return Subject(
      id: idValue,
      userId: map['user_id']?.toString(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#2196F3',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      isActive: (map['is_active'] is bool) 
          ? map['is_active'] 
          : (map['is_active'] ?? 1) == 1,
      totalQuestions: (map['total_questions'] is int) 
          ? map['total_questions'] 
          : (map['total_questions']?.toInt() ?? 0),
      correctAnswers: (map['correct_answers'] is int)
          ? map['correct_answers']
          : (map['correct_answers']?.toInt() ?? 0),
      difficultyWeight: (map['difficulty_weight'] is double)
          ? map['difficulty_weight']
          : ((map['difficulty_weight'] ?? 0.5).toDouble()),
    );
  }

  @override
  String toString() {
    return 'Subject(id: $id, name: $name, accuracy: ${accuracy.toStringAsFixed(1)}%)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subject && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
