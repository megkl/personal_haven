import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/providers/budget_provider.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:personal_haven/providers/food_provider.dart';
import 'package:personal_haven/providers/goal_provider.dart';
import 'package:personal_haven/providers/insights_settings_provider.dart';
import 'package:personal_haven/providers/journal_provider.dart';
import 'package:personal_haven/providers/mood_provider.dart';
import 'package:personal_haven/providers/task_provider.dart';

class MoodInsightsScreen extends ConsumerWidget {
  const MoodInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodState = ref.watch(moodProvider);
    final taskState = ref.watch(taskProvider);
    final goalState = ref.watch(goalProvider);
    final eventState = ref.watch(eventProvider);
    final journalState = ref.watch(journalProvider);
    final foodState = ref.watch(foodProvider);
    final transactionState = ref.watch(transactionProvider);
    final insightsSettings = ref.watch(insightsSettingsProvider);
    final weekMoods = moodState.weekMoods;
    final totalMoods = weekMoods.length;

    final moodCounts = <String, int>{};
    for (final mood in weekMoods) {
      moodCounts[mood.moodEmoji] = (moodCounts[mood.moodEmoji] ?? 0) + 1;
    }

    final sortedMoodEntries = moodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final moodStats = sortedMoodEntries.take(4).map((entry) {
      final option = MoodOptions.getByEmoji(entry.key);
      return {
        'emoji': entry.key,
        'label': option?.label ?? 'Mood',
        'percentage': totalMoods > 0
            ? '${((entry.value / totalMoods) * 100).round()}%'
            : '0%',
        'color': option?.color ?? AppColors.primary,
      };
    }).toList();

    while (moodStats.length < 4) {
      moodStats.add({
        'emoji': '—',
        'label': 'No data',
        'percentage': '0%',
        'color': context.colors.textSecondary,
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Insights'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: context.colors.cardColor,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Everything at a glance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${insightsSettings.budgetReviewCadence.label} budget reviews are enabled in Settings.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _buildInsightTile(
                      context,
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Tasks',
                      value:
                          '${taskState.completedCount}/${taskState.tasks.length}',
                    ),
                    _buildInsightTile(
                      context,
                      icon: Icons.flag_outlined,
                      label: 'Goals',
                      value:
                          '${goalState.completedCount}/${goalState.totalCount}',
                    ),
                    _buildInsightTile(
                      context,
                      icon: Icons.event_available_outlined,
                      label: 'Events',
                      value: '${eventState.upcomingCount} upcoming',
                    ),
                    _buildInsightTile(
                      context,
                      icon: Icons.auto_stories_outlined,
                      label: 'Journal',
                      value: '${journalState.thisWeekEntries.length} this week',
                    ),
                    // _buildInsightTile(
                    //   context,
                    //   icon: Icons.restaurant_menu_rounded,
                    //   label: 'Food',
                    //   value: '${foodState.todayCalories} cal',
                    // ),
                    _buildInsightTile(
                      context,
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Budget',
                      value:
                          '${transactionState.recentTransactions.length} entries',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood This Week',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 24),
                if (moodState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (totalMoods == 0)
                  Center(
                    child: Text(
                      'No moods saved yet. Log your mood from Home to start tracking.',
                      style: TextStyle(color: context.colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: moodStats.map((data) {
                      return _buildMoodStat(
                        context,
                        data['emoji'] as String,
                        data['label'] as String,
                        data['percentage'] as String,
                        data['color'] as Color,
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: context.colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mood History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                if (moodState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (weekMoods.isEmpty)
                  Center(
                    child: Text(
                      'No mood logs available yet.',
                      style: TextStyle(color: context.colors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ListView.separated(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: weekMoods.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final mood = weekMoods[index];
                      return _buildMoodHistoryItem(context, mood);
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = context.colors;

    return Container(
      width: 142,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(color: colors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodStat(
    BuildContext context,
    String emoji,
    String label,
    String percentage,
    Color color,
  ) {
    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 32, color: color)),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: context.colors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildMoodHistoryItem(BuildContext context, MoodLog mood) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color:
                  MoodOptions.getByEmoji(
                    mood.moodEmoji,
                  )?.color.withValues(alpha: 0.12) ??
                  AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(mood.moodEmoji, style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mood.moodLabel ??
                      MoodOptions.getByEmoji(mood.moodEmoji)?.label ??
                      'Mood',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE, MMM d · h:mm a').format(mood.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
                if (mood.notes != null && mood.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    mood.notes!,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
