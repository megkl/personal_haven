import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/data/data_sources/local/cache_helper.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class GoalRepository {
  final _fs = FirestoreService.instance;
  final _cache = CacheHelper();
  final _uuid = const Uuid();
  static const _col = 'goals';
  static const _cacheDuration = Duration(hours: 1);

  // ── CREATE ────────────────────────────────────────────────────────────────

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
    // Invalidate cache
    await _cache.clearData(userId, _col);
    return goal;
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Fetches all goals for the user, using the local cache when valid.
  Future<List<Goal>> getAllGoals(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getData(
        userId,
        _col,
        fromJson: (json) => Goal.fromJson(json as Map<String, dynamic>),
        expiry: _cacheDuration,
      );
      if (cached != null) return cached;
    }

    final snap = await _fs.query(
        userId, _col, (c) => c.orderBy('createdAt', descending: true));
    final goals = snap.docs.map((d) => Goal.fromFirestore(d)).toList();

    await _cache.saveData(userId, _col, goals,
        toJson: (g) => g.toJson());

    return goals;
  }

  Future<List<Goal>> getActiveGoals(String userId,
      {bool forceRefresh = false}) async {
    final all = await getAllGoals(userId, forceRefresh: forceRefresh);
    return all.where((g) => g.status == 'active').toList();
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

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<Goal> updateProgress(Goal goal, double newProgress) async {
    final updated = goal.copyWith(
      currentValue: newProgress,
      updatedAt: DateTime.now(),
      status: newProgress >= goal.targetValue ? 'completed' : goal.status,
    );
    await _fs.set(goal.userId, _col, goal.id, updated.toFirestore());
    // Invalidate cache
    await _cache.clearData(goal.userId, _col);
    return updated;
  }

  Future<void> updateGoal(Goal goal) async {
    await _fs.set(goal.userId, _col, goal.id, goal.toFirestore());
    // Invalidate cache
    await _cache.clearData(goal.userId, _col);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteGoal(String userId, String goalId) async {
    await _fs.delete(userId, _col, goalId);
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }
}
