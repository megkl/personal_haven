import 'package:personal_haven/data/data_sources/local/dao/mood_dao.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:uuid/uuid.dart';

class MoodRepository {
  final MoodDao _moodDao = MoodDao();
  final _uuid = const Uuid();

  /// Log a new mood entry
  Future<MoodLog> logMood({
    required String userId,
    required int moodLevel,
    required String moodEmoji,
    String? moodLabel,
    String? notes,
  }) async {
    final now = DateTime.now();

    final moodLog = MoodLog(
      id: _uuid.v4(),
      userId: userId,
      moodLevel: moodLevel,
      moodEmoji: moodEmoji,
      moodLabel: moodLabel,
      timestamp: now,
      notes: notes,
    );

    await _moodDao.insert(moodLog);

    return moodLog;
  }

  /// Get today's mood for a user
  Future<MoodLog?> getTodayMood(String userId) async {
    return await _moodDao.getTodayMood(userId);
  }

  /// Get moods for the past week
  Future<List<MoodLog>> getWeekMoods(String userId) async {
    return await _moodDao.getWeekMoods(userId);
  }

  /// Get moods for the past month
  Future<List<MoodLog>> getMonthMoods(String userId) async {
    return await _moodDao.getMonthMoods(userId);
  }

  /// Get weekly mood statistics (emoji -> count)
  Future<Map<String, int>> getWeekMoodStats(String userId) async {
    return await _moodDao.getWeekMoodStats(userId);
  }

  /// Get monthly mood statistics (emoji -> count)
  Future<Map<String, int>> getMonthMoodStats(String userId) async {
    final moods = await getMonthMoods(userId);
    final stats = <String, int>{};

    for (var mood in moods) {
      stats[mood.moodEmoji] = (stats[mood.moodEmoji] ?? 0) + 1;
    }

    return stats;
  }

  /// Get mood trend (average mood level) for the week
  Future<double> getWeeklyMoodTrend(String userId) async {
    final moods = await getWeekMoods(userId);
    if (moods.isEmpty) return 0.0;

    final total = moods.fold<int>(0, (sum, mood) => sum + mood.moodLevel);
    return total / moods.length;
  }

  /// Get most frequent mood this week
  Future<String?> getMostFrequentMood(String userId) async {
    final stats = await getWeekMoodStats(userId);
    if (stats.isEmpty) return null;

    return stats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}