import 'package:personal_haven/core/utils/biometrics_helper.dart';
import 'package:personal_haven/core/utils/password_helper.dart';
import 'package:personal_haven/data/data_sources/local/shared_prefs_helper.dart';
import 'package:personal_haven/data/models/user.dart';
import 'package:personal_haven/data/repositories/user_repository.dart';

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
    String? bio,
    String? avatarUrl,
    Map<String, dynamic>? preferencesJson,
    String? lastLoginAt,
    String? isPremium,
    bool enableBiometric = false,
  }) async {
    try {
      if (!_isValidEmail(email)) {
        return AuthResult(success: false, error: 'Invalid email address');
      }

      if (!PasswordHelper.isPasswordStrong(password)) {
        return AuthResult(
          success: false,
          error: PasswordHelper.getPasswordStrengthMessage(password),
        );
      }

      final user = await _userRepo.createUser(
        email: email,
        password: password,
        username: username,
        firstName: firstName,
        lastName: lastName,
        bio: bio,
        preferencesJson: preferencesJson,
        avatarUrl: avatarUrl,
        lastLoginAt: lastLoginAt,
        isPremium: isPremium,
        enableBiometric: enableBiometric,
      );

      if (user == null) {
        return AuthResult(success: false, error: 'Failed to create account. Email may already exist.');
      }

      final prefs = await SharedPrefsHelper.getInstance();
      await prefs.saveUserSession(user);

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

      // ✅ Save user session using SharedPrefsHelper
      final prefs = await SharedPrefsHelper.getInstance();
      await prefs.saveUserSession(user);

      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Login with biometric
  Future<AuthResult> loginWithBiometric(String userId) async {
    try {
      final isEnabled = await _userRepo.isBiometricEnabled(userId);
      if (!isEnabled) {
        return AuthResult(success: false, error: 'Biometric authentication not enabled');
      }

      final authenticated = await BiometricHelper.authenticate(
        reason: 'Login to Personal Haven',
      );

      if (!authenticated) {
        return AuthResult(success: false, error: 'Biometric authentication failed');
      }

      final user = await _userRepo.getUserById(userId);
      if (user == null) {
        return AuthResult(success: false, error: 'User not found');
      }

      await _userRepo.updateBiometricLastUsed(userId);
      await _userRepo.updateLastLogin(userId);

      // ✅ Save user session using SharedPrefsHelper
      final prefs = await SharedPrefsHelper.getInstance();
      await prefs.saveUserSession(user);

      return AuthResult(success: true, user: user);
    } catch (e) {
      return AuthResult(success: false, error: e.toString());
    }
  }

  /// Get current user from session
  Future<User?> getCurrentUser() async {
    final prefs = await SharedPrefsHelper.getInstance();
    final userId = prefs.getUserId();

    if (userId != null) {
      return await _userRepo.getUserById(userId);
    }
    return null;
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPrefsHelper.getInstance();
    return prefs.isLoggedIn();
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await SharedPrefsHelper.getInstance();
    await prefs.clearSession();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

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
