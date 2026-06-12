import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/data/repositories/goal_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'goal_provider.g.dart';
final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository();
});

class GoalState {
  final List<Goal> goals;
  final bool isLoading;
  final String? error;

  GoalState({
    this.goals = const [],
    this.isLoading = false,
    this.error,
  });

  GoalState copyWith({
    List<Goal>? goals,
    bool? isLoading,
    String? error,
  }) {
    return GoalState(
      goals: goals ?? this.goals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Computed properties
  List<Goal> get activeGoals =>
      goals.where((g) => g.status == 'active' && !g.isCompleted).toList();

  List<Goal> get completedGoals => goals.where((g) => g.isCompleted).toList();

  List<Goal> get pausedGoals =>
      goals.where((g) => g.status == 'paused').toList();

  int get activeCount => activeGoals.length;
  int get completedCount => completedGoals.length;
  int get totalCount => goals.length;

  double get overallProgress {
    if (activeGoals.isEmpty) return 0;
    double total = 0;
    for (final goal in activeGoals) {
      total += goal.progressPercentage;
    }
    return total / activeGoals.length;
  }

  // Get goals by category
  List<Goal> getGoalsByCategory(String category) {
    return goals.where((g) => g.category == category).toList();
  }

  // Get upcoming deadlines (goals due within 7 days)
  List<Goal> get upcomingDeadlines {
    final now = DateTime.now();
    return activeGoals.where((g) {
      if (g.targetDate == null) return false;
      final daysRemaining = g.targetDate!.difference(now).inDays;
      return daysRemaining >= 0 && daysRemaining <= 7;
    }).toList()
      ..sort((a, b) => a.targetDate!.compareTo(b.targetDate!));
  }
}



@riverpod
class GoalNotifier extends _$GoalNotifier {
  final GoalRepository _repository = GoalRepository();

  String get _userId => ref.watch(currentUserIdProvider);

  @override
  GoalState build() {
    if (_userId.isNotEmpty) {
      Future.microtask(loadGoals);
    }
    return GoalState();
  }

  Future<void> loadGoals() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final goals = await _repository.getAllGoals(_userId);
      state = state.copyWith(goals: goals, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load goals: ${e.toString()}',
      );
    }
  }

  Future<void> addGoal({
    required String title,
    String? description,
    required double targetValue,
    required String unit,
    DateTime? targetDate,
    String category = 'personal',
  }) async {
    try {
      final newGoal = await _repository.createGoal(
        userId: _userId,
        title: title,
        description: description,
        targetValue: targetValue,
        unit: unit,
        targetDate: targetDate,
        category: category,
      );

      state = state.copyWith(goals: [newGoal, ...state.goals]);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add goal: ${e.toString()}');
    }
  }

  Future<void> updateGoal(Goal goal) async {
    try {
      await _repository.updateGoal(goal);

      final updated = state.goals.map((g) {
        return g.id == goal.id ? goal : g;
      }).toList();

      state = state.copyWith(goals: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update goal: ${e.toString()}');
    }
  }

  Future<void> updateProgress(Goal goal, double newProgress) async {
    try {
      final updatedGoal = await _repository.updateProgress(goal, newProgress);

      final updated = state.goals.map((g) {
        return g.id == updatedGoal.id ? updatedGoal : g;
      }).toList();

      state = state.copyWith(goals: updated);

      // Notify on completion
      if (updatedGoal.isCompleted && !goal.isCompleted) {
        await NotificationService.instance
            .notifyGoalCompleted(updatedGoal.title);
      }
      // Notify if deadline approaching
      final days = updatedGoal.daysRemaining;
      if (!updatedGoal.isCompleted && (days == 3 || days == 1)) {
        await NotificationService.instance.notifyGoalDeadlineApproaching(
            updatedGoal.id, updatedGoal.title, days);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to update progress: ${e.toString()}');
    }
  }

  Future<void> togglePause(Goal goal) async {
    try {
      final newStatus = goal.status == 'paused' ? 'active' : 'paused';
      final updatedGoal = goal.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

      await _repository.updateGoal(updatedGoal);

      final updated = state.goals.map((g) {
        return g.id == updatedGoal.id ? updatedGoal : g;
      }).toList();

      state = state.copyWith(goals: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update goal: ${e.toString()}');
    }
  }

  Future<void> markComplete(Goal goal) async {
    try {
      final updatedGoal = goal.copyWith(
        status: 'completed',
        currentValue: goal.targetValue,
        updatedAt: DateTime.now(),
      );

      await _repository.updateGoal(updatedGoal);

      final updated = state.goals.map((g) {
        return g.id == updatedGoal.id ? updatedGoal : g;
      }).toList();

      state = state.copyWith(goals: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to complete goal: ${e.toString()}');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _repository.deleteGoal(_userId, goalId);
      final updated = state.goals.where((g) => g.id != goalId).toList();
      state = state.copyWith(goals: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete goal: ${e.toString()}');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Additional providers
final activeGoalsProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalProvider).activeGoals;
});

final goalStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final state = ref.watch(goalProvider);
  return {
    'total': state.totalCount,
    'active': state.activeCount,
    'completed': state.completedCount,
    'overallProgress': state.overallProgress,
  };
});

final upcomingDeadlinesProvider = Provider<List<Goal>>((ref) {
  return ref.watch(goalProvider).upcomingDeadlines;
});