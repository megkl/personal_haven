import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/presentation/screens/auth/signup_screen.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/services/social_auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleSocialLogin(
      Future<SocialAuthResult> Function() signIn) async {
    setState(() => _isLoading = true);
    final result = await signIn();
    if (!mounted) return;

    if (result.success) {
      final ok = await ref.read(authProvider.notifier).socialLogin(result);
      if (!mounted) return;
      if (ok) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
        return;
      }
    }

    setState(() => _isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Sign-in failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6E3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa,
                      color: Colors.white.withOpacity(0.9), size: 32),
                  const SizedBox(width: 12),
                  const Text(
                    'Personal Haven',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3E40),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E40),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Log in to your safe space',
                style: TextStyle(fontSize: 16, color: Color(0xFF2D3E40)),
              ),
              const SizedBox(height: 48),
              if (_isLoading)
                const CircularProgressIndicator(color: Color(0xFF4ECDC4))
              else ...[
                _SocialButton(
                  label: 'Continue with Google',
                  icon: _googleIcon(),
                  onTap: () => _handleSocialLogin(
                      SocialAuthService.instance.signInWithGoogle),
                ),
                const SizedBox(height: 16),
                _SocialButton(
                  label: 'Continue with Microsoft',
                  icon: _microsoftIcon(),
                  onTap: () => _handleSocialLogin(
                      SocialAuthService.instance.signInWithMicrosoft),
                ),
                const SizedBox(height: 16),
                _SocialButton(
                  label: 'Continue with Apple',
                  icon: const Icon(Icons.apple, size: 22),
                  onTap: () => _handleSocialLogin(
                      SocialAuthService.instance.signInWithApple),
                ),
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF2D3E40)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: const Text(
                      'Sign Up',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Image.network(
      'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
      width: 22,
      height: 22,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.g_mobiledata, size: 22, color: Color(0xFF4285F4)),
    );
  }

  Widget _microsoftIcon() {
    return const Icon(Icons.window, size: 22, color: Color(0xFF00A4EF));
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: icon,
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3E40),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          side: BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
        ),
      ),
    );
  }
}
