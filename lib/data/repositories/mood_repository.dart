import 'package:personal_haven/data/data_sources/local/dao/mood_dao.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:uuid/uuid.dart';

class MoodRepository {
  final MoodDao _moodDao;
  final Uuid _uuid = const Uuid();

  MoodRepository({MoodDao? moodDao}) : _moodDao = moodDao ?? MoodDao();

  Future<MoodLog> logMood({
    required String userId,
    required int moodLevel,
    required String moodEmoji,
    String? notes,
  }) async {
    final log = MoodLog(
      id: _uuid.v4(),
      userId: userId,
      moodLevel: moodLevel,
      moodEmoji: moodEmoji,
      notes: notes,
      timestamp: DateTime.now(),
    );

    await _moodDao.insert(log);
    return log;
  }

  Future<MoodLog?> getTodayMood(String userId) async {
    return await _moodDao.getTodayMood(userId);
  }

  Future<List<MoodLog>> getWeekMoods(String userId) async {
    return await _moodDao.getWeekMoods(userId);
  }

  Future<List<MoodLog>> getMonthMoods(String userId) async {
    return await _moodDao.getMonthMoods(userId);
  }

  Future<Map<String, int>> getWeekMoodStats(String userId) async {
    return await _moodDao.getWeekMoodStats(userId);
  }
}
