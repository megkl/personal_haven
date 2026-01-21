import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/data/repositories/mood_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  return MoodRepository();
});

class MoodState {
  final MoodLog? todayMood;
  final List<MoodLog> weekMoods;
  final bool isLoading;
  final String? error;

  MoodState({
    this.todayMood,
    this.weekMoods = const [],
    this.isLoading = false,
    this.error,
  });

  MoodState copyWith({
    MoodLog? todayMood,
    List<MoodLog>? weekMoods,
    bool? isLoading,
    String? error,
  }) {
    return MoodState(
      todayMood: todayMood ?? this.todayMood,
      weekMoods: weekMoods ?? this.weekMoods,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MoodNotifier extends StateNotifier<MoodState> {
  final MoodRepository _repository;
  final String _userId;

  MoodNotifier(this._repository, this._userId) : super(MoodState()) {
    loadTodayMood();
  }

  Future<void> loadTodayMood() async {
    state = state.copyWith(isLoading: true);
    try {
      final todayMood = await _repository.getTodayMood(_userId);
      final weekMoods = await _repository.getWeekMoods(_userId);
      state = state.copyWith(
        todayMood: todayMood,
        weekMoods: weekMoods,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load mood: ${e.toString()}',
      );
    }
  }

  Future<void> logMood(int moodLevel, String moodEmoji, {String? notes}) async {
    try {
      final log = await _repository.logMood(
        userId: _userId,
        moodLevel: moodLevel,
        moodEmoji: moodEmoji,
        notes: notes,
      );
      state = state.copyWith(todayMood: log);
      await loadTodayMood(); // Refresh week moods
    } catch (e) {
      state = state.copyWith(error: 'Failed to log mood: ${e.toString()}');
    }
  }
}

final moodProvider = StateNotifierProvider<MoodNotifier, MoodState>((ref) {
  final repository = ref.watch(moodRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return MoodNotifier(repository, userId);
});

final weekMoodStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(moodRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getWeekMoodStats(userId);
});