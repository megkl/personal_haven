import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class FoodRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'food_entries';

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
    await _fs.set(userId, _col, entry.id, entry.toFirestore());
    return entry;
  }

  Future<List<FoodEntry>> getAllEntries(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('consumedAt', descending: true));
    return snap.docs.map((d) => FoodEntry.fromFirestore(d)).toList();
  }

  Future<List<FoodEntry>> getTodayEntries(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final snap = await _fs.query(
        userId,
        _col,
        (c) => c
            .where('consumedAt', isGreaterThanOrEqualTo: start)
            .where('consumedAt', isLessThan: end)
            .orderBy('consumedAt'));
    return snap.docs.map((d) => FoodEntry.fromFirestore(d)).toList();
  }

  Future<List<FoodEntry>> getEntriesByMealType(
      String userId, String mealType) async {
    final today = await getTodayEntries(userId);
    return today.where((e) => e.mealType == mealType.toLowerCase()).toList();
  }

  Future<int> getTodayCalories(String userId) async {
    final entries = await getTodayEntries(userId);
    return entries.fold<int>(0, (s, e) => s + (e.calories ?? 0));
  }

  Future<Map<String, int>> getTodayMacros(String userId) async {
    final entries = await getTodayEntries(userId);
    return {
      'calories': entries.fold<int>(0, (s, e) => s + (e.calories ?? 0)),
      'protein': entries.fold<int>(0, (s, e) => s + (e.protein ?? 0)),
      'carbs': entries.fold<int>(0, (s, e) => s + (e.carbs ?? 0)),
      'fat': entries.fold<int>(0, (s, e) => s + (e.fat ?? 0)),
    };
  }

  Future<void> updateEntry(FoodEntry entry) async {
    await _fs.set(entry.userId, _col, entry.id, entry.toFirestore());
  }

  Future<void> deleteEntry(String userId, String entryId) async {
    await _fs.delete(userId, _col, entryId);
  }

  Future<void> deleteAllEntries(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
