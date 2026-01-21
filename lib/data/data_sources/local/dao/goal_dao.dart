import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/goal.dart';

class GoalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insert(Goal goal) async {
    final db = await _dbHelper.database;
    await db.insert('goals', goal.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Goal>> getAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<List<Goal>> getActiveGoals(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'active'],
      orderBy: 'target_date ASC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<List<Goal>> getCompletedGoals(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ? AND status = ?',
      whereArgs: [userId, 'completed'],
      orderBy: 'updated_at DESC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<List<Goal>> getByCategory(String userId, String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'goals',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Goal.fromMap(map)).toList();
  }

  Future<Map<String, int>> getGoalStats(String userId) async {
    final db = await _dbHelper.database;
    
    final totalResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM goals WHERE user_id = ?',
      [userId],
    );
    
    final activeResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM goals WHERE user_id = ? AND status = ?',
      [userId, 'active'],
    );
    
    final completedResult = await db.rawQuery(
      'SELECT COUNT(*) as count FROM goals WHERE user_id = ? AND status = ?',
      [userId, 'completed'],
    );

    return {
      'total': Sqflite.firstIntValue(totalResult) ?? 0,
      'active': Sqflite.firstIntValue(activeResult) ?? 0,
      'completed': Sqflite.firstIntValue(completedResult) ?? 0,
    };
  }

  Future<int> update(Goal goal) async {
    final db = await _dbHelper.database;
    return await db.update(
      'goals',
      goal.toMap(),
      where: 'goal_id = ?',
      whereArgs: [goal.id],
    );
  }

  Future<int> delete(String goalId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'goals',
      where: 'goal_id = ?',
      whereArgs: [goalId],
    );
  }
}