import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:personal_haven/data/repositories/task_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';

/// Provider for TaskRepository
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});

/// Task state
class TaskState {
  final List<Task> tasks;
  final bool isLoading;
  final String? error;
  final String filterType; // 'all', 'pending', 'completed', 'urgent', 'today'

  TaskState({
    this.tasks = const [],
    this.isLoading = false,
    this.error,
    this.filterType = 'all',
  });

  TaskState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    String? error,
    String? filterType,
  }) {
    return TaskState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      filterType: filterType ?? this.filterType,
    );
  }

  /// Get pending tasks count
  int get pendingCount => tasks.where((t) => !t.isCompleted).length;

  /// Get completed tasks count
  int get completedCount => tasks.where((t) => t.isCompleted).length;

  /// Get urgent tasks count
  int get urgentCount => tasks.where((t) => t.isUrgent && !t.isCompleted).length;

  /// Get completion percentage
  double get completionPercentage {
    if (tasks.isEmpty) return 0.0;
    return (completedCount / tasks.length) * 100;
  }
}

/// Task Notifier
class TaskNotifier extends StateNotifier<TaskState> {
  final TaskRepository _repository;
  final String _userId;

  TaskNotifier(this._repository, this._userId) : super(TaskState()) {
    loadTasks();
  }

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

      state = state.copyWith(
        tasks: [newTask, ...state.tasks],
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add task: ${e.toString()}',
      );
    }
  }

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

  /// Delete a task
  Future<void> deleteTask(String taskId) async {
    try {
      await _repository.deleteTask(taskId);
      
      final updatedTasks = state.tasks.where((t) => t.id != taskId).toList();
      state = state.copyWith(tasks: updatedTasks);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete task: ${e.toString()}',
      );
    }
  }

  /// Change filter
  Future<void> setFilter(String filterType) async {
    state = state.copyWith(filterType: filterType);
    await loadTasks();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh tasks
  Future<void> refresh() async {
    await loadTasks();
  }
}

/// Provider for TaskNotifier
final taskProvider = StateNotifierProvider<TaskNotifier, TaskState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  return TaskNotifier(repository, userId);
});

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

/// Provider for today's tasks
final todayTasksProvider = FutureProvider<List<Task>>((ref) async {
  final repository = ref.watch(taskRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  return await repository.getTodayTasks(userId);
});