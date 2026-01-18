import 'package:flutter/material.dart';
import 'package:personal_haven/presentation/screens/auth/login_screen.dart';
import 'package:personal_haven/presentation/screens/profile/main_navigation_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _biometricEnabled = false;
  bool _newsletterSubscribed = true;

  Future<void> _signUp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userEmail', _emailController.text);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFB8E6E3),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.spa, color: Colors.white.withOpacity(0.9)),
                  const SizedBox(width: 8),
                  const Text(
                    'Personal Haven',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3E40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              const Text(
                'Create Your Haven',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3E40),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Let's personzlize your space.",
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF2D3E40),
                ),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'First Name',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  hintText: 'Email Address',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fingerprint, color: Color(0xFF4ECDC4)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Enable Face ID / Touch ID',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2D3E40),
                            ),
                          ),
                        ),
                        Switch(
                          value: _biometricEnabled,
                          onChanged: (value) => setState(() => _biometricEnabled = value),
                          activeColor: const Color(0xFF4ECDC4),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        const Icon(Icons.email, color: Color(0xFF4ECDC4)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Subscribe to Newsletter',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF2D3E40),
                            ),
                          ),
                        ),
                        Switch(
                          value: _newsletterSubscribed,
                          onChanged: (value) => setState(() => _newsletterSubscribed = value),
                          activeColor: const Color(0xFF4ECDC4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ECDC4),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Terms of Service',
                      style: TextStyle(color: Color(0xFF2D3E40)),
                    ),
                  ),
                  const Text('  |  ', style: TextStyle(color: Color(0xFF2D3E40))),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Privacy Policy',
                      style: TextStyle(color: Color(0xFF2D3E40)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Already have of account? ',
                    style: TextStyle(color: Color(0xFF2D3E40)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(
                        color: Color(0xFF4ECDC4),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
