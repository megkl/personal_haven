import 'package:personal_haven/data/data_sources/local/dao/journal_dao.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:uuid/uuid.dart';

/// Repository for Journal Entry operations
/// Abstracts data sources and provides business logic
class JournalRepository {
  final JournalDao _journalDao;
  final Uuid _uuid = const Uuid();

  JournalRepository({JournalDao? journalDao}) 
      : _journalDao = journalDao ?? JournalDao();

  /// Create a new journal entry
  Future<JournalEntry> createEntry({
    required String userId,
    required String title,
    required String content,
    required String category,
    String? emoji,
    List<String> tags = const [],
  }) async {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      category: category,
      emoji: emoji,
      tags: tags,
    );

    await _journalDao.insert(entry);
    return entry;
  }

  /// Get all entries for a user
  Future<List<JournalEntry>> getAllEntries(String userId) async {
    return await _journalDao.getAllByUserId(userId);
  }

  /// Get entry by ID
  Future<JournalEntry?> getEntryById(String entryId) async {
    return await _journalDao.getById(entryId);
  }

  /// Get entries by category
  Future<List<JournalEntry>> getEntriesByCategory(
    String userId,
    String category,
  ) async {
    if (category == 'All') {
      return await getAllEntries(userId);
    }
    return await _journalDao.getByCategory(userId, category);
  }

  /// Search entries
  Future<List<JournalEntry>> searchEntries(
    String userId,
    String query,
  ) async {
    if (query.isEmpty) {
      return await getAllEntries(userId);
    }
    return await _journalDao.search(userId, query);
  }

  /// Get today's entries
  Future<List<JournalEntry>> getTodayEntries(String userId) async {
    return await _journalDao.getTodayEntries(userId);
  }

  /// Get entries for date range
  Future<List<JournalEntry>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    return await _journalDao.getByDateRange(userId, startDate, endDate);
  }

  /// Update an entry
  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    final updatedEntry = entry.copyWith(
      updatedAt: DateTime.now(),
    );
    
    await _journalDao.update(updatedEntry);
    return updatedEntry;
  }

  /// Delete an entry
  Future<void> deleteEntry(String entryId) async {
    await _journalDao.delete(entryId);
  }

  /// Delete all entries for a user
  Future<void> deleteAllEntries(String userId) async {
    await _journalDao.deleteAllByUserId(userId);
  }

  /// Get entry count
  Future<int> getEntryCount(String userId) async {
    return await _journalDao.getCount(userId);
  }

  /// Get entries by tags
  Future<List<JournalEntry>> getEntriesByTags(
    String userId,
    List<String> tags,
  ) async {
    return await _journalDao.getByTags(userId, tags);
  }

  /// Get category statistics
  Future<Map<String, int>> getCategoryStats(String userId) async {
    return await _journalDao.getCountByCategory(userId);
  }

  /// Get this week's entries
  Future<List<JournalEntry>> getThisWeekEntries(String userId) async {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
    
    return await getEntriesByDateRange(userId, startOfWeek, endOfWeek);
  }

  /// Get this month's entries
  Future<List<JournalEntry>> getThisMonthEntries(String userId) async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    
    return await getEntriesByDateRange(userId, startOfMonth, endOfMonth);
  }

  /// Export entries as JSON
  Future<List<Map<String, dynamic>>> exportEntries(String userId) async {
    final entries = await getAllEntries(userId);
    return entries.map((e) => e.toJson()).toList();
  }
}