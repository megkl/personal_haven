import 'package:personal_haven/data/data_sources/local/dao/goal_dao.dart';
import 'package:personal_haven/data/models/goal.dart';
import 'package:uuid/uuid.dart';

class GoalRepository {
  final GoalDao _goalDao;
  final Uuid _uuid = const Uuid();

  GoalRepository({GoalDao? goalDao}) : _goalDao = goalDao ?? GoalDao();

  Future<Goal> createGoal({
    required String userId,
    required String title,
    String? description,
    required double targetValue,
    required String unit,
    DateTime? targetDate,
    String category = 'personal',
  }) async {
    final now = DateTime.now();
    final goal = Goal(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      targetValue: targetValue,
      currentValue: 0,
      unit: unit,
      startDate: now,
      targetDate: targetDate,
      category: category,
      createdAt: now,
      updatedAt: now,
    );

    await _goalDao.insert(goal);
    return goal;
  }

  Future<List<Goal>> getAllGoals(String userId) async {
    return await _goalDao.getAllByUserId(userId);
  }

  Future<List<Goal>> getActiveGoals(String userId) async {
    return await _goalDao.getActiveGoals(userId);
  }

  Future<Map<String, int>> getGoalStats(String userId) async {
    return await _goalDao.getGoalStats(userId);
  }

  Future<Goal> updateProgress(Goal goal, double newProgress) async {
    final updatedGoal = goal.copyWith(
      currentValue: newProgress,
      updatedAt: DateTime.now(),
      status: newProgress >= goal.targetValue ? 'completed' : goal.status,
    );
    await _goalDao.update(updatedGoal);
    return updatedGoal;
  }

  Future<void> updateGoal(Goal goal) async {
    await _goalDao.update(goal);
  }

  Future<void> deleteGoal(String goalId) async {
    await _goalDao.delete(goalId);
  }
}
