// ============================================================================
// progress_card.dart
// ============================================================================
import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class ProgressCard extends StatelessWidget {
  final int todayEntryCount;

  const ProgressCard({
    super.key,
    required this.todayEntryCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'You wrote $todayEntryCount journal ${todayEntryCount == 1 ? 'entry' : 'entries'} and logged\n3 meals',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {},
            child: const Text(
              'View Full Recap',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ============================================================================
// mood_check_in_card.dart
// ============================================================================
class MoodCheckInCard extends StatelessWidget {
  const MoodCheckInCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigate to mood tracking
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'How so you feeling?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text(
              '😊',
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      ),
    );
  }
}


// ============================================================================
// tasks_card.dart
// ============================================================================
class TasksCard extends StatelessWidget {
  const TasksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Urgent Tasks',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }
}