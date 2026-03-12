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
  final Uuid _uuid = Uuid();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _isStreaming = false;
  String _streamingText = '';
  String? _streamingMessageId;
  List<String> _suggestedReplies = [];

  // ✅ Topic categories for quick access
  int _selectedTopicIndex = 0;
  final List<Map<String, dynamic>> _topics = [
    {
      'label': '💰 Tài chính',
      'color': const Color(0xFF00CED1),
      'actions': [
        {'emoji': '📊', 'label': 'Phân tích chi tiêu', 'msg': 'Phân tích chi tiêu của tôi tháng này'},
        {'emoji': '💰', 'label': 'Kiểm tra ngân sách', 'msg': 'Tôi có đang chi tiêu quá ngân sách không?'},
        {'emoji': '💡', 'label': 'Gợi ý tiết kiệm', 'msg': 'Làm thế nào để tôi tiết kiệm được nhiều hơn?'},
        {'emoji': '🔮', 'label': 'Dự đoán chi tiêu', 'msg': 'Dự đoán chi tiêu cuối tháng của tôi'},
      ],
    },
    {
      'label': '🏥 Sức khỏe',
      'color': Colors.green,
      'actions': [
        {'emoji': '🥗', 'label': 'Chế độ ăn uống', 'msg': 'Chế độ ăn uống lành mạnh cho người đi làm như thế nào?'},
        {'emoji': '🏃', 'label': 'Tập thể dục', 'msg': 'Lịch tập thể dục hiệu quả cho người bận rộn'},
        {'emoji': '😴', 'label': 'Giấc ngủ', 'msg': 'Làm sao để cải thiện chất lượng giấc ngủ?'},
        {'emoji': '🧘', 'label': 'Giảm stress', 'msg': 'Cách quản lý stress và lo âu hiệu quả'},
      ],
    },
    {
      'label': '💻 Công nghệ',
      'color': Colors.indigo,
      'actions': [
        {'emoji': '📱', 'label': 'Flutter/Dart', 'msg': 'Giải thích về Flutter và Dart cho người mới học'},
        {'emoji': '🔥', 'label': 'Firebase', 'msg': 'Firebase Firestore hoạt động như thế nào?'},
        {'emoji': '🤖', 'label': 'AI & ML', 'msg': 'Trí tuệ nhân tạo và Machine Learning là gì?'},
        {'emoji': '🌐', 'label': 'Web Dev', 'msg': 'Cách học lập trình web từ đầu'},
      ],
    },
    {
      'label': '⛪ Đức tin',
      'color': Colors.amber[700]!,
      'actions': [
        {'emoji': '📖', 'label': 'Kinh Thánh', 'msg': 'Giải thích về Tin Mừng Gioan chương 3'},
        {'emoji': '🙏', 'label': 'Cầu nguyện', 'msg': 'Cách cầu nguyện hiệu quả hơn trong cuộc sống bận rộn'},
        {'emoji': '✝️', 'label': 'Giáo lý', 'msg': 'Giải thích các Bí tích trong Công Giáo'},
        {'emoji': '🕊️', 'label': 'Đời sống tâm linh', 'msg': 'Làm sao để sống đức tin trong thời đại ngày nay?'},
      ],
    },
    {
      'label': '📚 Học tập',
      'color': Colors.orange,
      'actions': [
        {'emoji': '📝', 'label': 'Phương pháp học', 'msg': 'Phương pháp học tập hiệu quả nhất là gì?'},
        {'emoji': '🧮', 'label': 'Toán học', 'msg': 'Giải thích xác suất và thống kê cơ bản'},
        {'emoji': '🌍', 'label': 'Lịch sử VN', 'msg': 'Tóm tắt lịch sử Việt Nam qua các thời kỳ'},
        {'emoji': '🔬', 'label': 'Khoa học', 'msg': 'Giải thích về biến đổi khí hậu'},
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _sendWelcomeMessage();
  }

  void _sendWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        message: 'Xin chào! Tôi là **BuddyAI** 🤖\n\n'
            'Tôi có thể giúp bạn về **mọi lĩnh vực**:\n\n'
            '• 💰 Tài chính & Chi tiêu cá nhân\n'
            '• 🏥 Sức khỏe & Dinh dưỡng\n'
            '• 💻 Công nghệ & Lập trình\n'
            '• ⛪ Đức tin Công Giáo\n'
            '• 📚 Giáo dục & Học tập\n'
            '• 🌍 Lịch sử & Địa lý\n'
            '• 🧠 Khoa học & Nhiều hơn nữa...\n\n'
            'Bạn muốn hỏi gì hôm nay?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _suggestedReplies = [
        'Phân tích chi tiêu tháng này',
        'Cách học lập trình Flutter',
        'Chia sẻ về Tin Mừng hôm nay',
      ];
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping || _isStreaming) return;

    final userMsg = text.trim();
    _messageController.clear();
    _focusNode.unfocus();

    setState(() {
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        message: userMsg,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
      _suggestedReplies = [];
    });

    _scrollToBottom();

    try {
      String aiResponse = await _aiService.sendMessage(
        userMsg,
        chatHistory: _messages.length > 1
            ? _messages.sublist(0, _messages.length - 1)
            : [],
      );

      final streamId = _uuid.v4();
      setState(() {
        _isTyping = false;
        _isStreaming = true;
        _streamingText = '';
        _streamingMessageId = streamId;
        _messages.add(ChatMessage(
          id: streamId,
          message: '',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });

      // Stream từng ký tự
      for (int i = 0; i < aiResponse.length; i++) {
        await Future.delayed(const Duration(milliseconds: 10));
        if (!mounted) break;
        setState(() {
          _streamingText = aiResponse.substring(0, i + 1);
          final idx = _messages.indexWhere((m) => m.id == streamId);
          if (idx != -1) {
            _messages[idx] = ChatMessage(
              id: streamId,
              message: _streamingText,
              isUser: false,
              timestamp: _messages[idx].timestamp,
            );
          }
        });
        if (i % 30 == 0) _scrollToBottom();
      }

      setState(() {
        _isStreaming = false;
        _streamingMessageId = null;
        _suggestedReplies = _generateSuggestedReplies(userMsg);
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isTyping = false;
        _isStreaming = false;
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          message: 'Xin lỗi, tôi gặp sự cố kết nối. Vui lòng thử lại! 😅',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  List<String> _generateSuggestedReplies(String userMsg) {
    final msg = userMsg.toLowerCase();

    if (msg.contains('chi tiêu') || msg.contains('phân tích') || msg.contains('ngân sách')) {
      return ['Danh mục nào chi nhiều nhất?', 'Gợi ý cắt giảm chi tiêu', 'Kế hoạch tiết kiệm cho tôi'];
    } else if (msg.contains('tiết kiệm') || msg.contains('mục tiêu')) {
      return ['Quy tắc 50/30/20 là gì?', 'Cách tiết kiệm hiệu quả hơn', 'Đặt mục tiêu tài chính'];
    } else if (msg.contains('flutter') || msg.contains('dart') || msg.contains('lập trình')) {
      return ['Giải thích State Management', 'Firebase với Flutter', 'Tips debug Flutter'];
    } else if (msg.contains('kinh thánh') || msg.contains('công giáo') || msg.contains('đức tin') || msg.contains('cầu nguyện')) {
      return ['Chia sẻ về Tin Mừng hôm nay', 'Ý nghĩa của các Bí tích', 'Cách đọc Kinh Thánh mỗi ngày'];
    } else if (msg.contains('sức khỏe') || msg.contains('ăn') || msg.contains('tập')) {
      return ['Chế độ ăn lành mạnh', 'Lịch tập thể dục phù hợp', 'Cách giảm stress'];
    } else if (msg.contains('học') || msg.contains('lịch sử') || msg.contains('khoa học')) {
      return ['Phương pháp học hiệu quả', 'Giải thích chi tiết hơn', 'Cho ví dụ thực tế'];
    }

    return ['Hỏi thêm về tài chính', 'Tư vấn sức khỏe', 'Hỏi về lập trình'];
  }

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

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Xóa cuộc trò chuyện?'),
        content: const Text('Toàn bộ lịch sử chat sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _suggestedReplies = [];
              });
              _sendWelcomeMessage();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ✅ Topic selector tabs
  Widget _buildTopicTabs() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _topics.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedTopicIndex == index;
          final color = _topics[index]['color'] as Color;
          return GestureDetector(
            onTap: () => setState(() => _selectedTopicIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? color : color.withOpacity(0.3),
                ),
              ),
              child: Text(
                _topics[index]['label'],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ✅ Quick action grid per topic
  Widget _buildQuickActionGrid() {
    final actions = _topics[_selectedTopicIndex]['actions'] as List;
    final color = _topics[_selectedTopicIndex]['color'] as Color;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 3.0,
        children: actions.map((action) {
          return GestureDetector(
            onTap: () => _sendMessage(action['msg']),
            child: Container(
              decoration: BoxDecoration(
                color: color.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(action['emoji'], style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      action['label'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ✅ Suggested replies
  Widget _buildSuggestedReplies() {
    if (_suggestedReplies.isEmpty || _isTyping || _isStreaming) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gợi ý tiếp theo:',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _suggestedReplies.map((reply) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => _sendMessage(reply),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF00CED1).withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4)
                        ],
                      ),
                      child: Text(reply,
                          style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF00897B),
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
                borderRadius: BorderRadius.circular(19),
              ),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BuddyAI',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  _isTyping || _isStreaming ? 'Đang trả lời...' : 'Trợ lý AI toàn diện',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isTyping || _isStreaming
                        ? const Color(0xFF00CED1)
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
            onPressed: _clearConversation,
            tooltip: 'Xóa hội thoại',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick actions khi mới vào
          if (_messages.length <= 1) ...[
            const SizedBox(height: 8),
            _buildTopicTabs(),
            const SizedBox(height: 4),
            _buildQuickActionGrid(),
          ],

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const TypingIndicator();
                }
                final msg = _messages[index];
                return MessageBubble(
                  message: msg,
                  isStreaming: _isStreaming && msg.id == _streamingMessageId,
                );
              },
            ),
          ),

          // Suggested replies
          _buildSuggestedReplies(),

          // Input
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
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
                    focusNode: _focusNode,
                    enabled: !_isTyping && !_isStreaming,
                    decoration: InputDecoration(
                      hintText: _isTyping || _isStreaming
                          ? 'BuddyAI đang trả lời...'
                          : 'Hỏi bất cứ điều gì...',
                      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF3C3C3C)
                          : Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 15),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: _isTyping || _isStreaming
                        ? const LinearGradient(colors: [Colors.grey, Colors.grey])
                        : const LinearGradient(
                            colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _isTyping || _isStreaming
                        ? []
                        : [
                            BoxShadow(
                              color: const Color(0xFF00CED1).withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _isTyping || _isStreaming
                          ? Icons.hourglass_empty
                          : Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onPressed: _isTyping || _isStreaming
                        ? null
                        : () => _sendMessage(_messageController.text),
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
    _focusNode.dispose();
    super.dispose();
  }
}