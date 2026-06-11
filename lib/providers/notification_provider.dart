import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/services/notification_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
part 'notification_provider.g.dart';
class NotificationPrefs {
  final bool masterEnabled;
  final bool dailyReminders;
  final bool moodReminder;
  final bool journalReminder;
  final bool taskReminders;
  final bool goalReminders;
  final bool eventReminders;
  final bool subscriptionAlerts;
  final bool weeklyInsights;

  const NotificationPrefs({
    this.masterEnabled = true,
    this.dailyReminders = true,
    this.moodReminder = true,
    this.journalReminder = true,
    this.taskReminders = true,
    this.goalReminders = true,
    this.eventReminders = true,
    this.subscriptionAlerts = true,
    this.weeklyInsights = true,
  });

  NotificationPrefs copyWith({
    bool? masterEnabled,
    bool? dailyReminders,
    bool? moodReminder,
    bool? journalReminder,
    bool? taskReminders,
    bool? goalReminders,
    bool? eventReminders,
    bool? subscriptionAlerts,
    bool? weeklyInsights,
  }) {
    return NotificationPrefs(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      dailyReminders: dailyReminders ?? this.dailyReminders,
      moodReminder: moodReminder ?? this.moodReminder,
      journalReminder: journalReminder ?? this.journalReminder,
      taskReminders: taskReminders ?? this.taskReminders,
      goalReminders: goalReminders ?? this.goalReminders,
      eventReminders: eventReminders ?? this.eventReminders,
      subscriptionAlerts: subscriptionAlerts ?? this.subscriptionAlerts,
      weeklyInsights: weeklyInsights ?? this.weeklyInsights,
    );
  }

  Map<String, bool> toMap() => {
        'masterEnabled': masterEnabled,
        'dailyReminders': dailyReminders,
        'moodReminder': moodReminder,
        'journalReminder': journalReminder,
        'taskReminders': taskReminders,
        'goalReminders': goalReminders,
        'eventReminders': eventReminders,
        'subscriptionAlerts': subscriptionAlerts,
        'weeklyInsights': weeklyInsights,
      };

  factory NotificationPrefs.fromMap(Map<String, bool> m) => NotificationPrefs(
        masterEnabled: m['masterEnabled'] ?? true,
        dailyReminders: m['dailyReminders'] ?? true,
        moodReminder: m['moodReminder'] ?? true,
        journalReminder: m['journalReminder'] ?? true,
        taskReminders: m['taskReminders'] ?? true,
        goalReminders: m['goalReminders'] ?? true,
        eventReminders: m['eventReminders'] ?? true,
        subscriptionAlerts: m['subscriptionAlerts'] ?? true,
        weeklyInsights: m['weeklyInsights'] ?? true,
      );
}


@riverpod
class NotificationNotifier extends _$NotificationNotifier {
  static const _prefix = 'notif_';
  @override
  NotificationPrefs build() {
    // replaces the constructor — runs on first use
    Future.microtask(_load);
    return NotificationPrefs();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <String, bool>{};
    for (final key in NotificationPrefs().toMap().keys) {
      map[key] = prefs.getBool('$_prefix$key') ?? true;
    }
    state = NotificationPrefs.fromMap(map);
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }

  Future<void> setMaster(bool value) async {
    state = state.copyWith(masterEnabled: value);
    await _save('masterEnabled', value);
    if (value) {
      await NotificationService.instance.requestPermission();
      await _rescheduleAll();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> toggle(String key, bool value) async {
    state = _applyKey(key, value);
    await _save(key, value);
    await _rescheduleAll();
  }

  NotificationPrefs _applyKey(String key, bool value) {
    switch (key) {
      case 'dailyReminders':
        return state.copyWith(dailyReminders: value);
      case 'moodReminder':
        return state.copyWith(moodReminder: value);
      case 'journalReminder':
        return state.copyWith(journalReminder: value);
      case 'taskReminders':
        return state.copyWith(taskReminders: value);
      case 'goalReminders':
        return state.copyWith(goalReminders: value);
      case 'eventReminders':
        return state.copyWith(eventReminders: value);
      case 'subscriptionAlerts':
        return state.copyWith(subscriptionAlerts: value);
      case 'weeklyInsights':
        return state.copyWith(weeklyInsights: value);
      default:
        return state;
    }
  }

  Future<void> _rescheduleAll() async {
    if (!state.masterEnabled) return;
    final svc = NotificationService.instance;

    // Daily reminders
    if (state.dailyReminders) {
      await svc.scheduleDailyReminders();
    } else {
      await svc.cancelDailyReminders();
    }

    // Weekly insights
    if (state.weeklyInsights) {
      await svc.scheduleWeeklyMoodSummary();
    }
  }
}

