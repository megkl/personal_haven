import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/providers/notification_provider.dart';
import 'package:personal_haven/services/notification_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Master toggle ──────────────────────────────────────────────
          _Card(children: [
            _SectionTitle('Notifications'),
            const SizedBox(height: 4),
            const Text(
              'Control which reminders Personal Haven sends you.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _ToggleRow(
              icon: Icons.notifications_active,
              title: 'All Notifications',
              subtitle: 'Master on/off switch',
              value: prefs.masterEnabled,
              onChanged: (v) async {
                await ref.read(notificationProvider.notifier).setMaster(v);
                if (v && context.mounted) {
                  final granted =
                      await NotificationService.instance.requestPermission();
                  if (!granted && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text(
                          'Please enable notifications in your device settings'),
                    ));
                  }
                }
              },
              highlight: true,
            ),
          ]),

          const SizedBox(height: 16),

          // ── Daily reminders ────────────────────────────────────────────
          _Card(children: [
            _SectionTitle('Daily Reminders'),
            const SizedBox(height: 12),
            _ToggleRow(
              icon: Icons.wb_sunny_outlined,
              title: 'Morning Check-in',
              subtitle: '8:00 AM — Start your day mindfully',
              value: prefs.masterEnabled && prefs.dailyReminders,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('dailyReminders', v),
            ),
            const Divider(height: 24),
            _ToggleRow(
              icon: Icons.mood,
              title: 'Evening Mood Log',
              subtitle: '8:00 PM — Reflect on your day',
              value: prefs.masterEnabled && prefs.moodReminder,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('moodReminder', v),
            ),
            const Divider(height: 24),
            _ToggleRow(
              icon: Icons.book_outlined,
              title: 'Journal Prompt',
              subtitle: '9:00 PM — Write your thoughts',
              value: prefs.masterEnabled && prefs.journalReminder,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('journalReminder', v),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Wellness ───────────────────────────────────────────────────
          _Card(children: [
            _SectionTitle('Wellness'),
            const SizedBox(height: 12),
            _ToggleRow(
              icon: Icons.restaurant_outlined,
              title: 'Meal Reminder',
              subtitle: '1:00 PM — Log your lunch',
              value: prefs.masterEnabled && prefs.dailyReminders,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('dailyReminders', v),
            ),
            const Divider(height: 24),
            _ToggleRow(
              icon: Icons.bar_chart,
              title: 'Weekly Mood Summary',
              subtitle: 'Every Sunday — Review your week',
              value: prefs.masterEnabled && prefs.weeklyInsights,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('weeklyInsights', v),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Tasks & Goals ──────────────────────────────────────────────
          _Card(children: [
            _SectionTitle('Tasks & Goals'),
            const SizedBox(height: 12),
            _ToggleRow(
              icon: Icons.check_circle_outline,
              title: 'Task Reminders',
              subtitle: 'Due today & overdue alerts',
              value: prefs.masterEnabled && prefs.taskReminders,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('taskReminders', v),
            ),
            const Divider(height: 24),
            _ToggleRow(
              icon: Icons.flag_outlined,
              title: 'Goal Deadlines',
              subtitle: 'Approaching & completion alerts',
              value: prefs.masterEnabled && prefs.goalReminders,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('goalReminders', v),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Events & Subscription ──────────────────────────────────────
          _Card(children: [
            _SectionTitle('Events & Subscription'),
            const SizedBox(height: 12),
            _ToggleRow(
              icon: Icons.event_outlined,
              title: 'Event Reminders',
              subtitle: '1 hour before each event',
              value: prefs.masterEnabled && prefs.eventReminders,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('eventReminders', v),
            ),
            const Divider(height: 24),
            _ToggleRow(
              icon: Icons.workspace_premium_outlined,
              title: 'Subscription Alerts',
              subtitle: 'Expiry warnings & renewal reminders',
              value: prefs.masterEnabled && prefs.subscriptionAlerts,
              enabled: prefs.masterEnabled,
              onChanged: (v) => ref
                  .read(notificationProvider.notifier)
                  .toggle('subscriptionAlerts', v),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;
  final bool highlight;

  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (highlight ? AppColors.primary : AppColors.primaryLight)
                  .withOpacity(highlight ? 0.15 : 1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon,
                color: highlight ? AppColors.primary : AppColors.primary,
                size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
