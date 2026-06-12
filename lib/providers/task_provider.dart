import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:personal_haven/data/repositories/task_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'task_provider.g.dart';

/// Provider for TaskRepository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Task state
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final String filterType; // 'all', 'pending', 'completed', 'urgent', 'today', 'overdue'
  final String? searchQuery;

  TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.filterType = 'all',
    this.searchQuery,
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    String? filterType,
    String? searchQuery,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterType: filterType ?? this.filterType,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────────────────────

  /// Get pending tasks
  List<Task> get pendingTasks => tasks.where((t) => !t.isCompleted).toList();

  /// Get completed tasks
  List<Task> get completedTasks => tasks.where((t) => t.isCompleted).toList();

  /// Get urgent tasks
  List<Task> get urgentTasks =>
      tasks.where((t) => t.isUrgent && !t.isCompleted).toList();

  /// Get overdue tasks
  List<Task> get overdueTasks =>
      tasks.where((t) => t.isOverdue && !t.isCompleted).toList();

  /// Get today's tasks
  List<Task> get todayTasks =>
      tasks.where((t) => t.isDueToday && !t.isCompleted).toList();

  /// Get pending tasks count
  int get pendingCount => pendingTasks.length;

  /// Get completed tasks count
  int get completedCount => completedTasks.length;

  /// Get urgent tasks count
  int get urgentCount => urgentTasks.length;

  /// Get overdue tasks count
  int get overdueCount => overdueTasks.length;

  /// Get completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    return (completedCount / tasks.length) * 100;
  }

  /// Get filtered tasks based on current filter
  List<Task> get filteredTasks {
    switch (filterType) {
      case 'pending':
        return pendingTasks;
      case 'completed':
        return completedTasks;
      case 'urgent':
        return urgentTasks;
      case 'today':
        return todayTasks;
      case 'overdue':
        return overdueTasks;
      default:
        return tasks;
    }
  }

  /// Get tasks by priority
  Map<String, List<Task>> get tasksByPriority {
    return {
      'urgent': pendingTasks.where((t) => t.priority == 'urgent').toList(),
      'high': pendingTasks.where((t) => t.priority == 'high').toList(),
      'medium': pendingTasks.where((t) => t.priority == 'medium').toList(),
      'low': pendingTasks.where((t) => t.priority == 'low').toList(),
    };
  }

  /// Get tasks by category
  Map<String, List<Task>> get tasksByCategory {
    final Map<String, List<Task>> grouped = {};
    for (var task in tasks) {
      grouped.putIfAbsent(task.category, () => []).add(task);
    }
    return grouped;
  }
}


@riverpod
class TaskNotifier extends _$TaskNotifier {
  final TaskRepository _repository = TaskRepository();

  String get _userId => ref.watch(currentUserIdProvider);

  @override
  TaskState build() {
    if (_userId.isNotEmpty) {
      Future.microtask(loadTasks);
    }
    return TaskState();
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────────

  /// Load tasks based on filter
  Future<void> loadTasks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      List<Task> tasks;

      switch (state.filterType) {
        case 'pending':
          tasks = await _repository.getPendingTasks(_userId);
          break;
        case 'completed':
          tasks = await _repository.getCompletedTasks(_userId);
          break;
        case 'urgent':
          tasks = await _repository.getUrgentTasks(_userId);
          break;
        case 'today':
          tasks = await _repository.getTodayTasks(_userId);
          break;
        case 'overdue':
          tasks = await _repository.getOverdueTasks(_userId);
          break;
        default:
          tasks = await _repository.getAllTasks(_userId);
      }

      state = state.copyWith(
        tasks: tasks,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load tasks: ${e.toString()}',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Add a new task
  Future<void> addTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String priority = 'medium',
    String category = 'personal',
  }) async {
    try {
      final newTask = await _repository.createTask(
        userId: _userId,
        title: title,
        description: description,
        dueDate: dueDate,
        priority: priority,
        category: category,
      );

      state = state.copyWith(tasks: [newTask, ...state.tasks]);

      // Notify if due today or overdue
      if (newTask.isDueToday) {
        await NotificationService.instance
            .notifyTaskDueToday(newTask.id, newTask.title);
      } else if (newTask.isOverdue) {
        await NotificationService.instance
            .notifyTaskOverdue(newTask.id, newTask.title);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to add task: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  /// Toggle task completion
  Future<void> toggleTask(Task task) async {
    try {
      final updatedTask = await _repository.toggleTask(task);

      final updatedTasks = state.tasks.map((t) {
        return t.id == updatedTask.id ? updatedTask : t;
      }).toList();

      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to toggle task: ${e.toString()}',
      );
    }
  }

  /// Update a task
  Future<void> updateTask(Task task) async {
    try {
      final updatedTask = await _repository.updateTask(task);

      final updatedTasks = state.tasks.map((t) {
        return t.id == updatedTask.id ? updatedTask : t;
      }).toList();

      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update task: ${e.toString()}',
      );
    }
  }

  /// Update task priority
  Future<void> updatePriority(Task task, String newPriority) async {
    try {
      final updatedTask = await _repository.updatePriority(task, newPriority);

      final updatedTasks = state.tasks.map((t) {
        return t.id == updatedTask.id ? updatedTask : t;
      }).toList();

      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update priority: ${e.toString()}',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(_userId, taskId);
      final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete task: ${e.toString()}');
    }
  }

  /// Delete all completed tasks
  Future<void> deleteCompletedTasks() async {
    try {
      await _repository.deleteCompletedTasks(_userId);
      final updatedTasks = state.tasks.where((t) => !t.isCompleted).toList();
      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete completed tasks: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FILTER & SEARCH
  // ─────────────────────────────────────────────────────────────

  /// Change filter
  Future<void> setFilter(String filterType) async {
    state = state.copyWith(filterType: filterType);
    await loadTasks();
  }

  /// Search tasks
  Future<void> searchTasks(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchQuery: null);
      await loadTasks();
      return;
    }

    state = state.copyWith(searchQuery: query, isLoading: true);

    try {
      final tasks = await _repository.searchTasks(_userId, query);
      state = state.copyWith(tasks: tasks, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search tasks: ${e.toString()}',
      );
    }
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchQuery: null);
    loadTasks();
  }

  // ─────────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────────

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh tasks
  Future<void> refresh() async {
    await loadTasks();
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────


/// Provider for task statistics
final taskStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return await repository.getTaskStats(userId);
});

/// Provider for completion percentage
final taskCompletionProvider = FutureProvider<double>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return await repository.getCompletionPercentage(userId);
});

/// Provider for urgent tasks count
final urgentTasksCountProvider = Provider<int>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.urgentCount;
});

/// Provider for overdue tasks count
final overdueTasksCountProvider = Provider<int>((ref) {
  final taskState = ref.watch(taskProvider);
  return taskState.overdueCount;
});

/// Provider for today's tasks
final todayTasksProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return await repository.getTodayTasks(userId);
});

/// Provider for pending tasks
final pendingTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskProvider).pendingTasks;
});

/// Provider for completed tasks
final completedTasksProvider = Provider<List<Task>>((ref) {
  return ref.watch(taskProvider).completedTasks;
});