import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/data/repositories/journal_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'journal_provider.g.dart';

/// Provider for JournalRepository
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  return JournalRepository();
});

/// State for journal entries
class JournalState {
  final List<JournalEntry> entries;
  final List<JournalEntry> searchResults;
  final bool isLoading;
  final bool isSearching;
  final String? error;
  final String selectedCategory;
  final String searchQuery;

  JournalState({
    this.entries = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.error,
    this.selectedCategory = 'All',
    this.searchQuery = '',
  });

  JournalState copyWith({
    List<JournalEntry>? entries,
    List<JournalEntry>? searchResults,
    bool? isLoading,
    bool? isSearching,
    String? error,
    String? selectedCategory,
    String? searchQuery,
  }) {
    return JournalState(
      entries: entries ?? this.entries,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────────────────────

  /// Get entries filtered by current category
  List<JournalEntry> get filteredEntries {
    if (selectedCategory == 'All') return entries;
    return entries.where((e) => e.category == selectedCategory).toList();
  }

  /// Get entries based on search or filter
  List<JournalEntry> get displayedEntries {
    if (isSearching && searchQuery.isNotEmpty) {
      return searchResults;
    }
    return filteredEntries;
  }

  /// Today's entries
  List<JournalEntry> get todayEntries {
    final now = DateTime.now();
    return entries
        .where(
          (e) =>
              e.entryDate.year == now.year &&
              e.entryDate.month == now.month &&
              e.entryDate.day == now.day,
        )
        .toList();
  }

  /// This week's entries
  List<JournalEntry> get thisWeekEntries {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    return entries.where((e) => e.entryDate.isAfter(weekAgo)).toList();
  }

  /// Count by category
  Map<String, int> get categoryStats {
    final Map<String, int> stats = {};
    for (var entry in entries) {
      stats[entry.category] = (stats[entry.category] ?? 0) + 1;
    }
    return stats;
  }

  /// All unique tags
  Set<String> get allTags {
    final tags = <String>{};
    for (var entry in entries) {
      tags.addAll(entry.tags);
    }
    return tags;
  }
}

@riverpod
class JournalNotifier extends _$JournalNotifier {
  final JournalRepository _repository = JournalRepository();

  String get _userId => ref.read(currentUserIdProvider);

  @override
  JournalState build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isNotEmpty) {
      Future.microtask(loadEntries);
    }
    return JournalState();
  }

  // ─────────────────────────────────────────────────────────────
  // LOAD
  // ─────────────────────────────────────────────────────────────

  /// Load all entries
  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final entries = await _repository.getAllEntries(_userId);
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load entries: ${e.toString()}',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CREATE
  // ─────────────────────────────────────────────────────────────

  /// Add a new entry
  Future<void> addEntry({
    required String title,
    required String content,
    required String category,
    String? emoji,
    List<String> tags = const [],
    DateTime? entryDate,
  }) async {
    try {
      final newEntry = await _repository.createEntry(
        userId: _userId,
        title: title,
        content: content,
        category: category,
        emoji: emoji,
        tags: tags,
        entryDate: entryDate,
      );

      // Add to beginning of list (most recent first)
      state = state.copyWith(entries: [newEntry, ...state.entries]);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add entry: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // UPDATE
  // ─────────────────────────────────────────────────────────────

  /// Update an entry
  Future<void> updateEntry(JournalEntry entry) async {
    try {
      final updatedEntry = await _repository.updateEntry(entry);

      final updatedEntries = state.entries.map((e) {
        return e.id == updatedEntry.id ? updatedEntry : e;
      }).toList();

      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update entry: ${e.toString()}');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // DELETE
  // ─────────────────────────────────────────────────────────────

  /// Delete an entry
  Future<void> deleteEntry(String entryId) async {
    try {
      await _repository.deleteEntry(_userId, entryId);
      final updatedEntries = state.entries
          .where((e) => e.id != entryId)
          .toList();
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete entry: ${e.toString()}');
    }
  }

  /// Delete all entries
  Future<void> deleteAllEntries() async {
    try {
      await _repository.deleteAllEntries(_userId);
      state = state.copyWith(entries: []);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to delete entries: ${e.toString()}',
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // SEARCH & FILTER
  // ─────────────────────────────────────────────────────────────

  /// Search entries
  Future<void> searchEntries(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(
        isSearching: false,
        searchQuery: '',
        searchResults: [],
      );
      return;
    }

    state = state.copyWith(isSearching: true, searchQuery: query);

    try {
      final results = await _repository.searchEntries(_userId, query);
      state = state.copyWith(searchResults: results);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to search entries: ${e.toString()}',
      );
    }
  }

  /// Set selected category
  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(
      isSearching: false,
      searchQuery: '',
      searchResults: [],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // STATISTICS
  // ─────────────────────────────────────────────────────────────

  /// Get today's entry count
  Future<int> getTodayCount() async {
    final todayEntries = await _repository.getTodayEntries(_userId);
    return todayEntries.length;
  }

  /// Get entry count
  Future<int> getEntryCount() async {
    return await _repository.getEntryCount(_userId);
  }

  /// Get all unique tags
  Future<List<String>> getAllTags() async {
    return await _repository.getAllTags(_userId);
  }

  // ─────────────────────────────────────────────────────────────
  // UTILITIES
  // ─────────────────────────────────────────────────────────────

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh entries
  Future<void> refresh() async {
    await loadEntries();
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDERS
// ─────────────────────────────────────────────────────────────

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

/// Provider for all unique tags
final allTagsProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(journalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return await repository.getAllTags(userId);
});

/// Provider for recent entries
final recentEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repository = ref.watch(journalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return await repository.getRecentEntries(userId, limit: 5);
});

/// Provider for this week's entries
final thisWeekEntriesProvider = FutureProvider<List<JournalEntry>>((ref) async {
  final repository = ref.watch(journalRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);

  return await repository.getThisWeekEntries(userId);
});
