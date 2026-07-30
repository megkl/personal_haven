import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationIds {
  static const morningCheckin = 1;
  static const eveningMood = 2;
  static const journalPrompt = 3;
  static const mealReminder = 4;
  static const trialExpiring3Days = 10;
  static const trialExpiring1Day = 11;
  static const subscriptionExpired = 12;
  static const taskDueTodayBase = 100;
  static const taskOverdueBase = 200;
  static const goalDeadlineBase = 300;
  static const eventReminderBase = 400;
  static const streakEncouragement = 500;
  static const weeklyMoodSummary = 501;
  static const noonStreakReminder = 502;
  static const testNotification = 900;
}

class NotificationChannels {
  static const dailyId = 'daily_reminders';
  static const dailyName = 'Daily Reminders';
  static const subscriptionId = 'subscription';
  static const subscriptionName = 'Subscription Alerts';
  static const tasksId = 'tasks';
  static const tasksName = 'Task Reminders';
  static const goalsId = 'goals';
  static const goalsName = 'Goal Reminders';
  static const eventsId = 'events';
  static const eventsName = 'Event Reminders';
  static const wellnessId = 'wellness';
  static const wellnessName = 'Wellness Insights';
  static const testId = 'test_notifications';
  static const testName = 'Test Notifications';
}

class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  Future<void>? _initializing;
  static const _firstPermissionPromptKey =
      'notification_permission_prompted_once';

  Future<void> initialize() {
    if (_initialized) return Future<void>.value();
    return _initializing ??= _initialize().whenComplete(() {
      _initializing = null;
    });
  }

  Future<void> _initialize() async {
    tz.initializeTimeZones();
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      // The timezone package defaults to UTC. Scheduling remains functional if
      // a platform cannot report an IANA timezone identifier.
    }

    const android = AndroidInitializationSettings('ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );
    _initialized = true;
  }

  void _onTap(NotificationResponse response) {}

  Future<bool> requestPermission() async {
    await initialize();
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    final android = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    final androidEnabled = await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
    return (ios ?? true) && (android ?? true) && (androidEnabled ?? true);
  }

  Future<bool?> requestPermissionOnFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_firstPermissionPromptKey) ?? false) return null;

    final granted = await requestPermission();
    if (granted) {
      // Match the notification provider's persisted master preference so a
      // user who accepts the system prompt actually receives reminders.
      await prefs.setBool('notif_masterEnabled', true);
    }
    await prefs.setBool(_firstPermissionPromptKey, true);
    return granted;
  }

  Future<bool> notificationsEnabled({String? androidChannelId}) async {
    await initialize();

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      if (await android.areNotificationsEnabled() != true) return false;
      if (androidChannelId != null) {
        final channels = await android.getNotificationChannels();
        final matching = channels
            ?.where((channel) => channel.id == androidChannelId)
            .firstOrNull;
        if (matching != null && matching.importance == Importance.none) {
          return false;
        }
      }
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final iosPermissions = await ios?.checkPermissions();
    if (iosPermissions != null &&
        (!iosPermissions.isEnabled || !iosPermissions.isAlertEnabled)) {
      return false;
    }
    return true;
  }

  Future<bool> isPending(int id) async {
    await initialize();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((notification) => notification.id == id);
  }

  NotificationDetails _details(
    String channelId,
    String channelName, {
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,
        icon: 'ic_notification',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _scheduleAt(DateTime dt) => tz.TZDateTime.from(dt, tz.local);

  // ── Immediate ─────────────────────────────────────────────────────────────

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String channelId = NotificationChannels.dailyId,
    String channelName = NotificationChannels.dailyName,
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      payload: null,
      notificationDetails: _details(channelId, channelName),
    );
  }

  // ── Daily recurring ───────────────────────────────────────────────────────

  Future<void> scheduleDailyReminders({
    int morningMinuteOfDay = 8 * 60,
    int eveningMinuteOfDay = 20 * 60,
    int journalMinuteOfDay = 21 * 60,
    int mealMinuteOfDay = 13 * 60,
  }) async {
    await initialize();
    await _scheduleDailyAt(
      id: NotificationIds.morningCheckin,
      hour: morningMinuteOfDay ~/ 60,
      minute: morningMinuteOfDay % 60,
      title: '🌅 Good morning!',
      body: 'How are you feeling today? Log your mood to start the day right.',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );
    await _scheduleDailyAt(
      id: NotificationIds.eveningMood,
      hour: eveningMinuteOfDay ~/ 60,
      minute: eveningMinuteOfDay % 60,
      title: '🌙 Evening check-in',
      body: 'Take a moment to reflect — log your mood before the day ends.',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );
    await _scheduleDailyAt(
      id: NotificationIds.journalPrompt,
      hour: journalMinuteOfDay ~/ 60,
      minute: journalMinuteOfDay % 60,
      title: '📓 Journal time',
      body: 'Write down your thoughts. Even a few lines can make a difference.',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );
    await _scheduleDailyAt(
      id: NotificationIds.mealReminder,
      hour: mealMinuteOfDay ~/ 60,
      minute: mealMinuteOfDay % 60,
      title: '🥗 Lunch check',
      body: "Don't forget to log your meals in your food diary.",
      channelId: NotificationChannels.wellnessId,
      channelName: NotificationChannels.wellnessName,
    );
  }

  Future<void> _scheduleDailyAt({
    required int id,
    required int hour,
    required int minute,
    required String title,
    required String body,
    required String channelId,
    required String channelName,
  }) async {
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: _nextInstanceOfTime(hour, minute),
      notificationDetails: _details(channelId, channelName),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminders() async {
    for (final id in [
      NotificationIds.morningCheckin,
      NotificationIds.eveningMood,
      NotificationIds.journalPrompt,
      NotificationIds.mealReminder,
    ]) {
      await _plugin.cancel(id: id);
    }
  }

  Future<void> cancelMoodReminders() async {
    await _plugin.cancel(id: NotificationIds.morningCheckin);
    await _plugin.cancel(id: NotificationIds.eveningMood);
  }

  Future<void> cancelJournalReminders() async {
    await _plugin.cancel(id: NotificationIds.journalPrompt);
  }

  Future<void> cancelMealReminders() async {
    await _plugin.cancel(id: NotificationIds.mealReminder);
  }

  // ── Weekly ────────────────────────────────────────────────────────────────

  Future<void> scheduleWeeklyMoodSummary({int minuteOfDay = 18 * 60}) async {
    await initialize();
    final now = tz.TZDateTime.now(tz.local);
    var daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) daysUntilSunday += 7;
    final nextSunday = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + daysUntilSunday,
      minuteOfDay ~/ 60,
      minuteOfDay % 60,
    );

    await _plugin.zonedSchedule(
      id: NotificationIds.weeklyMoodSummary,
      title: '📊 Your weekly mood summary',
      body: 'Check your mood insights to see how your week went.',
      scheduledDate: nextSunday,
      notificationDetails: _details(
        NotificationChannels.wellnessId,
        NotificationChannels.wellnessName,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> cancelWeeklyMoodSummary() async {
    await _plugin.cancel(id: NotificationIds.weeklyMoodSummary);
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> notifyTaskDueToday(String taskId, String taskTitle) async {
    await show(
      id: NotificationIds.taskDueTodayBase + taskId.hashCode.abs() % 100,
      title: '✅ Task due today',
      body: '"$taskTitle" is due today. Don\'t let it slip!',
      channelId: NotificationChannels.tasksId,
      channelName: NotificationChannels.tasksName,
    );
  }

  Future<void> notifyTaskOverdue(String taskId, String taskTitle) async {
    await show(
      id: NotificationIds.taskOverdueBase + taskId.hashCode.abs() % 100,
      title: '⚠️ Overdue task',
      body: '"$taskTitle" is overdue. Tap to review your tasks.',
      channelId: NotificationChannels.tasksId,
      channelName: NotificationChannels.tasksName,
    );
  }

  Future<void> cancelTaskNotifications() async {
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(id: NotificationIds.taskDueTodayBase + i);
      await _plugin.cancel(id: NotificationIds.taskOverdueBase + i);
    }
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  Future<void> notifyGoalDeadlineApproaching(
    String goalId,
    String goalTitle,
    int daysLeft,
  ) async {
    await show(
      id: NotificationIds.goalDeadlineBase + goalId.hashCode.abs() % 100,
      title: '🎯 Goal deadline approaching',
      body:
          '"$goalTitle" is due in $daysLeft day${daysLeft == 1 ? '' : 's'}. Keep pushing!',
      channelId: NotificationChannels.goalsId,
      channelName: NotificationChannels.goalsName,
    );
  }

  Future<void> notifyGoalCompleted(String goalTitle) async {
    await show(
      id: NotificationIds.goalDeadlineBase + 99,
      title: '🏆 Goal achieved!',
      body: 'You completed "$goalTitle". Amazing work!',
      channelId: NotificationChannels.goalsId,
      channelName: NotificationChannels.goalsName,
    );
  }

  Future<void> cancelGoalNotifications() async {
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(id: NotificationIds.goalDeadlineBase + i);
    }
  }

  // ── Events ────────────────────────────────────────────────────────────────

  Future<void> scheduleEventReminder(
    String eventId,
    String eventTitle,
    DateTime eventTime,
  ) async {
    await initialize();
    final reminderTime = eventTime.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = NotificationIds.eventReminderBase + eventId.hashCode.abs() % 100;

    await _plugin.zonedSchedule(
      id: id,
      title: '⏰ Upcoming event',
      body: 'Your event "$eventTitle" starts in 1 hour.',
      scheduledDate: _scheduleAt(reminderTime),
      notificationDetails: _details(
        NotificationChannels.eventsId,
        NotificationChannels.eventsName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    await _plugin.cancel(
      id: NotificationIds.eventReminderBase + eventId.hashCode.abs() % 100,
    );
  }

  Future<void> cancelEventReminders() async {
    for (var i = 0; i < 100; i++) {
      await _plugin.cancel(id: NotificationIds.eventReminderBase + i);
    }
  }

  // ── Subscription ─────────────────────────────────────────────────────────

  Future<void> scheduleSubscriptionReminders(DateTime expiryDate) async {
    await initialize();
    final now = DateTime.now();
    final threeDays = expiryDate.subtract(const Duration(days: 3));
    final oneDay = expiryDate.subtract(const Duration(days: 1));

    if (threeDays.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: NotificationIds.trialExpiring3Days,
        title: '⏳ Your subscription expires soon',
        body:
            'Your Personal Haven access expires in 3 days. Renew to keep your haven.',
        scheduledDate: _scheduleAt(threeDays),
        notificationDetails: _details(
          NotificationChannels.subscriptionId,
          NotificationChannels.subscriptionName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }

    if (oneDay.isAfter(now)) {
      await _plugin.zonedSchedule(
        id: NotificationIds.trialExpiring1Day,
        title: '🔔 Last day of your subscription',
        body:
            'Your access expires tomorrow. Subscribe now to avoid interruption.',
        scheduledDate: _scheduleAt(oneDay),
        notificationDetails: _details(
          NotificationChannels.subscriptionId,
          NotificationChannels.subscriptionName,
          importance: Importance.high,
          priority: Priority.high,
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> notifySubscriptionExpired() async {
    await show(
      id: NotificationIds.subscriptionExpired,
      title: '🔒 Subscription expired',
      body: 'Renew your Personal Haven subscription to continue your journey.',
      channelId: NotificationChannels.subscriptionId,
      channelName: NotificationChannels.subscriptionName,
    );
  }

  Future<void> cancelSubscriptionNotifications() async {
    await _plugin.cancel(id: NotificationIds.trialExpiring3Days);
    await _plugin.cancel(id: NotificationIds.trialExpiring1Day);
    await _plugin.cancel(id: NotificationIds.subscriptionExpired);
  }

  // ── Streaks ───────────────────────────────────────────────────────────────

  /// Schedule a daily noon reminder. Calling this whenever the app is opened
  /// moves the next reminder to tomorrow; if the app stays closed, it repeats
  /// each day until the user returns.
  Future<void> scheduleNoonStreakReminderAfterToday() async {
    await initialize();
    await cancelNoonStreakReminder();

    final now = tz.TZDateTime.now(tz.local);
    final tomorrowAtNoon = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day + 1,
      12,
    );

    await _plugin.zonedSchedule(
      id: NotificationIds.noonStreakReminder,
      title: 'Keep your haven streak going 🔥',
      body: 'A small check-in today keeps your momentum alive.',
      scheduledDate: tomorrowAtNoon,
      notificationDetails: _details(
        NotificationChannels.dailyId,
        NotificationChannels.dailyName,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNoonStreakReminder() async {
    await _plugin.cancel(id: NotificationIds.noonStreakReminder);
  }

  Future<void> notifyJournalStreak(int days) async {
    await show(
      id: NotificationIds.streakEncouragement,
      title: '🔥 $days-day journal streak!',
      body: "You've journaled $days days in a row. Keep the momentum going!",
    );
  }

  Future<void> notifyMoodLogged(String emoji) async {
    await show(
      id: NotificationIds.eveningMood + 1,
      title: '$emoji Mood logged',
      body: 'Great job checking in with yourself today.',
    );
  }

  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      id: NotificationIds.testNotification,
      title: '🔔 Test notification',
      body: 'Notifications are working in Personal Haven.',
      payload: null,
      notificationDetails: _details(
        NotificationChannels.testId,
        NotificationChannels.testName,
        importance: Importance.high,
        priority: Priority.high,
      ),
    );
  }

  Future<void> scheduleTestNotificationInFiveSeconds() async {
    await initialize();
    await _plugin.zonedSchedule(
      id: NotificationIds.testNotification + 1,
      title: '⏰ Scheduled test',
      body: 'This notification was scheduled 5 seconds ago.',
      scheduledDate: tz.TZDateTime.now(
        tz.local,
      ).add(const Duration(seconds: 5)),
      notificationDetails: _details(
        NotificationChannels.testId,
        NotificationChannels.testName,
        importance: Importance.high,
        priority: Priority.high,
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  Future<void> cancelAll() async {
    await initialize();
    await _plugin.cancelAll();
  }
}
