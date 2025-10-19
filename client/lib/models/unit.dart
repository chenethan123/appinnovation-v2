class Unit {
  final int? id;
  final int subjectId;
  final String name;
  final String? description;
  final int orderIndex; // For ordering units (Unit 1, Unit 2, etc.)
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isCurrent; // Is this the current unit being studied?
  final DateTime createdAt;

  Unit({
    this.id,
    required this.subjectId,
    required this.name,
    this.description,
    required this.orderIndex,
    this.startDate,
    this.endDate,
    this.isCurrent = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'name': name,
      'description': description,
      'order_index': orderIndex,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'is_current': isCurrent ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Create from Map (from database)
  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'] as int?,
      subjectId: map['subject_id'] as int,
      name: map['name'] as String,
      description: map['description'] as String?,
      orderIndex: map['order_index'] as int,
      startDate: map['start_date'] != null 
          ? DateTime.parse(map['start_date'] as String)
          : null,
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : null,
      isCurrent: (map['is_current'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Copy with method for updates
  Unit copyWith({
    int? id,
    int? subjectId,
    String? name,
    String? description,
    int? orderIndex,
    DateTime? startDate,
    DateTime? endDate,
    bool? isCurrent,
    DateTime? createdAt,
  }) {
    return Unit(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      name: name ?? this.name,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isCurrent: isCurrent ?? this.isCurrent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Check if unit is scheduled for a specific date
  bool isScheduledFor(DateTime date) {
    if (startDate == null || endDate == null) return false;
    return date.isAfter(startDate!) && date.isBefore(endDate!);
  }

  /// Check if unit is currently active (today is within its date range)
  bool get isActive {
    final now = DateTime.now();
    return isScheduledFor(now) || isCurrent;
  }

  /// Get progress percentage based on date range
  double get progressPercentage {
    if (startDate == null || endDate == null) return 0.0;
    
    final now = DateTime.now();
    if (now.isBefore(startDate!)) return 0.0;
    if (now.isAfter(endDate!)) return 100.0;
    
    final totalDuration = endDate!.difference(startDate!).inDays;
    final elapsed = now.difference(startDate!).inDays;
    
    return (elapsed / totalDuration * 100).clamp(0.0, 100.0);
  }

  @override
  String toString() {
    return 'Unit(id: $id, name: $name, orderIndex: $orderIndex, isCurrent: $isCurrent)';
  }
}
