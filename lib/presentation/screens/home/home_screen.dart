import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/utils/affirmations_helper.dart';
import 'package:personal_haven/core/utils/currency_formatter.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/data/models/event.dart';
import 'package:personal_haven/data/models/food_entry.dart';
import 'package:personal_haven/data/models/goal.dart';
import 'package:personal_haven/data/models/journal_entry.dart';
import 'package:personal_haven/data/models/mood_log.dart';
import 'package:personal_haven/data/models/task.dart';
import 'package:personal_haven/presentation/screens/home/widgets/haven_ai_chat_sheet.dart';
import 'package:personal_haven/presentation/screens/home/widgets/mood_caurosel_sheet.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:personal_haven/presentation/screens/subscription/subscription_screen.dart';
import 'package:personal_haven/presentation/widgets/common/task_complete_toggle.dart';
import 'package:personal_haven/providers/event_provider.dart';
import 'package:personal_haven/providers/food_provider.dart';
import 'package:personal_haven/providers/goal_provider.dart';
import 'package:personal_haven/providers/journal_provider.dart';
import 'package:personal_haven/providers/mood_provider.dart';
import 'package:personal_haven/providers/streak_provider.dart';
import 'package:personal_haven/providers/task_provider.dart';
import 'package:personal_haven/providers/subscription_provider.dart';

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
  late AnimationController _pulseController;

  final List<Animation<double>> _fadeAnims = [];
  final List<Animation<Offset>> _slideAnims = [];
  late Animation<double> _pulseAnim;

  static const int _cardCount = 6;

  @override
  void initState() {
    super.initState();

    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

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
    final upcomingEvents = _upcomingEventsFromNow(eventState.events);

    if (_isLoading || moodState.isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFB8E6E3),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.homeBackground,
      body: Stack(
        children: [
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
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 104),
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

                          // Tasks (conditional)
                          if (taskState.tasks.isNotEmpty) ...[
                            _animated(4, _buildTasksCard(taskState)),
                            const SizedBox(height: 14),
                          ],

                          // Journal (conditional)
                          if (journalState.entries.isNotEmpty) ...[
                            _animated(5, _buildJournalCard(journalState)),
                            const SizedBox(height: 14),
                          ],

                          // Active goals (conditional)
                          if (goalState.activeGoals.isNotEmpty) ...[
                            _animated(3, _buildGoalsCard(goalState)),
                            const SizedBox(height: 14),
                          ],

                          // Events
                          _animated(5, _buildEventsCard(upcomingEvents)),
                          const SizedBox(height: 14),

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
                            error: (_, _) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (!_showMoodOverlay)
            Positioned(right: 18, bottom: 18, child: _buildAssistantButton()),

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

  // ─── HEADER ───────────────────────────────────────────────────

  Widget _buildAssistantButton() {
    return Semantics(
      button: true,
      label: 'Open Haven assistant',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _openAssistant,
          child: Container(
            height: 54,
            padding: const EdgeInsets.fromLTRB(10, 0, 16, 0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.32),
                  blurRadius: 18,
                  offset: const Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                const Text(
                  'Ask Haven',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openAssistant() async {
    var subscriptionState = ref.read(subscriptionProvider);
    if (subscriptionState.isLoading) {
      await ref.read(subscriptionProvider.notifier).refresh();
      if (!mounted) return;
      subscriptionState = ref.read(subscriptionProvider);
    }

    final hasAccess = subscriptionState.hasFullAccess;

    if (!hasAccess) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const SubscriptionScreen()),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      backgroundColor: Colors.transparent,
      builder: (_) => const HavenAiChatSheet(),
    );
  }

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
                      color: context.colors.cardColor.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.spa, color: Colors.white, size: 18),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _userName ?? 'Friend',
                        style: TextStyle(
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
                Semantics(
                  button: true,
                  label:
                      '${streakState.currentStreak} day streak. Open streak summary and badges.',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _showStreakSummary(streakState),
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
                            color: context.colors.cardColor.withValues(
                              alpha: 0.28,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('🔥', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '${streakState.currentStreak}',
                                style: TextStyle(
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
                  ),
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
                      color: Colors.white.withValues(alpha: 0.6),
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
                          backgroundColor: context.colors.cardColor.withValues(
                            alpha: 0.3,
                          ),
                          child: Text(
                            _userName?.isNotEmpty == true
                                ? _userName![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
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
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.3),
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
              color: context.colors.cardColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.auto_awesome, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
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
                  style: TextStyle(
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

  void _showStreakSummary(StreakState streakState) {
    const badges = [
      (3, 'Spark', Icons.local_fire_department_outlined),
      (7, 'One Week', Icons.calendar_view_week_outlined),
      (14, 'Momentum', Icons.bolt_outlined),
      (30, 'Monthly', Icons.workspace_premium_outlined),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.78,
          ),
          decoration: BoxDecoration(
            color: sheetContext.colors.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheetContext.colors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('🔥', style: TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your streak',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            streakState.isNewStreakToday
                                ? 'Today is counted. Keep showing up.'
                                : 'You have checked in today.',
                            style: TextStyle(
                              fontSize: 13,
                              color: sheetContext.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStreakCard(streakState),
                const SizedBox(height: 24),
                const Text(
                  'Badges',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Badges unlock from your best streak.',
                  style: TextStyle(
                    fontSize: 12,
                    color: sheetContext.colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.75,
                  ),
                  itemCount: badges.length,
                  itemBuilder: (context, index) {
                    final (days, label, icon) = badges[index];
                    final isEarned = streakState.longestStreak >= days;

                    return Semantics(
                      label: isEarned
                          ? '$label badge earned for a $days day streak'
                          : '$label badge locked. Reach a $days day streak',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? AppColors.primary.withValues(alpha: 0.12)
                              : sheetContext.colors.cardColor2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isEarned
                                ? AppColors.primary.withValues(alpha: 0.45)
                                : sheetContext.colors.divider,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isEarned ? icon : Icons.lock_outline,
                              color: isEarned
                                  ? AppColors.primary
                                  : sheetContext.colors.textSecondary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    isEarned ? 'Earned' : '$days days',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: sheetContext.colors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakCard(StreakState streakState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
          Text(emoji, style: TextStyle(fontSize: 22)),
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
              color: context.colors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verticalDivider() {
    return Container(height: 40, width: 1, color: context.colors.divider);
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
          const SizedBox(height: 6),
          Text(
            _todayProgressCaption(journalState, taskState, goalState),
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              color: context.colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem(
                emoji: '🌱',
                label: _unitLabel(taskState.completedCount, 'task'),
                value: '${taskState.completedCount}',
                navigationLabel: 'Plan tasks',
                color: const Color(0xFFFF9A9E),
                onTap: () => _navigateTo(3),
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                emoji: '✍️',
                label: _unitLabel(
                  journalState?.todayEntries.length ?? 0,
                  'journal',
                ),
                value: '${journalState?.todayEntries.length ?? 0}',
                navigationLabel: 'Reflect',
                color: const Color(0xFFFFB347),
                onTap: () => _navigateTo(1),
              ),
              const SizedBox(width: 12),
              _buildStatItem(
                emoji: '💪',
                label: _unitLabel(goalState.activeCount, 'goal'),
                value: '${goalState.activeCount}',
                navigationLabel: 'Grow goals',
                color: const Color(0xFF667eea),
                onTap: () => _navigateTo(2),
              ),
            ],
          ),
          if (taskState.pendingCount > 0 ||
              goalState.activeGoals.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(height: 1, color: context.colors.cardColor2),
            const SizedBox(height: 10),
            Row(
              children: [
                if (taskState.pendingCount > 0)
                  Expanded(
                    child: Text(
                      '${taskState.pendingCount} ${_unitLabel(taskState.pendingCount, 'task')} pending',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textSecondary,
                      ),
                    ),
                  ),
                if (goalState.completedCount > 0)
                  Text(
                    '${goalState.completedCount} ${_unitLabel(goalState.completedCount, 'goal')} done 🎉',
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
    required String navigationLabel,
    required Color color,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              _buildAnimatedProgressIcon(emoji, color),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color.withValues(alpha: 0.9),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 18),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        navigationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 14,
                      color: color.withValues(alpha: 0.95),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedProgressIcon(String emoji, Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final t = _pulseController.value * math.pi * 2;
        final dy = math.sin(t) * 2.2;
        final angle = math.sin(t) * 0.045;
        final glow = 0.12 + (math.sin(t) + 1) * 0.06;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: glow),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: glow),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
        );
      },
    );
  }

  String _unitLabel(int count, String singular) {
    return count == 1 ? singular : '${singular}s';
  }

  String _todayProgressCaption(
    JournalState? journalState,
    TaskState taskState,
    GoalState goalState,
  ) {
    final journals = journalState?.todayEntries.length ?? 0;
    if (taskState.completedCount > 0) {
      return 'Nice momentum. Tap a section below to keep shaping your day.';
    }
    if (journals > 0) {
      return 'You have reflected today. Choose what to build on next.';
    }
    if (goalState.activeGoals.isNotEmpty) {
      return 'Your goals are ready. Tap below to make one small move.';
    }
    return 'Start small today. Tasks, journals, and goals are one tap away.';
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
            _viewAllButton(
              'View all ${goalState.activeCount} goals',
              () => _navigateTo(2),
            ),
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
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${progress.toInt()}%',
                style: TextStyle(
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
                backgroundColor: context.colors.cardColor2,
                valueColor: const AlwaysStoppedAnimation<Color>(goalColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${CurrencyFormatter.formatUnitAmount(goal.currentValue, goal.unit)} / ${CurrencyFormatter.formatUnitAmount(goal.targetValue, goal.unit)}',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.textSecondary,
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
                        : context.colors.textSecondary,
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
              final mood = MoodOptions.getByEmoji(entry.key);
              final label = mood?.label ?? _shortMoodLabel(entry.key);
              final color = mood?.color ?? AppColors.primary;

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.28)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(entry.key, style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.colors.textPrimary,
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
                backgroundColor: context.colors.cardColor2,
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
                  style: TextStyle(color: context.colors.textSecondary),
                ),
              ),
            )
          else
            ...pendingTasks.map((task) => _buildTaskItem(task)),
          if (taskState.pendingCount > 3)
            _viewAllButton(
              'View all ${taskState.pendingCount} tasks',
              () => _navigateTo(3),
            ),
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
          TaskCompleteToggle(
            isCompleted: task.isCompleted,
            color: color,
            size: 24,
            onTap: () => ref.read(taskProvider.notifier).toggleTask(task),
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
                    fontWeight: FontWeight.bold,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? context.colors.textSecondary
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
                      color: task.isOverdue
                          ? Colors.red
                          : context.colors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            width: 4,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  // ─── EVENTS CARD ──────────────────────────────────────────────

  Widget _buildEventsCard(List<Event> events) {
    return _glassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardHeader('Upcoming Events', '${events.length} events'),
          const SizedBox(height: 12),
          if (events.isEmpty)
            Text(
              'No upcoming events. Enjoy your day 🌸',
              style: TextStyle(
                fontSize: 13,
                color: context.colors.textSecondary,
              ),
            )
          else
            ...events.take(3).map((event) {
              final schedule = _formatEventSchedule(event);
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
                            event.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                event.isAllDay
                                    ? Icons.calendar_today_outlined
                                    : Icons.schedule_rounded,
                                size: 13,
                                color: AppColors.primaryDark,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  schedule,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          if (events.length > 3)
            _viewAllButton(
              'View all ${events.length} events',
              () => _navigateTo(3),
            ),
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
            style: TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            DateFormat('MMM d').format(entry.entryDate),
            style: TextStyle(fontSize: 11, color: context.colors.textSecondary),
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
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.foodName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  entry.mealType[0].toUpperCase() + entry.mealType.substring(1),
                  style: TextStyle(
                    fontSize: 11,
                    color: context.colors.textSecondary,
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
              color: context.colors.textSecondary,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.colors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: context.isDark ? 0.16 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _cardHeader(String title, String? trailing) {
    final icon = switch (title) {
      "Today's Progress" => Icons.insights_outlined,
      'Active Goals' => Icons.flag_outlined,
      "This Week's Moods" => Icons.mood_outlined,
      'Tasks' => Icons.task_alt_outlined,
      'Upcoming Events' => Icons.calendar_month_outlined,
      'Journal' => Icons.menu_book_outlined,
      "Today's Meals" => Icons.restaurant_outlined,
      _ => Icons.spa_outlined,
    };

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
        ),
        if (trailing != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trailing,
              style: TextStyle(
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
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ─── UTILITIES ────────────────────────────────────────────────

  void _navigateTo(int index) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => MainNavigationScreen(currentIndex: index),
        transitionsBuilder: (_, anim, _, child) =>
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

  String _formatEventSchedule(Event event) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
    );
    final dayLabel = eventDay == today
        ? 'Today'
        : eventDay == today.add(const Duration(days: 1))
        ? 'Tomorrow'
        : DateFormat('EEE, MMM d').format(event.eventDate);

    if (event.isAllDay || event.startTime == null) {
      return '$dayLabel · All day';
    }
    return '$dayLabel · ${DateFormat('h:mm a').format(event.startTime!)}';
  }

  List<Event> _upcomingEventsFromNow(List<Event> events) {
    final now = DateTime.now();
    final upcoming =
        events.where((event) => _eventVisibleUntil(event).isAfter(now)).toList()
          ..sort((a, b) => _eventSortTime(a).compareTo(_eventSortTime(b)));
    return upcoming;
  }

  DateTime _eventSortTime(Event event) {
    return event.startTime ?? event.eventDate;
  }

  DateTime _eventVisibleUntil(Event event) {
    if (event.endTime != null) return event.endTime!;
    if (!event.isAllDay && event.startTime != null) return event.startTime!;
    return DateTime(
      event.eventDate.year,
      event.eventDate.month,
      event.eventDate.day,
      23,
      59,
      59,
      999,
    );
  }

  String _shortMoodLabel(String value) {
    const labels = {
      '😀': 'Happy',
      '😃': 'Happy',
      '😄': 'Happy',
      '😁': 'Happy',
      '🙂': 'Good',
      '😡': 'Angry',
      '😠': 'Angry',
      '😞': 'Sad',
      '😭': 'Sad',
      '😟': 'Worried',
      '😨': 'Anxious',
    };
    return labels[value] ?? 'Mood';
  }
}
