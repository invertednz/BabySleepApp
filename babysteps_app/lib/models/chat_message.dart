import 'dart:typed_data';

enum MessageSender { user, ai }

class ChatMessage {
  final String? id;
  final String text;
  final MessageSender sender;
  final DateTime timestamp;
  final Uint8List? imageBytes;
  final String? imageMimeType;
  final bool isLoading;
  final bool isError;

  ChatMessage({
    this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.imageBytes,
    this.imageMimeType,
    this.isLoading = false,
    this.isError = false,
  });

  bool get hasImage => imageBytes != null && imageBytes!.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    String? text,
    MessageSender? sender,
    DateTime? timestamp,
    Uint8List? imageBytes,
    String? imageMimeType,
    bool? isLoading,
    bool? isError,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      imageBytes: imageBytes ?? this.imageBytes,
      imageMimeType: imageMimeType ?? this.imageMimeType,
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
    );
  }
}
