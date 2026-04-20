import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/auth/login_screen.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/services/biometric_service.dart';
import 'package:personal_haven/splash_screen.dart';

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer>
    with WidgetsBindingObserver {
  bool _biometricPassed = false;
  bool _checkingBiometric = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _runBiometricCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-prompt when app comes back to foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_biometricPassed) {
      _runBiometricCheck();
    }
    // Lock again when app goes to background
    if (state == AppLifecycleState.paused) {
      _lockIfEnabled();
    }
  }

  Future<void> _lockIfEnabled() async {
    final enabled = await BiometricService.instance.isEnabled();
    if (enabled && mounted) {
      setState(() => _biometricPassed = false);
    }
  }

  Future<void> _runBiometricCheck() async {
    if (_checkingBiometric) return;
    setState(() => _checkingBiometric = true);

    final passed = await BiometricService.instance.authenticateIfEnabled();

    if (mounted) {
      setState(() {
        _biometricPassed = passed;
        _checkingBiometric = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final hasSeenOnboardingAsync = ref.watch(hasSeenOnboardingProvider);

    // Show biometric lock screen while checking or if auth failed
    if (_checkingBiometric) {
      return const _LoadingScaffold();
    }

    if (!_biometricPassed) {
      return _BiometricLockScreen(onRetry: _runBiometricCheck);
    }

    return hasSeenOnboardingAsync.when(
      data: (hasSeenOnboarding) {
        if (authState.isLoading) return const _LoadingScaffold();
        if (!hasSeenOnboarding) return const SplashScreen();
        if (!authState.isAuthenticated) return const LoginScreen();
        return const SplashScreen();
      },
      loading: () => const _LoadingScaffold(),
      error: (_, __) => const Scaffold(
        body: Center(child: Text('Error initializing app')),
      ),
    );
  }
}

// ── Biometric lock screen shown when auth is required ────────────────────────

class _BiometricLockScreen extends StatelessWidget {
  final VoidCallback onRetry;
  const _BiometricLockScreen({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6E3),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_rounded,
                  size: 72, color: Colors.white.withOpacity(0.9)),
              const SizedBox(height: 24),
              const Text(
                'Personal Haven',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E40),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Authenticate to continue',
                style: TextStyle(fontSize: 16, color: Color(0xFF2D3E40)),
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.fingerprint, size: 24),
                label: const Text(
                  'Unlock',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(200, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
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

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }
}
