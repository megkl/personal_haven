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
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider).value ?? ThemeMode.system;
    final currencyCode =
        ref.watch(currencyProvider).value ?? CurrencyFormatter.defaultCode;
    final notificationPrefs = ref.watch(notificationProvider);
    final isDark = themeMode == ThemeMode.dark;
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
                Divider(color: colors.divider),
                _buildSettingRow(
                  context,
                  'Dark Mode',
                  Icons.dark_mode_outlined,
                  Switch(
                    value: isDark,
                    onChanged: (_) =>
                        ref.read(themeProvider.notifier).toggleDark(),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
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
                Divider(color: colors.divider),
                _buildSettingRow(
                  context,
                  'Language',
                  Icons.language_outlined,
                  DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    dropdownColor: colors.cardColor,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    items: ['English', 'Spanish', 'French']
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _language = value);
                    },
                  ),
                ),
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
                  subtitle: 'Morning and evening mood prompts',
                  icon: Icons.mood_outlined,
                  value: notificationPrefs.moodReminder,
                  enabled:
                      notificationPrefs.masterEnabled &&
                      notificationPrefs.dailyReminders,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('moodReminder', value),
                ),
                _notificationToggle(
                  context,
                  title: 'Journal prompts',
                  subtitle: 'A gentle evening writing reminder',
                  icon: Icons.edit_note_outlined,
                  value: notificationPrefs.journalReminder,
                  enabled:
                      notificationPrefs.masterEnabled &&
                      notificationPrefs.dailyReminders,
                  onChanged: (value) => ref
                      .read(notificationProvider.notifier)
                      .toggle('journalReminder', value),
                ),
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
