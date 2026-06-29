import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Generic cache helper for storing Firestore data locally with timestamps.
class CacheHelper {
  static const String _cachePrefix = 'cache_';
  static const String _timestampSuffix = '_timestamp';
  static const Duration defaultExpiry = Duration(hours: 24);

  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Generate cache key from collection and user ID
  static String _getCacheKey(String userId, String collection) {
    return '$_cachePrefix${userId}_$collection';
  }

  static String _getTimestampKey(String userId, String collection) {
    return '$_cachePrefix${userId}_${collection}$_timestampSuffix';
  }

  /// Save data to cache
  Future<void> saveData<T>(
  String userId,
  String collection,
  List<T> data, {
  required Map<String, dynamic> Function(T) toJson,
}) async {
  await init();

  final key = _getCacheKey(userId, collection);
  final jsonList = data.map((item) => toJson(item)).toList();

  await _prefs!.setString(key, jsonEncode(jsonList));
  await _prefs!.setInt(
    _getTimestampKey(userId, collection),
    DateTime.now().millisecondsSinceEpoch,
  );
}

Future<List<T>?> getData<T>(
  String userId,
  String collection, {
  required T Function(dynamic) fromJson,
  Duration? expiry,
}) async {
  await init();

  final key = _getCacheKey(userId, collection);
  final json = _prefs!.getString(key);

  if (json == null) return null;

  if (expiry != null) {
    final timestamp = _prefs!.getInt(
      _getTimestampKey(userId, collection),
    );

    if (timestamp != null) {
      final cachedTime =
          DateTime.fromMillisecondsSinceEpoch(timestamp);

      if (DateTime.now().difference(cachedTime) > expiry) {
        await clearData(userId, collection);
        return null;
      }
    }
  }

  try {
    final list = jsonDecode(json) as List;
    return list.map((item) => fromJson(item)).toList();
  } catch (_) {
    return null;
  }
}


  /// Check if cache exists and is not expired
  Future<bool> isCacheValid(
    String userId,
    String collection, {
    Duration? expiry,
  }) async {
    await init();
    final key = _getCacheKey(userId, collection);
    final exists = _prefs!.containsKey(key);
    
    if (!exists || expiry == null) return exists;

    final timestampKey = _getTimestampKey(userId, collection);
    final timestamp = _prefs!.getInt(timestampKey);
    if (timestamp == null) return false;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cachedTime) <= expiry;
  }

  /// Clear cache for a specific collection
  Future<void> clearData(String userId, String collection) async {
    await init();
    await _prefs!.remove(_getCacheKey(userId, collection));
    await _prefs!.remove(_getTimestampKey(userId, collection));
  }

  /// Clear all cache
  Future<void> clearAllCache() async {
    await init();
    final keys = _prefs!.getKeys().where((k) => k.startsWith(_cachePrefix)).toList();
    for (final key in keys) {
      await _prefs!.remove(key);
    }
  }

  /// Get cache timestamp for a collection
  Future<DateTime?> getCacheTimestamp(String userId, String collection) async {
    await init();
    final timestampKey = _getTimestampKey(userId, collection);
    final timestamp = _prefs!.getInt(timestampKey);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }
}
