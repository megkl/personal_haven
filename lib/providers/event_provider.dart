import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/event.dart';
import 'package:personal_haven/data/repositories/event_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/services/notification_service.dart';

/// Provider for EventRepository
final eventRepositoryProvider = Provider<EventRepository>((ref) {
  return EventRepository();
});

/// Event state
class EventState {
  final List<Event> events;
  final List<Event> todayEvents;
  final List<Event> upcomingEvents;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;

  EventState({
    this.events = const [],
    this.todayEvents = const [],
    this.upcomingEvents = const [],
    this.isLoading = false,
    this.error,
    DateTime? selectedDate,
  }) : selectedDate = selectedDate ?? DateTime.now();

  EventState copyWith({
    List<Event>? events,
    List<Event>? todayEvents,
    List<Event>? upcomingEvents,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
  }) {
    return EventState(
      events: events ?? this.events,
      todayEvents: todayEvents ?? this.todayEvents,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
    );
  }

  // Computed properties
  int get totalCount => events.length;
  int get todayCount => todayEvents.length;
  int get upcomingCount => upcomingEvents.length;

  /// Get events for selected date
  List<Event> get selectedDateEvents {
    return events.where((e) {
      return e.eventDate.year == selectedDate.year &&
          e.eventDate.month == selectedDate.month &&
          e.eventDate.day == selectedDate.day;
    }).toList();
  }
}

/// Event Notifier
class EventNotifier extends StateNotifier<EventState> {
  final EventRepository _repository;
  final String _userId;

  EventNotifier(this._repository, this._userId) : super(EventState()) {
    loadEvents();
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────────

  /// Load all events and today's events
  Future<void> loadEvents() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final events = await _repository.getAllEvents(_userId);
      final todayEvents = await _repository.getTodayEvents(_userId);
      final upcomingEvents = await _repository.getUpcomingEvents(_userId, days: 7);

      state = state.copyWith(
        events: events,
        todayEvents: todayEvents,
        upcomingEvents: upcomingEvents,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load events: ${e.toString()}',
      );
    }
  }

  /// Load events for a specific month
  Future<List<Event>> loadMonthEvents(int year, int month) async {
    try {
      return await _repository.getEventsByMonth(_userId, year, month);
    } catch (e) {
      state = state.copyWith(error: 'Failed to load month events: ${e.toString()}');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Add a new event
  Future<void> addEvent({
    required String title,
    String? description,
    required DateTime eventDate,
    DateTime? startTime,
    DateTime? endTime,
    bool isAllDay = false,
    String? location,
    String category = 'personal',
    String? color,
    String? reminder,
  }) async {
    try {
      final newEvent = await _repository.createEvent(
        userId: _userId,
        title: title,
        description: description,
        eventDate: eventDate,
        startTime: startTime,
        endTime: endTime,
        isAllDay: isAllDay,
        location: location,
        category: category,
        color: color,
        reminder: reminder,
      );

      // Update state
      final updatedEvents = [...state.events, newEvent]
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

      // Update today's events if applicable
      List<Event> updatedTodayEvents = state.todayEvents;
      if (newEvent.isToday) {
        updatedTodayEvents = [...state.todayEvents, newEvent]
          ..sort((a, b) => (a.startTime ?? a.eventDate)
              .compareTo(b.startTime ?? b.eventDate));
      }

      // Update upcoming events if applicable
      List<Event> updatedUpcomingEvents = state.upcomingEvents;
      if (newEvent.isUpcoming || newEvent.isToday) {
        updatedUpcomingEvents = [...state.upcomingEvents, newEvent]
          ..sort((a, b) => a.eventDate.compareTo(b.eventDate));
      }

      state = state.copyWith(
        events: updatedEvents,
        todayEvents: updatedTodayEvents,
        upcomingEvents: updatedUpcomingEvents,
      );

      // Schedule a 1-hour-before reminder
      await NotificationService.instance.scheduleEventReminder(
          newEvent.id, newEvent.title, newEvent.startTime ?? newEvent.eventDate);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add event: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  /// Update an event
  Future<void> updateEvent(Event event) async {
    try {
      final updatedEvent = await _repository.updateEvent(event);

      final updatedEvents = state.events.map((e) {
        return e.id == updatedEvent.id ? updatedEvent : e;
      }).toList()
        ..sort((a, b) => a.eventDate.compareTo(b.eventDate));

      state = state.copyWith(events: updatedEvents);

      // Reload today and upcoming to ensure accuracy
      await _reloadTodayAndUpcoming();
    } catch (e) {
      state = state.copyWith(error: 'Failed to update event: ${e.toString()}');
    }
  }

  /// Change selected date
  void setSelectedDate(DateTime date) {
    state = state.copyWith(selectedDate: date);
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _repository.deleteEvent(_userId, eventId);
      // Cancel its reminder too
      await NotificationService.instance.cancelEventReminder(eventId);
      state = state.copyWith(
        events: state.events.where((e) => e.id != eventId).toList(),
        todayEvents: state.todayEvents.where((e) => e.id != eventId).toList(),
        upcomingEvents:
            state.upcomingEvents.where((e) => e.id != eventId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete event: ${e.toString()}');
    }
  }

  /// Delete past events
  Future<void> deletePastEvents() async {
    try {
      await _repository.deletePastEvents(_userId);
      await loadEvents();
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete past events: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────

  Future<void> _reloadTodayAndUpcoming() async {
    try {
      final todayEvents = await _repository.getTodayEvents(_userId);
      final upcomingEvents = await _repository.getUpcomingEvents(_userId, days: 7);

      state = state.copyWith(
        todayEvents: todayEvents,
        upcomingEvents: upcomingEvents,
      );
    } catch (_) {}
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh events
  Future<void> refresh() async {
    await loadEvents();
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

/// Main event provider
final eventProvider = StateNotifierProvider<EventNotifier, EventState>((ref) {
  final repository = ref.watch(eventRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return EventNotifier(repository, userId);
});

/// Provider for today's events
final todayEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(eventProvider).todayEvents;
});

/// Provider for upcoming events
final upcomingEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(eventProvider).upcomingEvents;
});

/// Provider for selected date events
final selectedDateEventsProvider = Provider<List<Event>>((ref) {
  return ref.watch(eventProvider).selectedDateEvents;
});

/// Provider for event count today
final todayEventCountProvider = Provider<int>((ref) {
  return ref.watch(eventProvider).todayCount;
});

/// Provider for this week's event count
final weekEventCountProvider = Provider<int>((ref) {
  return ref.watch(eventProvider).upcomingCount;
});

/// Provider for dates with events (for calendar)
final datesWithEventsProvider =
    FutureProvider.family<Set<String>, ({int year, int month})>(
        (ref, params) async {
  final repository = ref.watch(eventRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return await repository.getDatesWithEvents(userId, params.year, params.month);
});