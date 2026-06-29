import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:personal_haven/data/data_sources/local/cache_helper.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class FoodRepository {
  final _fs = FirestoreService.instance;
  final _cache = CacheHelper();
  final _uuid = const Uuid();
  static const _col = 'food_entries';
  static const _cacheDuration = Duration(hours: 1);

  // ── CREATE ────────────────────────────────────────────────────────────────

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
    // Invalidate cache
    await _cache.clearData(userId, _col);
    return entry;
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Fetches all food entries for the user, using the local cache when valid.
  Future<List<FoodEntry>> getAllEntries(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getData(
        userId,
        _col,
        fromJson: (json) => FoodEntry.fromJson(json as Map<String, dynamic>),
        expiry: _cacheDuration,
      );
      if (cached != null) return cached;
    }

    final snap = await _fs.query(
        userId, _col, (c) => c.orderBy('consumedAt', descending: true));
    final entries =
        snap.docs.map((d) => FoodEntry.fromFirestore(d)).toList();

    await _cache.saveData(userId, _col, entries,
        toJson: (e) => e.toJson());

    return entries;
  }

  Future<List<FoodEntry>> getTodayEntries(String userId,
      {bool forceRefresh = false}) async {
    final all = await getAllEntries(userId, forceRefresh: forceRefresh);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return all
        .where((e) =>
            e.consumedAt.isAfter(todayStart) &&
            e.consumedAt.isBefore(todayEnd))
        .toList()
      ..sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
  }

  Future<List<FoodEntry>> getEntriesByMealType(
      String userId, String mealType) async {
    final today = await getTodayEntries(userId);
    return today
        .where((e) => e.mealType == mealType.toLowerCase())
        .toList();
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

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<void> updateEntry(FoodEntry entry) async {
    await _fs.set(entry.userId, _col, entry.id, entry.toFirestore());
    // Invalidate cache
    await _cache.clearData(entry.userId, _col);
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteEntry(String userId, String entryId) async {
    await _fs.delete(userId, _col, entryId);
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }

  Future<void> deleteAllEntries(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }
}
