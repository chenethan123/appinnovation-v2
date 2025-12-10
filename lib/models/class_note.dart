/// Model for user-uploaded class notes that can be used to generate customized questions
class ClassNote {
  final String? id;
  final String userId;
  final String subjectName;
  final String title;
  final String content;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final int questionCount;

  ClassNote({
    this.id,
    required this.userId,
    required this.subjectName,
    required this.title,
    required this.content,
    this.fileName,
    this.fileSize,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
    this.questionCount = 0,
  });

  /// Create a copy with updated fields
  ClassNote copyWith({
    String? id,
    String? userId,
    String? subjectName,
    String? title,
    String? content,
    String? fileName,
    int? fileSize,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    int? questionCount,
  }) {
    return ClassNote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      subjectName: subjectName ?? this.subjectName,
      title: title ?? this.title,
      content: content ?? this.content,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      questionCount: questionCount ?? this.questionCount,
    );
  }

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'subject_name': subjectName,
      'title': title,
      'content': content,
      'file_name': fileName,
      'file_size': fileSize,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
      'question_count': questionCount,
    };
  }

  /// Create from Map (from database)
  factory ClassNote.fromMap(Map<String, dynamic> map) {
    return ClassNote(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString() ?? '',
      subjectName: map['subject_name'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      fileName: map['file_name'],
      fileSize: map['file_size'],
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] ?? '') ?? DateTime.now(),
      isActive: map['is_active'] ?? true,
      questionCount: map['question_count'] ?? 0,
    );
  }

  /// Get content preview (first 200 characters)
  String get contentPreview {
    if (content.length <= 200) return content;
    return '${content.substring(0, 200)}...';
  }

  /// Get file size in human-readable format
  String get fileSizeFormatted {
    if (fileSize == null) return 'N/A';
    if (fileSize! < 1024) return '$fileSize B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  String toString() {
    return 'ClassNote(id: $id, title: $title, subject: $subjectName, questions: $questionCount)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassNote && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
