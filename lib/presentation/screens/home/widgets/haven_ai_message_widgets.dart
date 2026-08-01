import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';
import 'package:personal_haven/data/models/haven_chat_message.dart';

class HavenAiChatMessage {
  final String text;
  final bool isUser;
  final DateTime? createdAt;
  final HavenMessageStatus status;

  const HavenAiChatMessage({
    required this.text,
    required this.isUser,
    this.createdAt,
    this.status = HavenMessageStatus.sent,
  });
}

class HavenAiMessageBubble extends StatelessWidget {
  final HavenAiChatMessage message;

  const HavenAiMessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: message.isUser ? AppColors.primary : context.colors.cardColor2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(message.isUser ? 16 : 4),
            bottomRight: Radius.circular(message.isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser
                    ? Colors.white
                    : context.colors.textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            if (message.createdAt != null || message.isUser) ...[
              const SizedBox(height: 5),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.createdAt != null)
                    Text(
                      DateFormat('h:mm a').format(message.createdAt!),
                      style: TextStyle(
                        color: message.isUser
                            ? Colors.white70
                            : context.colors.textSecondary,
                        fontSize: 9.5,
                      ),
                    ),
                  if (message.isUser) ...[
                    if (message.createdAt != null) const SizedBox(width: 5),
                    Icon(
                      switch (message.status) {
                        HavenMessageStatus.sending => Icons.schedule_rounded,
                        HavenMessageStatus.failed =>
                          Icons.error_outline_rounded,
                        HavenMessageStatus.sent => Icons.done_rounded,
                      },
                      size: 12,
                      color: message.status == HavenMessageStatus.failed
                          ? const Color(0xFFFFD3D3)
                          : Colors.white70,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class HavenAiTypingBubble extends StatelessWidget {
  const HavenAiTypingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: context.colors.cardColor2,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}
