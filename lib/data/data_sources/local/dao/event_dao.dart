import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/event.dart';

/// Data Access Object for Events
class EventDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Insert a new event
  Future<void> insert(Event event) async {
    final db = await _dbHelper.database;
    await db.insert(
      'events',
      event.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple events
  Future<void> insertAll(List<Event> events) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var event in events) {
      batch.insert(
        'events',
        event.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  /// Get all events for a user
  Future<List<Event>> getAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'event_date ASC, start_time ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Get event by ID
  Future<Event?> getById(String eventId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'event_id = ?',
      whereArgs: [eventId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Event.fromMap(maps.first);
  }

  /// Get events for a specific date
  Future<List<Event>> getByDate(String userId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'user_id = ? AND event_date >= ? AND event_date <= ?',
      whereArgs: [
        userId,
        startOfDay.toIso8601String(),
        endOfDay.toIso8601String(),
      ],
      orderBy: 'start_time ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Get today's events
  Future<List<Event>> getTodayEvents(String userId) async {
    return getByDate(userId, DateTime.now());
  }

  /// Get upcoming events (next 7 days)
  Future<List<Event>> getUpcomingEvents(String userId, {int days = 7}) async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endDate = startOfToday.add(Duration(days: days, hours: 23, minutes: 59));

    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'user_id = ? AND event_date >= ? AND event_date <= ?',
      whereArgs: [
        userId,
        startOfToday.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'event_date ASC, start_time ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Get events for a month
  Future<List<Event>> getByMonth(String userId, int year, int month) async {
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'user_id = ? AND event_date >= ? AND event_date <= ?',
      whereArgs: [
        userId,
        startOfMonth.toIso8601String(),
        endOfMonth.toIso8601String(),
      ],
      orderBy: 'event_date ASC, start_time ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Get events by category
  Future<List<Event>> getByCategory(String userId, String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'event_date ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Get events for date range
  Future<List<Event>> getByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'events',
      where: 'user_id = ? AND event_date >= ? AND event_date <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'event_date ASC, start_time ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  /// Search events
  Future<List<Event>> search(String userId, String query) async {
    final db = await _dbHelper.database;
    final searchTerm = '%$query%';
    final maps = await db.query(
      'events',
      where: 'user_id = ? AND (title LIKE ? OR description LIKE ? OR location LIKE ?)',
      whereArgs: [userId, searchTerm, searchTerm, searchTerm],
      orderBy: 'event_date ASC',
    );

    return maps.map((map) => Event.fromMap(map)).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  /// Get event count
  Future<int> getCount(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM events WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get today's event count
  Future<int> getTodayCount(String userId) async {
    final events = await getTodayEvents(userId);
    return events.length;
  }

  /// Get this week's event count
  Future<int> getThisWeekCount(String userId) async {
    final events = await getUpcomingEvents(userId, days: 7);
    return events.length;
  }

  /// Get count by category
  Future<Map<String, int>> getCountByCategory(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM events 
      WHERE user_id = ? 
      GROUP BY category
      ORDER BY count DESC
    ''', [userId]);

    final Map<String, int> stats = {};
    for (final row in result) {
      final category = row['category'] as String?;
      final count = row['count'] as int?;
      if (category != null && count != null) {
        stats[category] = count;
      }
    }
    return stats;
  }

  /// Get dates with events (for calendar dots)
  Future<Set<String>> getDatesWithEvents(String userId, int year, int month) async {
    final db = await _dbHelper.database;
    final startOfMonth = DateTime(year, month, 1);
    final endOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

    final result = await db.rawQuery('''
      SELECT DISTINCT DATE(event_date) as date 
      FROM events 
      WHERE user_id = ? AND event_date >= ? AND event_date <= ?
    ''', [userId, startOfMonth.toIso8601String(), endOfMonth.toIso8601String()]);

    return result.map((row) => row['date'] as String).toSet();
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  /// Update an event
  Future<int> update(Event event) async {
    final db = await _dbHelper.database;
    return await db.update(
      'events',
      event.toMap(),
      where: 'event_id = ?',
      whereArgs: [event.id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Delete an event
  Future<int> delete(String eventId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'events',
      where: 'event_id = ?',
      whereArgs: [eventId],
    );
  }

  /// Delete all events for a user
  Future<int> deleteAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'events',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete past events
  Future<int> deletePastEvents(String userId) async {
    final db = await _dbHelper.database;
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    return await db.delete(
      'events',
      where: 'user_id = ? AND event_date < ?',
      whereArgs: [userId, startOfToday.toIso8601String()],
    );
  }
}