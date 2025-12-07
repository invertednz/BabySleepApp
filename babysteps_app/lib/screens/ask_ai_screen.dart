import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:babysteps_app/models/chat_message.dart';
import 'package:babysteps_app/theme/app_theme.dart';
import 'package:babysteps_app/widgets/chat_message_bubble.dart';
import 'package:babysteps_app/services/chat_service.dart';
import 'package:babysteps_app/providers/auth_provider.dart';
import 'package:babysteps_app/providers/baby_provider.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';

class AskAiScreen extends StatefulWidget {
  const AskAiScreen({super.key});

  @override
  State<AskAiScreen> createState() => _AskAiScreenState();
}

class _AskAiScreenState extends State<AskAiScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatService = ChatService();
  final _imagePicker = ImagePicker();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  Uint8List? _pendingImage;
  String? _pendingImageMimeType;

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    final babyProvider = context.read<BabyProvider>();
    final baby = babyProvider.selectedBaby;
    
    if (baby == null) {
      setState(() {
        _isLoading = false;
        _messages = [
          ChatMessage(
            text: "Hi! I'm your BabySteps AI assistant. I can help answer questions about your baby's development, sleep, activities, and more. What would you like to know?",
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        ];
      });
      return;
    }

    try {
      final history = await _chatService.getChatHistory(babyId: baby.id);
      setState(() {
        _isLoading = false;
        if (history.isEmpty) {
          _messages = [
            ChatMessage(
              text: "Hi! I'm your BabySteps AI assistant. I can help answer questions about ${baby.name}'s development, sleep, activities, and more. You can also share photos and I'll help you understand what I see!\n\nWhat would you like to know?",
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ),
          ];
        } else {
          _messages = history.map((h) => ChatMessage(
            id: h.id,
            text: h.content,
            sender: h.isUser ? MessageSender.user : MessageSender.ai,
            timestamp: h.createdAt,
          )).toList();
        }
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages = [
          ChatMessage(
            text: "Hi! I'm your BabySteps AI assistant. How can I help you today?",
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        ];
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final mimeType = picked.mimeType ?? 'image/jpeg';
        
        setState(() {
          _pendingImage = bytes;
          _pendingImageMimeType = mimeType;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image: $e')),
      );
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        final mimeType = picked.mimeType ?? 'image/jpeg';
        
        setState(() {
          _pendingImage = bytes;
          _pendingImageMimeType = mimeType;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to take photo: $e')),
      );
    }
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImage = null;
      _pendingImageMimeType = null;
    });
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty && _pendingImage == null) return;

    final babyProvider = context.read<BabyProvider>();
    final baby = babyProvider.selectedBaby;
    
    if (baby == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a baby first')),
      );
      return;
    }

    // Capture pending image before clearing
    final imageToSend = _pendingImage;
    final imageMimeType = _pendingImageMimeType;

    // Add user message
    final userMessage = ChatMessage(
      text: text,
      sender: MessageSender.user,
      timestamp: DateTime.now(),
      imageBytes: imageToSend,
      imageMimeType: imageMimeType,
    );

    // Add loading indicator
    final loadingMessage = ChatMessage(
      text: '',
      sender: MessageSender.ai,
      timestamp: DateTime.now(),
      isLoading: true,
    );

    setState(() {
      _messages.add(userMessage);
      _messages.add(loadingMessage);
      _isSending = true;
    });

    _textController.clear();
    _clearPendingImage();
    _scrollToBottom();

    try {
      final response = await _chatService.sendMessage(
        babyId: baby.id,
        message: text.isNotEmpty ? text : 'What can you tell me about this image?',
        imageBytes: imageToSend,
        imageMimeType: imageMimeType,
      );

      // Remove loading message and add response
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          id: response.messageId,
          text: response.response,
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ));
        _isSending = false;
      });
      _scrollToBottom();
    } on PremiumRequiredException catch (_) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: 'AI Chat is a premium feature. Please upgrade to continue.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isSending = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          text: 'Sorry, something went wrong. Please try again.',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          isError: true,
        ));
        _isSending = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _clearChat() async {
    final babyProvider = context.read<BabyProvider>();
    final baby = babyProvider.selectedBaby;
    
    if (baby == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat History'),
        content: const Text('Are you sure you want to clear all chat messages? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _chatService.clearChatHistory(babyId: baby.id);
        setState(() {
          _messages = [
            ChatMessage(
              text: "Chat cleared. How can I help you with ${baby.name}?",
              sender: MessageSender.ai,
              timestamp: DateTime.now(),
            ),
          ];
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear chat: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final babyProvider = context.watch<BabyProvider>();
    final isPaid = authProvider.isPaidUser;
    final baby = babyProvider.selectedBaby;

    return Scaffold(
      appBar: AppBar(
        title: Text(baby != null ? 'Ask about ${baby.name}' : 'Ask AI'),
        backgroundColor: AppTheme.background,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          if (_messages.length > 1)
            IconButton(
              icon: const Icon(FeatherIcons.trash2),
              onPressed: _clearChat,
              tooltip: 'Clear chat',
            ),
        ],
      ),
      body: !isPaid
          ? _buildPremiumPrompt()
          : _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return ChatMessageBubble(message: _messages[index]);
                        },
                      ),
                    ),
                    _buildSuggestionChips(),
                    _buildTextInput(),
                  ],
                ),
    );
  }

  Widget _buildPremiumPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.lightPurple.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.smart_toy_outlined,
                size: 64,
                color: AppTheme.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Assistant',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Get personalized answers about your baby\'s development, sleep, activities, and more with our AI assistant.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/premium');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Upgrade to Premium',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChips() {
    if (_messages.length > 2 || _isSending) return const SizedBox.shrink();
    
    final babyProvider = context.read<BabyProvider>();
    final baby = babyProvider.selectedBaby;
    final babyName = baby?.name ?? 'my baby';

    final suggestions = [
      'Is $babyName on track?',
      'Sleep tips',
      'Play activities',
      'Feeding advice',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((suggestion) => ActionChip(
          label: Text(suggestion),
          labelStyle: TextStyle(color: AppTheme.primaryPurple, fontSize: 13),
          backgroundColor: AppTheme.lightPurple.withOpacity(0.2),
          side: BorderSide(color: AppTheme.lightPurple),
          onPressed: () {
            _textController.text = suggestion;
            _sendMessage();
          },
        )).toList(),
      ),
    );
  }

  Widget _buildTextInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show pending image preview
            if (_pendingImage != null) ...[
              Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: MemoryImage(_pendingImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: -4,
                    right: -4,
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.close, size: 16, color: Colors.grey.shade700),
                      ),
                      onPressed: _clearPendingImage,
                    ),
                  ),
                ],
              ),
            ],
            Row(
              children: [
                // Image picker button
                IconButton(
                  icon: Icon(FeatherIcons.image, color: AppTheme.textSecondary),
                  onPressed: _isSending ? null : _pickImage,
                  tooltip: 'Add image',
                ),
                // Camera button
                IconButton(
                  icon: Icon(FeatherIcons.camera, color: AppTheme.textSecondary),
                  onPressed: _isSending ? null : _takePhoto,
                  tooltip: 'Take photo',
                ),
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: _pendingImage != null 
                          ? 'Ask about this image...' 
                          : 'Ask me anything...',
                      border: InputBorder.none,
                      filled: false,
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    FeatherIcons.send,
                    color: _isSending ? AppTheme.textSecondary : AppTheme.primaryPurple,
                  ),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
