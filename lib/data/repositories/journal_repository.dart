import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/data/data_sources/local/cache_helper.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class JournalRepository {
  final _fs = FirestoreService.instance;
  final _cache = CacheHelper();
  final _uuid = const Uuid();
  static const _col = 'journal_entries';
  static const _cacheDuration = Duration(hours: 1);

  // ── CREATE ────────────────────────────────────────────────────────────────

  Future<JournalEntry> createEntry({
    required String userId,
    required String title,
    required String content,
    required String category,
    String? emoji,
    List<String> tags = const [],
    DateTime? entryDate,
  }) async {
    final now = DateTime.now();
    final entry = JournalEntry(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      content: content,
      entryDate: entryDate ?? now,
      createdAt: now,
      updatedAt: now,
      category: category,
      emoji: emoji,
      tags: tags,
    );
    await _fs.set(userId, _col, entry.id, entry.toFirestore());
    // Invalidate cache
    await _cache.clearData(userId, _col);
    return entry;
  }

  // ── READ ──────────────────────────────────────────────────────────────────

  /// Fetches all journal entries, using the local cache when valid.
  Future<List<JournalEntry>> getAllEntries(
    String userId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh) {
      final cached = await _cache.getData(
        userId,
        _col,
        fromJson: (json) =>
            JournalEntry.fromJson(json as Map<String, dynamic>),
        expiry: _cacheDuration,
      );
      if (cached != null) return cached;
    }

    final snap = await _fs.query(
        userId, _col, (c) => c.orderBy('entryDate', descending: true));
    final entries =
        snap.docs.map((d) => JournalEntry.fromFirestore(d)).toList();

    await _cache.saveData(userId, _col, entries,
        toJson: (e) => e.toJson());

    return entries;
  }

  Future<JournalEntry?> getEntryById(String userId, String entryId) async {
    // Check cache first for an exact match before hitting Firestore
    final all = await getAllEntries(userId);
    try {
      return all.firstWhere((e) => e.id == entryId);
    } catch (_) {
      final doc = await _fs.get(userId, _col, entryId);
      if (!doc.exists) return null;
      return JournalEntry.fromFirestore(doc);
    }
  }

  Future<List<JournalEntry>> getEntriesByCategory(
      String userId, String category) async {
    final all = await getAllEntries(userId);
    if (category == 'All') return all;
    return all.where((e) => e.category == category).toList();
  }

  Future<List<JournalEntry>> getRecentEntries(String userId,
      {int limit = 10}) async {
    final all = await getAllEntries(userId);
    return all.take(limit).toList();
  }

  Future<List<JournalEntry>> getTodayEntries(String userId) async {
    final all = await getAllEntries(userId);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));
    return all
        .where((e) =>
            e.entryDate.isAfter(todayStart) && e.entryDate.isBefore(todayEnd))
        .toList();
  }

  Future<List<JournalEntry>> getThisWeekEntries(String userId) async {
    final all = await getAllEntries(userId);
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    return all.where((e) => e.entryDate.isAfter(weekAgo)).toList();
  }

  Future<List<JournalEntry>> searchEntries(
      String userId, String query) async {
    final all = await getAllEntries(userId);
    final q = query.toLowerCase();
    return all
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.content.toLowerCase().contains(q))
        .toList();
  }

  Future<int> getEntryCount(String userId) async {
    final all = await getAllEntries(userId);
    return all.length;
  }

  Future<Map<String, int>> getCategoryStats(String userId) async {
    final all = await getAllEntries(userId);
    final stats = <String, int>{};
    for (final e in all) {
      stats[e.category] = (stats[e.category] ?? 0) + 1;
    }
    return stats;
  }

  Future<List<String>> getAllTags(String userId) async {
    final all = await getAllEntries(userId);
    final tags = <String>{};
    for (final e in all) {
      tags.addAll(e.tags);
    }
    return tags.toList();
  }

  // ── UPDATE ────────────────────────────────────────────────────────────────

  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _fs.set(entry.userId, _col, entry.id, updated.toFirestore());
    // Invalidate cache
    await _cache.clearData(entry.userId, _col);
    return updated;
  }

  // ── DELETE ────────────────────────────────────────────────────────────────

  Future<void> deleteEntry(String userId, String entryId) async {
    await _fs.delete(userId, _col, entryId);
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }

  Future<void> deleteAllEntries(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }
}
