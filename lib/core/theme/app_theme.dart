import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

/// Central theme definitions for Personal Haven.
/// Colours are kept on-brand — teal primary, warm neutrals —
/// with dark surfaces that feel calm rather than harsh.
class AppTheme {
  AppTheme._();

  // ── Shared ──────────────────────────────────────────────────────────────

  static const String _fontFamily = 'Outfit';

  static const _primary = AppColors.primary; // #4ECDC4
  static const _primaryDark = AppColors.primaryDark; // #3AA99F

  // ── Light theme ─────────────────────────────────────────────────────────

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    primaryColor: _primary,
    scaffoldBackgroundColor: const Color(0xFFF5F5F5),
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      brightness: Brightness.light,
      surface: Colors.white,
      onSurface: const Color(0xFF2D3E40),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _primary,
      foregroundColor: Colors.white,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? _primary : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? _primary.withValues(alpha: 0.5)
              : Colors.grey.shade300),
    ),
    dividerColor: const Color(0xFFEEEEEE),
    iconTheme: const IconThemeData(color: Color(0xFF2D3E40)),
    textTheme: _textTheme(Brightness.light),
    extensions: const [AppColorExtension.light],
  );

  // ── Dark theme ──────────────────────────────────────────────────────────

  // Dark surfaces: layered warm-dark neutrals so white cards don't blind.
  static const Color _darkBg = Color(0xFF121A1B);       // page bg
  static const Color _darkSurface = Color(0xFF1E2A2B);  // cards
  static const Color _darkSurface2 = Color(0xFF243133); // elevated cards
  static const Color _darkOnSurface = Color(0xFFE8F4F3);
  static const Color _darkSubtext = Color(0xFF8AADAB);

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    primaryColor: _primary,
    scaffoldBackgroundColor: _darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primary,
      primary: _primary,
      brightness: Brightness.dark,
      surface: _darkSurface,
      onSurface: _darkOnSurface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _darkSurface,
      foregroundColor: _darkOnSurface,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: _darkOnSurface,
      ),
    ),
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: _darkSubtext),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? _primary : Colors.grey.shade400),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? _primary.withValues(alpha: 0.5)
              : Colors.grey.shade700),
    ),
    dividerColor: const Color(0xFF2A3A3B),
    iconTheme: IconThemeData(color: _darkOnSurface),
    textTheme: _textTheme(Brightness.dark),
    extensions: const [AppColorExtension.dark],
  );

  // ── Text theme ───────────────────────────────────────────────────────────

  static TextTheme _textTheme(Brightness brightness) {
    final base =
        brightness == Brightness.light ? const Color(0xFF2D3E40) : const Color(0xFFE8F4F3);
    final sub =
        brightness == Brightness.light ? const Color(0xFF666666) : const Color(0xFF8AADAB);

    return TextTheme(
      displayLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: base),
      displayMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: base),
      headlineLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold, color: base),
      headlineMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, color: base),
      titleLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, color: base),
      titleMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500, color: base),
      bodyLarge: TextStyle(fontFamily: _fontFamily, color: base),
      bodyMedium: TextStyle(fontFamily: _fontFamily, color: sub),
      bodySmall: TextStyle(fontFamily: _fontFamily, color: sub, fontSize: 12),
      labelLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600, color: base),
    );
  }
}

// ── Theme extension for easy access to semantic surface colours ──────────────

@immutable
class AppColorExtension extends ThemeExtension<AppColorExtension> {
  const AppColorExtension({
    required this.cardColor,
    required this.cardColor2,
    required this.homeBackground,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.navBar,
  });

  final Color cardColor;
  final Color cardColor2;
  final Color homeBackground;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color navBar;

  static const light = AppColorExtension(
    cardColor: Colors.white,
    cardColor2: Color(0xFFF5F5F5),
    homeBackground: Color(0xFFB8E6E3),
    textPrimary: Color(0xFF2D3E40),
    textSecondary: Color(0xFF666666),
    divider: Color(0xFFEEEEEE),
    navBar: Colors.white,
  );

  static const dark = AppColorExtension(
    cardColor: Color(0xFF1E2A2B),
    cardColor2: Color(0xFF243133),
    homeBackground: Color(0xFF1A2E2F),
    textPrimary: Color(0xFFE8F4F3),
    textSecondary: Color(0xFF8AADAB),
    divider: Color(0xFF2A3A3B),
    navBar: Color(0xFF1E2A2B),
  );

  @override
  AppColorExtension copyWith({
    Color? cardColor,
    Color? cardColor2,
    Color? homeBackground,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? navBar,
  }) {
    return AppColorExtension(
      cardColor: cardColor ?? this.cardColor,
      cardColor2: cardColor2 ?? this.cardColor2,
      homeBackground: homeBackground ?? this.homeBackground,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      navBar: navBar ?? this.navBar,
    );
  }

  @override
  AppColorExtension lerp(AppColorExtension? other, double t) {
    if (other == null) return this;
    return AppColorExtension(
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      cardColor2: Color.lerp(cardColor2, other.cardColor2, t)!,
      homeBackground: Color.lerp(homeBackground, other.homeBackground, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
    );
  }
}

// Handy extension method — usage: context.colors.cardColor
extension AppThemeExtension on BuildContext {
  AppColorExtension get colors =>
      Theme.of(this).extension<AppColorExtension>()!;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
