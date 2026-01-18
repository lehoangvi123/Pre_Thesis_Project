import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_message_model.dart';
import '../../../service/ai_assistant_service.dart';
import 'message_bubble.dart';
import 'typing_indicator.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({Key? key}) : super(key: key);

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView> {
  final AIAssistantService _aiService = AIAssistantService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  final Uuid _uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _sendWelcomeMessage();
  }

  // Send welcome message
  void _sendWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        message: 'Xin chào! Tôi là BuddyAI 🤖\n\n'
            'Tôi có thể giúp bạn:\n'
            '💰 Phân tích chi tiêu\n'
            '📊 Kiểm tra ngân sách\n'
            '💡 Gợi ý tiết kiệm\n'
            '🎯 Theo dõi mục tiêu\n\n'
            'Bạn muốn hỏi gì về tài chính của mình?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    });
  }

  // Send message
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        message: text,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Get AI response
    try {
      String aiResponse = await _aiService.sendMessage(text, chatHistory: _messages);

      setState(() {
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          message: aiResponse,
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          message: 'Xin lỗi, tôi gặp sự cố. Vui lòng thử lại! 😅',
          isUser: false,
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
    }

    _scrollToBottom();
  }

  // Scroll to bottom
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Quick action buttons
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _quickActionChip('📊 Phân tích chi tiêu', () {
              _sendMessage('Phân tích chi tiêu của tôi tháng này');
            }),
            const SizedBox(width: 8),
            _quickActionChip('💰 Kiểm tra ngân sách', () {
              _sendMessage('Tôi có đang chi tiêu quá ngân sách không?');
            }),
            const SizedBox(width: 8),
            _quickActionChip('💡 Gợi ý tiết kiệm', () {
              _sendMessage('Làm thế nào để tiết kiệm nhiều hơn?');
            }),
            const SizedBox(width: 8),
            _quickActionChip('🔮 Dự đoán', () {
              _sendMessage('Dự đoán chi tiêu cuối tháng');
            }),
          ],
        ),
      ),
    );
  }

  Widget _quickActionChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        backgroundColor: Colors.teal.withOpacity(0.1),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('BuddyAI', style: TextStyle(fontSize: 18)),
                Text('Trợ lý tài chính AI',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Column(
        children: [
          // Quick actions
          if (_messages.length <= 1) _buildQuickActions(),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const TypingIndicator();
                }
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),

          // Input field
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Hỏi BuddyAI về tài chính...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.teal,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: () => _sendMessage(_messageController.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}