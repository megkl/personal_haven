import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/mood_log.dart';

class MoodDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insert(MoodLog log) async {
    final db = await _dbHelper.database;
    await db.insert('mood_logs', log.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MoodLog?> getTodayMood(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'mood_logs',
      where: 'user_id = ? AND timestamp >= ? AND timestamp <= ?',
      whereArgs: [userId, startOfDay.toIso8601String(), endOfDay.toIso8601String()],
      orderBy: 'timestamp DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return MoodLog.fromMap(maps.first);
  }

  Future<List<MoodLog>> getWeekMoods(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final db = await _dbHelper.database;
    final maps = await db.query(
      'mood_logs',
      where: 'user_id = ? AND timestamp >= ?',
      whereArgs: [userId, weekAgo.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => MoodLog.fromMap(map)).toList();
  }

  Future<List<MoodLog>> getMonthMoods(String userId) async {
    final now = DateTime.now();
    final monthAgo = now.subtract(const Duration(days: 30));

    final db = await _dbHelper.database;
    final maps = await db.query(
      'mood_logs',
      where: 'user_id = ? AND timestamp >= ?',
      whereArgs: [userId, monthAgo.toIso8601String()],
      orderBy: 'timestamp DESC',
    );

    return maps.map((map) => MoodLog.fromMap(map)).toList();
  }

  Future<Map<String, int>> getWeekMoodStats(String userId) async {
    final moods = await getWeekMoods(userId);
    final stats = <String, int>{};

    for (var mood in moods) {
      stats[mood.moodEmoji] = (stats[mood.moodEmoji] ?? 0) + 1;
    }

    return stats;
  }
}
