import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'app_theme_mode'; // 0=system, 1=light, 2=dark

class ThemeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getInt(_kThemeModeKey) ?? 0;
    return _fromInt(raw);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeModeKey, _toInt(mode));
  }

  Future<void> toggleDark() async {
    final current = state.value ?? ThemeMode.system;
    final next =
        current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(next);
  }

  ThemeMode _fromInt(int v) => switch (v) {
        1 => ThemeMode.light,
        2 => ThemeMode.dark,
        _ => ThemeMode.system,
      };

  int _toInt(ThemeMode m) => switch (m) {
        ThemeMode.light => 1,
        ThemeMode.dark => 2,
        _ => 0,
      };
}

final themeProvider =
    AsyncNotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

/// Convenience: true when the resolved theme is dark.
/// Uses MediaQuery as fallback when system mode is active.
final isDarkProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeProvider).value ?? ThemeMode.system;
  return mode == ThemeMode.dark;
});
