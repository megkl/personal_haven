import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// ── Notification IDs (stable, never reuse across categories) ─────────────────
class NotificationIds {
  // Daily recurring
  static const morningCheckin = 1;
  static const eveningMood = 2;
  static const journalPrompt = 3;
  static const mealReminder = 4;

  // Subscription
  static const trialExpiring3Days = 10;
  static const trialExpiring1Day = 11;
  static const subscriptionExpired = 12;

  // Tasks (dynamic: base + hash)
  static const taskDueTodayBase = 100;
  static const taskOverdueBase = 200;

  // Goals
  static const goalDeadlineBase = 300;

  // Events
  static const eventReminderBase = 400;

  // Streaks / encouragement
  static const streakEncouragement = 500;
  static const weeklyMoodSummary = 501;
}

// ── Channel IDs ───────────────────────────────────────────────────────────────
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
}

/// Central notification service. Call [initialize] once in main().
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // Default to Nairobi — update if you detect user locale
    tz.setLocalLocation(tz.getLocation('Africa/Nairobi'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: _onTap,
    );

    _initialized = true;
  }

  void _onTap(NotificationResponse response) {
    // Navigation on tap can be wired here via a global navigator key if needed
  }

  /// Request permission (Android 13+, iOS always).
  Future<bool> requestPermission() async {
    final ios = await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final android = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    return (ios ?? true) && (android ?? true);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NotificationDetails _details(
    String channelId,
    String channelName, {
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
    String? largeIcon,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        importance: importance,
        priority: priority,
        icon: '@mipmap/ic_launcher',
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
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _scheduleAt(DateTime dt) {
    return tz.TZDateTime.from(dt, tz.local);
  }

  // ── Immediate / one-shot ──────────────────────────────────────────────────

  /// Show an immediate notification (e.g. after an action).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    String channelId = NotificationChannels.dailyId,
    String channelName = NotificationChannels.dailyName,
  }) async {
    await _plugin.show(id, title, body, _details(channelId, channelName));
  }

  // ── Daily recurring ───────────────────────────────────────────────────────

  /// Schedule all daily reminders. Call once after user enables notifications.
  Future<void> scheduleDailyReminders() async {
    await _scheduleDailyAt(
      id: NotificationIds.morningCheckin,
      hour: 8,
      minute: 0,
      title: '🌅 Good morning!',
      body: 'How are you feeling today? Log your mood to start the day right.',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );

    await _scheduleDailyAt(
      id: NotificationIds.eveningMood,
      hour: 20,
      minute: 0,
      title: '🌙 Evening check-in',
      body: 'Take a moment to reflect — log your mood before the day ends.',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );

    await _scheduleDailyAt(
      id: NotificationIds.journalPrompt,
      hour: 21,
      minute: 0,
      title: '📓 Journal time',
      body: 'Write down your thoughts. Even a few lines can make a difference.',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );

    await _scheduleDailyAt(
      id: NotificationIds.mealReminder,
      hour: 13,
      minute: 0,
      title: '🥗 Lunch check',
      body: 'Don\'t forget to log your meals in your food diary.',
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
      id,
      title,
      body,
      _nextInstanceOfTime(hour, minute),
      _details(channelId, channelName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyReminders() async {
    await _plugin.cancel(NotificationIds.morningCheckin);
    await _plugin.cancel(NotificationIds.eveningMood);
    await _plugin.cancel(NotificationIds.journalPrompt);
    await _plugin.cancel(NotificationIds.mealReminder);
  }

  // ── Weekly ────────────────────────────────────────────────────────────────

  /// Schedule a weekly mood summary every Sunday at 18:00.
  Future<void> scheduleWeeklyMoodSummary() async {
    final now = tz.TZDateTime.now(tz.local);
    // Find next Sunday
    var daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday <= 0) daysUntilSunday += 7;
    final nextSunday = tz.TZDateTime(
        tz.local, now.year, now.month, now.day + daysUntilSunday, 18, 0);

    await _plugin.zonedSchedule(
      NotificationIds.weeklyMoodSummary,
      '📊 Your weekly mood summary',
      'Check your mood insights to see how your week went.',
      nextSunday,
      _details(NotificationChannels.wellnessId, NotificationChannels.wellnessName),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  /// Notify about a task due today.
  Future<void> notifyTaskDueToday(String taskId, String taskTitle) async {
    final id = NotificationIds.taskDueTodayBase + taskId.hashCode.abs() % 100;
    await show(
      id: id,
      title: '✅ Task due today',
      body: '"$taskTitle" is due today. Don\'t let it slip!',
      channelId: NotificationChannels.tasksId,
      channelName: NotificationChannels.tasksName,
    );
  }

  /// Notify about an overdue task.
  Future<void> notifyTaskOverdue(String taskId, String taskTitle) async {
    final id = NotificationIds.taskOverdueBase + taskId.hashCode.abs() % 100;
    await show(
      id: id,
      title: '⚠️ Overdue task',
      body: '"$taskTitle" is overdue. Tap to review your tasks.',
      channelId: NotificationChannels.tasksId,
      channelName: NotificationChannels.tasksName,
    );
  }

  // ── Goals ─────────────────────────────────────────────────────────────────

  /// Notify when a goal deadline is 3 days away.
  Future<void> notifyGoalDeadlineApproaching(
      String goalId, String goalTitle, int daysLeft) async {
    final id = NotificationIds.goalDeadlineBase + goalId.hashCode.abs() % 100;
    await show(
      id: id,
      title: '🎯 Goal deadline approaching',
      body: '"$goalTitle" is due in $daysLeft day${daysLeft == 1 ? '' : 's'}. Keep pushing!',
      channelId: NotificationChannels.goalsId,
      channelName: NotificationChannels.goalsName,
    );
  }

  /// Notify when a goal is completed.
  Future<void> notifyGoalCompleted(String goalTitle) async {
    await show(
      id: NotificationIds.goalDeadlineBase + 99,
      title: '🏆 Goal achieved!',
      body: 'You completed "$goalTitle". Amazing work!',
      channelId: NotificationChannels.goalsId,
      channelName: NotificationChannels.goalsName,
    );
  }

  // ── Events ────────────────────────────────────────────────────────────────

  /// Schedule a reminder 1 hour before an event.
  Future<void> scheduleEventReminder(
      String eventId, String eventTitle, DateTime eventTime) async {
    final reminderTime = eventTime.subtract(const Duration(hours: 1));
    if (reminderTime.isBefore(DateTime.now())) return;

    final id = NotificationIds.eventReminderBase + eventId.hashCode.abs() % 100;
    await _plugin.zonedSchedule(
      id,
      '📅 Upcoming event',
      '"$eventTitle" starts in 1 hour.',
      _scheduleAt(reminderTime),
      _details(NotificationChannels.eventsId, NotificationChannels.eventsName,
          importance: Importance.high, priority: Priority.high),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelEventReminder(String eventId) async {
    final id = NotificationIds.eventReminderBase + eventId.hashCode.abs() % 100;
    await _plugin.cancel(id);
  }

  // ── Subscription ─────────────────────────────────────────────────────────

  /// Schedule trial/subscription expiry warnings.
  Future<void> scheduleSubscriptionReminders(DateTime expiryDate) async {
    final threeDays = expiryDate.subtract(const Duration(days: 3));
    final oneDay = expiryDate.subtract(const Duration(days: 1));
    final now = DateTime.now();

    if (threeDays.isAfter(now)) {
      await _plugin.zonedSchedule(
        NotificationIds.trialExpiring3Days,
        '⏳ Your subscription expires soon',
        'Your Personal Haven access expires in 3 days. Renew to keep your haven.',
        _scheduleAt(threeDays),
        _details(NotificationChannels.subscriptionId,
            NotificationChannels.subscriptionName,
            importance: Importance.high,
            priority: Priority.high),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }

    if (oneDay.isAfter(now)) {
      await _plugin.zonedSchedule(
        NotificationIds.trialExpiring1Day,
        '🔔 Last day of your subscription',
        'Your access expires tomorrow. Subscribe now to avoid interruption.',
        _scheduleAt(oneDay),
        _details(NotificationChannels.subscriptionId,
            NotificationChannels.subscriptionName,
            importance: Importance.high,
            priority: Priority.high),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  /// Show an immediate notification when subscription expires.
  Future<void> notifySubscriptionExpired() async {
    await show(
      id: NotificationIds.subscriptionExpired,
      title: '🔒 Subscription expired',
      body: 'Renew your Personal Haven subscription to continue your journey.',
      channelId: NotificationChannels.subscriptionId,
      channelName: NotificationChannels.subscriptionName,
    );
  }

  // ── Streaks / encouragement ───────────────────────────────────────────────

  /// Encourage the user when they've journaled multiple days in a row.
  Future<void> notifyJournalStreak(int days) async {
    await show(
      id: NotificationIds.streakEncouragement,
      title: '🔥 $days-day journal streak!',
      body: 'You\'ve journaled $days days in a row. Keep the momentum going!',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );
  }

  /// Encourage after logging mood.
  Future<void> notifyMoodLogged(String emoji) async {
    await show(
      id: NotificationIds.eveningMood + 1,
      title: '$emoji Mood logged',
      body: 'Great job checking in with yourself today.',
      channelId: NotificationChannels.dailyId,
      channelName: NotificationChannels.dailyName,
    );
  }

  // ── Cancel all ────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
