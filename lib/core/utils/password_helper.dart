import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
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

class PasswordRequirements extends StatelessWidget {
  final String password;
  final VoidCallback? onAllRequirementsMet;

  const PasswordRequirements({
    super.key,
    required this.password,
    this.onAllRequirementsMet,
  });

  @override
  Widget build(BuildContext context) {
    final requirements = [
      PasswordRequirement(
        text: 'At least 8 characters',
        isMet: password.length >= 8,
      ),
      PasswordRequirement(
        text: 'Uppercase and lowercase letters',
        isMet: _hasUpperAndLower(password),
      ),
      PasswordRequirement(
        text: 'At least one number',
        isMet: password.contains(RegExp(r'[0-9]')),
      ),
      PasswordRequirement(
        text: 'At least one special character',
        isMet: password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]')),
      ),
    ];

    final allMet = requirements.every((req) => req.isMet);
    final metCount = requirements.where((req) => req.isMet).length;

    // Trigger callback when all requirements are met
    if (allMet && onAllRequirementsMet != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onAllRequirementsMet!();
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: metCount / requirements.length,
                    backgroundColor: const Color(0xFFE0E0E0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getProgressColor(metCount, requirements.length),
                    ),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$metCount/${requirements.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getProgressColor(metCount, requirements.length),
                ),
              ),
            ],
          ),
        ),

        // Requirements list
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: requirements
                .map((req) => _PasswordRequirementRow(
                      text: req.text,
                      isMet: req.isMet,
                    ))
                .toList(),
          ),
        ),

        // Success message when all met
        if (allMet)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: Color(0xFF4CAF50),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Password is strong!',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  bool _hasUpperAndLower(String password) {
    return password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]'));
  }

  Color _getProgressColor(int met, int total) {
    final progress = met / total;
    if (progress <= 0.25) return const Color(0xFFE57373); // Red
    if (progress <= 0.5) return const Color(0xFFFFB74D); // Orange
    if (progress <= 0.75) return const Color(0xFFFFD54F); // Yellow
    return const Color(0xFF4CAF50); // Green
  }
}

class PasswordRequirement {
  final String text;
  final bool isMet;

  PasswordRequirement({
    required this.text,
    required this.isMet,
  });
}

class _PasswordRequirementRow extends StatelessWidget {
  final String text;
  final bool isMet;

  const _PasswordRequirementRow({
    required this.text,
    required this.isMet,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Icon(
              isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: isMet ? const Color(0xFF4CAF50) : const Color(0xFFBDBDBD),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 13,
                color: isMet ? const Color(0xFF2D3E40) : const Color(0xFF9E9E9E),
                fontWeight: isMet ? FontWeight.w500 : FontWeight.normal,
                decoration: isMet ? TextDecoration.lineThrough : TextDecoration.none,
                decorationColor: const Color(0xFF4CAF50),
              ),
              child: Text(text),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HELPER: Check if password meets all requirements
// ═══════════════════════════════════════════════════════════════════════════

class PasswordValidator {
  static bool isValid(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]')) &&
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;/]'));
  }

  static String? validate(String? password) {
    if (password == null || password.isEmpty) {
      return 'Password is required';
    }
    if (!isValid(password)) {
      return 'Password does not meet requirements';
    }
    return null;
  }
}
