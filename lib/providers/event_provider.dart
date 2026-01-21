import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/event.dart';
import 'package:personal_haven/data/models/journal_entry.dart';

final journalEntriesProvider = StateNotifierProvider<JournalNotifier, List<JournalEntry>>((ref) {
  return JournalNotifier();
});

class JournalNotifier extends StateNotifier<List<JournalEntry>> {
  JournalNotifier() : super([]) {
    _loadMockData();
  }

  void _loadMockData() {
    state = [
      JournalEntry(
        id: '1',
        userId: '1',
        title: 'Morning Reflections',
        content: 'Gratitude for a new day and setting intentions. 😊',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'All',
        emoji: '😊',
      ),
      JournalEntry(
        id: '2',
        userId: '1',
        title: 'Project Brainstorm',
        content: 'Gratitude for a new day and',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        updatedAt: DateTime.now(),
        category: 'Notes',
        emoji: '💡',
      ),
      JournalEntry(
        id: '3',
        userId: '1',
        title: 'Project Goal Updarm',
        content: 'Gratitude for a new day',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Notes',
        tags: ['Health'],
      ),
      JournalEntry(
        id: '4',
        userId: '1',
        title: 'Fitness Goal Update',
        content: 'Gratitude for a new day and intentions.',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        category: 'Goals',
        emoji: '😁',
      ),
    ];
  }

  void addEntry(JournalEntry entry) {
    state = [entry, ...state];
  }

  void updateEntry(JournalEntry entry) {
    state = [
      for (final e in state)
        if (e.id == entry.id) entry else e,
    ];
  }

  void deleteEntry(String id) {
    state = state.where((e) => e.id != id).toList();
  }
}

final userNameProvider = StateProvider<String>((ref) => 'Meg');

final eventsProvider = StateProvider<List<Event>>((ref) {
  return [
    Event(
      id: '1',
      title: 'Yoga Class',
      time: DateTime.now().add(const Duration(hours: 2)),
    ),
    Event(
      id: '2',
      title: 'Creative Writing',
      time: DateTime.now().add(const Duration(hours: 4)),
    ),
  ];
});
