import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/utils/affirmations_helper.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/presentation/widgets/cards/mood_selection_dialog.dart';
import 'package:personal_haven/providers/event_provider.dart';
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

  // Affirmation
  String _todayAffirmation = '';

  // Stats
  int _todayJournalCount = 0;
  int _todayMealCount = 0;
  int _weeklyJournalCount = 0;
  int _weeklyMealCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserData(),
      _loadAffirmation(),
      _loadStats(),
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

  Future<void> _loadStats() async {
    final prefs = await SharedPrefsHelper.getInstance();

    setState(() {
      _todayJournalCount = prefs.getTodayJournalCount() ?? 0;
      _todayMealCount = prefs.getTodayMealCount() ?? 0;
      _weeklyJournalCount = prefs.getWeeklyJournalCount() ?? 0;
      _weeklyMealCount = prefs.getWeeklyMealCount() ?? 0;
    });
  }

  Future<void> _showMoodSelector() async {
    final moodState = ref.read(moodProvider);

    final mood = await showDialog<MoodLog>(
      context: context,
      builder: (context) => MoodSelectionDialog(currentMood: moodState.todayMood),
    );

    if (mood != null) {
      // Use the provider to log mood - this persists the state!
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
            backgroundColor: const Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch the mood provider - this will automatically rebuild when mood changes
    final moodState = ref.watch(moodProvider);
    final weeklyMoodStats = ref.watch(weekMoodStatsProvider);
    final events = ref.watch(eventsProvider);
    final greeting = _getGreeting();

    // Show loading if initial data or mood is loading
    if (_isLoading || moodState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFB8E6E3),
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Show error if any
    if (moodState.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(moodState.error!),
            backgroundColor: Colors.red,
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFB8E6E3),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
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
            ),

            // Content
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  // Refresh all data
                  await ref.read(moodProvider.notifier).loadTodayMood();
                  ref.invalidate(weekMoodStatsProvider);
                  await _loadStats();
                },
                color: const Color(0xFF4ECDC4),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        '$greeting, $_userName!',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Mood Check-in Card
                      _buildMoodCard(moodState.todayMood),
                      const SizedBox(height: 16),

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

                      // Today's Progress Card
                      _buildProgressCard(moodState.todayMood),
                      const SizedBox(height: 16),

                      // Today's Affirmation
                      _buildAffirmationCard(),
                      const SizedBox(height: 16),

                      // Upcoming Events
                      _buildEventsCard(events),
                      const SizedBox(height: 16),

                      // Quick Stats
                      _buildQuickStats(weeklyMoodStats),
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

  // ─────────────────────────────────────────────────────────────
  // Mood Card
  // ─────────────────────────────────────────────────────────────

  Widget _buildMoodCard(MoodLog? todayMood) {
    return GestureDetector(
      onTap: _showMoodSelector,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: todayMood != null
              ? MoodOptions.getByEmoji(todayMood.moodEmoji)?.color ??
                  const Color(0xFF4ECDC4)
              : const Color(0xFF4ECDC4),
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
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        todayMood.moodEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Mood",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                          Text(
                            todayMood.moodLabel ?? '',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (todayMood.notes != null && todayMood.notes!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"${todayMood.notes}"',
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    'Tap to update',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'How are you feeling?',
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

  // ─────────────────────────────────────────────────────────────
  // Weekly Mood Summary
  // ─────────────────────────────────────────────────────────────

  Widget _buildWeeklyMoodSummary(Map<String, int> weeklyMoodCounts) {
    final sortedMoods = weeklyMoodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week\'s Moods',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E40),
                ),
              ),
              Icon(
                Icons.insights,
                color: Color(0xFF4ECDC4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: sortedMoods.take(5).map((entry) {
              final mood = MoodOptions.getByEmoji(entry.key);
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: mood?.color.withOpacity(0.2) ??
                      Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 6),
                    Text(
                      '×${entry.value}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3E40),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              // Navigate to mood analytics
            },
            child: const Text(
              'View Full Analytics →',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Progress Card
  // ─────────────────────────────────────────────────────────────

  Widget _buildProgressCard(MoodLog? todayMood) {
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
          const Text(
            "Today's Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E40),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.book_outlined,
                value: _todayJournalCount.toString(),
                label: 'Journals',
                color: const Color(0xFF4ECDC4),
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: Icons.restaurant_outlined,
                value: _todayMealCount.toString(),
                label: 'Meals',
                color: const Color(0xFFFFB347),
              ),
              const SizedBox(width: 24),
              _buildStatItem(
                icon: todayMood != null
                    ? Icons.sentiment_satisfied
                    : Icons.sentiment_neutral,
                value: todayMood?.moodEmoji ?? '—',
                label: 'Mood',
                color: const Color(0xFFFF9A9E),
                isEmoji: todayMood != null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          Text(
            'This week: $_weeklyJournalCount journals · $_weeklyMealCount meals',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF666666),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              // Navigate to full recap
            },
            child: const Text(
              'View Full Recap',
              style: TextStyle(
                color: Color(0xFF4ECDC4),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    bool isEmoji = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: isEmoji
              ? Text(value, style: const TextStyle(fontSize: 24))
              : Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 8),
        if (!isEmoji)
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E40),
            ),
          ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF666666),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Affirmation Card
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
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Text(
                "Today's Affirmation",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  // Share affirmation
                },
                child: Icon(
                  Icons.share_outlined,
                  color: Colors.white.withOpacity(0.8),
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '"$_todayAffirmation"',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Events Card
  // ─────────────────────────────────────────────────────────────

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

  // ─────────────────────────────────────────────────────────────
  // Quick Stats
  // ─────────────────────────────────────────────────────────────

  Widget _buildQuickStats(AsyncValue<Map<String, int>> weeklyMoodStats) {
    final moodCount = weeklyMoodStats.whenOrNull(data: (d) => d.length) ?? 0;

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.local_fire_department,
                  color: Color(0xFFFF6B6B),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '$_weeklyJournalCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3E40),
                  ),
                ),
                const Text(
                  'Week Streak',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: Color(0xFFFFD93D),
                  size: 28,
                ),
                const SizedBox(height: 8),
                Text(
                  '$moodCount',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3E40),
                  ),
                ),
                const Text(
                  'Moods Logged',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF666666),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}