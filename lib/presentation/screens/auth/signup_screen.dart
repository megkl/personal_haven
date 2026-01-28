import 'package:flutter/material.dart';
import 'package:personal_haven/core/utils/biometrics_helper.dart';
import 'package:personal_haven/core/utils/password_helper.dart';
import 'package:personal_haven/presentation/screens/auth/login_screen.dart';
import 'package:personal_haven/presentation/screens/home/home_screen.dart';
import 'package:personal_haven/services/auth_service.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _biometricEnabled = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _biometricAvailable = false;
  String _biometricType = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await BiometricHelper.isAvailable();
    if (available) {
      final types = await BiometricHelper.getAvailableBiometrics();
      setState(() {
        _biometricAvailable = types.isNotEmpty;
        _biometricType = BiometricHelper.getBiometricTypeName(types);
      });
    }
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.instance.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      username: _usernameController.text.trim().isEmpty 
          ? null 
          : _usernameController.text.trim(),
      firstName: _firstNameController.text.trim().isEmpty 
          ? null 
          : _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim().isEmpty 
          ? null 
          : _lastNameController.text.trim(),
      enableBiometric: _biometricEnabled,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      // Navigate to home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Sign up failed'),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
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
                  "Let's personalize your space.",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF2D3E40),
                  ),
                ),
                const SizedBox(height: 40),

                // First Name
                TextFormField(
                  controller: _firstNameController,
                  decoration: _inputDecoration('First Name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name
                TextFormField(
                  controller: _lastNameController,
                  decoration: _inputDecoration('Last Name (Optional)'),
                ),
                const SizedBox(height: 16),

                // Username
                TextFormField(
                  controller: _usernameController,
                  decoration: _inputDecoration('Username (Optional)'),
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email Address'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration('Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF4ECDC4),
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (!PasswordHelper.isPasswordStrong(value)) {
                      return PasswordHelper.getPasswordStrengthMessage(value);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: _inputDecoration('Confirm Password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF4ECDC4),
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Password requirements
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _passwordRequirement('At least 8 characters'),
                      _passwordRequirement('Uppercase and lowercase letters'),
                      _passwordRequirement('At least one number'),
                      _passwordRequirement('At least one special character'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Biometric toggle
                if (_biometricAvailable)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _biometricType.contains('Face') 
                              ? Icons.face 
                              : Icons.fingerprint,
                          color: const Color(0xFF4ECDC4),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enable $_biometricType',
                            style: const TextStyle(
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
                  ),
                const SizedBox(height: 32),

                // Sign Up Button
                ElevatedButton(
                  onPressed: _isLoading ? null : _signUp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ECDC4),
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Sign Up',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // Terms and Privacy
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

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
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
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  Widget _passwordRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: Color(0xFF2D3E40)),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Color(0xFF2D3E40)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
