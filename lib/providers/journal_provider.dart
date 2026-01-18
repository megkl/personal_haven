import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/data/repositories/journal_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';

/// Provider for JournalRepository
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

/// State for journal entries
class JournalState {
  final List<JournalEntry> entries;
  final bool isLoading;
  final String? error;
  final String selectedCategory;

  JournalState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory = 'All',
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }
}

/// Journal State Notifier
class JournalNotifier extends StateNotifier<JournalState> {
  final JournalRepository _repository;
  final String _userId;

  JournalNotifier(this._repository, this._userId) : super(JournalState()) {
    loadEntries();
  }

  /// Load all entries
  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final entries = await _repository.getAllEntries(_userId);
      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load entries: ${e.toString()}',
      );
    }
  }

  /// Add a new entry
  Future<void> addEntry({
    required String title,
    required String content,
    required String category,
    String? emoji,
    List<String> tags = const [],
  }) async {
    try {
      final newEntry = await _repository.createEntry(
        userId: _userId,
        title: title,
        content: content,
        category: category,
        emoji: emoji,
        tags: tags,
      );

      state = state.copyWith(
        entries: [newEntry, ...state.entries],
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add entry: ${e.toString()}',
      );
    }
  }

  /// Update an entry
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      final updatedEntry = await _repository.updateEntry(entry);
      
      final updatedEntries = state.entries.map((e) {
        return e.id == updatedEntry.id ? updatedEntry : e;
      }).toList();

      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update entry: ${e.toString()}',
      );
    }
  }

  /// Delete an entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await _repository.deleteEntry(entryId);
      
      final updatedEntries = state.entries.where((e) => e.id != entryId).toList();
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete entry: ${e.toString()}',
      );
    }
  }

  /// Filter by category
  Future<void> filterByCategory(String category) async {
    state = state.copyWith(selectedCategory: category, isLoading: true);
    
    try {
      final entries = await _repository.getEntriesByCategory(_userId, category);
      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to filter entries: ${e.toString()}',
      );
    }
  }

  /// Search entries
  Future<void> searchEntries(String query) async {
    state = state.copyWith(isLoading: true);
    
    try {
      final entries = await _repository.searchEntries(_userId, query);
      state = state.copyWith(
        entries: entries,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to search entries: ${e.toString()}',
      );
    }
  }

  /// Get today's entry count
  Future<int> getTodayCount() async {
    final todayEntries = await _repository.getTodayEntries(_userId);
    return todayEntries.length;
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for JournalNotifier
final journalProvider = StateNotifierProvider<JournalNotifier, JournalState>((ref) {
  final repository = ref.watch(journalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  return JournalNotifier(repository, userId);
});

/// Provider for today's entry count
final todayEntryCountProvider = FutureProvider<int>((ref) async {
  final notifier = ref.watch(journalProvider.notifier);
  return await notifier.getTodayCount();
});

/// Provider for category statistics
final categoryStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(journalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  
  return await repository.getCategoryStats(userId);
});