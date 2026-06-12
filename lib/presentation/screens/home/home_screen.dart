import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/utils/affirmations_helper.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:personal_haven/presentation/screens/home/widgets/mood_caurosel_sheet.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:personal_haven/providers/food_provider.dart';
import 'package:personal_haven/providers/goal_provider.dart';
import 'package:personal_haven/providers/journal_provider.dart';
import 'package:personal_haven/providers/mood_provider.dart';
import 'package:personal_haven/providers/streak_provider.dart';
import 'package:personal_haven/providers/task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  String? _userName;
  String? _avatarUrl;
  bool _isLoading = true;
  String _todayAffirmation = '';
  bool _showMoodOverlay = false;

  // Animation controllers
  late AnimationController _staggerController;
  late AnimationController _floatController;
  late AnimationController _pulseController;

  final List<Animation<double>> _fadeAnims = [];
  final List<Animation<Offset>> _slideAnims = [];
  late Animation<double> _floatAnim;
  late Animation<double> _pulseAnim;

  static const int _cardCount = 6;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -4, end: 4).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    _pulseAnim = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < _cardCount; i++) {
      final start = i * 0.12;
      final end = (start + 0.5).clamp(0.0, 1.0);

      _fadeAnims.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );

      _slideAnims.add(
        Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _staggerController,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        ),
      );
    }

    _loadInitialData();
  }

  @override
  void dispose() {
    _staggerController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([_loadUserData(), _loadAffirmation()]);
    if (!mounted) return;

    // Check mood before revealing home — wait for provider to settle
    await ref.read(moodProvider.notifier).loadTodayMood();
    if (!mounted) return;

    final moodState = ref.read(moodProvider);
    final needsMood = moodState.todayMood == null && !moodState.isLoading;

    setState(() {
      _isLoading = false;
      _showMoodOverlay = needsMood;
    });

    // Start home stagger only if no overlay is shown (or after overlay dismisses)
    if (!needsMood) _staggerController.forward();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPrefsHelper.getInstance();
    if (mounted) {
      setState(() {
        _userName =
            prefs.getUsername() ??
            prefs.getFullName() ??
            prefs.getFirstName() ??
            prefs.getUserEmail() ??
            'Friend';
        _avatarUrl = prefs.getAvatarUrl();
      });
    }
  }

  Future<void> _loadAffirmation() async {
    final affirmation = await AffirmationsHelper.getTodayAffirmation();
    if (mounted) setState(() => _todayAffirmation = affirmation);
  }

  /// Shows the mood overlay — used both for first-open check-in
  /// and when the user taps the mood card to edit.
  void _openMoodOverlay() {
    setState(() => _showMoodOverlay = true);
  }

  Future<void> _onMoodOverlaySaved(MoodOption mood, String? note) async {
    await ref
        .read(moodProvider.notifier)
        .logMood(mood.level, mood.emoji, moodLabel: mood.label, notes: note);
    if (!mounted) return;
    setState(() => _showMoodOverlay = false);
    if (_staggerController.value == 0) _staggerController.forward();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${mood.emoji}  Feeling ${mood.label} — saved!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _onMoodOverlaySkipped() {
    setState(() => _showMoodOverlay = false);
    if (_staggerController.value == 0) _staggerController.forward();
  }

  Widget _animated(int index, Widget child) {
    final i = index.clamp(0, _cardCount - 1);
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(position: _slideAnims[i], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final moodState = ref.watch(moodProvider);
    final weeklyMoodStats = ref.watch(weekMoodStatsProvider);
    final foodState = ref.watch(foodProvider);
    final goalState = ref.watch(goalProvider);
    final taskState = ref.watch(taskProvider);
    final eventState = ref.watch(eventProvider);
    final journalState = ref.watch(journalProvider);
    final streakAsync = ref.watch(streakProvider);
    final streakState = streakAsync.value ?? const StreakState();

    if (_isLoading || moodState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFB8E6E3),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFB8E6E3),
      body: Stack(
        children: [
          // ── Home content ───────────────────────────────────────
          _buildBackgroundDecor(),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(streakState),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshAll,
                    color: AppColors.primaryDark,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mood card
                          // _animated(0, _buildMoodCard(moodState.todayMood)),
                          // const SizedBox(height: 14),

                          // Affirmation
                          _animated(1, _buildAffirmationCard()),
                          const SizedBox(height: 14),

                          // Today's progress
                          _animated(
                            2,
                            _buildTodayProgressCard(
                              journalState,
                              taskState,
                              goalState,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Active goals (conditional)
                          if (goalState.activeGoals.isNotEmpty) ...[
                            _animated(3, _buildGoalsCard(goalState)),
                            const SizedBox(height: 14),
                          ],

                          // Tasks (conditional)
                          if (taskState.tasks.isNotEmpty) ...[
                            _animated(4, _buildTasksCard(taskState)),
                            const SizedBox(height: 14),
                          ],

                          // Events
                          _animated(5, _buildEventsCard(eventState.events)),
                          const SizedBox(height: 14),

                          // Journal (conditional)
                          if (journalState.entries.isNotEmpty) ...[
                            _animated(5, _buildJournalCard(journalState)),
                            const SizedBox(height: 14),
                          ],

                          // Food (conditional)
                          if (foodState.todayEntries.isNotEmpty) ...[
                            _animated(5, _buildFoodEntriesCard(foodState)),
                            const SizedBox(height: 8),
                          ],

                          // Weekly mood (conditional)
                          weeklyMoodStats.when(
                            data: (stats) {
                              if (stats.isEmpty) return const SizedBox.shrink();
                              return Column(
                                children: [
                                  _animated(3, _buildWeeklyMoodSummary(stats)),
                                  const SizedBox(height: 14),
                                ],
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Mood check-in overlay (seamless, no bottom sheet) ──
          if (_showMoodOverlay)
            Positioned.fill(
              child: MoodCheckInOverlay(
                existingMood: moodState.todayMood,
                canSkip: moodState.todayMood != null,
                onSaved: _onMoodOverlaySaved,
                onSkipped: _onMoodOverlaySkipped,
              ),
            ),
        ],
      ),
    );
  }

  // ─── BACKGROUND DECORATION ────────────────────────────────────

  Widget _buildBackgroundDecor() {
    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -60 + _floatAnim.value * 0.5,
              right: -40,
              child: _blob(160, const Color(0xFF4ECDC4), 0.18),
            ),
            Positioned(
              top: 180 + _floatAnim.value,
              left: -50,
              child: _blob(120, const Color(0xFFFFB347), 0.12),
            ),
            Positioned(
              bottom: 200 - _floatAnim.value * 0.6,
              right: -30,
              child: _blob(100, const Color(0xFFFF9A9E), 0.15),
            ),
          ],
        );
      },
    );
  }

  Widget _blob(double size, Color color, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(opacity),
      ),
    );
  }

  // ─── HEADER ───────────────────────────────────────────────────

  Widget _buildHeader(StreakState streakState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App logo + greeting
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.spa, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        _userName ?? 'Friend',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          Row(
            children: [
              // Streak badge
              if (streakState.currentStreak > 0)
                InkWell(
                    child: AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (context, child) => Transform.scale(
                        scale: streakState.isNewStreakToday
                            ? _pulseAnim.value
                            : 1.0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.28),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '${streakState.currentStreak}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    onTap: (){
                    }
                ),
              const SizedBox(width: 10),

              // Avatar
              GestureDetector(
                onTap: () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MainNavigationScreen(currentIndex: 4),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.6),
                      width: 2,
                    ),
                  ),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── MOOD CARD ────────────────────────────────────────────────

  Widget _buildMoodCard(MoodLog? todayMood) {
    final baseColor = todayMood != null
        ? MoodOptions.getByEmoji(todayMood.moodEmoji)?.color ??
              AppColors.primary
        : AppColors.primary;

    return GestureDetector(
      onTap: _openMoodOverlay,
      child: AnimatedBuilder(
        animation: _floatAnim,
        builder: (ctx, child) => Transform.translate(
          offset: Offset(0, _floatAnim.value * 0.4),
          child: child,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    baseColor.withOpacity(0.30),
                    baseColor.withOpacity(0.12),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.35)),
                boxShadow: [
                  BoxShadow(
                    color: baseColor.withOpacity(0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: todayMood != null
                  ? Row(
                      children: [
                        // Big emoji with glow
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: baseColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            todayMood.moodEmoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Mood",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.white.withOpacity(0.85),
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                todayMood.moodLabel ?? '',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              if (todayMood.notes != null &&
                                  todayMood.notes!.isNotEmpty)
                                Text(
                                  '"${todayMood.notes}"',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.edit_outlined,
                            color: Colors.white.withOpacity(0.9),
                            size: 16,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '🌸',
                            style: TextStyle(fontSize: 30),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'How are you feeling today?',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Tap to check in',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Log',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── AFFIRMATION CARD ─────────────────────────────────────────

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Today's Affirmation",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '"$_todayAffirmation"',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontStyle: FontStyle.italic,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── STREAK CARD ──────────────────────────────────────────────

  Widget _buildStreakCard(StreakState streakState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _streakTile(
            '🔥',
            '${streakState.currentStreak}',
            'Day Streak',
            const Color(0xFFFF6B6B),
          ),
          _verticalDivider(),
          _streakTile(
            '🏆',
            '${streakState.longestStreak}',
            'Best Streak',
            const Color(0xFFFFB347),
          ),
          _verticalDivider(),
          _streakTile(
            '📅',
            _getStreakDays(),
            'This Week',
            const Color(0xFF4ECDC4),
          ),
        ],
      ),
    );
  }

  String _getStreakDays() {
    final streak = ref.read(streakProvider).value;
    final current = streak?.currentStreak ?? 0;
    return '${math.min(current, 7)}/7';
  }

  Widget _streakTile(String emoji, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 40, width: 1, color: Colors.grey.shade200);
  }

  // ─── TODAY'S PROGRESS ─────────────────────────────────────────

  Widget _buildTodayProgressCard(
    JournalState? journalState,
    TaskState taskState,
    GoalState goalState,
  ) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            "Today's Progress",
            DateFormat('MMM d').format(DateTime.now()),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                emoji: '🌱',
                label: 'Tasks',
                value: '${taskState.completedCount}',
                color: const Color(0xFFFF9A9E),
                onTap: () => _navigateTo(3),
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                emoji: '✍️',
                label: 'Journals',
                value: '${journalState?.todayEntries.length ?? 0}',
                color: const Color(0xFFFFB347),
                onTap: () => _navigateTo(1),
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                emoji: '💪',
                label: 'Goals',
                value: '${goalState.activeCount}',
                color: const Color(0xFF667eea),
                onTap: () => _navigateTo(2),
              ),
            ],
          ),
          if (taskState.pendingCount > 0 ||
              goalState.activeGoals.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: Colors.grey.shade100),
            const SizedBox(height: 10),
            Row(
              children: [
                if (taskState.pendingCount > 0)
                  Expanded(
                    child: Text(
                      '${taskState.pendingCount} tasks pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                if (goalState.completedCount > 0)
                  Text(
                    '${goalState.completedCount} goals done 🎉',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade600,
                    ),
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
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.withOpacity(0.9),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── GOALS CARD ───────────────────────────────────────────────

  Widget _buildGoalsCard(GoalState goalState) {
    final goals = goalState.activeGoals.take(3).toList();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Active Goals', '${goalState.activeCount} active'),
          const SizedBox(height: 12),
          ...goals.map((goal) => _buildGoalItem(goal)),
          if (goalState.activeGoals.length > 3)
            _viewAllButton('View all ${goalState.activeCount} goals', () {}),
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
    const goalColor = Color(0xFF667eea);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                categoryEmojis[goal.category] ?? '🎯',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
                  color: goalColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(goalColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${goal.currentValue.toStringAsFixed(0)}/${goal.targetValue.toStringAsFixed(0)} ${goal.unit}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
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
                        : Colors.grey.shade400,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── WEEKLY MOOD SUMMARY ──────────────────────────────────────

  Widget _buildWeeklyMoodSummary(Map<String, int> weeklyMoodCounts) {
    final sorted = weeklyMoodCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader("This Week's Moods", null),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sorted.take(5).map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 5),
                    Text(
                      '×${entry.value}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
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

  // ─── TASKS CARD ───────────────────────────────────────────────

  Widget _buildTasksCard(TaskState taskState) {
    final pendingTasks = taskState.tasks
        .where((t) => !t.isCompleted)
        .take(3)
        .toList();
    final completionPct = taskState.completionPercentage;

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader(
            'Tasks',
            '${taskState.completedCount}/${taskState.tasks.length}',
          ),
          const SizedBox(height: 10),
          // Progress bar animated
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: completionPct / 100),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: Colors.grey.shade100,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF6BCB77),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (pendingTasks.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '🎉 All tasks completed!',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            )
          else
            ...pendingTasks.map((task) => _buildTaskItem(task)),
          if (taskState.pendingCount > 3)
            _viewAllButton('View all ${taskState.pendingCount} tasks', () {}),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Task task) {
    final priorityColors = {
      'urgent': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.grey,
    };
    final color = priorityColors[task.priority] ?? Colors.grey;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => ref.read(taskProvider.notifier).toggleTask(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted ? AppColors.primary : color,
                  width: 2,
                ),
                color: task.isCompleted
                    ? AppColors.primary
                    : Colors.transparent,
              ),
              child: task.isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? Colors.grey.shade400
                        : const Color(0xFF2D3E40),
                  ),
                ),
                if (task.dueDate != null)
                  Text(
                    task.isOverdue
                        ? 'Overdue'
                        : task.isDueToday
                        ? 'Due today'
                        : DateFormat('MMM d').format(task.dueDate!),
                    style: TextStyle(
                      fontSize: 11,
                      color: task.isOverdue ? Colors.red : Colors.grey.shade400,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: color.withOpacity(0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EVENTS CARD ──────────────────────────────────────────────

  Widget _buildEventsCard(List events) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Upcoming', '${events.length} events'),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              'No upcoming events. Enjoy your day 🌸',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            )
          else
            ...events.take(3).map((event) {
              final time = _formatEventTime(event);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A3AA)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
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
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3E40),
                            ),
                          ),
                          if (time.isNotEmpty)
                            Text(
                              time,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─── JOURNAL CARD ─────────────────────────────────────────────

  Widget _buildJournalCard(JournalState journalState) {
    final recentEntries = journalState.entries.take(2).toList();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Journal', '${journalState.todayEntries.length} today'),
          const SizedBox(height: 12),
          ...recentEntries.map((entry) => _buildJournalEntryItem(entry)),
          _viewAllButton(
            'View all ${journalState.entries.length} entries',
            () => _navigateTo(1),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalEntryItem(JournalEntry entry) {
    final categoryData = JournalCategories.getByName(entry.category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            entry.emoji ?? categoryData?.emoji ?? '📝',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.content,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d').format(entry.entryDate),
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // ─── FOOD CARD ────────────────────────────────────────────────

  Widget _buildFoodEntriesCard(FoodState foodState) {
    final entries = foodState.todayEntries.take(4).toList();

    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader("Today's Meals", '${foodState.todayCalories} cal'),
          const SizedBox(height: 12),
          ...entries.map((entry) => _buildFoodEntryItem(entry)),
          if (foodState.todayEntries.length > 4)
            _viewAllButton(
              'View all ${foodState.todayEntries.length} entries',
              () => _navigateTo(3),
            ),
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
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              ],
            ),
          ),
          Text(
            '${entry.calories ?? 0} cal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // ─── SHARED UI HELPERS ────────────────────────────────────────

  Widget _glassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, String? trailing) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3E40),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trailing,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _viewAllButton(String label, VoidCallback onTap) {
    return Center(
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        ),
        child: Text(
          '$label →',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ─── UTILITIES ────────────────────────────────────────────────

  void _navigateTo(int index) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainNavigationScreen(currentIndex: index),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 250),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤️';
    return 'Good Evening 🌙';
  }

  String _formatEventTime(dynamic event) {
    try {
      if (event.eventTime != null && event.eventTime.toString().isNotEmpty) {
        return event.eventTime.toString();
      }
      if (event.eventDate != null) {
        final date = event.eventDate is DateTime
            ? event.eventDate
            : DateTime.tryParse(event.eventDate.toString());
        if (date != null) return DateFormat('MMM d, h:mm a').format(date);
      }
    } catch (_) {}
    return '';
  }
}
