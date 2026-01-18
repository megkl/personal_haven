import 'package:personal_haven/data/data_sources/local/database_helper.dart';
import 'package:sqflite/sqflite.dart';
import 'package:personal_haven/data/models/journal_entry.dart';

/// Data Access Object for Journal Entries
/// Handles all database operations for journal entries
class JournalDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  /// Insert a new journal entry
  Future<void> insert(JournalEntry entry) async {
    final db = await _dbHelper.database;
    await db.insert(
      'journal_entries',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

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
    final maps = await db.query(
      'journal_entries',
      where: 'user_id = ? AND (title LIKE ? OR content LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%'],
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
      where: 'user_id = ? AND entry_date BETWEEN ? AND ?',
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

  /// Get entry count for a user
  Future<int> getCount(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM journal_entries WHERE user_id = ?',
      [userId],
    );
    return Sqflite.firstIntValue(result) ?? 0;
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

  /// Get statistics: count by category
  Future<Map<String, int>> getCountByCategory(String userId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT category, COUNT(*) as count 
      FROM journal_entries 
      WHERE user_id = ? 
      GROUP BY category
    ''', [userId]);

    return Map.fromEntries(
      result.map((row) => MapEntry(
        row['category'] as String,
        row['count'] as int,
      )),
    );
  }
}