import 'package:flutter/material.dart';

class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF4ECDC4);
  static const Color primaryLight = Color(0xFFB8E6E3);
  static const Color primaryDark = Color(0xFF3AA99F);

  // Accent Colors
  static const Color accent = Color(0xFFCD8B76);
  static const Color accentLight = Color(0xFFE5B5A3);

  // Background Colors
  static const Color background = Color(0xFFF5F5F5);
  static const Color backgroundLight = Color(0xFFF0F4F3);
  static const Color backgroundDark = Color(0xFF2D3E40);

  // Text Colors
  static const Color textPrimary = Color(0xFF2D3E40);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textWhite = Colors.white;

  // Card & Surface Colors
  static const Color cardBackground = Colors.white;
  static const Color surface = Colors.white;

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Mood Colors
  static const Color moodHappy = Color.fromARGB(255, 182, 156, 5);
  static const Color moodNeutral = Color(0xFFB0B0B0);
  static const Color moodSad = Color.fromARGB(255, 46, 47, 48);
  static const Color moodCalm = Color(0xFF6495ED);
  static const Color moodFrustrated = Color.fromARGB(255, 166, 196, 251);
  static const Color moodTired = Color.fromARGB(255, 68, 72, 79);

  // Category Colors
  static const Color categoryNotes = Color(0xFFFFE082);
  static const Color categoryGoals = Color(0xFF81C784);
  static const Color categoryFood = Color(0xFFFF8A65);
  static const Color categoryHealth = Color(0xFFE57373);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FA)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Border Colors
  static const Color border = Color(0xFFE0E0E0);
  static const Color borderLight = Color(0xFFF0F0F0);
  static const Color borderDark = Color(0xFFBDBDBD);

  // Shadow Colors
  static Color shadow = Colors.black.withValues(alpha: 0.1);
  static Color shadowLight = Colors.black.withValues(alpha: 0.05);
  static Color shadowDark = Colors.black.withValues(alpha: 0.15);
}