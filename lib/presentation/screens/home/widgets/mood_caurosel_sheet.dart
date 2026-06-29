import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/data/models/mood_log.dart';

class MoodCheckInOverlay extends StatefulWidget {
  final void Function(MoodOption mood, String? note) onSaved;
  final VoidCallback? onSkipped;
  final bool canSkip;
  final MoodLog? existingMood;

  const MoodCheckInOverlay({
    super.key,
    required this.onSaved,
    this.onSkipped,
    this.canSkip = false,
    this.existingMood,
  });

  @override
  State<MoodCheckInOverlay> createState() => _MoodCheckInOverlayState();
}

class _MoodCheckInOverlayState extends State<MoodCheckInOverlay>
    with TickerProviderStateMixin {
  late final List<MoodOption> _moods;
  late final PageController _pageController;
  late final AnimationController _entranceController;
  late final AnimationController _exitController;
  late final TextEditingController _noteController;

  late int _selectedIndex;
  double _moodPosition = 0;
  bool _showNote = false;
  bool _isExiting = false;

  @override
  void initState() {
    super.initState();
    _moods = [...MoodOptions.all]
      ..sort((a, b) {
        final levelComparison = a.level.compareTo(b.level);
        if (levelComparison != 0) return levelComparison;
        return MoodOptions.all.indexOf(a).compareTo(MoodOptions.all.indexOf(b));
      });

    final existingIndex = widget.existingMood == null
        ? -1
        : _moods.indexWhere(
            (mood) => mood.emoji == widget.existingMood!.moodEmoji,
          );
    final neutralIndex = _moods.indexWhere((mood) => mood.label == 'Neutral');
    _selectedIndex = existingIndex >= 0 ? existingIndex : neutralIndex;
    _moodPosition = _selectedIndex.toDouble();

    _pageController = PageController(
      viewportFraction: 0.52,
      initialPage: _selectedIndex,
    )..addListener(_syncMoodPosition);
    _noteController = TextEditingController(
      text: widget.existingMood?.notes ?? '',
    );
    _showNote = _noteController.text.isNotEmpty;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 460),
    )..forward();
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
  }

  @override
  void dispose() {
    _pageController
      ..removeListener(_syncMoodPosition)
      ..dispose();
    _noteController.dispose();
    _entranceController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _syncMoodPosition() {
    if (!_pageController.hasClients ||
        !_pageController.position.haveDimensions) {
      return;
    }
    final page = _pageController.page ?? _selectedIndex.toDouble();
    final nextIndex = page.round().clamp(0, _moods.length - 1);
    if ((_moodPosition - page).abs() < 0.001 && nextIndex == _selectedIndex) {
      return;
    }
    setState(() {
      _moodPosition = page.clamp(0, (_moods.length - 1).toDouble());
      _selectedIndex = nextIndex;
    });
  }

  void _selectMood(double value) {
    final index = value.round().clamp(0, _moods.length - 1);
    setState(() {
      _moodPosition = value;
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _finish(VoidCallback callback) async {
    if (_isExiting) return;
    _isExiting = true;
    FocusScope.of(context).unfocus();
    await _exitController.forward();
    if (mounted) callback();
  }

  Future<void> _save() {
    return _finish(() {
      final note = _noteController.text.trim();
      widget.onSaved(_moods[_selectedIndex], note.isEmpty ? null : note);
    });
  }

  Future<void> _skip() {
    return _finish(() => widget.onSkipped?.call());
  }

  @override
  Widget build(BuildContext context) {
    final selected = _moods[_selectedIndex];
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedBuilder(
      animation: Listenable.merge([_entranceController, _exitController]),
      builder: (context, child) {
        final entrance = CurvedAnimation(
          parent: _entranceController,
          curve: Curves.easeOutCubic,
        ).value;
        final exit =
            1 -
            CurvedAnimation(
              parent: _exitController,
              curve: Curves.easeIn,
            ).value;

        return Opacity(
          opacity: entrance * exit,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - entrance)),
            child: Transform.scale(scale: 0.97 + (0.03 * exit), child: child),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        color: Color.alphaBlend(
          selected.color.withValues(alpha: context.isDark ? 0.16 : 0.12),
          context.colors.homeBackground,
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + keyboardInset),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _buildTopBar(),
                        const SizedBox(height: 18),
                        _buildTitle(),
                        const Spacer(),
                        _buildCarousel(),
                        const SizedBox(height: 12),
                        _buildMoodLabel(selected),
                        const SizedBox(height: 20),
                        _buildMoodSlider(selected),
                        const Spacer(),
                        _buildNoteSection(),
                        const SizedBox(height: 14),
                        _buildSaveButton(),
                        if (widget.canSkip) _buildSkipButton(),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.spa_rounded,
            color: AppColors.primaryDark,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            'Personal Haven',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
        ),
        if (widget.canSkip)
          IconButton(
            tooltip: 'Close mood check-in',
            onPressed: _skip,
            icon: const Icon(Icons.close_rounded),
          ),
      ],
    );
  }

  Widget _buildTitle() {
    final isEditing = widget.existingMood != null;
    return Column(
      children: [
        Text(
          isEditing ? 'How do you feel now?' : 'Meet Your Mood.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isEditing
              ? 'Take a breath and choose what feels closest.'
              : 'A small check-in can make the day feel lighter.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: context.colors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        itemCount: _moods.length,
        itemBuilder: (context, index) {
          return AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              final page =
                  _pageController.hasClients &&
                      _pageController.position.haveDimensions
                  ? _pageController.page ?? _selectedIndex.toDouble()
                  : _selectedIndex.toDouble();
              final distance = (page - index).abs();
              final scale = (1 - distance * 0.32).clamp(0.62, 1.0);
              final opacity = (1 - distance * 0.42).clamp(0.42, 1.0);
              return Transform.scale(
                scale: scale,
                child: Opacity(opacity: opacity, child: child),
              );
            },
            child: GestureDetector(
              onTap: () => _selectMood(index.toDouble()),
              child: _MoodFace(
                mood: _moods[index],
                isSelected: index == _selectedIndex,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMoodLabel(MoodOption selected) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Container(
        key: ValueKey(selected.label),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: context.colors.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected.color.withValues(alpha: 0.65),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: selected.color.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'I feel ${selected.label.toLowerCase()}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: context.colors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMoodSlider(MoodOption selected) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 9,
            activeTrackColor: selected.color,
            inactiveTrackColor: context.colors.divider,
            thumbColor: selected.color,
            overlayColor: selected.color.withValues(alpha: 0.16),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 15),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            tickMarkShape: SliderTickMarkShape.noTickMark,
          ),
          child: Slider(
            value: _moodPosition.clamp(0, (_moods.length - 1).toDouble()),
            min: 0,
            max: (_moods.length - 1).toDouble(),
            divisions: _moods.length - 1,
            onChanged: _selectMood,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Heavy',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.textSecondary,
                ),
              ),
              Text(
                'Bright',
                style: TextStyle(
                  fontSize: 11,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteSection() {
    return Column(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _showNote = !_showNote),
          icon: Icon(
            _showNote
                ? Icons.keyboard_arrow_up_rounded
                : Icons.edit_note_rounded,
            size: 18,
          ),
          label: Text(_showNote ? 'Hide note' : 'Add a note'),
          style: TextButton.styleFrom(
            foregroundColor: context.colors.textSecondary,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          child: _showNote
              ? TextField(
                  controller: _noteController,
                  maxLines: 2,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: 'What is shaping this feeling?',
                    filled: true,
                    fillColor: context.colors.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.colors.divider),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: context.colors.divider),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton.icon(
        onPressed: _save,
        icon: const Icon(Icons.check_rounded),
        label: Text(
          widget.existingMood == null ? 'Save Check-in' : 'Update Check-in',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSkipButton() {
    return TextButton(
      onPressed: _skip,
      style: TextButton.styleFrom(
        foregroundColor: context.colors.textSecondary,
      ),
      child: const Text('Maybe later'),
    );
  }
}

class _MoodFace extends StatelessWidget {
  final MoodOption mood;
  final bool isSelected;

  const _MoodFace({required this.mood, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: isSelected ? 170 : 132,
        height: isSelected ? 170 : 132,
        decoration: BoxDecoration(
          color: mood.color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.65),
            width: isSelected ? 5 : 3,
          ),
          boxShadow: [
            BoxShadow(
              color: mood.color.withValues(alpha: isSelected ? 0.34 : 0.16),
              blurRadius: isSelected ? 28 : 14,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Center(
          child: Text(
            mood.emoji,
            style: TextStyle(fontSize: isSelected ? 76 : 52, height: 1),
          ),
        ),
      ),
    );
  }
}
