import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/providers/biometric_provider.dart';

class PrivacySecurityScreen extends ConsumerStatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  ConsumerState<PrivacySecurityScreen> createState() =>
      _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends ConsumerState<PrivacySecurityScreen> {
  @override
  Widget build(BuildContext context) {
    final biometric = ref.watch(biometricProvider);
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
                  biometric.isAvailable
                      ? 'Use ${biometric.label} to unlock Personal Haven'
                      : 'Set up Face ID or fingerprint in device settings first',
                  Icons.fingerprint,
                  Switch(
                    value: biometric.isEnabled,
                    onChanged: biometric.isLoading || !biometric.isAvailable
                        ? null
                        : _toggleBiometric,
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

  Future<void> _toggleBiometric(bool value) async {
    final changed = await ref.read(biometricProvider.notifier).toggle(value);
    if (!mounted) return;

    final biometric = ref.read(biometricProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          changed
              ? value
                    ? '${biometric.label} lock enabled'
                    : 'Biometric lock disabled'
              : 'Biometric verification was not completed',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: changed ? AppColors.primary : Colors.red,
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
}
