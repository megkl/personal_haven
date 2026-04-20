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

  // ─────────────────────────────────────────────────────────────
  // Computed Properties - Today's Stats
  // ─────────────────────────────────────────────────────────────

  List<FoodEntry> get todayEntries {
    final now = DateTime.now();
    return entries.where((e) =>
        e.consumedAt.year == now.year &&
        e.consumedAt.month == now.month &&
        e.consumedAt.day == now.day).toList();
  }

  int get todayCalories {
    int total = 0;
    for (final entry in todayEntries) {
      total += entry.calories ?? 0;
    }
    return total;
  }

  int get todayProtein {
    int total = 0;
    for (final entry in todayEntries) {
      total += entry.protein ?? 0;
    }
    return total;
  }

  int get todayCarbs {
    int total = 0;
    for (final entry in todayEntries) {
      total += entry.carbs ?? 0;
    }
    return total;
  }

  int get todayFat {
    int total = 0;
    for (final entry in todayEntries) {
      total += entry.fat ?? 0;
    }
    return total;
  }

  // Meal type specific
  List<FoodEntry> getEntriesByMealType(String mealType) {
    return todayEntries.where((e) => e.mealType == mealType).toList();
  }

  int getCaloriesByMealType(String mealType) {
    int total = 0;
    for (final entry in getEntriesByMealType(mealType)) {
      total += entry.calories ?? 0;
    }
    return total;
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
    int? protein,
    int? carbs,
    int? fat,
  }) async {
    try {
      final newEntry = await _repository.createEntry(
        userId: _userId,
        mealType: mealType,
        foodName: foodName,
        description: description,
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
      );

      // Add to beginning of list (most recent first in meals, but we sort by time)
      final updatedEntries = [...state.entries, newEntry];
      // Sort by consumed time
      updatedEntries.sort((a, b) => a.consumedAt.compareTo(b.consumedAt));
      
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: 'Failed to add entry: ${e.toString()}');
    }
  }

  Future<void> updateEntry(FoodEntry entry) async {
    try {
      await _repository.updateEntry(entry);
      
      final updatedEntries = state.entries.map((e) {
        return e.id == entry.id ? entry : e;
      }).toList();
      
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: 'Failed to update entry: ${e.toString()}');
    }
  }

  Future<void> deleteEntry(String entryId) async {
    try {
      await _repository.deleteEntry(_userId, entryId);
      final updatedEntries = state.entries.where((e) => e.id != entryId).toList();
      state = state.copyWith(entries: updatedEntries);
    } catch (e) {
      state = state.copyWith(error: 'Failed to delete entry: ${e.toString()}');
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final foodProvider = StateNotifierProvider<FoodNotifier, FoodState>((ref) {
  final repository = ref.watch(foodRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return FoodNotifier(repository, userId);
});

// Additional providers for specific data
final todayCaloriesProvider = Provider<int>((ref) {
  return ref.watch(foodProvider).todayCalories;
});

final todayMacrosProvider = Provider<Map<String, int>>((ref) {
  final foodState = ref.watch(foodProvider);
  return {
    'calories': foodState.todayCalories,
    'protein': foodState.todayProtein,
    'carbs': foodState.todayCarbs,
    'fat': foodState.todayFat,
  };
});