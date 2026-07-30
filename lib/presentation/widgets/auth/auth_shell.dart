import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    required this.imagePath,
    required this.imageSemanticLabel,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.content,
    required this.footer,
    super.key,
  });

  final String imagePath;
  final String imageSemanticLabel;
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget content;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final illustrationHeight = (screenHeight * 0.39).clamp(220.0, 340.0);

    return Scaffold(
      backgroundColor: isDark
          ? theme.scaffoldBackgroundColor
          : const Color(0xFFDDF4F1),
      body: Stack(
        children: [
          Positioned(
            right: -86,
            top: -92,
            child: _DecorativeCircle(
              size: 245,
              color: AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.14),
            ),
          ),
          Positioned(
            left: -92,
            bottom: -105,
            child: _DecorativeCircle(
              size: 230,
              color: AppColors.primaryLight.withValues(
                alpha: isDark ? 0.05 : 0.58,
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverToBoxAdapter(child: _buildBrand(theme)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(25, 27, 25, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.25,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          title,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontSize: 31,
                            height: 1.08,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 650),
                    curve: Curves.easeOutCubic,
                    tween: Tween(begin: 0.93, end: 1),
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: Opacity(
                        opacity: ((value - 0.93) / 0.07).clamp(0, 1),
                        child: child,
                      ),
                    ),
                    child: Semantics(
                      image: true,
                      label: imageSemanticLabel,
                      child: Image.asset(
                        imagePath,
                        height: illustrationHeight,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        excludeFromSemantics: true,
                      ),
                    ),
                  ),
                ),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Text(
                            subtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: context.colors.textSecondary,
                              fontSize: 15,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        content,
                        const Spacer(),
                        const SizedBox(height: 18),
                        footer,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.82),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.spa_rounded,
              size: 21,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Personal Haven',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthActionButton extends StatelessWidget {
  const AuthActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isLoading = false,
    this.emphasized = true,
    super.key,
  });

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 58,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: emphasized
              ? AppColors.primaryDark
              : theme.colorScheme.surface,
          foregroundColor: emphasized
              ? Colors.white
              : context.colors.textPrimary,
          disabledBackgroundColor: emphasized
              ? AppColors.textPrimary.withValues(alpha: 0.65)
              : theme.colorScheme.surface,
          side: emphasized
              ? BorderSide.none
              : BorderSide(color: AppColors.primary.withValues(alpha: 0.45)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.primary,
                  ),
                )
              : Row(
                  key: const ValueKey('content'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: emphasized
                            ? Colors.white
                            : AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: icon,
                    ),
                    const SizedBox(width: 11),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    required this.message,
    required this.actionLabel,
    required this.onPressed,
    super.key,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(message, style: TextStyle(color: context.colors.textSecondary)),
        TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primaryDark,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            actionLabel,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  const _DecorativeCircle({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
