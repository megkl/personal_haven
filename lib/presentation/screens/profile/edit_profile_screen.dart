import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/providers/auth_provider.dart';
import 'package:personal_haven/providers/user_provider.dart';

/// Edit Profile Screen - Update user profile information
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  bool _isDeletingAccount = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).user;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    await ref
        .read(userProvider.notifier)
        .updateProfile(
          firstName: _nameController.text.trim().isNotEmpty
              ? _nameController.text.trim()
              : null,
          bio: _bioController.text.isNotEmpty ? _bioController.text : null,
        );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmationController = TextEditingController();
    var confirmation = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Permanently delete account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently deletes your profile and all Personal Haven '
                'data, including journals, moods, goals, tasks, wellness, and '
                'budget records. This cannot be undone.',
              ),
              const SizedBox(height: 16),
              const Text('Type DELETE to confirm.'),
              const SizedBox(height: 8),
              TextField(
                controller: confirmationController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Confirmation',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => setDialogState(() {
                  confirmation = value.trim();
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: confirmation == 'DELETE'
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              child: const Text(
                'Delete permanently',
                style: TextStyle(color: Colors.red),
              ),
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
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    setState(() => _isDeletingAccount = false);
    final message =
        ref.read(authProvider).error ??
        'Account deletion failed. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).user;

    return Scaffold(
      backgroundColor: AppColors.primaryLight,
      appBar: AppBar(
        title: Text('Update Profile'),
        backgroundColor: AppColors.primaryLight,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile Avatar with Edit Button
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: context.colors.cardColor,
                  backgroundImage: user?.avatarUrl != null
                      ? NetworkImage(user!.avatarUrl!)
                      : null,
                  child: user?.avatarUrl == null
                      ? Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.primaryLight,
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      // TODO: Implement image picker
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image picker not yet implemented'),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              user?.fullName ?? 'User',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 40),
            // Name Field
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: context.colors.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Email Field (read-only — managed by Firebase Auth)
            TextField(
              controller: _emailController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Email Address',
                filled: true,
                fillColor: context.colors.cardColor2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(
                  Icons.lock_outline,
                  color: context.colors.textSecondary,
                ),
                helperText: 'Email is managed by your sign-in provider',
              ),
            ),
            const SizedBox(height: 16),
            // Bio Field
            TextField(
              controller: _bioController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Bio (Optional)',
                filled: true,
                fillColor: context.colors.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                suffixIcon: Icon(
                  Icons.edit,
                  color: context.colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Save Changes Button
            ElevatedButton(
              onPressed: _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: Text(
                'Save Changes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Delete Account Button
            TextButton(
              onPressed: _isDeletingAccount ? null : _showDeleteAccountDialog,
              child: _isDeletingAccount
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Delete Account',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
