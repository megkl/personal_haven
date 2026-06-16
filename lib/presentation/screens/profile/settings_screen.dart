import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:personal_haven/providers/currency_provider.dart';
import 'package:personal_haven/providers/notification_provider.dart';
import 'package:personal_haven/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider).value ?? ThemeMode.system;
    final currencyCode =
        ref.watch(currencyProvider).value ?? CurrencyFormatter.defaultCode;
    final notificationPrefs = ref.watch(notificationProvider);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingRow(
                  context,
                  'Notifications',
                  Icons.notifications_outlined,
                  Switch(
                    value: notificationPrefs.masterEnabled,
                    onChanged: (value) => ref
                        .read(notificationProvider.notifier)
                        .setMaster(value),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                // Divider(color: colors.divider),
                // _buildSettingRow(
                //   context,
                //   'Dark Mode',
                //   Icons.dark_mode_outlined,
                //   Switch(
                //     value: isDark,
                //     onChanged: (_) =>
                //         ref.read(themeProvider.notifier).toggleDark(),
                //     activeThumbColor: AppColors.primary,
                //   ),
                // ),
                Divider(color: colors.divider),
                _buildSettingRow(
                  context,
                  'Currency',
                  Icons.payments_outlined,
                  DropdownButton<String>(
                    value: currencyCode,
                    underline: const SizedBox(),
                    dropdownColor: colors.cardColor,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    items: CurrencyFormatter.supported
                        .map(
                          (currency) => DropdownMenuItem(
                            value: currency.code,
                            child: Text(
                              '${currency.code} (${currency.symbol.trim()})',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        ref.read(currencyProvider.notifier).setCurrency(value);
                      }
                    },
                  ),
                ),
                // Divider(color: colors.divider),
                // _buildSettingRow(
                //   context,
                //   'Language',
                //   Icons.language_outlined,
                //   DropdownButton<String>(
                //     value: _language,
                //     underline: const SizedBox(),
                //     dropdownColor: colors.cardColor,
                //     style: TextStyle(color: colors.textPrimary, fontSize: 14),
                //     items: ['English', 'Spanish', 'French']
                //         .map(
                //           (lang) =>
                //               DropdownMenuItem(value: lang, child: Text(lang)),
                //         )
                //         .toList(),
                //     onChanged: (value) {
                //       if (value != null) setState(() => _language = value);
                //     },
                //   ),
                // ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose what Personal Haven can remind you about.',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
                const SizedBox(height: 12),
                // Row(
                //   children: [
                //     Expanded(
                //       child: OutlinedButton.icon(
                //         onPressed: () => _sendTestNotification(context),
                //         icon: const Icon(Icons.notifications_active_outlined),
                //         label: const Text('Test now'),
                //         style: OutlinedButton.styleFrom(
                //           foregroundColor: AppColors.primary,
                //           side: BorderSide(color: AppColors.primary),
                //           padding: const EdgeInsets.symmetric(vertical: 12),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(14),
                //           ),
                //         ),
                //       ),
                //     ),
                //     const SizedBox(width: 10),
                //     Expanded(
                //       child: OutlinedButton.icon(
                //         onPressed: () => _scheduleTestNotification(context),
                //         icon: const Icon(Icons.schedule_outlined),
                //         label: const Text('Test 5 sec'),
                //         style: OutlinedButton.styleFrom(
                //           foregroundColor: AppColors.primary,
                //           side: BorderSide(color: AppColors.primary),
                //           padding: const EdgeInsets.symmetric(vertical: 12),
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(14),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ],
                // ),
                const SizedBox(height: 12),
                _notificationToggle(
                  context,
                  title: 'Daily reminders',
                  subtitle: 'Mood, journal, and wellness nudges',
                  icon: Icons.today_outlined,
                  value: notificationPrefs.dailyReminders,
                  enabled: notificationPrefs.masterEnabled,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('dailyReminders', value),
                ),
                _notificationToggle(
                  context,
                  title: 'Mood check-ins',
                  subtitle: 'Mood prompts notification',
                  icon: Icons.mood_outlined,
                  value: notificationPrefs.moodReminder,
                  enabled:
                      notificationPrefs.masterEnabled &&
                      notificationPrefs.dailyReminders,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('moodReminder', value),
                ),
                _notificationTimeRow(
                  context,
                  title: 'Mood check-in time',
                  minuteOfDay: notificationPrefs.morningReminderMinute,
                  enabled:
                      notificationPrefs.masterEnabled &&
                      notificationPrefs.dailyReminders &&
                      notificationPrefs.moodReminder,
                  onTap: () => _pickNotificationTime(
                    context,
                    key: 'morningReminderMinute',
                    minuteOfDay: notificationPrefs.morningReminderMinute,
                  ),
                ),
                // _notificationTimeRow(
                //   context,
                //   title: 'Evening check-in',
                //   minuteOfDay: notificationPrefs.eveningReminderMinute,
                //   enabled:
                //       notificationPrefs.masterEnabled &&
                //       notificationPrefs.dailyReminders &&
                //       notificationPrefs.moodReminder,
                //   onTap: () => _pickNotificationTime(
                //     context,
                //     key: 'eveningReminderMinute',
                //     minuteOfDay: notificationPrefs.eveningReminderMinute,
                //   ),
                // ),
                _notificationToggle(
                  context,
                  title: 'Journal prompts',
                  subtitle: 'A gentle journal writing reminder',
                  icon: Icons.edit_note_outlined,
                  value: notificationPrefs.journalReminder,
                  enabled:
                      notificationPrefs.masterEnabled &&
                      notificationPrefs.dailyReminders,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('journalReminder', value),
                ),
                _notificationTimeRow(
                  context,
                  title: 'Journal time',
                  minuteOfDay: notificationPrefs.journalReminderMinute,
                  enabled:
                      notificationPrefs.masterEnabled &&
                      notificationPrefs.dailyReminders &&
                      notificationPrefs.journalReminder,
                  onTap: () => _pickNotificationTime(
                    context,
                    key: 'journalReminderMinute',
                    minuteOfDay: notificationPrefs.journalReminderMinute,
                  ),
                ),
                // _notificationTimeRow(
                //   context,
                //   title: 'Meal reminder',
                //   minuteOfDay: notificationPrefs.mealReminderMinute,
                //   enabled:
                //       notificationPrefs.masterEnabled &&
                //       notificationPrefs.dailyReminders,
                //   onTap: () => _pickNotificationTime(
                //     context,
                //     key: 'mealReminderMinute',
                //     minuteOfDay: notificationPrefs.mealReminderMinute,
                //   ),
                // ),
                _notificationToggle(
                  context,
                  title: 'Task reminders',
                  subtitle: 'Due today and overdue task alerts',
                  icon: Icons.task_alt_outlined,
                  value: notificationPrefs.taskReminders,
                  enabled: notificationPrefs.masterEnabled,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('taskReminders', value),
                ),
                _notificationToggle(
                  context,
                  title: 'Goal reminders',
                  subtitle: 'Goal deadlines and completions',
                  icon: Icons.flag_outlined,
                  value: notificationPrefs.goalReminders,
                  enabled: notificationPrefs.masterEnabled,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('goalReminders', value),
                ),
                _notificationToggle(
                  context,
                  title: 'Event reminders',
                  subtitle: 'Upcoming event reminders',
                  icon: Icons.event_outlined,
                  value: notificationPrefs.eventReminders,
                  enabled: notificationPrefs.masterEnabled,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('eventReminders', value),
                ),
                _notificationToggle(
                  context,
                  title: 'Weekly insights',
                  subtitle: 'Weekly mood summary',
                  icon: Icons.insights_outlined,
                  value: notificationPrefs.weeklyInsights,
                  enabled: notificationPrefs.masterEnabled,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('weeklyInsights', value),
                ),
                _notificationTimeRow(
                  context,
                  title: 'Weekly summary time',
                  minuteOfDay: notificationPrefs.weeklyInsightsMinute,
                  enabled:
                      notificationPrefs.masterEnabled &&
                      notificationPrefs.weeklyInsights,
                  onTap: () => _pickNotificationTime(
                    context,
                    key: 'weeklyInsightsMinute',
                    minuteOfDay: notificationPrefs.weeklyInsightsMinute,
                  ),
                ),
                _notificationToggle(
                  context,
                  title: 'Subscription alerts',
                  subtitle: 'Expiry and renewal reminders',
                  icon: Icons.workspace_premium_outlined,
                  value: notificationPrefs.subscriptionAlerts,
                  enabled: notificationPrefs.masterEnabled,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('subscriptionAlerts', value),
                  showDivider: false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Theme mode selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _themeOption(
                      context,
                      label: 'Light',
                      icon: Icons.light_mode_outlined,
                      selected: themeMode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(width: 10),
                    _themeOption(
                      context,
                      label: 'Dark',
                      icon: Icons.dark_mode_outlined,
                      selected: themeMode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.dark),
                    ),
                    const SizedBox(width: 10),
                    _themeOption(
                      context,
                      label: 'System',
                      icon: Icons.brightness_auto_outlined,
                      selected: themeMode == ThemeMode.system,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    String title,
    IconData icon,
    Widget trailing,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: colors.textPrimary),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _notificationToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    final colors = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        if (showDivider) Divider(color: colors.divider, height: 16),
      ],
    );
  }

  Widget _notificationTimeRow(
    BuildContext context, {
    required String title,
    required int minuteOfDay,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(48, 0, 0, 10),
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.cardColor2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.divider),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.schedule_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                Text(
                  _formatMinuteOfDay(context, minuteOfDay),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickNotificationTime(
    BuildContext context, {
    required String key,
    required int minuteOfDay,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60),
    );
    if (picked == null) return;
    await ref
        .read(notificationProvider.notifier)
        .setReminderMinute(key, picked.hour * 60 + picked.minute);
  }

  // Future<void> _sendTestNotification(BuildContext context) async {
  //   final granted = await ref
  //       .read(notificationProvider.notifier)
  //       .sendTestNotification();
  //   if (!context.mounted) return;
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         granted
  //             ? 'Test notification sent'
  //             : 'Notification permission was not granted',
  //       ),
  //       backgroundColor: granted ? AppColors.primary : Colors.red,
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

  // Future<void> _scheduleTestNotification(BuildContext context) async {
  //   final granted = await ref
  //       .read(notificationProvider.notifier)
  //       .scheduleTestNotification();
  //   if (!context.mounted) return;
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(
  //         granted
  //             ? 'Scheduled test notification for 5 seconds from now'
  //             : 'Notification or exact alarm permission was not granted',
  //       ),
  //       backgroundColor: granted ? AppColors.primary : Colors.red,
  //       behavior: SnackBarBehavior.floating,
  //     ),
  //   );
  // }

  String _formatMinuteOfDay(BuildContext context, int minuteOfDay) {
    return TimeOfDay(
      hour: minuteOfDay ~/ 60,
      minute: minuteOfDay % 60,
    ).format(context);
  }

  Widget _themeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : colors.cardColor2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : colors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : colors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
