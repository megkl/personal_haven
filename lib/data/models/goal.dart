
import 'package:equatable/equatable.dart';

class Goal extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final double targetValue;
  final double currentValue;
  final String unit; // 'KES', 'kg', 'minutes', 'count', etc.
  final DateTime startDate;
  final DateTime? targetDate;
  final String status; // 'active', 'completed', 'paused', 'archived'
  final String category; // 'fitness', 'finance', 'learning', 'personal'
  final DateTime createdAt;
  final DateTime updatedAt;

  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.targetValue,
    this.currentValue = 0.0,
    required this.unit,
    required this.startDate,
    this.targetDate,
    this.status = 'active',
    this.category = 'personal',
    required this.createdAt,
    required this.updatedAt,
  });

  double get progressPercentage {
    if (targetValue == 0) return 0;
    return (currentValue / targetValue * 100).clamp(0, 100);
  }

  bool get isCompleted => currentValue >= targetValue || status == 'completed';

  int get daysRemaining {
    if (targetDate == null) return -1;
    return targetDate!.difference(DateTime.now()).inDays;
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? startDate,
    DateTime? targetDate,
    String? status,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Goal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'unit': unit,
      'startDate': startDate.toIso8601String(),
      'targetDate': targetDate?.toIso8601String(),
      'status': status,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static Goal fromFirestore(dynamic doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Goal(
      id: doc.id,
      userId: d['userId'] as String,
      title: d['title'] as String,
      description: d['description'] as String?,
      targetValue: (d['targetValue'] as num).toDouble(),
      currentValue: (d['currentValue'] as num?)?.toDouble() ?? 0.0,
      unit: d['unit'] as String,
      startDate: DateTime.parse(d['startDate'] as String),
      targetDate: d['targetDate'] != null
          ? DateTime.parse(d['targetDate'] as String)
          : null,
      status: d['status'] as String? ?? 'active',
      category: d['category'] as String? ?? 'personal',
      createdAt: DateTime.parse(d['createdAt'] as String),
      updatedAt: DateTime.parse(d['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goal_id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'start_date': startDate.toIso8601String(),
      'target_date': targetDate?.toIso8601String(),
      'status': status,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      id: map['goal_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      targetValue: (map['target_value'] as num).toDouble(),
      currentValue: (map['current_value'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String,
      startDate: DateTime.parse(map['start_date'] as String),
      targetDate: map['target_date'] != null
          ? DateTime.parse(map['target_date'] as String)
          : null,
      status: map['status'] as String? ?? 'active',
      category: map['category'] as String? ?? 'personal',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        description,
        targetValue,
        currentValue,
        unit,
        startDate,
        targetDate,
        status,
        category,
        createdAt,
        updatedAt,
      ];
}