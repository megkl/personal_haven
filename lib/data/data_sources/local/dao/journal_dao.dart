import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/journal_entry.dart';

/// Data Access Object for Journal Entries
/// Handles all database operations for journal entries
class JournalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Insert a new journal entry
  Future<void> insert(JournalEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert(
      'journal_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Insert multiple entries at once
  Future<void> insertAll(List<JournalEntry> entries) async {
    final db = await _dbHelper.database;
    final batch = db.batch();
    for (var entry in entries) {
      batch.insert(
        'journal_entries',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ─────────────────────────────────────────────────────────────
  // READ
  // ─────────────────────────────────────────────────────────────

  /// Get all journal entries for a user
  Future<List<JournalEntry>> getAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'journal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'entry_date DESC',
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Get journal entry by ID
  Future<JournalEntry?> getById(String entryId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'journal_entries',
      where: 'entry_id = ?',
      whereArgs: [entryId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return JournalEntry.fromMap(maps.first);
  }

  /// Get entries by category
  Future<List<JournalEntry>> getByCategory(String userId, String category) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'journal_entries',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
      orderBy: 'entry_date DESC',
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Search entries by title or content
  Future<List<JournalEntry>> search(String userId, String query) async {
    final db = await _dbHelper.database;
    final searchTerm = '%$query%';
    final maps = await db.query(
      'journal_entries',
      where: 'user_id = ? AND (title LIKE ? OR content LIKE ? OR tags LIKE ?)',
      whereArgs: [userId, searchTerm, searchTerm, searchTerm],
      orderBy: 'entry_date DESC',
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Advanced search with filters
  Future<List<JournalEntry>> advancedSearch({
    required String userId,
    String? query,
    String? category,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? tags,
  }) async {
    final db = await _dbHelper.database;
    
    final whereClauses = <String>['user_id = ?'];
    final whereArgs = <dynamic>[userId];

    if (query != null && query.isNotEmpty) {
      whereClauses.add('(title LIKE ? OR content LIKE ?)');
      whereArgs.addAll(['%$query%', '%$query%']);
    }

    if (category != null && category != 'All') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (startDate != null) {
      whereClauses.add('entry_date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereClauses.add('entry_date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (tags != null && tags.isNotEmpty) {
      final tagClauses = tags.map((tag) => "tags LIKE '%$tag%'").join(' OR ');
      whereClauses.add('($tagClauses)');
    }

    final maps = await db.query(
      'journal_entries',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'entry_date DESC',
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Get entries for a specific date range
  Future<List<JournalEntry>> getByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'journal_entries',
      where: 'user_id = ? AND entry_date >= ? AND entry_date <= ?',
      whereArgs: [
        userId,
        startDate.toIso8601String(),
        endDate.toIso8601String(),
      ],
      orderBy: 'entry_date DESC',
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Get today's entries
  Future<List<JournalEntry>> getTodayEntries(String userId) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return getByDateRange(userId, startOfDay, endOfDay);
  }

  /// Get this week's entries
  Future<List<JournalEntry>> getThisWeekEntries(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return getByDateRange(userId, start, end);
  }

  /// Get recent entries with limit
  Future<List<JournalEntry>> getRecentEntries(String userId, {int limit = 10}) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'journal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'entry_date DESC',
      limit: limit,
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  /// Get entry count for a user
  Future<int> getCount(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_entries WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Get statistics: count by category
  Future<Map<String, int>> getCountByCategory(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM journal_entries 
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

  /// Get entries with specific tags
  Future<List<JournalEntry>> getByTags(String userId, List<String> tags) async {
    final db = await _dbHelper.database;

    // Create a LIKE clause for each tag
    final whereClauses = tags.map((tag) => "tags LIKE '%$tag%'").join(' OR ');

    final maps = await db.query(
      'journal_entries',
      where: 'user_id = ? AND ($whereClauses)',
      whereArgs: [userId],
      orderBy: 'entry_date DESC',
    );

    return maps.map((map) => JournalEntry.fromMap(map)).toList();
  }

  /// Get all unique tags for a user
  Future<List<String>> getAllTags(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT DISTINCT tags FROM journal_entries WHERE user_id = ? AND tags IS NOT NULL AND tags != ""',
      [userId],
    );

    final Set<String> uniqueTags = {};
    for (final row in result) {
      final tagsStr = row['tags'] as String?;
      if (tagsStr != null && tagsStr.isNotEmpty) {
        uniqueTags.addAll(tagsStr.split(',').map((t) => t.trim()));
      }
    }
    return uniqueTags.toList()..sort();
  }

  /// Get entry count by date (for calendar/heatmap)
  Future<Map<String, int>> getCountByDate(String userId, {int days = 30}) async {
    final db = await _dbHelper.database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final result = await db.rawQuery('''
      SELECT DATE(entry_date) as date, COUNT(*) as count 
      FROM journal_entries 
      WHERE user_id = ? AND entry_date >= ?
      GROUP BY DATE(entry_date)
      ORDER BY date DESC
    ''', [userId, startDate.toIso8601String()]);

    final Map<String, int> dateStats = {};
    for (final row in result) {
      final date = row['date'] as String?;
      final count = row['count'] as int?;
      if (date != null && count != null) {
        dateStats[date] = count;
      }
    }
    return dateStats;
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  /// Update an entry
  Future<int> update(JournalEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'journal_entries',
      entry.toMap(),
      where: 'entry_id = ?',
      whereArgs: [entry.id],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Delete an entry
  Future<int> delete(String entryId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'journal_entries',
      where: 'entry_id = ?',
      whereArgs: [entryId],
    );
  }

  /// Delete all entries for a user
  Future<int> deleteAllByUserId(String userId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'journal_entries',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  /// Delete entries by category
  Future<int> deleteByCategory(String userId, String category) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'journal_entries',
      where: 'user_id = ? AND category = ?',
      whereArgs: [userId, category],
    );
  }
}