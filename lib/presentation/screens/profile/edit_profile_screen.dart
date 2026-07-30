import 'package:flutter/material.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/presentation/widgets/common/network_avatar.dart';
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
  bool _isSaving = false;

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
    if (_isSaving) return;
    final fullName = _nameController.text.trim();
    if (fullName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final nameParts = fullName.split(RegExp(r'\s+'));
    await ref
        .read(userProvider.notifier)
        .updateProfile(
          firstName: nameParts.first,
          lastName: nameParts.skip(1).join(' '),
          bio: _bioController.text.trim(),
        );

    if (!mounted) return;
    final error = ref.read(userProvider).error;
    if (error != null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.error),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Edit profile'),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: context.colors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF319E96), AppColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryDark.withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            shape: BoxShape.circle,
                          ),
                          child: NetworkAvatar(
                            size: 76,
                            imageUrl: user?.avatarUrl,
                            backgroundColor: Colors.white,
                            fallback: const Icon(
                              Icons.person_rounded,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal details',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Keep your haven feeling personal and familiar.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.86),
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.colors.cardColor,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel(
                          label: 'Full name',
                          icon: Icons.badge_outlined,
                        ),
                        const SizedBox(height: 9),
                        TextField(
                          controller: _nameController,
                          enabled: !_isSaving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.name],
                          decoration: _fieldDecoration(
                            context,
                            hintText: 'Your full name',
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel(
                          label: 'Email address',
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 9),
                        TextField(
                          controller: _emailController,
                          readOnly: true,
                          decoration: _fieldDecoration(
                            context,
                            hintText: 'Email address',
                            readOnly: true,
                            suffixIcon: Icons.lock_outline_rounded,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Managed securely by your sign-in provider',
                          style: TextStyle(
                            color: context.colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _FieldLabel(
                          label: 'Bio',
                          icon: Icons.notes_rounded,
                          optional: true,
                        ),
                        const SizedBox(height: 9),
                        TextField(
                          controller: _bioController,
                          enabled: !_isSaving,
                          minLines: 3,
                          maxLines: 5,
                          maxLength: 160,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: _fieldDecoration(
                            context,
                            hintText:
                                'A short note about you, your focus, or what matters most.',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _isSaving ? null : _saveChanges,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.check_rounded),
                    label: Text(_isSaving ? 'Saving changes…' : 'Save changes'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.64,
                      ),
                      disabledForegroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Changes appear on your profile immediately.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    BuildContext context, {
    required String hintText,
    bool readOnly = false,
    bool alignLabelWithHint = false,
    IconData? suffixIcon,
  }) {
    final borderColor = AppColors.primary.withValues(alpha: 0.16);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: borderColor),
    );

    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: context.colors.textSecondary.withValues(alpha: 0.78),
        fontSize: 14,
      ),
      alignLabelWithHint: alignLabelWithHint,
      filled: true,
      fillColor: readOnly
          ? context.colors.cardColor2
          : Theme.of(context).scaffoldBackgroundColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      suffixIcon: suffixIcon == null
          ? null
          : Icon(suffixIcon, size: 19, color: context.colors.textSecondary),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.icon,
    this.optional = false,
  });

  final String label;
  final IconData icon;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: context.colors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text(
            'Optional',
            style: TextStyle(color: context.colors.textSecondary, fontSize: 12),
          ),
        ],
      ],
    );
  }
}
