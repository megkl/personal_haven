import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/event.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class EventRepository {
  final _fs = FirestoreService.instance;
  final _uuid = const Uuid();
  static const _col = 'events';

  Future<Event> createEvent({
    required String userId,
    required String title,
    String? description,
    required DateTime eventDate,
    DateTime? startTime,
    DateTime? endTime,
    bool isAllDay = false,
    String? location,
    String category = 'personal',
    String? color,
    bool isRecurring = false,
    String? recurrenceRule,
    String? reminder,
  }) async {
    final now = DateTime.now();
    final event = Event(
      id: _uuid.v4(),
      userId: userId,
      title: title,
      description: description,
      eventDate: eventDate,
      startTime: startTime,
      endTime: endTime,
      isAllDay: isAllDay,
      location: location,
      category: category,
      color: color,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      reminder: reminder,
      createdAt: now,
      updatedAt: now,
    );
    await _fs.set(userId, _col, event.id, event.toFirestore());
    return event;
  }

  Future<List<Event>> getAllEvents(String userId) async {
    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('eventDate', descending: false));
    return snap.docs.map((d) => Event.fromFirestore(d)).toList();
  }

  Future<Event?> getEventById(String userId, String eventId) async {
    final doc = await _fs.get(userId, _col, eventId);
    if (!doc.exists) return null;
    return Event.fromFirestore(doc);
  }

  Future<List<Event>> getEventsByDate(String userId, DateTime date) async {
    final start = DateTime(date.year, date.month, date.day).toIso8601String();
    final end =
        DateTime(date.year, date.month, date.day + 1).toIso8601String();
    final snap = await _fs.query(
        userId,
        _col,
        (c) => c
            .where('eventDate', isGreaterThanOrEqualTo: start)
            .where('eventDate', isLessThan: end));
    return snap.docs.map((d) => Event.fromFirestore(d)).toList();
  }

  Future<List<Event>> getTodayEvents(String userId) async {
    return getEventsByDate(userId, DateTime.now());
  }

  Future<List<Event>> getUpcomingEvents(String userId, {int days = 7}) async {
    final now = DateTime.now().toIso8601String();
    final future = DateTime.now()
        .add(Duration(days: days))
        .toIso8601String();
    final snap = await _fs.query(
        userId,
        _col,
        (c) => c
            .where('eventDate', isGreaterThanOrEqualTo: now)
            .where('eventDate', isLessThanOrEqualTo: future)
            .orderBy('eventDate'));
    return snap.docs.map((d) => Event.fromFirestore(d)).toList();
  }

  Future<List<Event>> getEventsByMonth(
      String userId, int year, int month) async {
    final start = DateTime(year, month, 1).toIso8601String();
    final end = DateTime(year, month + 1, 1).toIso8601String();
    final snap = await _fs.query(
        userId,
        _col,
        (c) => c
            .where('eventDate', isGreaterThanOrEqualTo: start)
            .where('eventDate', isLessThan: end)
            .orderBy('eventDate'));
    return snap.docs.map((d) => Event.fromFirestore(d)).toList();
  }

  Future<List<Event>> searchEvents(String userId, String query) async {
    final all = await getAllEvents(userId);
    final q = query.toLowerCase();
    return all
        .where((e) =>
            e.title.toLowerCase().contains(q) ||
            (e.description?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  Future<int> getCount(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    return snap.size;
  }

  Future<Map<String, int>> getCategoryStats(String userId) async {
    final all = await getAllEvents(userId);
    final stats = <String, int>{};
    for (final e in all) {
      stats[e.category] = (stats[e.category] ?? 0) + 1;
    }
    return stats;
  }

  Future<Set<String>> getDatesWithEvents(
      String userId, int year, int month) async {
    final events = await getEventsByMonth(userId, year, month);
    return events
        .map((e) =>
            '${e.eventDate.year}-${e.eventDate.month.toString().padLeft(2, '0')}-${e.eventDate.day.toString().padLeft(2, '0')}')
        .toSet();
  }

  Future<Event> updateEvent(Event event) async {
    final updated = event.copyWith(updatedAt: DateTime.now());
    await _fs.set(event.userId, _col, event.id, updated.toFirestore());
    return updated;
  }

  Future<void> deleteEvent(String userId, String eventId) async {
    await _fs.delete(userId, _col, eventId);
  }

  Future<void> deleteAllEvents(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  Future<void> deletePastEvents(String userId) async {
    final now = DateTime.now().toIso8601String();
    final snap = await _fs.query(userId, _col,
        (c) => c.where('eventDate', isLessThan: now));
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}
