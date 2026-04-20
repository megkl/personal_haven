import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/task.dart';

/// Data Access Object for Tasks
class TaskDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Insert a new task
  Future<void> insert(Task task) async {
    final db = await _dbHelper.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple tasks
  Future<void> insertAll(List<Task> tasks) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var task in tasks) {
      batch.insert(
        'tasks',
        task.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  /// Get all tasks for a user
  Future<List<Task>> getAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_completed ASC, due_date ASC, created_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get task by ID
  Future<Task?> getById(String taskId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  /// Get pending tasks (not completed)
  Future<List<Task>> getPendingTasks(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND is_completed = 0',
      whereArgs: [userId],
      orderBy: 'CASE priority '
          "WHEN 'urgent' THEN 1 "
          "WHEN 'high' THEN 2 "
          "WHEN 'medium' THEN 3 "
          "WHEN 'low' THEN 4 "
          'ELSE 5 END, due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get completed tasks
  Future<List<Task>> getCompletedTasks(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [userId],
      orderBy: 'completed_at DESC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get urgent tasks (high/urgent priority or overdue)
  Future<List<Task>> getUrgentTasks(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();

    final maps = await db.query(
      'tasks',
      where: '''user_id = ? AND is_completed = 0 AND 
               (priority IN ('urgent', 'high') OR 
               (due_date IS NOT NULL AND due_date < ?))''',
      whereArgs: [userId, now],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get tasks due today
  Future<List<Task>> getTodayTasks(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where:
          'user_id = ? AND is_completed = 0 AND due_date >= ? AND due_date <= ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'CASE priority '
          "WHEN 'urgent' THEN 1 "
          "WHEN 'high' THEN 2 "
          "WHEN 'medium' THEN 3 "
          "WHEN 'low' THEN 4 "
          'ELSE 5 END, due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND is_completed = 0 AND due_date < ?',
      whereArgs: [userId, startOfDay.toIso8601String()],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get tasks due this week
  Future<List<Task>> getThisWeekTasks(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfWeek = startOfDay.add(const Duration(days: 7));

    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where:
          'user_id = ? AND is_completed = 0 AND due_date >= ? AND due_date <= ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfWeek.toIso8601String(),
      ],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get tasks by category
  Future<List<Task>> getByCategory(String userId, String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'is_completed ASC, due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Get tasks by priority
  Future<List<Task>> getByPriority(String userId, String priority) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND priority = ? AND is_completed = 0',
      whereArgs: [userId, priority],
      orderBy: 'due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  /// Search tasks
  Future<List<Task>> search(String userId, String query) async {
    final db = await _dbHelper.database;
    final searchTerm = '%$query%';
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND (title LIKE ? OR description LIKE ?)',
      whereArgs: [userId, searchTerm, searchTerm],
      orderBy: 'is_completed ASC, due_date ASC',
    );

    return maps.map((map) => Task.fromMap(map)).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  /// Get task count by status
  Future<Map<String, int>> getTaskStats(String userId) async {
    final db = await _dbHelper.database;

    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ?',
      [userId],
    );

    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND is_completed = 1',
      [userId],
    );

    final pendingResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND is_completed = 0',
      [userId],
    );

    final urgentResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND is_completed = 0 AND priority IN ('urgent', 'high')",
      [userId],
    );

    final overdueResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM tasks WHERE user_id = ? AND is_completed = 0 AND due_date < ?',
      [userId, DateTime.now().toIso8601String()],
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'completed': Sqflite.firstIntValue(completedResult) ?? 0,
      'pending': Sqflite.firstIntValue(pendingResult) ?? 0,
      'urgent': Sqflite.firstIntValue(urgentResult) ?? 0,
      'overdue': Sqflite.firstIntValue(overdueResult) ?? 0,
    };
  }

  /// Get completion percentage
  Future<double> getCompletionPercentage(String userId) async {
    final stats = await getTaskStats(userId);
    final total = stats['total'] ?? 0;
    final completed = stats['completed'] ?? 0;

    if (total == 0) return 0.0;
    return (completed / total) * 100;
  }

  /// Get count by priority
  Future<Map<String, int>> getCountByPriority(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT priority, COUNT(*) as count 
      FROM tasks 
      WHERE user_id = ? AND is_completed = 0
      GROUP BY priority
    ''', [userId]);

    final Map<String, int> stats = {};
    for (final row in result) {
      final priority = row['priority'] as String?;
      final count = row['count'] as int?;
      if (priority != null && count != null) {
        stats[priority] = count;
      }
    }
    return stats;
  }

  /// Get count by category
  Future<Map<String, int>> getCountByCategory(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM tasks 
      WHERE user_id = ?
      GROUP BY category
    ''', [userId]);

    final Map<String, int> stats = {};
    for (final row in result) {
      final category = row['category'] as String?;
      final count = row['count'] as int?;
      if (category != null && count != null) {
        stats[category] = count;
      }
    }
    return stats;
  }

  /// Get daily completion stats (last 7 days)
  Future<Map<String, int>> getDailyCompletionStats(String userId) async {
    final db = await _dbHelper.database;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));

    final result = await db.rawQuery('''
      SELECT DATE(completed_at) as date, COUNT(*) as count 
      FROM tasks 
      WHERE user_id = ? AND is_completed = 1 AND completed_at >= ?
      GROUP BY DATE(completed_at)
      ORDER BY date DESC
    ''', [userId, weekAgo.toIso8601String()]);

    final Map<String, int> stats = {};
    for (final row in result) {
      final date = row['date'] as String?;
      final count = row['count'] as int?;
      if (date != null && count != null) {
        stats[date] = count;
      }
    }
    return stats;
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  /// Update a task
  Future<int> update(Task task) async {
    final db = await _dbHelper.database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'task_id = ?',
      whereArgs: [task.id],
    );
  }

  /// Toggle task completion
  Future<int> toggleCompletion(String taskId) async {
    final db = await _dbHelper.database;
    final task = await getById(taskId);
    if (task == null) return 0;

    final newStatus = task.isCompleted ? 0 : 1;
    final completedAt = newStatus == 1 ? DateTime.now().toIso8601String() : null;

    return await db.update(
      'tasks',
      {
        'is_completed': newStatus,
        'completed_at': completedAt,
      },
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Delete a task
  Future<int> delete(String taskId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

  /// Delete all tasks for a user
  Future<int> deleteAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete completed tasks
  Future<int> deleteCompletedTasks(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'tasks',
      where: 'user_id = ? AND is_completed = 1',
      whereArgs: [userId],
    );
  }

  /// Delete old completed tasks (older than X days)
  Future<int> deleteOldCompletedTasks(String userId, {int daysOld = 30}) async {
    final db = await _dbHelper.database;
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    return await db.delete(
      'tasks',
      where: 'user_id = ? AND is_completed = 1 AND completed_at < ?',
      whereArgs: [userId, cutoffDate.toIso8601String()],
    );
  }
}