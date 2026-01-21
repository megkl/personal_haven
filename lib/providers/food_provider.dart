import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:personal_haven/data/repositories/food_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';

final foodRepositoryProvider = Provider<FoodRepository>((ref) {
  return FoodRepository();
});

class FoodState {
  final List<FoodEntry> entries;
  final bool isLoading;
  final String? error;

  FoodState({
    this.entries = const [],
    this.isLoading = false,
    this.error,
  });

  FoodState copyWith({
    List<FoodEntry>? entries,
    bool? isLoading,
    String? error,
  }) {
    return FoodState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  int get todayCalories {
    final now = DateTime.now();
    return entries
        .where((e) =>
            e.consumedAt.year == now.year &&
            e.consumedAt.month == now.month &&
            e.consumedAt.day == now.day)
        .fold(0, (sum, entry) => sum + (entry.calories ?? 0));
  }
}

class FoodNotifier extends StateNotifier<FoodState> {
  final FoodRepository _repository;
  final String _userId;

  FoodNotifier(this._repository, this._userId) : super(FoodState()) {
    loadEntries();
  }

  Future<void> loadEntries() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final entries = await _repository.getTodayEntries(_userId);
      state = state.copyWith(entries: entries, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load entries: ${e.toString()}',
      );
    }
  }

  Future<void> addEntry({
    required String mealType,
    required String foodName,
    String? description,
    int? calories,
  }) async {
    try {
      final newEntry = await _repository.createEntry(
        userId: _userId,
        mealType: mealType,
        foodName: foodName,
        description: description,
        calories: calories,
      );
      state = state.copyWith(entries: [newEntry, ...state.entries]);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add entry: ${e.toString()}');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _repository.deleteEntry(entryId);
      final updatedEntries = state.entries.where((e) => e.id != entryId).toList();
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete entry: ${e.toString()}');
    }
  }
}

final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return FoodNotifier(repository, userId);
});
