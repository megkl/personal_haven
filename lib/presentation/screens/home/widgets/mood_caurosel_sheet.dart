import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/data/models/mood_log.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MOOD CHECK-IN OVERLAY
//
// A full-screen widget that slides up seamlessly over the home content.
// Used both on first open (no mood yet) and when editing today's mood via
// the mood card tap — no bottom sheet, no navigation needed.
// ─────────────────────────────────────────────────────────────────────────────

class MoodCheckInOverlay extends StatefulWidget {
  final void Function(MoodOption mood, String? note) onSaved;
  final VoidCallback? onSkipped;
  final bool canSkip;

  /// Pre-selected mood when editing an existing entry.
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
  late PageController _pageController;
  late int _selectedIndex;
  final TextEditingController _noteController = TextEditingController();
  bool _showNote = false;
  bool _isExiting = false;

  // Entrance — slides up from bottom
  late AnimationController _entranceCtrl;
  late Animation<Offset> _entranceSlide;
  late Animation<double> _entranceFade;

  // Exit — shrinks and fades away
  late AnimationController _exitCtrl;
  late Animation<double> _exitFade;
  late Animation<double> _exitScale;

  // Emoji bounce on page change
  late AnimationController _bounceCtrl;
  late Animation<double> _bounceAnim;

  // Smooth background color shift per mood
  late AnimationController _colorCtrl;
  late Animation<Color?> _bgColorAnim;
  Color _fromColor = const Color(0xFFB8E6E3);
  Color _toColor = const Color(0xFFB8E6E3);

  @override
  void initState() {
    super.initState();

    // Resolve starting index
    if (widget.existingMood != null) {
      final idx = MoodOptions.all.indexWhere(
        (m) => m.emoji == widget.existingMood!.moodEmoji,
      );
      _selectedIndex = idx < 0 ? 4 : idx;
    } else {
      _selectedIndex = 4; // Neutral
    }

    _pageController = PageController(
      viewportFraction: 0.44,
      initialPage: _selectedIndex,
    );

    if (widget.existingMood?.notes != null) {
      _noteController.text = widget.existingMood!.notes!;
      _showNote = true;
    }

    // Entrance: slides up from slightly below
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _entranceFade = CurvedAnimation(
      parent: _entranceCtrl,
      curve: Curves.easeOut,
    );
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(
          CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOutCubic),
        );

    // Exit: scales down and fades
    _exitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _exitFade = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
    _exitScale = Tween<double>(
      begin: 1.0,
      end: 0.94,
    ).animate(CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));

    // Bounce
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bounceAnim = Tween<double>(
      begin: 1.0,
      end: 1.13,
    ).animate(CurvedAnimation(parent: _bounceCtrl, curve: Curves.elasticOut));

    // Background color
    _colorCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _initColor(_selectedIndex);
    _bgColorAnim = ColorTween(
      begin: _fromColor,
      end: _toColor,
    ).animate(_colorCtrl);

    _entranceCtrl.forward();
  }

  void _initColor(int index) {
    final c = MoodOptions.all[index].color.withValues(alpha: 0.20);
    _fromColor = c;
    _toColor = c;
  }

  @override
  void dispose() {
    _pageController.dispose();
    _noteController.dispose();
    _entranceCtrl.dispose();
    _exitCtrl.dispose();
    _bounceCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  void _onPageChanged(int i) {
    final newColor = MoodOptions.all[i].color.withValues(alpha: 0.20);
    _fromColor = _bgColorAnim.value ?? _fromColor;
    _toColor = newColor;
    _bgColorAnim = ColorTween(
      begin: _fromColor,
      end: _toColor,
    ).animate(_colorCtrl);
    _colorCtrl.forward(from: 0);
    _bounceCtrl.forward(from: 0);
    setState(() => _selectedIndex = i);
  }

  Future<void> _save() async {
    if (_isExiting) return;
    _isExiting = true;
    await _exitCtrl.forward();
    if (mounted) {
      widget.onSaved(
        MoodOptions.all[_selectedIndex],
        _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );
    }
  }

  Future<void> _skip() async {
    if (_isExiting) return;
    _isExiting = true;
    await _exitCtrl.forward();
    if (mounted) widget.onSkipped?.call();
  }

  @override
  Widget build(BuildContext context) {
    final selected = MoodOptions.all[_selectedIndex];
    final size = MediaQuery.of(context).size;
    final bottomPad = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _entranceCtrl,
        _exitCtrl,
        _colorCtrl,
        _bounceCtrl,
      ]),
      builder: (context, child) {
        final bg = _bgColorAnim.value ?? selected.color.withValues(alpha: 0.18);

        return Opacity(
          opacity: (_entranceFade.value * _exitFade.value).clamp(0.0, 1.0),
          child: Transform.scale(
            scale: _exitScale.value,
            child: FractionalTranslation(
              translation: _entranceSlide.value,
              child: Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      bg,
                      Color.lerp(bg, Colors.white, 0.50)!,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.40, 1.0],
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomPad),
          child: Column(
            children: [
              const SizedBox(height: 28),
              _buildBranding(),
              const SizedBox(height: 10),
              _buildTitle(),
              const Spacer(flex: 2),
              _buildCarousel(),
              const SizedBox(height: 18),
              _buildMoodLabel(selected),
              const SizedBox(height: 14),
              _buildDots(),
              const Spacer(flex: 3),
              _buildNoteSection(),
              const SizedBox(height: 6),
              _buildSaveButton(selected),
              if (widget.canSkip) _buildSkipButton(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ── Branding ──────────────────────────────────────────────────

  Widget _buildBranding() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF4ECDC4).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Text('🌿', style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(width: 8),
        Text(
          'Personal Haven',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3E40),
          ),
        ),
      ],
    );
  }

  Widget _buildTitle() {
    final isEditing = widget.existingMood != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Text(
            isEditing ? 'Update Your Mood.' : 'Know Your Mind.',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3E40),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isEditing
                ? 'Swipe to how you\'re feeling now'
                : 'Check in with yourself — how are you feeling?',
            style: TextStyle(
              fontSize: 13,
              color: context.colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Carousel ──────────────────────────────────────────────────

  Widget _buildCarousel() {
    return SizedBox(
      height: 210,
      child: PageView.builder(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        itemCount: MoodOptions.all.length,
        itemBuilder: (context, i) {
          return GestureDetector(
            onTap: () {
              if (i != _selectedIndex) {
                _pageController.animateToPage(
                  i,
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: AnimatedBuilder(
              animation: Listenable.merge([_pageController, _bounceCtrl]),
              builder: (context, _) {
                double scale;
                double opacity;

                if (_pageController.position.haveDimensions) {
                  final page =
                      _pageController.page ?? _selectedIndex.toDouble();
                  final diff = (page - i).abs();
                  scale = (1.0 - diff * 0.26).clamp(0.58, 1.0);
                  opacity = (1.0 - diff * 0.55).clamp(0.30, 1.0);
                } else {
                  scale = i == _selectedIndex ? 1.0 : 0.58;
                  opacity = i == _selectedIndex ? 1.0 : 0.38;
                }

                final isCenter = i == _selectedIndex;
                final mood = MoodOptions.all[i];
                final finalScale = isCenter ? scale * _bounceAnim.value : scale;

                return Transform.scale(
                  scale: finalScale,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            mood.color.withValues(
                              alpha: isCenter ? 0.52 : 0.30,
                            ),
                            mood.color.withValues(
                              alpha: isCenter ? 0.18 : 0.06,
                            ),
                          ],
                          radius: 0.80,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: isCenter
                            ? [
                                BoxShadow(
                                  color: mood.color.withValues(alpha: 0.32),
                                  blurRadius: 32,
                                  offset: const Offset(0, 14),
                                  spreadRadius: 2,
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          mood.emoji,
                          style: TextStyle(
                            fontSize: isCenter ? 82 : 54,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ── Mood label ────────────────────────────────────────────────

  Widget _buildMoodLabel(MoodOption selected) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: anim,
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Container(
        key: ValueKey(selected.label),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: selected.color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: selected.color.withValues(alpha: 0.38),
            width: 1.5,
          ),
        ),
        child: Text(
          'I feel ${selected.label}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _darken(selected.color),
          ),
        ),
      ),
    );
  }

  // ── Dots ──────────────────────────────────────────────────────

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(MoodOptions.all.length, (i) {
        final isSelected = i == _selectedIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          width: isSelected ? 22 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isSelected
                ? MoodOptions.all[i].color
                : context.colors.divider,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // ── Note section ──────────────────────────────────────────────

  Widget _buildNoteSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => setState(() => _showNote = !_showNote),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showNote
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.edit_note_rounded,
                  size: 18,
                  color: context.colors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  _showNote ? 'Hide note' : 'Add a note (optional)',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            child: _showNote
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextField(
                      controller: _noteController,
                      maxLines: 2,
                      maxLength: 200,
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: "What's on your mind?",
                        hintStyle: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: context.colors.cardColor.withValues(
                          alpha: 0.7,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        counterStyle: TextStyle(fontSize: 10),
                      ),
                    ),
                  )
                : const SizedBox(height: 4),
          ),
        ],
      ),
    );
  }

  // ── Buttons ───────────────────────────────────────────────────

  Widget _buildSaveButton(MoodOption selected) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 8, 28, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4ECDC4),
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: const Color(0xFF4ECDC4).withValues(alpha: 0.40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(32),
            ),
          ),
          child: Text(
            widget.existingMood != null ? 'Update Mood' : 'Save Mood',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      ),
      child: Text('Skip for now', style: TextStyle(fontSize: 13)),
    );
  }

  // ── Util ──────────────────────────────────────────────────────

  Color _darken(Color c) {
    final hsl = HSLColor.fromColor(c);
    return hsl.withLightness((hsl.lightness - 0.22).clamp(0.0, 1.0)).toColor();
  }
}
