import 'package:flutter/material.dart';
import 'package:babysteps_app/models/chat_message.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatMessageBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatMessageBubble({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    final isUserMessage = message.sender == MessageSender.user;
    
    // Loading indicator for AI thinking
    if (message.isLoading) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: Radius.zero,
              ),
              border: Border.all(color: AppTheme.lightPurple),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryPurple),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Thinking...',
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Error state
    if (message.isError) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: Radius.zero,
              ),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade400, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message.text,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: isUserMessage ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUserMessage) ...[
          Container(
            margin: const EdgeInsets.only(left: 8, top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.lightPurple.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.smart_toy_outlined,
              size: 16,
              color: AppTheme.primaryPurple,
            ),
          ),
        ],
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            decoration: BoxDecoration(
              color: isUserMessage ? AppTheme.primaryPurple : AppTheme.cardBackground,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: isUserMessage ? const Radius.circular(16) : Radius.zero,
                bottomRight: isUserMessage ? Radius.zero : const Radius.circular(16),
              ),
              border: isUserMessage ? null : Border.all(color: AppTheme.lightPurple),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show image if attached
                if (message.hasImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      message.imageBytes!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (message.text.isNotEmpty) const SizedBox(height: 8),
                ],
                // Message text - use markdown for AI responses
                if (message.text.isNotEmpty)
                  isUserMessage
                      ? Text(
                          message.text,
                          style: const TextStyle(color: Colors.white),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                            strong: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                            em: TextStyle(color: AppTheme.textPrimary, fontStyle: FontStyle.italic),
                            listBullet: TextStyle(color: AppTheme.textPrimary),
                            h1: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
                            h2: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                            h3: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          shrinkWrap: true,
                          softLineBreak: true,
                        ),
              ],
            ),
          ),
        ),
        if (isUserMessage) ...[
          Container(
            margin: const EdgeInsets.only(right: 8, top: 4),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.person_outline,
              size: 16,
              color: AppTheme.primaryPurple,
            ),
          ),
        ],
      ],
    );
  }
}
