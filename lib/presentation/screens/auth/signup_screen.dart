import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/screens/auth/login_screen.dart';
import 'package:personal_haven/presentation/screens/legal/terms_screen.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:personal_haven/presentation/widgets/auth/auth_shell.dart';
import 'package:personal_haven/presentation/widgets/common/google_mark.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/services/social_auth_service.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  bool _isLoading = false;

  Future<void> _handleSocialSignUp(
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
        content: Text(authError ?? result.error ?? 'Sign-up failed'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _openHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const MainNavigationScreen(currentIndex: 0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      imagePath: 'assets/images/auth/signup-create.png',
      imageSemanticLabel: 'A person creating a calm personal space',
      eyebrow: 'WELCOME TO',
      title: 'Personal Haven.',
      subtitle:
          'Create your private place to reflect, organize, and grow gently.',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthActionButton(
            label: 'Sign up with Google',
            icon: const GoogleMark(size: 22),
            isLoading: _isLoading,
            onPressed: () => _handleSocialSignUp(
              SocialAuthService.instance.signInWithGoogle,
            ),
          ),
          const SizedBox(height: 13),
          _LegalNotice(
            onTermsPressed: () => openTermsAndConditions(context),
            onPrivacyPressed: () => openPrivacyPolicy(context),
          ),
        ],
      ),
      footer: AuthSwitchPrompt(
        message: 'Continue your personal have journey? ',
        actionLabel: 'Log in',
        onPressed: () => Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        ),
      ),
    );
  }
}

class _LegalNotice extends StatefulWidget {
  const _LegalNotice({
    required this.onTermsPressed,
    required this.onPrivacyPressed,
  });

  final VoidCallback onTermsPressed;
  final VoidCallback onPrivacyPressed;

  @override
  State<_LegalNotice> createState() => _LegalNoticeState();
}

class _LegalNoticeState extends State<_LegalNotice> {
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onTermsPressed();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => widget.onPrivacyPressed();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(height: 1.5);
    final linkStyle = textStyle?.copyWith(
      color: AppColors.primaryDark,
      fontWeight: FontWeight.w800,
    );

    return Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          const TextSpan(text: 'By continuing, you agree to our '),
          TextSpan(
            text: 'Terms',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
          const TextSpan(text: ' and '),
          TextSpan(
            text: 'Privacy Policy',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          const TextSpan(text: '.'),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
