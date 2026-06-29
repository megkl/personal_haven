import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _biometricLock = false;
  bool _cloudSync = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Privacy & Security'),
        backgroundColor: AppColors.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: context.colors.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSecurityRow(
                  'Biometric Lock',
                  'Use Face ID / Touch ID to unlock app',
                  Icons.fingerprint,
                  Switch(
                    value: _biometricLock,
                    onChanged: (value) {
                      setState(() => _biometricLock = value);
                    },
                    activeThumbColor: AppColors.primary,
                  ),
                ),
                // const Divider(height: 32),
                // _buildSecurityRow(
                //   'Cloud Sync',
                //   'Sync your data across devices',
                //   Icons.cloud,
                //   Switch(
                //     value: _cloudSync,
                //     onChanged: (value) {
                //       setState(() => _cloudSync = value);
                //     },
                //     activeThumbColor: AppColors.primary,
                //   ),
                // ),
                // if (!_cloudSync)
                //   Padding(
                //     padding: const EdgeInsets.only(left: 40, top: 8),
                //     child: Text(
                //       'All data will be stored only on this device',
                //       style: TextStyle(
                //         fontSize: 12,
                //         color: Colors.orange.shade700,
                //       ),
                //     ),
                //   ),
              ],
            ),
          ),
          // const SizedBox(height: 20),
          // Container(
          //   padding: const EdgeInsets.all(20),
          //   decoration: BoxDecoration(
          //     color: context.colors.cardColor,
          //     borderRadius: BorderRadius.circular(16),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: [
          //       Text(
          //         'Data Management',
          //         style: TextStyle(
          //           fontSize: 18,
          //           fontWeight: FontWeight.bold,
          //           color: context.colors.textPrimary,
          //         ),
          //       ),
          //       const SizedBox(height: 16),
          //       _buildActionButton(
          //         'Export All Data',
          //         'Download your data as ZIP file',
          //         Icons.download,
          //         () {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(
          //               content: Text('Export feature coming soon'),
          //             ),
          //           );
          //         },
          //       ),
          //       const Divider(height: 32),
          //       _buildActionButton(
          //         'Clear Cache',
          //         'Free up storage space',
          //         Icons.cleaning_services,
          //         () {
          //           ScaffoldMessenger.of(context).showSnackBar(
          //             const SnackBar(
          //               content: Text('Cache cleared successfully'),
          //               backgroundColor: AppColors.success,
          //             ),
          //           );
          //         },
          //       ),
          //     ],
          //   ),
          // ),
        
        ],
      ),
    );
  }

  Widget _buildSecurityRow(
    String title,
    String subtitle,
    IconData icon,
    Widget trailing,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: context.colors.textSecondary),
        ],
      ),
    );
  }
}
