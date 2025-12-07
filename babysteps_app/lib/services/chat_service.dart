import 'dart:convert';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:babysteps_app/config/supabase_config.dart';

/// Service for AI chatbot functionality
class ChatService {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final _client = Supabase.instance.client;

  /// Send a message to the AI chatbot
  /// Returns the AI response or throws an exception
  Future<ChatResponse> sendMessage({
    required String babyId,
    required String message,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    // Build request body
    final body = <String, dynamic>{
      'baby_id': babyId,
      'message': message,
    };

    // Add image if provided
    if (imageBytes != null && imageMimeType != null) {
      body['image_base64'] = base64Encode(imageBytes);
      body['image_mime_type'] = imageMimeType;
    }

    // Call edge function
    final response = await _client.functions.invoke(
      'baby_chat',
      body: body,
    );

    if (response.status != 200) {
      final errorData = response.data;
      final errorMessage = errorData is Map ? errorData['error'] ?? 'Unknown error' : 'Request failed';
      
      if (response.status == 403) {
        throw PremiumRequiredException(errorMessage);
      }
      throw Exception(errorMessage);
    }

    final data = response.data as Map<String, dynamic>;
    return ChatResponse(
      response: data['response'] as String,
      contextUsed: List<String>.from(data['context_used'] ?? []),
      messageId: data['message_id'] as String?,
    );
  }

  /// Get chat history for a baby
  Future<List<ChatHistoryMessage>> getChatHistory({
    required String babyId,
    int limit = 50,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    final response = await _client
        .from('baby_chat_messages')
        .select('id, role, content, image_url, created_at')
        .eq('baby_id', babyId)
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    final messages = (response as List)
        .map((row) => ChatHistoryMessage.fromJson(row))
        .toList();

    // Return in chronological order
    return messages.reversed.toList();
  }

  /// Clear chat history for a baby
  Future<void> clearChatHistory({required String babyId}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    await _client
        .from('baby_chat_messages')
        .delete()
        .eq('baby_id', babyId)
        .eq('user_id', userId);
  }
}

/// Response from the AI chatbot
class ChatResponse {
  final String response;
  final List<String> contextUsed;
  final String? messageId;

  ChatResponse({
    required this.response,
    required this.contextUsed,
    this.messageId,
  });
}

/// A message from chat history
class ChatHistoryMessage {
  final String id;
  final String role;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  ChatHistoryMessage({
    required this.id,
    required this.role,
    required this.content,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatHistoryMessage.fromJson(Map<String, dynamic> json) {
    return ChatHistoryMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
  bool get hasImage => imageUrl != null && imageUrl!.isNotEmpty;
}

/// Exception thrown when premium is required
class PremiumRequiredException implements Exception {
  final String message;
  PremiumRequiredException(this.message);

  @override
  String toString() => message;
}
