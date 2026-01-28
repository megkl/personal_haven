import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/presentation/screens/onboarding/onboarding_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _navigateToNextScreen();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _navigateToNextScreen() async {
    // Wait for splash animation
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check auth status
    final authState = ref.read(authProvider);
    final hasSeenOnboardingAsync = await ref.read(hasSeenOnboardingProvider.future);

    if (!mounted) return;

    Widget nextScreen;

    if (!hasSeenOnboardingAsync) {
      // First time user - show onboarding
      nextScreen = const OnboardingScreen();
    } else if (authState.isAuthenticated) {
      // Logged in user - go to home
      nextScreen = const MainNavigationScreen();
    } else {
      // Returning user not logged in - show onboarding (which leads to login/signup)
      nextScreen = const OnboardingScreen();
    }

    // Navigate with fade transition
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryLight,
              AppColors.primary,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.spa,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Column(
                  children: [
                    Text(
                      'Personal Haven',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your Little Safe Space.',
                      style: TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 16,
                        color: Colors.white70,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
              // Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// OPTION 2: Animated Ripple Splash
// ============================================================================

class RippleSplashScreen extends ConsumerStatefulWidget {
  const RippleSplashScreen({super.key});

  @override
  ConsumerState<RippleSplashScreen> createState() => _RippleSplashScreenState();
}

class _RippleSplashScreenState extends ConsumerState<RippleSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _rippleController;
  late AnimationController _fadeController;
  late Animation<double> _rippleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _rippleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );

    _fadeController.forward();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      // Navigation logic here (same as main splash screen)
    }
  }

  @override
  void dispose() {
    _rippleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Stack(
        children: [
          // Animated ripples
          Center(
            child: AnimatedBuilder(
              animation: _rippleAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: List.generate(3, (index) {
                    final delay = index * 0.3;
                    final animValue = (_rippleAnimation.value - delay).clamp(0.0, 1.0);
                    return Container(
                      width: 300 * animValue,
                      height: 300 * animValue,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity((1 - animValue) * 0.3),
                          width: 2,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ),
          // Logo and text
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa,
                      size: 50,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Personal Haven',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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

// ============================================================================
// OPTION 3: Particle Splash
// ============================================================================
class ParticleSplashScreen extends ConsumerStatefulWidget {
  const ParticleSplashScreen({super.key});

  @override
  ConsumerState<ParticleSplashScreen> createState() => _ParticleSplashScreenState();
}

class _ParticleSplashScreenState extends ConsumerState<ParticleSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    _initializeParticles();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _navigateToNextScreen();
  }

  void _initializeParticles() {
    for (int i = 0; i < 30; i++) {
      _particles.add(Particle());
    }
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      // Navigation logic here
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary, AppColors.primaryLight],
          ),
        ),
        child: Stack(
          children: [
            // Animated particles
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: ParticlePainter(_particles, _controller.value),
                  size: Size.infinite,
                );
              },
            ),
            // Logo and text
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.spa,
                      size: 60,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Personal Haven',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double size = 3;

  Particle() {
    reset();
  }

  void reset() {
    x = (0.5 - 0.5) * 400;
    y = (0.5 - 0.5) * 800;
    vx = (0.5 - 0.5) * 2;
    vy = (0.5 - 0.5) * 2;
    size = 2 + 0.5 * 4;
  }

  void update() {
    x += vx;
    y += vy;
    
    if (x.abs() > 200 || y.abs() > 400) {
      reset();
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlePainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (var particle in particles) {
      particle.update();
      canvas.drawCircle(
        Offset(centerX + particle.x, centerY + particle.y),
        particle.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) => true;
}

// ============================================================================
// OPTION 4: Breathing Logo Splash
// ============================================================================
class BreathingSplashScreen extends ConsumerStatefulWidget {
  const BreathingSplashScreen({super.key});

  @override
  ConsumerState<BreathingSplashScreen> createState() => _BreathingSplashScreenState();
}

class _BreathingSplashScreenState extends ConsumerState<BreathingSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathController;
  late Animation<double> _breathAnimation;

  @override
  void initState() {
    super.initState();
    
    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _breathAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _breathController,
        curve: Curves.easeInOut,
      ),
    );

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      // Navigation logic here
    }
  }

  @override
  void dispose() {
    _breathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primaryLight, AppColors.primary],
          ),
        ),
        child: Center(
          child: ScaleTransition(
            scale: _breathAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.spa,
                    size: 70,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Personal Haven',
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Breathe. Reflect. Grow.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}