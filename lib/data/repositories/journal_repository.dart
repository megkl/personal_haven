import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class JournalRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'journal_entries';

  // ── CREATE ───────────────────────────────────────────────────────────────────

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
    return entry;
  }

  // ── READ ─────────────────────────────────────────────────────────────────────

  Future<List<JournalEntry>> getAllEntries(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('entryDate', descending: true));
    return snap.docs.map((d) => JournalEntry.fromFirestore(d)).toList();
  }

  Future<JournalEntry?> getEntryById(String userId, String entryId) async {
    final doc = await _fs.get(userId, _col, entryId);
    if (!doc.exists) return null;
    return JournalEntry.fromFirestore(doc);
  }

  Future<List<JournalEntry>> getEntriesByCategory(
      String userId, String category) async {
    if (category == 'All') return getAllEntries(userId);
    final snap = await _fs.query(userId, _col,
        (c) => c.where('category', isEqualTo: category)
            .orderBy('entryDate', descending: true));
    return snap.docs.map((d) => JournalEntry.fromFirestore(d)).toList();
  }

  Future<List<JournalEntry>> getRecentEntries(String userId,
      {int limit = 10}) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('entryDate', descending: true).limit(limit));
    return snap.docs.map((d) => JournalEntry.fromFirestore(d)).toList();
  }

  Future<List<JournalEntry>> getTodayEntries(String userId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _fs.query(
        userId,
        _col,
        (c) => c
            .where('entryDate',
                isGreaterThanOrEqualTo: start.toIso8601String())
            .where('entryDate', isLessThan: end.toIso8601String()));
    return snap.docs.map((d) => JournalEntry.fromFirestore(d)).toList();
  }

  Future<List<JournalEntry>> getThisWeekEntries(String userId) async {
    final weekAgo =
        DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
    final snap = await _fs.query(userId, _col,
        (c) => c.where('entryDate', isGreaterThanOrEqualTo: weekAgo)
            .orderBy('entryDate', descending: true));
    return snap.docs.map((d) => JournalEntry.fromFirestore(d)).toList();
  }

  Future<List<JournalEntry>> searchEntries(
      String userId, String query) async {
    // Client-side search (Firestore doesn't support full-text natively)
    final all = await getAllEntries(userId);
    final q = query.toLowerCase();
    return all
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            e.content.toLowerCase().contains(q))
        .toList();
  }

  Future<int> getEntryCount(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    return snap.size;
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

  // ── UPDATE ───────────────────────────────────────────────────────────────────

  Future<JournalEntry> updateEntry(JournalEntry entry) async {
    final updated = entry.copyWith(updatedAt: DateTime.now());
    await _fs.set(entry.userId, _col, entry.id, updated.toFirestore());
    return updated;
  }

  // ── DELETE ───────────────────────────────────────────────────────────────────

  Future<void> deleteEntry(String userId, String entryId) async {
    await _fs.delete(userId, _col, entryId);
  }

  Future<void> deleteAllEntries(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
