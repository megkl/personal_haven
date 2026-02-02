import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:personal_haven/data/models/user.dart';

class SharedPrefsHelper {
  static const String _keyUserId = 'current_user_id';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUsername = 'username';
  static const String _keyFirstName = 'first_name';
  static const String _keyLastName = 'last_name';
  static const String _keyBio = 'bio';
  static const String _keyAvatarUrl = 'avatar_url';
  static const bool _keyIsPremium = false;
  static const Map<String, dynamic> _keyPreferences = {};
  static const String _keyLastLoginAt = 'last_login_at';

   static const String _keyJournalCount = 'journal_count';
  static const String _keyMealCount = 'meal_count';
  static const String _keyWeeklyJournalCount = 'weekly_journal_count';
  static const String _keyWeeklyMealCount = 'weekly_meal_count';
  static const String _keyLastStatsDate = 'last_stats_date';
  static const String _keyLastWeekReset = 'last_week_reset';


  static SharedPrefsHelper? _instance;
  static SharedPreferences? _prefs;

  SharedPrefsHelper._();

  static Future<SharedPrefsHelper> getInstance() async {
    _instance ??= SharedPrefsHelper._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // ─────────────────────────────────────────────────────────────
  // Save User Session
  // ─────────────────────────────────────────────────────────────

  Future<void> saveUserSession(User user) async {
    await _prefs?.setString(_keyUserId, user.id);
    await _prefs?.setBool(_keyIsLoggedIn, true);
    await _prefs?.setString(_keyUserEmail, user.email);
    
    if (user.username != null) {
      await _prefs?.setString(_keyUsername, user.username!);
    }
    if (user.firstName != null) {
      await _prefs?.setString(_keyFirstName, user.firstName!);
    }
    if (user.lastName != null) {
      await _prefs?.setString(_keyLastName, user.lastName!);
    }
    if (user.bio != null) {
      await _prefs?.setString(_keyBio, user.bio!);
    }
    if (user.avatarUrl != null) {
      await _prefs?.setString(_keyAvatarUrl, user.avatarUrl!);
    }
    
    
    await _prefs?.setString(_keyLastLoginAt, DateTime.now().toIso8601String());
  }

  // ─────────────────────────────────────────────────────────────
  // Get User Details
  // ─────────────────────────────────────────────────────────────

  String? getUserId() => _prefs?.getString(_keyUserId);

  String? getUserEmail() => _prefs?.getString(_keyUserEmail);

  String? getUsername() => _prefs?.getString(_keyUsername);

  String? getFirstName() => _prefs?.getString(_keyFirstName);

  String? getLastName() => _prefs?.getString(_keyLastName);

  String? getFullName() {
    final first = getFirstName();
    final last = getLastName();
    if (first != null && last != null) {
      return '$first $last';
    }
    return first ?? last ?? getUsername();
  }

  String? getBio() => _prefs?.getString(_keyBio);

  String? getAvatarUrl() => _prefs?.getString(_keyAvatarUrl);

  String? getLastLoginAt() => _prefs?.getString(_keyLastLoginAt);

  // ─────────────────────────────────────────────────────────────
  // Session Status
  // ─────────────────────────────────────────────────────────────

  bool isLoggedIn() => _prefs?.getBool(_keyIsLoggedIn) ?? false;

  // ─────────────────────────────────────────────────────────────
  // Update Individual Fields
  // ─────────────────────────────────────────────────────────────

  Future<void> updateUsername(String username) async {
    await _prefs?.setString(_keyUsername, username);
  }

  Future<void> updateFirstName(String firstName) async {
    await _prefs?.setString(_keyFirstName, firstName);
  }

  Future<void> updateLastName(String lastName) async {
    await _prefs?.setString(_keyLastName, lastName);
  }

  Future<void> updateBio(String bio) async {
    await _prefs?.setString(_keyBio, bio);
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    await _prefs?.setString(_keyAvatarUrl, avatarUrl);
  }

  // ─────────────────────────────────────────────────────────────
  // Clear Session
  // ─────────────────────────────────────────────────────────────

  Future<void> clearSession() async {
    await _prefs?.remove(_keyUserId);
    await _prefs?.remove(_keyUserEmail);
    await _prefs?.remove(_keyUsername);
    await _prefs?.remove(_keyFirstName);
    await _prefs?.remove(_keyLastName);
    await _prefs?.remove(_keyBio);
    await _prefs?.remove(_keyAvatarUrl);
    await _prefs?.remove(_keyLastLoginAt);
    await _prefs?.setBool(_keyIsLoggedIn, false);
  }

  /// Clear all data (use with caution)
  Future<void> clearAll() async {
    await _prefs?.clear();
  }

  int? getTodayJournalCount() => _prefs?.getInt(_getTodayKey(_keyJournalCount));
  int? getTodayMealCount() => _prefs?.getInt(_getTodayKey(_keyMealCount));

  // Weekly counts
  int? getWeeklyJournalCount() => _prefs?.getInt(_keyWeeklyJournalCount);
  int? getWeeklyMealCount() => _prefs?.getInt(_keyWeeklyMealCount);

  // Increment journal count
  Future<void> incrementJournalCount() async {
    final todayKey = _getTodayKey(_keyJournalCount);
    final current = _prefs?.getInt(todayKey) ?? 0;
    await _prefs?.setInt(todayKey, current + 1);

    // Also increment weekly
    final weekly = _prefs?.getInt(_keyWeeklyJournalCount) ?? 0;
    await _prefs?.setInt(_keyWeeklyJournalCount, weekly + 1);
  }

  // Increment meal count
  Future<void> incrementMealCount() async {
    final todayKey = _getTodayKey(_keyMealCount);
    final current = _prefs?.getInt(todayKey) ?? 0;
    await _prefs?.setInt(todayKey, current + 1);

    // Also increment weekly
    final weekly = _prefs?.getInt(_keyWeeklyMealCount) ?? 0;
    await _prefs?.setInt(_keyWeeklyMealCount, weekly + 1);
  }

  // Decrement counts (for delete)
  Future<void> decrementJournalCount() async {
    final todayKey = _getTodayKey(_keyJournalCount);
    final current = _prefs?.getInt(todayKey) ?? 0;
    if (current > 0) {
      await _prefs?.setInt(todayKey, current - 1);
    }

    final weekly = _prefs?.getInt(_keyWeeklyJournalCount) ?? 0;
    if (weekly > 0) {
      await _prefs?.setInt(_keyWeeklyJournalCount, weekly - 1);
    }
  }

  Future<void> decrementMealCount() async {
    final todayKey = _getTodayKey(_keyMealCount);
    final current = _prefs?.getInt(todayKey) ?? 0;
    if (current > 0) {
      await _prefs?.setInt(todayKey, current - 1);
    }

    final weekly = _prefs?.getInt(_keyWeeklyMealCount) ?? 0;
    if (weekly > 0) {
      await _prefs?.setInt(_keyWeeklyMealCount, weekly - 1);
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Stats Reset Logic
  // ─────────────────────────────────────────────────────────────

  Future<void> _checkAndResetDailyCounts() async {
    final lastDate = _prefs?.getString(_keyLastStatsDate);
    final today = _getDateString(DateTime.now());

    if (lastDate != today) {
      await _prefs?.setString(_keyLastStatsDate, today);
      // Daily counts are already keyed by date, so no reset needed
    }

    // Check weekly reset (every Monday)
    await _checkAndResetWeeklyCounts();
  }

  Future<void> _checkAndResetWeeklyCounts() async {
    final lastWeekReset = _prefs?.getString(_keyLastWeekReset);
    final now = DateTime.now();
    final currentWeek = _getWeekNumber(now);
    final currentYear = now.year;
    final weekKey = '$currentYear-W$currentWeek';

    if (lastWeekReset != weekKey) {
      // New week - reset weekly counts
      await _prefs?.setInt(_keyWeeklyJournalCount, 0);
      await _prefs?.setInt(_keyWeeklyMealCount, 0);
      await _prefs?.setString(_keyLastWeekReset, weekKey);
    }
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final daysDiff = date.difference(firstDayOfYear).inDays;
    return ((daysDiff + firstDayOfYear.weekday) / 7).ceil();
  }

  String _getTodayKey(String baseKey) {
    return '${baseKey}_${_getDateString(DateTime.now())}';
  }

  String _getDateString(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

}
