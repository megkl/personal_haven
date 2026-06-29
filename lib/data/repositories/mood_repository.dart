import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/data/data_sources/local/cache_helper.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class MoodRepository {
  final _fs = FirestoreService.instance;
  final _cache = CacheHelper();
  final _uuid = const Uuid();
  static const _col = 'mood_logs';
  static const _cacheDuration = Duration(hours: 1);

  // ── WRITE ─────────────────────────────────────────────────────────────────

  Future<MoodLog> logMood({
    required String userId,
    required int moodLevel,
    required String moodEmoji,
    String? moodLabel,
    String? notes,
  }) async {
    final log = MoodLog(
      id: _uuid.v4(),
      userId: userId,
      moodLevel: moodLevel,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      timestamp: DateTime.now(),
      notes: notes,
    );
    await _fs.set(userId, _col, log.id, log.toFirestore());
    // Invalidate so the next read reflects the new mood
    await _cache.clearData(userId, _col);
    return log;
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Fetches all mood logs for the user, using the cache when available.
  Future<List<MoodLog>> getAllMoods(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getData(
        userId,
        _col,
        fromJson: (json) => MoodLog.fromJson(json as Map<String, dynamic>),
        expiry: _cacheDuration,
      );
      if (cached != null) return cached;
    }

    final snap = await _fs.query(
        userId, _col, (c) => c.orderBy('timestamp', descending: true));
    final moods = snap.docs.map((d) => MoodLog.fromFirestore(d)).toList();

    await _cache.saveData(userId, _col, moods,
        toJson: (m) => m.toJson());

    return moods;
  }

  Future<MoodLog?> getTodayMood(String userId) async {
    final all = await getAllMoods(userId);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    try {
      return all.firstWhere((m) => m.timestamp.isAfter(todayStart));
    } catch (_) {
      return null;
    }
  }

  Future<List<MoodLog>> getWeekMoods(String userId) async {
    final all = await getAllMoods(userId);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return all.where((m) => m.timestamp.isAfter(weekAgo)).toList();
  }

  Future<List<MoodLog>> getMonthMoods(String userId) async {
    final all = await getAllMoods(userId);
    final monthAgo = DateTime.now().subtract(const Duration(days: 30));
    return all.where((m) => m.timestamp.isAfter(monthAgo)).toList();
  }

  Future<Map<String, int>> getWeekMoodStats(String userId) async {
    final moods = await getWeekMoods(userId);
    final stats = <String, int>{};
    for (final m in moods) {
      stats[m.moodEmoji] = (stats[m.moodEmoji] ?? 0) + 1;
    }
    return stats;
  }

  Future<double> getWeeklyMoodTrend(String userId) async {
    final moods = await getWeekMoods(userId);
    if (moods.isEmpty) return 0.0;
    return moods.fold<int>(0, (s, m) => s + m.moodLevel) / moods.length;
  }

  Future<String?> getMostFrequentMood(String userId) async {
    final stats = await getWeekMoodStats(userId);
    if (stats.isEmpty) return null;
    return stats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}
