import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider).value ?? ThemeMode.system;
    final isDark = themeMode == ThemeMode.dark;
    final colors = context.colors;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingRow(
                  context,
                  'Notifications',
                  Icons.notifications_outlined,
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) =>
                        setState(() => _notificationsEnabled = value),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                Divider(color: colors.divider),
                _buildSettingRow(
                  context,
                  'Dark Mode',
                  Icons.dark_mode_outlined,
                  Switch(
                    value: isDark,
                    onChanged: (_) =>
                        ref.read(themeProvider.notifier).toggleDark(),
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                Divider(color: colors.divider),
                _buildSettingRow(
                  context,
                  'Language',
                  Icons.language_outlined,
                  DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    dropdownColor: colors.cardColor,
                    style: TextStyle(color: colors.textPrimary, fontSize: 14),
                    items: ['English', 'Spanish', 'French']
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _language = value);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Theme mode selector
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _themeOption(
                      context,
                      label: 'Light',
                      icon: Icons.light_mode_outlined,
                      selected: themeMode == ThemeMode.light,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.light),
                    ),
                    const SizedBox(width: 10),
                    _themeOption(
                      context,
                      label: 'Dark',
                      icon: Icons.dark_mode_outlined,
                      selected: themeMode == ThemeMode.dark,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.dark),
                    ),
                    const SizedBox(width: 10),
                    _themeOption(
                      context,
                      label: 'System',
                      icon: Icons.brightness_auto_outlined,
                      selected: themeMode == ThemeMode.system,
                      onTap: () => ref
                          .read(themeProvider.notifier)
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(
    BuildContext context,
    String title,
    IconData icon,
    Widget trailing,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 16, color: colors.textPrimary),
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _themeOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.12)
                : colors.cardColor2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : colors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: selected ? AppColors.primary : colors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  color: selected ? AppColors.primary : colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
