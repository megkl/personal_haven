import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/presentation/screens/auth/signup_screen.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/providers/biometric_provider.dart';
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
    // Only show biometric on login if user was previously logged in
    final prefs = await SharedPreferences.getInstance();
    final wasLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    if (!wasLoggedIn) return;

    final available = await BiometricService.instance.isAvailable();
    final enabled = await BiometricService.instance.isEnabled();
    final label = await BiometricService.instance.getBiometricLabel();

    if (mounted) {
      setState(() {
        _biometricAvailable = available && enabled;
        _biometricLabel = label;
      });
      // Auto-prompt if available
      if (_biometricAvailable) _loginWithBiometric();
    }
  }

  Future<void> _loginWithBiometric() async {
    setState(() => _isLoading = true);
    final ok = await BiometricService.instance.authenticate(
      reason: 'Log in to Personal Haven',
    );
    if (!mounted) return;
    if (ok) {
      // Biometric passed — restore the existing Firebase session
      await ref.read(authProvider.notifier).checkAuthStatus();
      if (!mounted) return;
      if (ref.read(authProvider).isAuthenticated) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
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
                  Icon(
                    Icons.spa,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
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
              Text(
                'Welcome Back',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E40),
                ),
              ),
              const SizedBox(height: 8),
              Text(
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
                    SocialAuthService.instance.signInWithGoogle,
                  ),
                ),
                if (_biometricAvailable) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: const [
                      Expanded(child: Divider(color: Color(0xFF2D3E40))),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'or',
                          style: TextStyle(color: Color(0xFF2D3E40)),
                        ),
                      ),
                      Expanded(child: Divider(color: Color(0xFF2D3E40))),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SocialButton(
                    label: 'Use $_biometricLabel',
                    icon: Icon(
                      _biometricLabel == 'Face ID'
                          ? Icons.face_unlock_rounded
                          : Icons.fingerprint,
                      size: 24,
                      color: const Color(0xFF4ECDC4),
                    ),
                    onTap: _loginWithBiometric,
                  ),
                ],
              ],
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(color: Color(0xFF2D3E40)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: Text(
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
      errorBuilder: (_, _, _) =>
          Icon(Icons.g_mobiledata, size: 22, color: Color(0xFF4285F4)),
    );
  }

  Widget _microsoftIcon() {
    return Icon(Icons.window, size: 22, color: Color(0xFF00A4EF));
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
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3E40),
          ),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: context.colors.cardColor,
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
