import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/data/repositories/goal_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';

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

  List<Goal> get activeGoals => goals.where((g) => g.status == 'active').toList();
  List<Goal> get completedGoals => goals.where((g) => g.isCompleted).toList();
  int get activeCount => activeGoals.length;
  int get completedCount => completedGoals.length;
}

class GoalNotifier extends StateNotifier<GoalState> {
  final GoalRepository _repository;
  final String _userId;

  GoalNotifier(this._repository, this._userId) : super(GoalState()) {
    loadGoals();
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

  Future<void> updateProgress(Goal goal, double newProgress) async {
    try {
      final updatedGoal = await _repository.updateProgress(goal, newProgress);
      final updated = state.goals.map((g) {
        return g.id == updatedGoal.id ? updatedGoal : g;
      }).toList();
      state = state.copyWith(goals: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update progress: ${e.toString()}');
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _repository.deleteGoal(goalId);
      final updated = state.goals.where((g) => g.id != goalId).toList();
      state = state.copyWith(goals: updated);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete goal: ${e.toString()}');
    }
  }
}

final goalProvider = StateNotifierProvider<GoalNotifier, GoalState>((ref) {
  final repository = ref.watch(goalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return GoalNotifier(repository, userId);
});