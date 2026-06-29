import 'package:equatable/equatable.dart';

/// Task model for todo items
class Task extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final bool isCompleted;
  final DateTime? dueDate;
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String category; // 'personal', 'work', 'wellness', 'finance'
  final DateTime createdAt;
  final DateTime? completedAt;

  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.isCompleted = false,
    this.dueDate,
    this.priority = 'medium',
    this.category = 'personal',
    required this.createdAt,
    this.completedAt,
  });

  /// Check if task is overdue
  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDeadline!.isBefore(DateTime.now());
  }

  /// Whether the task has an explicit time rather than a date-only deadline.
  bool get hasDueTime =>
      dueDate != null &&
      (dueDate!.hour != 0 ||
          dueDate!.minute != 0 ||
          dueDate!.second != 0 ||
          dueDate!.millisecond != 0 ||
          dueDate!.microsecond != 0);

  /// Date-only tasks remain valid until the end of their due day.
  DateTime? get dueDeadline {
    if (dueDate == null) return null;
    if (hasDueTime) return dueDate;
    return DateTime(
      dueDate!.year,
      dueDate!.month,
      dueDate!.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Check if task is due today
  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    return dueDate!.year == now.year &&
        dueDate!.month == now.month &&
        dueDate!.day == now.day;
  }

  /// Check if task is urgent (high priority or overdue)
  bool get isUrgent {
    return priority == 'urgent' || (priority == 'high' && isOverdue);
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    bool? isCompleted,
    DateTime? dueDate,
    String? priority,
    String? category,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearDueDate = false,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toFirestore() => toJson();

  static Task fromFirestore(dynamic doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Task.fromJson({...d, 'id': doc.id});
  }

  Map<String, dynamic> toMap() {
    return {
      'task_id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_completed': isCompleted ? 1 : 0,
      'due_date': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['task_id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      isCompleted: map['is_completed'] == 1,
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      priority: map['priority'] as String? ?? 'medium',
      category: map['category'] as String? ?? 'personal',
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
      'dueDate': dueDate?.toIso8601String(),
      'priority': priority,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? false,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String? ?? 'personal',
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    isCompleted,
    dueDate,
    priority,
    category,
    createdAt,
    completedAt,
  ];

  @override
  String toString() {
    return 'Task(id: $id, title: $title, completed: $isCompleted, priority: $priority)';
  }
}
