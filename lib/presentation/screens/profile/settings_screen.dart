import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('App Settings'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSettingRow(
                  'Notifications',
                  Icons.notifications,
                  Switch(
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(),
                _buildSettingRow(
                  'Dark Mode',
                  Icons.dark_mode,
                  Switch(
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() => _darkModeEnabled = value);
                    },
                    activeColor: AppColors.primary,
                  ),
                ),
                const Divider(),
                _buildSettingRow(
                  'Language',
                  Icons.language,
                  DropdownButton<String>(
                    value: _language,
                    underline: const SizedBox(),
                    items: ['English', 'Spanish', 'French']
                        .map((lang) => DropdownMenuItem(
                              value: lang,
                              child: Text(lang),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _language = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingRow(String title, IconData icon, Widget trailing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

