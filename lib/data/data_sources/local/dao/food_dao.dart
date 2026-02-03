import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/food_entry.dart';

class FoodDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  Future<void> insert(FoodEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert(
      'food_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  Future<FoodEntry?> getById(String entryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_entries',
      where: 'food_entry_id = ?',
      whereArgs: [entryId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return FoodEntry.fromMap(maps.first);
  }

  Future<List<FoodEntry>> getAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'consumed_at DESC',
    );
    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }

  Future<List<FoodEntry>> getTodayEntries(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_entries',
      where: 'user_id = ? AND consumed_at >= ? AND consumed_at <= ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'consumed_at ASC',
    );
    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }

  Future<List<FoodEntry>> getByMealType(String userId, String mealType) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_entries',
      where: 'user_id = ? AND meal_type = ? AND consumed_at >= ? AND consumed_at <= ?',
      whereArgs: [
        userId,
        mealType,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'consumed_at ASC',
    );
    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }

  Future<List<FoodEntry>> getByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_entries',
      where: 'user_id = ? AND consumed_at >= ? AND consumed_at <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'consumed_at DESC',
    );
    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS - Fixed return types
  // ─────────────────────────────────────────────────────────────

  Future<int> getTodayCalories(String userId) async {
    final entries = await getTodayEntries(userId);
    int total = 0;
    for (final entry in entries) {
      total += entry.calories ?? 0;
    }
    return total;
  }

  Future<int> getTodayProtein(String userId) async {
    final entries = await getTodayEntries(userId);
    int total = 0;
    for (final entry in entries) {
      total += entry.protein ?? 0;
    }
    return total;
  }

  Future<int> getTodayCarbs(String userId) async {
    final entries = await getTodayEntries(userId);
    int total = 0;
    for (final entry in entries) {
      total += entry.carbs ?? 0;
    }
    return total;
  }

  Future<int> getTodayFat(String userId) async {
    final entries = await getTodayEntries(userId);
    int total = 0;
    for (final entry in entries) {
      total += entry.fat ?? 0;
    }
    return total;
  }

  Future<Map<String, int>> getTodayMacros(String userId) async {
    final entries = await getTodayEntries(userId);
    int calories = 0;
    int protein = 0;
    int carbs = 0;
    int fat = 0;

    for (final entry in entries) {
      calories += entry.calories ?? 0;
      protein += entry.protein ?? 0;
      carbs += entry.carbs ?? 0;
      fat += entry.fat ?? 0;
    }

    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
    };
  }

  Future<Map<String, int>> getCaloriesByMealType(String userId) async {
    final entries = await getTodayEntries(userId);
    final Map<String, int> mealCalories = {
      'breakfast': 0,
      'lunch': 0,
      'dinner': 0,
      'snack': 0,
    };

    for (final entry in entries) {
      final type = entry.mealType.toLowerCase();
      mealCalories[type] = (mealCalories[type] ?? 0) + (entry.calories ?? 0);
    }

    return mealCalories;
  }

  Future<int> getWeeklyAverageCalories(String userId) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final entries = await getByDateRange(userId, weekAgo, now);

    if (entries.isEmpty) return 0;

    int totalCalories = 0;
    for (final entry in entries) {
      totalCalories += entry.calories ?? 0;
    }

    return totalCalories ~/ 7;
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  Future<int> update(FoodEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'food_entries',
      entry.toMap(),
      where: 'food_entry_id = ?',
      whereArgs: [entry.id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  Future<int> delete(String entryId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'food_entries',
      where: 'food_entry_id = ?',
      whereArgs: [entryId],
    );
  }

  Future<int> deleteAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'food_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}