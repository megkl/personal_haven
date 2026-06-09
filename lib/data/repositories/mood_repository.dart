import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class MoodRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'mood_logs';

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
    return log;
  }

  Future<MoodLog?> getTodayMood(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day).toIso8601String();
    final end = DateTime(now.year, now.month, now.day + 1).toIso8601String();
    final snap = await _fs.query(
        userId,
        _col,
        (c) => c
            .where('timestamp', isGreaterThanOrEqualTo: start)
            .where('timestamp', isLessThan: end)
            .orderBy('timestamp', descending: true)
            .limit(1));
    if (snap.docs.isEmpty) return null;
    return MoodLog.fromFirestore(snap.docs.first);
  }

  Future<List<MoodLog>> getWeekMoods(String userId) async {
    final weekAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final snap = await _fs.query(userId, _col,
        (c) => c.where('timestamp', isGreaterThanOrEqualTo: weekAgo)
            .orderBy('timestamp', descending: true));
    return snap.docs.map((d) => MoodLog.fromFirestore(d)).toList();
  }

  Future<List<MoodLog>> getMonthMoods(String userId) async {
    final monthAgo =
        DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final snap = await _fs.query(userId, _col,
        (c) => c.where('timestamp', isGreaterThanOrEqualTo: monthAgo)
            .orderBy('timestamp', descending: true));
    return snap.docs.map((d) => MoodLog.fromFirestore(d)).toList();
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
