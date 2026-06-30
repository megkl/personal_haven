import 'package:flutter/material.dart';
import 'package:personal_haven/core/constants/app_colors.dart';
import 'package:personal_haven/core/theme/app_theme.dart';

class HavenAiChatMessage {
  final String text;
  final bool isUser;

  const HavenAiChatMessage({required this.text, required this.isUser});
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
        child: Text(
          message.text,
          style: TextStyle(
            color: message.isUser ? Colors.white : context.colors.textPrimary,
            fontSize: 13,
            height: 1.35,
          ),
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
