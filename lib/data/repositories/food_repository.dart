import 'package:personal_haven/data/data_sources/local/dao/food_dao.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:uuid/uuid.dart';

class FoodRepository {
  final FoodDao _foodDao;
  final Uuid _uuid = const Uuid();

  FoodRepository({FoodDao? foodDao}) : _foodDao = foodDao ?? FoodDao();

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  Future<FoodEntry> createEntry({
    required String userId,
    required String mealType,
    required String foodName,
    String? description,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    DateTime? consumedAt,
  }) async {
    final entry = FoodEntry(
      id: _uuid.v4(),
      userId: userId,
      mealType: mealType.toLowerCase(),
      foodName: foodName,
      description: description,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      consumedAt: consumedAt ?? DateTime.now(),
    );

    await _foodDao.insert(entry);
    return entry;
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  Future<FoodEntry?> getEntryById(String entryId) async {
    return await _foodDao.getById(entryId);
  }

  Future<List<FoodEntry>> getAllEntries(String userId) async {
    return await _foodDao.getAllByUserId(userId);
  }

  Future<List<FoodEntry>> getTodayEntries(String userId) async {
    return await _foodDao.getTodayEntries(userId);
  }

  Future<List<FoodEntry>> getEntriesByMealType(
    String userId,
    String mealType,
  ) async {
    return await _foodDao.getByMealType(userId, mealType);
  }

  Future<List<FoodEntry>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _foodDao.getByDateRange(userId, startDate, endDate);
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  Future<int> getTodayCalories(String userId) async {
    return await _foodDao.getTodayCalories(userId);
  }

  Future<Map<String, int>> getTodayMacros(String userId) async {
    return await _foodDao.getTodayMacros(userId);
  }

  Future<Map<String, int>> getCaloriesByMealType(String userId) async {
    return await _foodDao.getCaloriesByMealType(userId);
  }

  Future<int> getWeeklyAverageCalories(String userId) async {
    return await _foodDao.getWeeklyAverageCalories(userId);
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  Future<void> updateEntry(FoodEntry entry) async {
    await _foodDao.update(entry);
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  Future<void> deleteEntry(String entryId) async {
    await _foodDao.delete(entryId);
  }

  Future<void> deleteAllEntries(String userId) async {
    await _foodDao.deleteAllByUserId(userId);
  }
}