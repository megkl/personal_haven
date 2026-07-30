import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/data/models/subscription.dart';
import 'package:personal_haven/presentation/screens/auth/login_screen.dart';
import 'package:personal_haven/presentation/screens/legal/terms_screen.dart';
import 'package:personal_haven/presentation/screens/profile/edit_profile_screen.dart';
import 'package:personal_haven/presentation/screens/profile/mood_insights_screen.dart';
import 'package:personal_haven/presentation/screens/profile/privacy_security_screen.dart';
import 'package:personal_haven/presentation/screens/profile/settings_screen.dart';
import 'package:personal_haven/presentation/screens/subscription/subscription_screen.dart';
import 'package:personal_haven/presentation/widgets/common/network_avatar.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/providers/subscription_provider.dart';
import 'package:personal_haven/providers/user_provider.dart';

/// The account hub for personal details, preferences, and account actions.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isDeletingAccount = false;

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final user = userState.user;
    final subscription = ref.watch(subscriptionProvider);

    if (userState.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final displayName = user?.fullName ?? 'Personal Haven member';
    final email = user?.email ?? 'No email available';
    final bio = user?.bio?.trim();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildPageHeading(context),
                  const SizedBox(height: 18),
                  _buildProfileHeader(
                    context,
                    displayName: displayName,
                    email: email,
                    bio: bio,
                    avatarUrl: user?.avatarUrl,
                    membershipLabel: _membershipLabel(subscription),
                  ),
                  if (!subscription.hasFullAccess) ...[
                    const SizedBox(height: 14),
                    _buildPremiumBanner(context),
                  ],
                  const SizedBox(height: 18),
                  _ProfileSection(
                    title: 'Your haven',
                    children: [
                      _ProfileAction(
                        icon: Icons.insights_outlined,
                        title: 'Insights',
                        subtitle:
                            'See patterns in how you have been feeling and what you have achieved.',
                        onTap: () => _open(context, const MoodInsightsScreen()),
                      ),
                      _ProfileAction(
                        icon: Icons.tune_rounded,
                        title: 'App settings',
                        subtitle: 'Notifications, currency, and preferences',
                        onTap: () => _open(context, const SettingsScreen()),
                      ),
                      _ProfileAction(
                        icon: Icons.shield_outlined,
                        title: 'Privacy & security',
                        subtitle: 'Manage protection for your account',
                        onTap: () =>
                            _open(context, const PrivacySecurityScreen()),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _ProfileSection(
                    title: 'Legal & support',
                    children: [
                      _ProfileAction(
                        icon: Icons.description_outlined,
                        title: 'Terms & conditions',
                        onTap: () => openTermsAndConditions(context),
                      ),
                      _ProfileAction(
                        icon: Icons.privacy_tip_outlined,
                        title: 'Privacy policy',
                        onTap: () => openPrivacyPolicy(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _buildAccountActions(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeading(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Profile',
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.05,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Your account and personal preferences',
          style: TextStyle(color: context.colors.textSecondary, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildProfileHeader(
    BuildContext context, {
    required String displayName,
    required String email,
    required String? bio,
    required String? avatarUrl,
    required String membershipLabel,
  }) {
    return Semantics(
      button: true,
      label: 'Open personal details',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, const EditProfileScreen()),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF319E96), AppColors.primary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.22),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileAvatar(avatarUrl: avatarUrl, displayName: displayName),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        height: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.84),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              membershipLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (bio != null && bio.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        bio,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumBanner(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(context, const SubscriptionScreen()),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFFF2D6), Color(0xFFFFE3AA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE8B95C)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF9A6500),
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Unlock your full haven',
                      style: TextStyle(
                        color: Color(0xFF5F4108),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Explore every journal and wellness feature',
                      style: TextStyle(
                        color: Color(0xFF80601E),
                        fontSize: 12,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: Color(0xFF9A6500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account actions',
            style: TextStyle(
              color: context.colors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign out safely, or permanently remove your account and data.',
            style: TextStyle(
              color: context.colors.textSecondary,
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showLogoutDialog,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Log out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.colors.textPrimary,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: context.colors.divider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _isDeletingAccount ? null : _showDeleteAccountDialog,
            icon: _isDeletingAccount
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.delete_outline_rounded),
            label: Text(
              _isDeletingAccount ? 'Deleting account…' : 'Delete account',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size(double.infinity, 50),
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _membershipLabel(SubscriptionState subscription) {
    final active = subscription.active;
    if (active?.plan == SubscriptionPlan.free) {
      return 'Free trial · ${active!.daysRemaining} days left';
    }
    if (subscription.hasFullAccess) return 'Premium member';
    return 'Free account';
  }

  void _open(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmationController = TextEditingController();
    var confirmation = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 34,
          ),
          title: const Text(
            'Delete your account?',
            textAlign: TextAlign.center,
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your profile and all Personal Haven data will be permanently '
                  'deleted, including journals, moods, goals, tasks, wellness, '
                  'and budget records. This cannot be undone.',
                ),
                const SizedBox(height: 18),
                Text(
                  'Type DELETE to confirm',
                  style: TextStyle(
                    color: context.colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: confirmationController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'DELETE',
                    prefixIcon: Icon(Icons.delete_outline),
                  ),
                  onChanged: (value) => setDialogState(() {
                    confirmation = value.trim();
                  }),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Keep my account'),
            ),
            FilledButton(
              onPressed: confirmation == 'DELETE'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              child: const Text('Delete permanently'),
            ),
          ],
        ),
      ),
    );
    confirmationController.dispose();

    if (confirmed != true || !mounted) return;

    setState(() => _isDeletingAccount = true);
    final deleted = await ref.read(authProvider.notifier).deleteAccount();
    if (!mounted) return;

    if (deleted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
      return;
    }

    setState(() => _isDeletingAccount = false);
    final message =
        ref.read(authProvider).error ??
        'Account deletion failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: AppColors.primary),
        title: const Text('Log out?'),
        content: const Text(
          'You can sign back in at any time. Your saved data will remain in '
          'your Personal Haven account.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await ref.read(authProvider.notifier).logout();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (_) => false,
              );
            },
            child: const Text('Log out'),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.avatarUrl, required this.displayName});

  final String? avatarUrl;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final initial = displayName.trim().isEmpty
        ? 'P'
        : displayName.trim().characters.first.toUpperCase();
    return NetworkAvatar(
      size: 76,
      imageUrl: avatarUrl,
      border: Border.all(color: Colors.white.withValues(alpha: 0.72), width: 3),
      fallback: Text(
        initial,
        style: const TextStyle(
          color: AppColors.primaryDark,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
      decoration: BoxDecoration(
        color: context.colors.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: context.colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              title,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (var index = 0; index < children.length; index++) ...[
            children[index],
            if (index != children.length - 1)
              Divider(height: 1, indent: 62, color: context.colors.divider),
          ],
        ],
      ),
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primaryDark.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.primaryDark, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: context.colors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 12,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: context.colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
