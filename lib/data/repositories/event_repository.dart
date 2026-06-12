import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:personal_haven/data/models/event.dart';
import 'package:personal_haven/data/data_sources/local/cache_helper.dart';
import 'package:personal_haven/services/firestore_service.dart';
import 'package:uuid/uuid.dart';

class EventRepository {
  final _fs = FirestoreService.instance;
  final _cache = CacheHelper();
  final _uuid = const Uuid();
  static const _col = 'events';
  static const _cacheDuration = Duration(hours: 1);

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
    // Invalidate cache so next read fetches fresh data
    await _cache.clearData(userId, _col);
    return event;
  }

  Future<List<Event>> getAllEvents(String userId, {bool forceRefresh = false}) async {
    // Try cache first if not forcing refresh
    if (!forceRefresh) {
      final cached = await _cache.getData(
        userId,
        _col,
        fromJson: (json) => Event.fromJson(json),
        expiry: _cacheDuration,
      );
      if (cached != null) return cached;
    }

    // Fetch from Firestore
    final snap = await _fs.query(userId, _col,
        (c) => c.orderBy('eventDate', descending: false));
    final events = snap.docs.map((d) => Event.fromFirestore(d)).toList();
    
    // Cache result
    await _cache.saveData(userId, _col, events, toJson: (e) => e.toJson());
    
    return events;
  }

  Future<Event?> getEventById(String userId, String eventId) async {
    final doc = await _fs.get(userId, _col, eventId);
    if (!doc.exists) return null;
    return Event.fromFirestore(doc);
  }

  Future<List<Event>> getEventsByDate(String userId, DateTime date, {bool forceRefresh = false}) async {
    // Derive from all events cache
    final allEvents = await getAllEvents(userId, forceRefresh: forceRefresh);
    return allEvents.where((e) {
      return e.eventDate.year == date.year &&
          e.eventDate.month == date.month &&
          e.eventDate.day == date.day;
    }).toList();
  }

  Future<List<Event>> getTodayEvents(String userId, {bool forceRefresh = false}) async {
    return getEventsByDate(userId, DateTime.now(), forceRefresh: forceRefresh);
  }

  Future<List<Event>> getUpcomingEvents(String userId, {int days = 7, bool forceRefresh = false}) async {
    // For upcoming events, derive from cached data or fetch
    final allEvents = await getAllEvents(userId, forceRefresh: forceRefresh);
    final now = DateTime.now();
    final future = now.add(Duration(days: days));
    
    return allEvents.where((e) {
      return e.eventDate.isAfter(now) && e.eventDate.isBefore(future);
    }).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));
  }

  Future<List<Event>> getEventsByMonth(String userId, int year, int month, {bool forceRefresh = false}) async {
    // Derive from all events cache
    final allEvents = await getAllEvents(userId, forceRefresh: forceRefresh);
    return allEvents.where((e) {
      return e.eventDate.year == year && e.eventDate.month == month;
    }).toList()..sort((a, b) => a.eventDate.compareTo(b.eventDate));
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
    // Invalidate cache so next read fetches fresh data
    await _cache.clearData(event.userId, _col);
    return updated;
  }

  Future<void> deleteEvent(String userId, String eventId) async {
    await _fs.delete(userId, _col, eventId);
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }

  Future<void> deleteAllEvents(String userId) async {
    final snap = await _fs.getAll(userId, _col);
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    // Invalidate cache
    await _cache.clearData(userId, _col);
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
    // Invalidate cache
    await _cache.clearData(userId, _col);
  }

  /// Refresh cache by fetching from Firestore
  Future<List<Event>> refreshEvents(String userId) async {
    await _cache.clearData(userId, _col);
    return getAllEvents(userId, forceRefresh: true);
  }
  }

