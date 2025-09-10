import 'package:flutter/material.dart';
import 'package:babysteps_app/models/chat_message.dart';
import 'package:babysteps_app/theme/app_theme.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.sender == MessageSender.user;
    return Row(
      mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          decoration: BoxDecoration(
            color: isUserMessage ? AppTheme.primaryPurple : AppTheme.cardBackground,
            borderRadius: BorderRadius.circular(16).copyWith(
              bottomLeft: isUserMessage ? const Radius.circular(16) : Radius.zero,
              bottomRight: isUserMessage ? Radius.zero : const Radius.circular(16),
            ),
            border: isUserMessage ? null : Border.all(color: AppTheme.lightPurple)
          ),
          child: Text(
            message.text,
            style: TextStyle(color: isUserMessage ? Colors.white : AppTheme.textPrimary),
          ),
        ),
      ],
    );
  }
}
