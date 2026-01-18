class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? dueDate;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
    );
  }
}