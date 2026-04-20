import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/providers/biometric_provider.dart';

class PrivacySecurityScreen extends ConsumerWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bio = ref.watch(biometricProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Security'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: bio.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // ── Security ──────────────────────────────────────────────
                _Card(
                  children: [
                    _SectionTitle('Security'),
                    const SizedBox(height: 16),
                    _SecurityRow(
                      title: bio.isAvailable
                          ? 'Biometric Lock (${bio.label})'
                          : 'Biometric Lock',
                      subtitle: bio.isAvailable
                          ? 'Use ${bio.label} to unlock the app'
                          : 'Not available on this device',
                      icon: bio.label == 'Face ID'
                          ? Icons.face_unlock_rounded
                          : Icons.fingerprint,
                      trailing: Switch(
                        value: bio.isEnabled,
                        activeColor: AppColors.primary,
                        onChanged: bio.isAvailable
                            ? (value) async {
                                final ok = await ref
                                    .read(biometricProvider.notifier)
                                    .toggle(value);
                                if (!ok && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Biometric authentication failed or unavailable'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            : null,
                      ),
                    ),
                    if (bio.isEnabled)
                      Padding(
                        padding: const EdgeInsets.only(left: 40, top: 4),
                        child: Text(
                          '${bio.label} will be required each time you open the app',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary.withOpacity(0.8),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Data Management ───────────────────────────────────────
                _Card(
                  children: [
                    _SectionTitle('Data Management'),
                    const SizedBox(height: 16),
                    _ActionRow(
                      title: 'Export All Data',
                      subtitle: 'Download your data as a file',
                      icon: Icons.download,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Export feature coming soon')),
                      ),
                    ),
                    const Divider(height: 32),
                    _ActionRow(
                      title: 'Clear Cache',
                      subtitle: 'Free up storage space',
                      icon: Icons.cleaning_services,
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cache cleared'),
                          backgroundColor: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  const _SecurityRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
        ),
        trailing,
      ],
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}
