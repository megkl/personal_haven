import 'package:personal_haven/data/data_sources/local/dao/food_dao.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:uuid/uuid.dart';

class FoodRepository {
  final FoodDao _foodDao;
  final Uuid _uuid = const Uuid();

  FoodRepository({FoodDao? foodDao}) : _foodDao = foodDao ?? FoodDao();

  Future<FoodEntry> createEntry({
    required String userId,
    required String mealType,
    required String foodName,
    String? description,
    int? calories,
  }) async {
    final entry = FoodEntry(
      id: _uuid.v4(),
      userId: userId,
      mealType: mealType,
      foodName: foodName,
      description: description,
      calories: calories,
      consumedAt: DateTime.now(),
    );

    await _foodDao.insert(entry);
    return entry;
  }

  Future<List<FoodEntry>> getAllEntries(String userId) async {
    return await _foodDao.getAllByUserId(userId);
  }

  Future<List<FoodEntry>> getTodayEntries(String userId) async {
    return await _foodDao.getTodayEntries(userId);
  }

  Future<int> getTodayCalories(String userId) async {
    return await _foodDao.getTodayCalories(userId);
  }

  Future<void> updateEntry(FoodEntry entry) async {
    await _foodDao.update(entry);
  }

  Future<void> deleteEntry(String entryId) async {
    await _foodDao.delete(entryId);
  }
}

