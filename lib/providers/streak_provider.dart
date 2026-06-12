import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks app-open streaks and attaches to the user profile session.
class StreakState {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastOpenDate;
  final bool isNewStreakToday;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastOpenDate,
    this.isNewStreakToday = false,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastOpenDate,
    bool? isNewStreakToday,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastOpenDate: lastOpenDate ?? this.lastOpenDate,
      isNewStreakToday: isNewStreakToday ?? this.isNewStreakToday,
    );
  }
}

class StreakNotifier extends AsyncNotifier<StreakState> {
  static const _keyCurrentStreak = 'streak_current';
  static const _keyLongestStreak = 'streak_longest';
  static const _keyLastOpenDate = 'streak_last_open_date';

  @override
  Future<StreakState> build() async {
    return await _loadAndUpdate();
  }

  Future<StreakState> _loadAndUpdate() async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getInt(_keyCurrentStreak) ?? 0;
    final longest = prefs.getInt(_keyLongestStreak) ?? 0;
    final lastDateStr = prefs.getString(_keyLastOpenDate);

    final today = _dateOnly(DateTime.now());
    DateTime? lastDate;
    if (lastDateStr != null) {
      lastDate = DateTime.tryParse(lastDateStr);
    }

    int newCurrent = current;
    bool isNew = false;

    if (lastDate == null) {
      // First ever open
      newCurrent = 1;
      isNew = true;
    } else {
      final lastDay = _dateOnly(lastDate);
      final diff = today.difference(lastDay).inDays;

      if (diff == 0) {
        // Already opened today — no change
        isNew = false;
      } else if (diff == 1) {
        // Consecutive day — increment
        newCurrent = current + 1;
        isNew = true;
      } else {
        // Streak broken
        newCurrent = 1;
        isNew = true;
      }
    }

    final newLongest = newCurrent > longest ? newCurrent : longest;

    await prefs.setInt(_keyCurrentStreak, newCurrent);
    await prefs.setInt(_keyLongestStreak, newLongest);
    await prefs.setString(_keyLastOpenDate, today.toIso8601String());

    return StreakState(
      currentStreak: newCurrent,
      longestStreak: newLongest,
      lastOpenDate: today,
      isNewStreakToday: isNew,
    );
  }

  DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

final streakProvider = AsyncNotifierProvider<StreakNotifier, StreakState>(
  StreakNotifier.new,
);
