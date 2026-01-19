import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/task.dart';

/// Data Access Object for Tasks
class TaskDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new task
  Future<void> insert(Task task) async {
    final db = await _dbHelper.database;
    await db.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get all tasks for a user
  Future<List<Task>> getAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'tasks',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
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
      orderBy: 'due_date ASC',
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

  /// Get urgent tasks (high priority or overdue)
  Future<List<Task>> getUrgentTasks(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final maps = await db.query(
      'tasks',
      where: 'user_id = ? AND is_completed = 0 AND (priority = ? OR (due_date < ? AND due_date IS NOT NULL))',
      whereArgs: [userId, 'urgent', now],
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
      where: 'user_id = ? AND is_completed = 0 AND due_date >= ? AND due_date <= ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'priority DESC, due_date ASC',
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
      orderBy: 'created_at DESC',
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

  /// Delete a task
  Future<int> delete(String taskId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'tasks',
      where: 'task_id = ?',
      whereArgs: [taskId],
    );
  }

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

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'completed': Sqflite.firstIntValue(completedResult) ?? 0,
      'pending': Sqflite.firstIntValue(pendingResult) ?? 0,
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
}