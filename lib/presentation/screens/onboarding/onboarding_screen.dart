import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/auth/signup_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final PageController _pageController = PageController();
  late final AnimationController _floatController;
  late final AnimationController _progressController;

  int _currentPage = 0;
  bool _isFinishing = false;

  static const _pages = [
    _OnboardingPage(
      eyebrow: 'REFLECT',
      title: 'A quiet place for your thoughts',
      description:
          'Journal privately, check in with yourself, and return whenever you need a reset.',
      imagePath: 'assets/images/onboarding/reset.png',
      semanticLabel: 'A person writing peacefully in a journal',
      accent: AppColors.primary,
    ),
    _OnboardingPage(
      eyebrow: 'ORGANIZE',
      title: 'Bring your day into focus',
      description:
          'Keep tasks, moods, and goals together, without turning life into another dashboard.',
      imagePath: 'assets/images/onboarding/focus.png',
      semanticLabel: 'A person organizing tasks, moods, and goals',
      accent: AppColors.primaryDark,
    ),
    _OnboardingPage(
      eyebrow: 'GROW',
      title: 'Small steps, meaningful progress',
      description:
          'Build gentle routines, notice your patterns, and celebrate progress that feels like you.',
      imagePath: 'assets/images/onboarding/grow.png',
      semanticLabel: 'A person taking small steps toward a growing plant',
      accent: AppColors.primaryDark,
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 5))
          ..addStatusListener(_handleProgressStatus)
          ..forward();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _progressController.dispose();
    _floatController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _restartProgress();
    }
  }

  void _handleProgressStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed ||
        !mounted ||
        _currentPage == _pages.length - 1 ||
        !_pageController.hasClients) {
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _restartProgress() {
    _progressController
      ..stop()
      ..reset()
      ..forward();
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    _progressController.stop();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const SignUpScreen()),
    );
  }

  void _nextPage() {
    if (_currentPage == _pages.length - 1) {
      _finishOnboarding();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          _BackgroundOrb(
            alignment: const Alignment(1.3, -1.08),
            size: 250,
            color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.14),
          ),
          _BackgroundOrb(
            alignment: const Alignment(-1.42, 0.52),
            size: 210,
            color: AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.1),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(theme),
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _restartProgress(),
                    child: PageView.builder(
                      controller: _pageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: (index) {
                        setState(() => _currentPage = index);
                        _restartProgress();
                      },
                      itemCount: _pages.length,
                      itemBuilder: (context, index) => _OnboardingPageView(
                        page: _pages[index],
                        isActive: index == _currentPage,
                        floatAnimation: _floatController,
                      ),
                    ),
                  ),
                ),
                _buildFooter(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 14, 4),
      child: Row(
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
              size: 21,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Personal Haven',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: _currentPage == _pages.length - 1 ? 0 : 1,
            duration: const Duration(milliseconds: 220),
            child: IgnorePointer(
              ignoring: _currentPage == _pages.length - 1,
              child: TextButton(
                onPressed: _finishOnboarding,
                style: TextButton.styleFrom(
                  foregroundColor: theme.textTheme.bodyMedium?.color,
                ),
                child: const Text('Skip'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 22),
      child: Row(
        children: [
          const SizedBox(width: 58),
          Expanded(
            child: Semantics(
              label: 'Page ${_currentPage + 1} of ${_pages.length}',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOut,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 26 : 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: isLastPage ? 'Get started' : 'Next',
            child: SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _progressController,
                    builder: (context, child) => SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: _progressController.value,
                        strokeWidth: 2.5,
                        strokeCap: StrokeCap.round,
                        color: AppColors.primary,
                        backgroundColor: AppColors.primary.withValues(
                          alpha: 0.18,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.22),
                          blurRadius: 16,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: IconButton.filled(
                      onPressed: _isFinishing ? null : _nextPage,
                      tooltip: isLastPage ? 'Get started' : 'Next',
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.textPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.textPrimary
                            .withValues(alpha: 0.5),
                        padding: EdgeInsets.zero,
                      ),
                      icon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        transitionBuilder: (child, animation) =>
                            ScaleTransition(scale: animation, child: child),
                        child: Icon(
                          isLastPage
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          key: ValueKey(isLastPage),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({
    required this.page,
    required this.isActive,
    required this.floatAnimation,
  });

  final _OnboardingPage page;
  final bool isActive;
  final Animation<double> floatAnimation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final illustrationHeight = (constraints.maxHeight * 0.57).clamp(
          225.0,
          390.0,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedOpacity(
                    opacity: isActive ? 1 : 0.35,
                    duration: const Duration(milliseconds: 360),
                    child: AnimatedScale(
                      scale: isActive ? 1 : 0.94,
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      child: AnimatedBuilder(
                        animation: floatAnimation,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(
                            0,
                            isActive ? (floatAnimation.value - 0.5) * 8 : 0,
                          ),
                          child: child,
                        ),
                        child: Semantics(
                          image: true,
                          label: page.semanticLabel,
                          child: Image.asset(
                            page.imagePath,
                            height: illustrationHeight,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.high,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: isActive ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: Column(
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: page.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 13,
                          vertical: 7,
                        ),
                        child: Text(
                          page.eyebrow,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: page.accent,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.25,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontSize: 29,
                        height: 1.12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.textTheme.bodyMedium?.color,
                          fontSize: 15.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BackgroundOrb extends StatelessWidget {
  const _BackgroundOrb({
    required this.alignment,
    required this.size,
    required this.color,
  });

  final Alignment alignment;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.semanticLabel,
    required this.accent,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String imagePath;
  final String semanticLabel;
  final Color accent;
}
