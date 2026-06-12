import 'package:flutter_test/flutter_test.dart';
import 'package:personal_haven/data/models/task.dart';

void main() {
  Task taskWithDueDate(DateTime dueDate) => Task(
    id: 'task',
    userId: 'user',
    title: 'Test task',
    dueDate: dueDate,
    createdAt: DateTime(2026),
  );

  test('date-only task uses the end of its due day as the deadline', () {
    final task = taskWithDueDate(DateTime(2026, 6, 12));

    expect(task.hasDueTime, isFalse);
    expect(task.dueDeadline, DateTime(2026, 6, 12, 23, 59, 59, 999));
  });

  test('timed task uses its exact due time as the deadline', () {
    final task = taskWithDueDate(DateTime(2026, 6, 12, 14, 30));

    expect(task.hasDueTime, isTrue);
    expect(task.dueDeadline, DateTime(2026, 6, 12, 14, 30));
  });

  test('date-only task due today is not overdue before day end', () {
    final now = DateTime.now();
    final task = taskWithDueDate(DateTime(now.year, now.month, now.day));

    expect(task.isDueToday, isTrue);
    expect(task.isOverdue, isFalse);
  });

  test('clearing a due date removes the existing deadline', () {
    final task = taskWithDueDate(DateTime(2026, 6, 12, 14, 30));

    expect(task.copyWith(clearDueDate: true).dueDate, isNull);
  });
}
