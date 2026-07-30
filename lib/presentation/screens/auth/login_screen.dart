import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/auth/signup_screen.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:personal_haven/presentation/widgets/auth/auth_shell.dart';
import 'package:personal_haven/presentation/widgets/common/google_mark.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/services/biometric_service.dart';
import 'package:personal_haven/services/social_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;
  bool _biometricAvailable = false;
  String _biometricLabel = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!wasLoggedIn) return;

    final available = await BiometricService.instance.isAvailable();
    final enabled = await BiometricService.instance.isEnabled();
    final label = await BiometricService.instance.getBiometricLabel();

    if (!mounted) return;
    setState(() {
      _biometricAvailable = available && enabled;
      _biometricLabel = label;
    });
    if (_biometricAvailable) _loginWithBiometric();
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);
    final ok = await BiometricService.instance.authenticate(
      reason: 'Log in to Personal Haven',
    );
    if (!mounted) return;

    if (ok) {
      await ref.read(authProvider.notifier).checkAuthStatus();
      if (!mounted) return;
      if (ref.read(authProvider).isAuthenticated) {
        _openHome();
        return;
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleSocialLogin(
    Future<SocialAuthResult> Function() signIn,
  ) async {
    setState(() => _isLoading = true);
    final result = await signIn();
    if (!mounted) return;

    if (result.success) {
      final ok = await ref.read(authProvider.notifier).socialLogin(result);
      if (!mounted) return;
      if (ok) {
        _openHome();
        return;
      }
    }

    await ref.read(authProvider.notifier).checkAuthStatus();
    if (!mounted) return;
    if (ref.read(authProvider).isAuthenticated) {
      _openHome();
      return;
    }

    setState(() => _isLoading = false);
    final authError = ref.read(authProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(authError ?? result.error ?? 'Sign-in failed'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _openHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      imagePath: 'assets/images/auth/login-welcome.png',
      imageSemanticLabel: 'A person returning to their peaceful haven',
      eyebrow: 'WELCOME BACK TO',
      title: 'Your Personal Haven.',
      subtitle:
          'Pick up where you left off and make a little space for yourself.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthActionButton(
            label: 'Log in with Google',
            icon: const GoogleMark(size: 22),
            isLoading: _isLoading,
            onPressed: () =>
                _handleSocialLogin(SocialAuthService.instance.signInWithGoogle),
          ),
          if (_biometricAvailable) ...[
            const SizedBox(height: 18),
            _AuthDivider(label: 'or use $_biometricLabel'),
            const SizedBox(height: 18),
            AuthActionButton(
              label: 'Use $_biometricLabel',
              icon: Icon(
                _biometricLabel == 'Face ID'
                    ? Icons.face_unlock_rounded
                    : Icons.fingerprint_rounded,
                size: 24,
                color: AppColors.primaryDark,
              ),
              isLoading: _isLoading,
              emphasized: false,
              onPressed: _loginWithBiometric,
            ),
          ],
        ],
      ),
      footer: AuthSwitchPrompt(
        message: "Start your personal haven journey? ",
        actionLabel: 'Create one',
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SignUpScreen()),
        ),
      ),
    );
  }
}

class _AuthDivider extends StatelessWidget {
  const _AuthDivider({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: Theme.of(context).textTheme.bodySmall),
        ),
        Expanded(child: Divider(color: Theme.of(context).dividerColor)),
      ],
    );
  }
}
