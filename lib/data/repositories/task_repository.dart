import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class TaskRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'tasks';

  Future<Task> createTask({
    required String userId,
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String category = 'personal',
  }) async {
    final task = Task(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      dueDate: dueDate,
      priority: priority,
      category: category,
      createdAt: DateTime.now(),
    );
    await _fs.set(userId, _col, task.id, task.toFirestore());
    return task;
  }

  Future<List<Task>> getAllTasks(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('createdAt', descending: true));
    return snap.docs.map((d) => Task.fromFirestore(d)).toList();
  }

  Future<List<Task>> getPendingTasks(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.where('isCompleted', isEqualTo: false)
            .orderBy('createdAt', descending: true));
    return snap.docs.map((d) => Task.fromFirestore(d)).toList();
  }

  Future<List<Task>> getCompletedTasks(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.where('isCompleted', isEqualTo: true)
            .orderBy('createdAt', descending: true));
    return snap.docs.map((d) => Task.fromFirestore(d)).toList();
  }

  Future<List<Task>> getTodayTasks(String userId) async {
    final all = await getPendingTasks(userId);
    return all.where((t) => t.isDueToday).toList();
  }

  Future<List<Task>> getOverdueTasks(String userId) async {
    final all = await getPendingTasks(userId);
    return all.where((t) => t.isOverdue).toList();
  }

  Future<List<Task>> getUrgentTasks(String userId) async {
    final all = await getPendingTasks(userId);
    return all.where((t) => t.isUrgent).toList();
  }

  Future<List<Task>> getThisWeekTasks(String userId) async {
    final all = await getPendingTasks(userId);
    final weekFromNow = DateTime.now().add(const Duration(days: 7));
    return all
        .where((t) => t.dueDate != null && t.dueDate!.isBefore(weekFromNow))
        .toList();
  }

  Future<List<Task>> searchTasks(String userId, String query) async {
    final all = await getAllTasks(userId);
    final q = query.toLowerCase();
    return all
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            (t.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<Map<String, int>> getTaskStats(String userId) async {
    final all = await getAllTasks(userId);
    return {
      'total': all.length,
      'pending': all.where((t) => !t.isCompleted).length,
      'completed': all.where((t) => t.isCompleted).length,
      'overdue': all.where((t) => t.isOverdue).length,
    };
  }

  Future<double> getCompletionPercentage(String userId) async {
    final all = await getAllTasks(userId);
    if (all.isEmpty) return 0.0;
    return all.where((t) => t.isCompleted).length / all.length * 100;
  }

  Future<Task> toggleTask(Task task) async {
    final updated = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    await _fs.set(task.userId, _col, task.id, updated.toFirestore());
    return updated;
  }

  Future<Task> updateTask(Task task) async {
    await _fs.set(task.userId, _col, task.id, task.toFirestore());
    return task;
  }

  Future<Task> updatePriority(Task task, String newPriority) async {
    final updated = task.copyWith(priority: newPriority);
    await _fs.set(task.userId, _col, task.id, updated.toFirestore());
    return updated;
  }

  Future<void> deleteTask(String userId, String taskId) async {
    await _fs.delete(userId, _col, taskId);
  }

  Future<void> deleteCompletedTasks(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.where('isCompleted', isEqualTo: true));
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deleteAllTasks(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
