import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class HavenAiSuggestion {
  final String label;
  final IconData icon;
  final String prompt;

  const HavenAiSuggestion({
    required this.label,
    required this.icon,
    required this.prompt,
  });
}

const havenAiQuickSuggestions = [
   HavenAiSuggestion(
    label: 'Add task',
    icon: Icons.task_alt,
    prompt: 'Add task',
  ),
  HavenAiSuggestion(
    label: 'Journal',
    icon: Icons.edit_note_outlined,
    prompt: 'Journal',
  ),
  HavenAiSuggestion(
    label: 'Goal',
    icon: Icons.flag_outlined,
    prompt: 'Create a goal',
  ),
  HavenAiSuggestion(
    label: 'Track spend',
    icon: Icons.payments_outlined,
    prompt: 'Track spend',
  ),
  HavenAiSuggestion(
    label: 'Plan event',
    icon: Icons.calendar_month_outlined,
    prompt: 'Plan event',
  ),
  HavenAiSuggestion(
    label: 'Shopping list',
    icon: Icons.shopping_basket_outlined,
    prompt: 'Shopping list',
  ),
  HavenAiSuggestion(
    label: 'Log mood',
    icon: Icons.mood_outlined,
    prompt: 'Log mood',
  ),
  HavenAiSuggestion(
    label: 'Reflect',
    icon: Icons.psychology_alt_outlined,
    prompt: 'Help me understand what is on my mind',
  ),
  HavenAiSuggestion(
    label: 'Organize',
    icon: Icons.account_tree_outlined,
    prompt: 'Help me organize some scattered thoughts',
  ),
  HavenAiSuggestion(
    label: 'Make a plan',
    icon: Icons.route_outlined,
    prompt: 'Help me make a realistic action plan',
  ),
  HavenAiSuggestion(
    label: 'Get unstuck',
    icon: Icons.spa_outlined,
    prompt: 'I feel stuck and need a little motivation',
  )
 
];

class HavenAiSuggestionRail extends StatelessWidget {
  const HavenAiSuggestionRail({
    super.key,
    required this.prompts,
    required this.onPromptSelected,
    this.quickSuggestions = havenAiQuickSuggestions,
  });

  final List<String> prompts;
  final List<HavenAiSuggestion> quickSuggestions;
  final ValueChanged<String> onPromptSelected;

  @override
  Widget build(BuildContext context) {
    final activePrompts = prompts;
    final itemCount = activePrompts.isNotEmpty
        ? activePrompts.length
        : quickSuggestions.length;

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (activePrompts.isNotEmpty) {
            final prompt = activePrompts[index];
            return ActionChip(
              onPressed: () => onPromptSelected(prompt),
              label: Text(prompt),
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              side: BorderSide(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
              labelStyle: const TextStyle(
                color: AppColors.primaryDark,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            );
          }

          final suggestion = quickSuggestions[index];
          return ActionChip(
            onPressed: () => onPromptSelected(suggestion.prompt),
            avatar: Icon(
              suggestion.icon,
              size: 17,
              color: AppColors.primaryDark,
            ),
            label: Text(suggestion.label),
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
            labelStyle: const TextStyle(
              color: AppColors.primaryDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }
}
