import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/food_entry.dart';

class FoodDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<void> insert(FoodEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert('food_entries', entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace);
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
    final db = await _dbHelper.database;
    final maps = await db.query(
      'food_entries',
      where: 'user_id = ? AND meal_type = ?',
      whereArgs: [userId, mealType],
      orderBy: 'consumed_at DESC',
    );
    return maps.map((map) => FoodEntry.fromMap(map)).toList();
  }

   getTodayCalories(String userId) async {
    final entries = await getTodayEntries(userId);
    return entries.fold(0, (sum, entry) => sum + (entry.calories ?? 0));
  }
  

  Future<int> update(FoodEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'food_entries',
      entry.toMap(),
      where: 'food_entry_id = ?',
      whereArgs: [entry.id],
    );
  }

  Future<int> delete(String entryId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'food_entries',
      where: 'food_entry_id = ?',
      whereArgs: [entryId],
    );
  }
}

