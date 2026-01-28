import 'dart:convert';

import 'package:crypto/crypto.dart';
class PasswordHelper {
  /// Generate a random salt
  static String generateSalt() {
    final random = DateTime.now().millisecondsSinceEpoch.toString() +
        DateTime.now().microsecondsSinceEpoch.toString();
    return sha256.convert(utf8.encode(random)).toString().substring(0, 16);
  }

  /// Hash password with salt
  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode(password + salt);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Verify password
  static bool verifyPassword(String password, String hash, String salt) {
    final computedHash = hashPassword(password, salt);
    return computedHash == hash;
  }

  /// Validate password strength
  static bool isPasswordStrong(String password) {
    if (password.length < 8) return false;
    
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    return hasUppercase && hasLowercase && hasDigits && hasSpecialCharacters;
  }

  /// Get password strength message
  static String getPasswordStrengthMessage(String password) {
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain uppercase letters';
    }
    if (!password.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain lowercase letters';
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain numbers';
    }
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain special characters';
    }
    return 'Strong password';
  }
}
