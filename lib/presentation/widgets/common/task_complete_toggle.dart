import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';

class TaskCompleteToggle extends StatelessWidget {
  const TaskCompleteToggle({
    super.key,
    required this.isCompleted,
    required this.onTap,
    this.color,
    this.size = 26,
  });

  final bool isCompleted;
  final VoidCallback onTap;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;

    return Semantics(
      button: true,
      checked: isCompleted,
      label: isCompleted ? 'Mark task incomplete' : 'Mark task complete',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? AppColors.primary : Colors.transparent,
            border: Border.all(
              color: isCompleted
                  ? AppColors.primary
                  : activeColor.withValues(alpha: 0.62),
              width: 1.8,
            ),
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            child: isCompleted
                ? Icon(
                    Icons.check_rounded,
                    key: const ValueKey('complete'),
                    color: Colors.white,
                    size: size * 0.62,
                  )
                : Center(
                    key: const ValueKey('empty'),
                    child: Container(
                      width: size * 0.28,
                      height: size * 0.28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: activeColor.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
