import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/data/repositories/mood_repository.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/providers/notification_provider.dart';
import 'package:personal_haven/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
part 'mood_provider.g.dart';

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

@riverpod
class MoodNotifier extends _$MoodNotifier {
  final MoodRepository _repository = MoodRepository();

  String get _userId => ref.read(currentUserIdProvider);

  @override
  MoodState build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId.isNotEmpty) {
      Future.microtask(() => loadTodayMood(userId: userId));
    }
    return MoodState();
  }

  Future<void> loadTodayMood({String? userId}) async {
    final targetUserId = userId ?? _userId;
    if (targetUserId.isEmpty) return;
    state = state.copyWith(isLoading: true);
    try {
      final todayMood = await _repository.getTodayMood(targetUserId);
      final weekMoods = await _repository.getWeekMoods(targetUserId);
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

  Future<void> logMood(
    int moodLevel,
    String moodEmoji, {
    String? moodLabel,
    String? notes,
  }) async {
    try {
      final userId = _userId;
      if (userId.isEmpty) return;
      final log = await _repository.logMood(
        userId: userId,
        moodLevel: moodLevel,
        moodLabel: moodLabel ?? '',
        moodEmoji: moodEmoji,
        notes: notes,
      );
      state = state.copyWith(todayMood: log);
      await loadTodayMood(userId: userId);
      final notificationPrefs = ref.read(notificationProvider);
      if (notificationPrefs.masterEnabled && notificationPrefs.moodReminder) {
        // Notify after logging mood
        await NotificationService.instance.notifyMoodLogged(moodEmoji);
      }
    } catch (e) {
      state = state.copyWith(error: 'Failed to log mood: ${e.toString()}');
    }
  }
}

final weekMoodStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(moodRepositoryProvider);
  final userId = ref.watch(currentUserIdProvider);
  return await repository.getWeekMoodStats(userId);
});
