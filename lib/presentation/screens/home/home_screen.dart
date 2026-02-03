import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/utils/affirmations_helper.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/presentation/widgets/cards/mood_selection_dialog.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:personal_haven/providers/food_provider.dart';
import 'package:personal_haven/providers/goal_provider.dart';
import 'package:personal_haven/providers/mood_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _userName;
  String? _avatarUrl;
  bool _isLoading = true;
  String _todayAffirmation = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserData(),
      _loadAffirmation(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPrefsHelper.getInstance();
    setState(() {
      _userName = prefs.getFirstName() ?? prefs.getUsername() ?? 'Friend';
      _avatarUrl = prefs.getAvatarUrl();
    });
  }

  Future<void> _loadAffirmation() async {
    final affirmation = await AffirmationsHelper.getTodayAffirmation();
    setState(() => _todayAffirmation = affirmation);
  }

  Future<void> _showMoodSelector() async {
    final moodState = ref.read(moodProvider);
    final mood = await showDialog<MoodLog>(
      context: context,
      builder: (context) => MoodSelectionDialog(currentMood: moodState.todayMood),
    );

    if (mood != null) {
      await ref.read(moodProvider.notifier).logMood(
            mood.moodLevel,
            mood.moodEmoji,
            moodLabel: mood.moodLabel,
            notes: mood.notes,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood saved: ${mood.moodEmoji} ${mood.moodLabel ?? ""}'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);
    final weeklyMoodStats = ref.watch(weekMoodStatsProvider);
    final foodState = ref.watch(foodProvider);
    final goalState = ref.watch(goalProvider);
    final events = ref.watch(eventsProvider);
    final greeting = _getGreeting();

    if (_isLoading || moodState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFB8E6E3),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFB8E6E3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshAll,
                color: AppColors.primaryDark,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        '$greeting, $_userName!',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
   // Mood Card
                      _buildMoodCard(moodState.todayMood),
                      const SizedBox(height: 16),

                      // Today's Progress Summary
                      _buildTodayProgressCard(
                        moodState.todayMood,
                        foodState,
                        goalState,
                      ),
                      const SizedBox(height: 16),

                      // Affirmation
                      _buildAffirmationCard(),
                      const SizedBox(height: 16),
                   
                      // Active Goals Section
                      if (goalState.activeGoals.isNotEmpty) ...[
                        _buildGoalsCard(goalState),
                        const SizedBox(height: 16),
                      ],

                      // Food Entries Section
                      if (foodState.todayEntries.isNotEmpty) ...[
                        _buildFoodEntriesCard(foodState),
                        const SizedBox(height: 16),
                      ],

                      // Weekly Mood Summary
                      weeklyMoodStats.when(
                        data: (stats) {
                          if (stats.isEmpty) return const SizedBox.shrink();
                          return Column(
                            children: [
                              _buildWeeklyMoodSummary(stats),
                              const SizedBox(height: 16),
                            ],
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // Upcoming Events
                      _buildEventsCard(events),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      ref.read(moodProvider.notifier).loadTodayMood(),
      ref.read(foodProvider.notifier).loadEntries(),
      ref.read(goalProvider.notifier).loadGoals(),
    ]);
    ref.invalidate(weekMoodStatsProvider);
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.spa, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 8),
              const Text(
                'Personal Haven',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTap: () {
              // Navigate to profile
            },
            child: _avatarUrl != null
                ? CircleAvatar(
                    radius: 18,
                    backgroundImage: NetworkImage(_avatarUrl!),
                  )
                : CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    child: Text(
                      _userName?.isNotEmpty == true
                          ? _userName![0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodCard(MoodLog? todayMood) {
    return GestureDetector(
      onTap: _showMoodSelector,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: todayMood != null
              ? MoodOptions.getByEmoji(todayMood.moodEmoji)?.color ??
                  AppColors.primary
              : AppColors.primary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: todayMood != null
            ? Row(
                children: [
                  Text(todayMood.moodEmoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Today's Mood",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        Text(
                          todayMood.moodLabel ?? '',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        if (todayMood.notes != null && todayMood.notes!.isNotEmpty)
                          Text(
                            '"${todayMood.notes}"',
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.edit, color: Colors.white.withOpacity(0.7), size: 20),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('😊', style: TextStyle(fontSize: 28)),
                ],
              ),
      ),
    );
  }

  Widget _buildTodayProgressCard(
    MoodLog? todayMood,
    FoodState foodState,
    GoalState goalState,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Progress",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E40),
                ),
              ),
              Text(
                DateFormat('MMM d').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                emoji: todayMood?.moodEmoji ?? '😐',
                label: 'Mood',
                value: todayMood?.moodLabel ?? 'Not set',
                color: const Color(0xFFFF9A9E),
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                emoji: '🍽️',
                label: 'Calories',
                value: '${foodState.todayCalories}',
                color: const Color(0xFFFFB347),
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                emoji: '🎯',
                label: 'Goals',
                value: '${goalState.activeCount} active',
                color: const Color(0xFF667eea),
              ),
            ],
          ),
          if (foodState.todayEntries.isNotEmpty ||
              goalState.activeGoals.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                if (foodState.todayEntries.isNotEmpty)
                  Expanded(
                    child: Text(
                      '${foodState.todayEntries.length} meals logged',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                if (goalState.completedCount > 0)
                  Text(
                    '${goalState.completedCount} goals completed 🎉',
                    style: TextStyle(fontSize: 12, color: Colors.green.shade600),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required String emoji,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E40),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // FOOD ENTRIES CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildFoodEntriesCard(FoodState foodState) {
    final entries = foodState.todayEntries.take(4).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🍽️', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Today\'s Meals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E40),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB347).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${foodState.todayCalories} cal',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFB347),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Meal entries
          ...entries.map((entry) => _buildFoodEntryItem(entry)),

          if (foodState.todayEntries.length > 4) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to food diary
                },
                child: Text(
                  'View all ${foodState.todayEntries.length} entries →',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodEntryItem(FoodEntry entry) {
    final mealTypeEmojis = {
      'breakfast': '🌅',
      'lunch': '☀️',
      'dinner': '🌙',
      'snack': '🍎',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            mealTypeEmojis[entry.mealType] ?? '🍽️',
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.mealType[0].toUpperCase() + entry.mealType.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.calories ?? 0} cal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // GOALS CARD
  // ─────────────────────────────────────────────────────────────

  Widget _buildGoalsCard(GoalState goalState) {
    final goals = goalState.activeGoals.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Text('🎯', style: TextStyle(fontSize: 20)),
                  SizedBox(width: 8),
                  Text(
                    'Active Goals',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3E40),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${goalState.activeCount} active',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Goal items
          ...goals.map((goal) => _buildGoalItem(goal)),

          if (goalState.activeGoals.length > 3) ...[
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () {
                  // Navigate to goals
                },
                child: Text(
                  'View all ${goalState.activeCount} goals →',
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGoalItem(Goal goal) {
    final categoryEmojis = {
      'fitness': '💪',
      'finance': '💰',
      'learning': '📚',
      'personal': '🌟',
    };

    final progress = goal.progressPercentage;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                categoryEmojis[goal.category] ?? '🎯',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.toInt()}%',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF667eea),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.currentValue.toStringAsFixed(0)} / ${goal.targetValue.toStringAsFixed(0)} ${goal.unit}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade500,
                ),
              ),
              if (goal.daysRemaining >= 0)
                Text(
                  goal.daysRemaining == 0
                      ? 'Due today'
                      : '${goal.daysRemaining}d left',
                  style: TextStyle(
                    fontSize: 11,
                    color: goal.daysRemaining <= 7
                        ? Colors.orange
                        : Colors.grey.shade500,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // OTHER CARDS (Affirmation, Events, Weekly Mood)
  // ─────────────────────────────────────────────────────────────

  Widget _buildAffirmationCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A3AA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text(
                "Today's Affirmation",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$_todayAffirmation"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyMoodSummary(Map<String, int> weeklyMoodCounts) {
    final sortedMoods = weeklyMoodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text('📊', style: TextStyle(fontSize: 18)),
              SizedBox(width: 8),
              Text(
                'This Week\'s Moods',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedMoods.take(5).map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      '×${entry.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

 
 Widget _buildEventsCard(List events) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Upcoming Events',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3E40),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4ECDC4).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${events.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4ECDC4),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          const Text(
            'No upcoming events. Enjoy your day! 🌸',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          )
        else
          ...events.take(3).map((event) {
            // Format display time from event_time field
            String timeDisplay = _formatEventTime(event);

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ECDC4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.title ?? 'Untitled Event',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF2D3E40),
                          ),
                        ),
                        if (timeDisplay.isNotEmpty)
                          Text(
                            timeDisplay,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF666666),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
      ],
    ),
  );
}


/// Helper method to format event time for display
String _formatEventTime(dynamic event) {
  try {
    // Try eventTime field (String from database)
    if (event.eventTime != null && event.eventTime.toString().isNotEmpty) {
      return event.eventTime.toString();
    }
    
    // Try eventDate field
    if (event.eventDate != null) {
      final date = event.eventDate is DateTime 
          ? event.eventDate 
          : DateTime.tryParse(event.eventDate.toString());
      
      if (date != null) {
        return DateFormat('MMM d, h:mm a').format(date);
      }
    }
  } catch (_) {}
  
  return '';
}


  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}