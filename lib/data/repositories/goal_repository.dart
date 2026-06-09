import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class GoalRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'goals';

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
    await _fs.set(userId, _col, goal.id, goal.toFirestore());
    return goal;
  }

  Future<List<Goal>> getAllGoals(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('createdAt', descending: true));
    return snap.docs.map((d) => Goal.fromFirestore(d)).toList();
  }

  Future<List<Goal>> getActiveGoals(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.where('status', isEqualTo: 'active'));
    return snap.docs.map((d) => Goal.fromFirestore(d)).toList();
  }

  Future<Map<String, int>> getGoalStats(String userId) async {
    final all = await getAllGoals(userId);
    return {
      'total': all.length,
      'active': all.where((g) => g.status == 'active').length,
      'completed': all.where((g) => g.isCompleted).length,
      'paused': all.where((g) => g.status == 'paused').length,
    };
  }

  Future<Goal> updateProgress(Goal goal, double newProgress) async {
    final updated = goal.copyWith(
      currentValue: newProgress,
      updatedAt: DateTime.now(),
      status: newProgress >= goal.targetValue ? 'completed' : goal.status,
    );
    await _fs.set(goal.userId, _col, goal.id, updated.toFirestore());
    return updated;
  }

  Future<void> updateGoal(Goal goal) async {
    await _fs.set(goal.userId, _col, goal.id, goal.toFirestore());
  }

  Future<void> deleteGoal(String userId, String goalId) async {
    await _fs.delete(userId, _col, goalId);
  }
}
