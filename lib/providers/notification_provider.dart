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
  final int morningReminderMinute;
  final int eveningReminderMinute;
  final int journalReminderMinute;
  final int mealReminderMinute;
  final int weeklyInsightsMinute;

  const NotificationPrefs({
    this.masterEnabled = false,
    this.dailyReminders = false,
    this.moodReminder = false,
    this.journalReminder = false,
    this.taskReminders = false,
    this.goalReminders = false,
    this.eventReminders = false,
    this.subscriptionAlerts = false,
    this.weeklyInsights = false,
    this.morningReminderMinute = 8 * 60,
    this.eveningReminderMinute = 20 * 60,
    this.journalReminderMinute = 21 * 60,
    this.mealReminderMinute = 13 * 60,
    this.weeklyInsightsMinute = 18 * 60,
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
    int? morningReminderMinute,
    int? eveningReminderMinute,
    int? journalReminderMinute,
    int? mealReminderMinute,
    int? weeklyInsightsMinute,
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
      morningReminderMinute:
          morningReminderMinute ?? this.morningReminderMinute,
      eveningReminderMinute:
          eveningReminderMinute ?? this.eveningReminderMinute,
      journalReminderMinute:
          journalReminderMinute ?? this.journalReminderMinute,
      mealReminderMinute: mealReminderMinute ?? this.mealReminderMinute,
      weeklyInsightsMinute: weeklyInsightsMinute ?? this.weeklyInsightsMinute,
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
    masterEnabled: m['masterEnabled'] ?? false,
    dailyReminders: m['dailyReminders'] ?? false,
    moodReminder: m['moodReminder'] ?? false,
    journalReminder: m['journalReminder'] ?? false,
    taskReminders: m['taskReminders'] ?? false,
    goalReminders: m['goalReminders'] ?? false,
    eventReminders: m['eventReminders'] ?? false,
    subscriptionAlerts: m['subscriptionAlerts'] ?? false,
    weeklyInsights: m['weeklyInsights'] ?? false,
  );

  Map<String, int> timeMap() => {
    'morningReminderMinute': morningReminderMinute,
    'eveningReminderMinute': eveningReminderMinute,
    'journalReminderMinute': journalReminderMinute,
    'mealReminderMinute': mealReminderMinute,
    'weeklyInsightsMinute': weeklyInsightsMinute,
  };

  factory NotificationPrefs.fromPrefs({
    required Map<String, bool> bools,
    required Map<String, int> times,
  }) {
    const defaults = NotificationPrefs();
    return NotificationPrefs(
      masterEnabled: bools['masterEnabled'] ?? true,
      dailyReminders: bools['dailyReminders'] ?? true,
      moodReminder: bools['moodReminder'] ?? true,
      journalReminder: bools['journalReminder'] ?? true,
      taskReminders: bools['taskReminders'] ?? true,
      goalReminders: bools['goalReminders'] ?? true,
      eventReminders: bools['eventReminders'] ?? true,
      subscriptionAlerts: bools['subscriptionAlerts'] ?? true,
      weeklyInsights: bools['weeklyInsights'] ?? true,
      morningReminderMinute:
          times['morningReminderMinute'] ?? defaults.morningReminderMinute,
      eveningReminderMinute:
          times['eveningReminderMinute'] ?? defaults.eveningReminderMinute,
      journalReminderMinute:
          times['journalReminderMinute'] ?? defaults.journalReminderMinute,
      mealReminderMinute:
          times['mealReminderMinute'] ?? defaults.mealReminderMinute,
      weeklyInsightsMinute:
          times['weeklyInsightsMinute'] ?? defaults.weeklyInsightsMinute,
    );
  }
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
    if (!ref.mounted) return;

    final map = <String, bool>{};
    for (final key in NotificationPrefs().toMap().keys) {
      map[key] = prefs.getBool('$_prefix$key') ?? true;
    }
    final times = <String, int>{};
    for (final key in NotificationPrefs().timeMap().keys) {
      final defaultValue = NotificationPrefs().timeMap()[key]!;
      times[key] = prefs.getInt('$_prefix$key') ?? defaultValue;
    }
    state = NotificationPrefs.fromPrefs(bools: map, times: times);
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_prefix$key', value);
  }

  Future<void> _saveInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$key', value);
  }

  Future<void> setMaster(bool value) async {
    state = state.copyWith(masterEnabled: value);
    await _save('masterEnabled', value);
    if (!ref.mounted) return;

    if (value) {
      await NotificationService.instance.requestPermission();
      if (!ref.mounted) return;
      await _rescheduleAll();
    } else {
      await NotificationService.instance.cancelAll();
    }
  }

  Future<void> toggle(String key, bool value) async {
    state = _applyKey(key, value);
    await _save(key, value);
    if (!ref.mounted) return;
    await _rescheduleAll();
  }

  Future<void> setReminderMinute(String key, int minuteOfDay) async {
    state = _applyTimeKey(key, minuteOfDay.clamp(0, 23 * 60 + 59));
    await _saveInt(key, minuteOfDay);
    if (!ref.mounted) return;
    await _rescheduleAll();
  }

  Future<bool> sendTestNotification() async {
    if (!state.masterEnabled) {
      await setMaster(true);
    } else {
      final granted = await NotificationService.instance.requestPermission(
        includeExactAlarms: false,
      );
      if (!granted) return false;
    }
    await NotificationService.instance.showTestNotification();
    return true;
  }

  Future<bool> scheduleTestNotification() async {
    if (!state.masterEnabled) {
      await setMaster(true);
    }
    final granted = await NotificationService.instance.requestPermission();
    if (!granted) return false;
    await NotificationService.instance.scheduleTestNotificationInFiveSeconds();
    return true;
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

  NotificationPrefs _applyTimeKey(String key, int value) {
    switch (key) {
      case 'morningReminderMinute':
        return state.copyWith(morningReminderMinute: value);
      case 'eveningReminderMinute':
        return state.copyWith(eveningReminderMinute: value);
      case 'journalReminderMinute':
        return state.copyWith(journalReminderMinute: value);
      case 'mealReminderMinute':
        return state.copyWith(mealReminderMinute: value);
      case 'weeklyInsightsMinute':
        return state.copyWith(weeklyInsightsMinute: value);
      default:
        return state;
    }
  }

  Future<void> _rescheduleAll() async {
    if (!ref.mounted) return;

    final prefs = state;
    if (!prefs.masterEnabled) return;
    final svc = NotificationService.instance;

    // Daily reminders
    if (prefs.dailyReminders) {
      await svc.scheduleDailyReminders(
        morningMinuteOfDay: prefs.morningReminderMinute,
        //eveningMinuteOfDay: state.eveningReminderMinute,
        journalMinuteOfDay: prefs.journalReminderMinute,
        //mealMinuteOfDay: state.mealReminderMinute,
      );
      if (!prefs.moodReminder) {
        await svc.cancelMoodReminders();
      }
      if (!prefs.journalReminder) {
        await svc.cancelJournalReminders();
      }
    } else {
      await svc.cancelDailyReminders();
    }

    if (!prefs.taskReminders) {
      await svc.cancelTaskNotifications();
    }
    if (!prefs.goalReminders) {
      await svc.cancelGoalNotifications();
    }
    if (!prefs.eventReminders) {
      await svc.cancelEventReminders();
    }
    if (!prefs.subscriptionAlerts) {
      await svc.cancelSubscriptionNotifications();
    }

    // Weekly insights
    if (prefs.weeklyInsights) {
      await svc.scheduleWeeklyMoodSummary(
        minuteOfDay: prefs.weeklyInsightsMinute,
      );
    } else {
      await svc.cancelWeeklyMoodSummary();
    }
  }
}
