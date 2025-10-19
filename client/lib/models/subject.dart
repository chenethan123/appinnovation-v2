/**
 * Subject Model
 * Matches server API Subject schema
 */

class Subject {
  final int? id;
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

  // Copy with
  Subject copyWith({
    int? id,
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

  // From JSON (server response)
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      id: json['id'] as int?,
      name: json['name'] as String,
      description: json['description'] as String,
      color: json['color'] as String,
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      totalQuestions: json['totalQuestions'] as int? ?? json['total_questions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? json['correct_answers'] as int? ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? json['created_at']?.toString() ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? json['updated_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // To JSON (for server requests)
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'color': color,
      'isActive': isActive,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // For SQLite (local database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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
    return Subject(
      id: map['id']?.toInt(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      color: map['color'] ?? '#2196F3',
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      isActive: (map['is_active'] ?? 1) == 1,
      totalQuestions: map['total_questions']?.toInt() ?? 0,
      correctAnswers: map['correct_answers']?.toInt() ?? 0,
      difficultyWeight: (map['difficulty_weight'] ?? 0.5).toDouble(),
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
