import 'package:personal_haven/data/data_sources/local/dao/task_dao.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:uuid/uuid.dart';

/// Repository for Task operations
class TaskRepository {
  final TaskDao _taskDao;
  final Uuid _uuid = const Uuid();

  TaskRepository({TaskDao? taskDao}) : _taskDao = taskDao ?? TaskDao();

  /// Create a new task
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

    await _taskDao.insert(task);
    return task;
  }

  /// Get all tasks for a user
  Future<List<Task>> getAllTasks(String userId) async {
    return await _taskDao.getAllByUserId(userId);
  }

  /// Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    return await _taskDao.getById(taskId);
  }

  /// Get pending tasks
  Future<List<Task>> getPendingTasks(String userId) async {
    return await _taskDao.getPendingTasks(userId);
  }

  /// Get completed tasks
  Future<List<Task>> getCompletedTasks(String userId) async {
    return await _taskDao.getCompletedTasks(userId);
  }

  /// Get urgent tasks
  Future<List<Task>> getUrgentTasks(String userId) async {
    return await _taskDao.getUrgentTasks(userId);
  }

  /// Get today's tasks
  Future<List<Task>> getTodayTasks(String userId) async {
    return await _taskDao.getTodayTasks(userId);
  }

  /// Get tasks by category
  Future<List<Task>> getTasksByCategory(String userId, String category) async {
    return await _taskDao.getByCategory(userId, category);
  }

  /// Get tasks by priority
  Future<List<Task>> getTasksByPriority(String userId, String priority) async {
    return await _taskDao.getByPriority(userId, priority);
  }

  /// Toggle task completion
  Future<Task> toggleTask(Task task) async {
    final updatedTask = task.copyWith(
      isCompleted: !task.isCompleted,
      completedAt: !task.isCompleted ? DateTime.now() : null,
    );
    
    await _taskDao.update(updatedTask);
    return updatedTask;
  }

  /// Update a task
  Future<Task> updateTask(Task task) async {
    await _taskDao.update(task);
    return task;
  }

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    await _taskDao.delete(taskId);
  }

  /// Get task statistics
  Future<Map<String, int>> getTaskStats(String userId) async {
    return await _taskDao.getTaskStats(userId);
  }

  /// Get completion percentage
  Future<double> getCompletionPercentage(String userId) async {
    return await _taskDao.getCompletionPercentage(userId);
  }

  /// Get tasks grouped by priority
  Future<Map<String, List<Task>>> getTasksByPriorityGrouped(String userId) async {
    final tasks = await getPendingTasks(userId);
    
    return {
      'urgent': tasks.where((t) => t.priority == 'urgent').toList(),
      'high': tasks.where((t) => t.priority == 'high').toList(),
      'medium': tasks.where((t) => t.priority == 'medium').toList(),
      'low': tasks.where((t) => t.priority == 'low').toList(),
    };
  }

  /// Get overdue tasks
  Future<List<Task>> getOverdueTasks(String userId) async {
    final tasks = await getPendingTasks(userId);
    return tasks.where((task) => task.isOverdue).toList();
  }
}