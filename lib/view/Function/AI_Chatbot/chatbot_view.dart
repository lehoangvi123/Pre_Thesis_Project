// lib/view/Function/AI_Chatbot/chatbot_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:uuid/uuid.dart';
import '../../../models/chat_message_model.dart';
import '../../../service/ai_assistant_service.dart';
import 'typing_indicator.dart';

class ChatbotView extends StatefulWidget {
  const ChatbotView({Key? key}) : super(key: key);

  @override
  State<ChatbotView> createState() => _ChatbotViewState();
}

class _ChatbotViewState extends State<ChatbotView>
    with TickerProviderStateMixin {
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
  bool _hasStartedChat = false; // ✅ Ẩn welcome khi đã chat

  // ✅ Suggested prompts kiểu ChatGPT
  final List<Map<String, String>> _suggestions = [
    {'emoji': '', 'text': 'Phân tích chi tiêu tháng này'},
    {'emoji': '', 'text': 'Làm sao để tiết kiệm nhiều hơn?'},
    {'emoji': '', 'text': 'Chia sẻ Tin Mừng hôm nay'},
    {'emoji': '', 'text': 'Giải thích Flutter cho người mới'},
  ];

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() => setState(() {}));
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping || _isStreaming) return;

    final userMsg = text.trim();
    _messageController.clear();
    _focusNode.unfocus();

    if (!mounted) return;
    setState(() {
      _hasStartedChat = true;
      _messages.add(ChatMessage(
        id: _uuid.v4(),
        message: userMsg,
        isUser: true,
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    try {
      String aiResponse = await _aiService.sendMessage(
        userMsg,
        chatHistory: _messages.length > 1
            ? _messages.sublist(0, _messages.length - 1)
            : [],
      );

      if (!mounted) return;

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

      for (int i = 0; i < aiResponse.length; i++) {
        await Future.delayed(const Duration(milliseconds: 8));
        if (!mounted) return;
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
        if (i % 40 == 0) _scrollToBottom();
      }

      if (!mounted) return;
      setState(() {
        _isStreaming = false;
        _streamingMessageId = null;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isTyping = false;
        _isStreaming = false;
        _messages.add(ChatMessage(
          id: _uuid.v4(),
          message: 'Xin lỗi, có lỗi xảy ra. Vui lòng thử lại!',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    if (mounted) _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Xóa cuộc trò chuyện?'),
        content: const Text('Toàn bộ lịch sử sẽ bị xóa.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _messages.clear();
                _hasStartedChat = false;
              });
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF212121) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0D0D0D);
    final subColor = isDark ? const Color(0xFF8E8EA0) : const Color(0xFF8E8EA0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: textColor, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'BuddyAI',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: textColor),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                color: subColor, size: 20),
          ],
        ),
        actions: [
          if (_messages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.edit_outlined, color: textColor, size: 20),
              onPressed: _clearChat,
              tooltip: 'Cuộc trò chuyện mới',
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _hasStartedChat
                ? _buildChatList(isDark, textColor, subColor)
                : _buildWelcomeScreen(isDark, textColor, subColor),
          ),
          _buildInputBar(isDark, textColor, subColor),
        ],
      ),
    );
  }

  // ✅ Welcome screen kiểu ChatGPT
  Widget _buildWelcomeScreen(
      bool isDark, Color textColor, Color subColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 48),

          // Logo / icon
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2F2F2F)
                  : const Color(0xFFF4F4F4),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? const Color(0xFF444444)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(height: 20),

          // Greeting
          Text(
            'Tôi có thể giúp gì cho bạn?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 48),

          // Suggestion cards — 2x2 grid kiểu ChatGPT
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.55,
            children: _suggestions.map((s) {
              return _buildSuggestionCard(s, isDark, textColor);
            }).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(
      Map<String, String> s, bool isDark, Color textColor) {
    return GestureDetector(
      onTap: () => _sendMessage(s['text']!),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2F2F2F)
              : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3F3F3F)
                : const Color(0xFFE5E5E5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s['emoji']!, style: const TextStyle(fontSize: 20)),
            const Spacer(),
            Text(
              s['text']!,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Chat list — clean, no bubbles background noise
  Widget _buildChatList(bool isDark, Color textColor, Color subColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _messages.length + (_isTyping ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingRow(isDark);
        }
        final msg = _messages[index];
        if (msg.isUser) {
          return _buildUserMessage(msg, isDark, textColor);
        } else {
          return _buildAIMessage(
              msg, isDark, textColor, subColor,
              isStreaming: _isStreaming && msg.id == _streamingMessageId);
        }
      },
    );
  }

  // ✅ User message — right aligned, teal bubble
  Widget _buildUserMessage(
      ChatMessage msg, bool isDark, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                Clipboard.setData(ClipboardData(text: msg.message));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Đã sao chép'),
                      duration: Duration(seconds: 1)),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2F2F2F)
                      : const Color(0xFFF4F4F4),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  msg.message,
                  style: TextStyle(
                      fontSize: 15, color: textColor, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ AI message — left aligned, no bubble, just text + avatar
  Widget _buildAIMessage(ChatMessage msg, bool isDark, Color textColor,
      Color subColor,
      {bool isStreaming = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI avatar
          Container(
            width: 30, height: 30,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration( 
              color: isDark
                  ? const Color(0xFF2F2F2F)
                  : const Color(0xFFF4F4F4),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF444444)
                      : const Color(0xFFE5E5E5)),
            ),
            child: const Center(
              child: Text('🤖', style: TextStyle(fontSize: 14)),
            ),
          ),

          // Message content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.message.isEmpty && isStreaming)
                  _buildTypingDots(isDark)
                else
                  GestureDetector(
                    onLongPress: () {
                      Clipboard.setData(
                          ClipboardData(text: msg.message));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Đã sao chép'),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: _buildFormattedText(
                        msg.message, textColor, isStreaming),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30, height: 30,
            margin: const EdgeInsets.only(right: 12, top: 2),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2F2F2F)
                  : const Color(0xFFF4F4F4),
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark
                      ? const Color(0xFF444444)
                      : const Color(0xFFE5E5E5)),
            ),
            child: const Center(
                child: Text('🤖', style: TextStyle(fontSize: 14))),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildTypingDots(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDots(bool isDark) {
    return const SizedBox(
      height: 20,
      child: TypingIndicator(),
    );
  }

  // ✅ Simple markdown-like renderer
  Widget _buildFormattedText(
      String text, Color textColor, bool isStreaming) {
    final lines = text.split('\n');
    final widgets = <Widget>[];

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(line.substring(3),
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor)),
        ));
      } else if (line.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Text(line.substring(4),
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor)),
        ));
      } else if (line.startsWith('- ') || line.startsWith('• ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 7, right: 8),
                child: Container(
                    width: 5, height: 5,
                    decoration: const BoxDecoration(
                        color: Color(0xFF00CED1),
                        shape: BoxShape.circle)),
              ),
              Expanded(
                child: _buildInlineText(
                    line.substring(2), textColor),
              ),
            ],
          ),
        ));
      } else if (RegExp(r'^\d+\. ').hasMatch(line)) {
        final match = RegExp(r'^(\d+)\. (.+)').firstMatch(line);
        if (match != null) {
          widgets.add(Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 22, height: 22,
                  margin: const EdgeInsets.only(right: 8, top: 1),
                  decoration: const BoxDecoration(
                      color: Color(0xFF00CED1),
                      shape: BoxShape.circle),
                  child: Center(
                    child: Text(match.group(1)!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                Expanded(
                    child: _buildInlineText(
                        match.group(2)!, textColor)),
              ],
            ),
          ));
        }
      } else if (line.trim().isEmpty) {
        widgets.add(const SizedBox(height: 6));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: _buildInlineText(line, textColor),
        ));
      }
    }

    // Blinking cursor khi đang stream
    if (isStreaming && text.isNotEmpty) {
      widgets.add(_buildCursor());
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: widgets);
  }

  Widget _buildInlineText(String text, Color textColor) {
    // Bold: **text**
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    int last = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > last) {
        spans.add(TextSpan(
            text: text.substring(last, match.start),
            style: TextStyle(
                color: textColor, fontSize: 15, height: 1.6)));
      }
      spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
              color: textColor,
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w700)));
      last = match.end;
    }
    if (last < text.length) {
      spans.add(TextSpan(
          text: text.substring(last),
          style:
              TextStyle(color: textColor, fontSize: 15, height: 1.6)));
    }

    if (spans.isEmpty) {
      return Text(text,
          style:
              TextStyle(color: textColor, fontSize: 15, height: 1.6));
    }
    return RichText(
        text: TextSpan(children: spans),
        textAlign: TextAlign.left);
  }

  Widget _buildCursor() {
    return const _BlinkingCursor();
  }

  // ✅ Input bar — kiểu ChatGPT, rounded, clean
  Widget _buildInputBar(bool isDark, Color textColor, Color subColor) {
    final hasText = _messageController.text.trim().isNotEmpty;
    final isBusy = _isTyping || _isStreaming;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      color: isDark ? const Color(0xFF212121) : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2F2F2F)
              : const Color(0xFFF4F4F4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF3F3F3F)
                : const Color(0xFFE5E5E5),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                enabled: !isBusy,
                maxLines: 5,
                minLines: 1,
                textInputAction: TextInputAction.newline,
                style: TextStyle(
                    color: textColor, fontSize: 15, height: 1.4),
                decoration: InputDecoration(
                  hintText: isBusy
                      ? 'BuddyAI đang trả lời...'
                      : 'Hỏi bất cứ điều gì...',
                  hintStyle:
                      TextStyle(color: subColor, fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),

            // Send button
            Padding(
              padding: const EdgeInsets.only(right: 8, bottom: 8),
              child: GestureDetector(
                onTap: (hasText && !isBusy)
                    ? () => _sendMessage(_messageController.text)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    color: (hasText && !isBusy)
                        ? const Color(0xFF00CED1)
                        : (isDark
                            ? const Color(0xFF3F3F3F)
                            : const Color(0xFFE5E5E5)),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBusy
                        ? Icons.stop_rounded
                        : Icons.arrow_upward_rounded,
                    color: (hasText && !isBusy)
                        ? Colors.white
                        : subColor,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
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

// ✅ Blinking cursor widget
class _BlinkingCursor extends StatefulWidget {
  const _BlinkingCursor();

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Opacity(
        opacity: _controller.value,
        child: Container(
          width: 2, height: 18,
          margin: const EdgeInsets.only(top: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF00CED1),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}