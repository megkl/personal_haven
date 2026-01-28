import 'package:personal_haven/core/utils/biometrics_helper.dart';
import 'package:personal_haven/core/utils/password_helper.dart';
import 'package:personal_haven/data/models/user.dart';
import 'package:personal_haven/data/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final UserRepository _userRepo = UserRepository();
  static final AuthService instance = AuthService._init();

  AuthService._init();

  /// Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? username,
    String? firstName,
    String? lastName,
    bool enableBiometric = false,
  }) async {
    try {
      // Validate email
      if (!_isValidEmail(email)) {
        return AuthResult(success: false, error: 'Invalid email address');
      }

      // Validate password
      if (!PasswordHelper.isPasswordStrong(password)) {
        return AuthResult(
          success: false,
          error: PasswordHelper.getPasswordStrengthMessage(password),
        );
      }

      // Create user
      final user = await _userRepo.createUser(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
        enableBiometric: enableBiometric,
      );

      if (user == null) {
        return AuthResult(success: false, error: 'Failed to create account. Email may already exist.');
      }

      // Save session
      await _saveSession(user.id);

      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Login with email and password
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _userRepo.verifyLogin(email, password);

      if (user == null) {
        return AuthResult(success: false, error: 'Invalid email or password');
      }

      // Save session
      await _saveSession(user.id);

      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Login with biometric
  Future<AuthResult> loginWithBiometric(String userId) async {
    try {
      // Check if biometric is enabled
      final isEnabled = await _userRepo.isBiometricEnabled(userId);
      if (!isEnabled) {
        return AuthResult(success: false, error: 'Biometric authentication not enabled');
      }

      // Authenticate
      final authenticated = await BiometricHelper.authenticate(
        reason: 'Login to Personal Haven',
      );

      if (!authenticated) {
        return AuthResult(success: false, error: 'Biometric authentication failed');
      }

      // Get user
      final user = await _userRepo.getUserById(userId);
      if (user == null) {
        return AuthResult(success: false, error: 'User not found');
      }

      // Update last biometric use
      await _userRepo.updateBiometricLastUsed(userId);
      await _userRepo.updateLastLogin(userId);

      // Save session
      await _saveSession(user.id);

      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Get current user from session
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('current_user_id');

    if (userId != null) {
      return await _userRepo.getUserById(userId);
    }
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    await prefs.setBool('is_logged_in', false);
  }

  /// Save session
  Future<void> _saveSession(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', userId);
    await prefs.setBool('is_logged_in', true);
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final User? user;
  final String? error;

  AuthResult({
    required this.success,
    this.user,
    this.error,
  });
}