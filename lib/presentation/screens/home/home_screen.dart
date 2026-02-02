import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/utils/affirmations_helper.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/data/repositories/mood_repository.dart';
import 'package:personal_haven/presentation/widgets/cards/mood_selection_dialog.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:personal_haven/providers/task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _userName;
  String? _userEmail;
  String? _avatarUrl;
  bool _isLoading = true;


  MoodLog? _todayMood;
  Map<String, int> _weeklyMoodCounts = {};

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
    //_loadUserData();
    _loadAllData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPrefsHelper.getInstance();

    setState(() {
      _userName = prefs.getFirstName() ?? prefs.getUsername() ?? 'Friend';
      _userEmail = prefs.getUserEmail();
      _avatarUrl = prefs.getAvatarUrl();
      _isLoading = false;
    });
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadUserData(),
      _loadMoodData(),
      _loadAffirmation(),
      _loadStats(),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadMoodData() async {
    final moodRepo = await MoodRepository();
    final prefs = await SharedPrefsHelper.getInstance();
    final todayMood = await moodRepo.getTodayMood(prefs.getUserId()!);
    final weeklyCounts = await moodRepo.getWeekMoodStats(prefs.getUserId()!);

    setState(() {
      _todayMood = todayMood;
      _weeklyMoodCounts = weeklyCounts;
    });
  }

  Future<void> _loadAffirmation() async {
    final affirmation = await AffirmationsHelper.getTodayAffirmation();
    setState(() => _todayAffirmation = affirmation);
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPrefsHelper.getInstance();

    // Get today's counts
    final todayJournals = prefs.getTodayJournalCount() ?? 0;
    final todayMeals = prefs.getTodayMealCount() ?? 0;

    // Get weekly counts
    final weeklyJournals = prefs.getWeeklyJournalCount() ?? 0;
    final weeklyMeals = prefs.getWeeklyMealCount() ?? 0;

    setState(() {
      _todayJournalCount = todayJournals;
      _todayMealCount = todayMeals;
      _weeklyJournalCount = weeklyJournals;
      _weeklyMealCount = weeklyMeals;
    });
  }

  Future<void> _showMoodSelector() async {
    final prefs = await SharedPrefsHelper.getInstance();
    final mood = await showDialog<MoodLog>(
      context: context,
      builder: (context) => MoodSelectionDialog(currentMood: _todayMood),
    );

    if (mood != null) {
      final moodRepo =  MoodRepository();
      await moodRepo.logMood(
        userId: mood.userId,
        moodLevel: mood.moodLevel,
        moodEmoji: mood.moodEmoji,
        notes: mood.notes,
      );
      setState(() => _todayMood = mood);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood saved: ${mood.moodEmoji} ${mood.moodEmoji}'),
            backgroundColor: const Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      // Reload mood data for weekly counts
      await _loadMoodData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final greeting = _getGreeting();

    if (_isLoading) {
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
              child: SingleChildScrollView(
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
                    _buildMoodCard(),
                    const SizedBox(height: 16),

                    // Weekly Mood Summary (if has data)
                    if (_weeklyMoodCounts.isNotEmpty) ...[
                      _buildWeeklyMoodSummary(),
                      const SizedBox(height: 16),
                    ],

                    // Today's Progress Card
                    _buildProgressCard(),
                    const SizedBox(height: 16),

                    // Today's Affirmation
                    _buildAffirmationCard(),
                    const SizedBox(height: 16),

                    // Upcoming Events
                    _buildEventsCard(events),
                    const SizedBox(height: 16),

                    // Quick Stats
                    _buildQuickStats(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodCard() {
    return GestureDetector(
      onTap: _showMoodSelector,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _todayMood != null
              ? MoodOptions.getByEmoji(_todayMood!.moodEmoji)?.color ??
                  const Color(0xFF4ECDC4)
              : const Color(0xFF4ECDC4),
          borderRadius: BorderRadius.circular(16),
        ),
        child: _todayMood != null
            ? Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _todayMood!.moodEmoji,
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
                            _todayMood!.moodEmoji,
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
                  if (_todayMood!.notes != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '"${_todayMood!.notes}"',
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

  Widget _buildWeeklyMoodSummary() {
    final sortedMoods = _weeklyMoodCounts.entries.toList()
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
  // Progress Card - Real data from storage
  // ─────────────────────────────────────────────────────────────

  Widget _buildProgressCard() {
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
                icon: _todayMood != null
                    ? Icons.sentiment_satisfied
                    : Icons.sentiment_neutral,
                value: _todayMood?.moodEmoji ?? '—',
                label: 'Mood',
                color: const Color(0xFFFF9A9E),
                isEmoji: _todayMood != null,
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
  // Affirmation Card - Daily random
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
                            event.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF2D3E40),
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(event.time),
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

  // ─────────────────────────────────────────────────────────────
  // Quick Stats
  // ─────────────────────────────────────────────────────────────

  Widget _buildQuickStats() {
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
                  '${_weeklyMoodCounts.length}',
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