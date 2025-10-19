class Course {
  final int? id;
  final String courseId;
  final String subjectName;
  final String category;
  final String description;
  final bool isCustom; // User-added courses vs predefined

  Course({
    this.id,
    required this.courseId,
    required this.subjectName,
    required this.category,
    required this.description,
    this.isCustom = false,
  });

  Course copyWith({
    int? id,
    String? courseId,
    String? subjectName,
    String? category,
    String? description,
    bool? isCustom,
  }) {
    return Course(
      id: id ?? this.id,
      courseId: courseId ?? this.courseId,
      subjectName: subjectName ?? this.subjectName,
      category: category ?? this.category,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'course_id': courseId,
      'subject_name': subjectName,
      'category': category,
      'description': description,
      'is_custom': isCustom ? 1 : 0,
    };
  }

  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as int?,
      courseId: map['course_id'] as String,
      subjectName: map['subject_name'] as String,
      category: map['category'] as String,
      description: map['description'] as String? ?? '',
      isCustom: (map['is_custom'] as int?) == 1,
    );
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['courseId'] as String,
      subjectName: json['subjectName'] as String,
      category: json['category'] as String,
      description: json['description'] as String? ?? '',
      isCustom: false,
    );
  }

  @override
  String toString() => '$courseId - $subjectName';
}
