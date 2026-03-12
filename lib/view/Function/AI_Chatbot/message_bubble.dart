import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/chat_message_model.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isStreaming;

  const MessageBubble({
    Key? key,
    required this.message,
    this.isStreaming = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Avatar
          if (!message.isUser) ...[
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00CED1), Color(0xFF0097A7)],
                ),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],

          // Bubble
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyMessage(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? const Color(0xFF00CED1)
                      : isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8, offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MarkdownBody(
                      text: message.message,
                      isUser: message.isUser,
                      isDark: isDark,
                    ),
                    if (isStreaming && !message.isUser) const _BlinkingCursor(),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          DateFormat('HH:mm').format(message.timestamp),
                          style: TextStyle(
                            color: message.isUser
                                ? Colors.white.withOpacity(0.65)
                                : Colors.grey[400],
                            fontSize: 11,
                          ),
                        ),
                        if (!message.isUser) ...[
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => _copyMessage(context),
                            child: Icon(Icons.copy_rounded,
                                size: 13, color: Colors.grey[400]),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // User Avatar
          if (message.isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.blue[400],
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(children: [
          Icon(Icons.check_circle, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text('Đã sao chép'),
        ]),
        backgroundColor: const Color(0xFF00CED1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ✅ FULL MARKDOWN RENDERER
class _MarkdownBody extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isDark;

  const _MarkdownBody({
    required this.text,
    required this.isUser,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = isUser ? Colors.white : (isDark ? Colors.white : Colors.black87);
    final Color accentColor = isUser ? Colors.white : const Color(0xFF00CED1);

    final lines = text.split('\n');
    final List<Widget> widgets = [];
    int i = 0;

    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      // Dòng trống
      if (trimmed.isEmpty) {
        widgets.add(const SizedBox(height: 6));
        i++;
        continue;
      }

      // ── Code block ``` ──
      if (trimmed.startsWith('```')) {
        final buffer = StringBuffer();
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          buffer.writeln(lines[i]);
          i++;
        }
        i++;
        widgets.add(_buildCodeBlock(buffer.toString().trimRight(), isDark, accentColor));
        widgets.add(const SizedBox(height: 8));
        continue;
      }

      // ── Heading ### ## # ──
      if (trimmed.startsWith('### ')) {
        widgets.add(_buildHeading(trimmed.substring(4), textColor, 14));
        widgets.add(const SizedBox(height: 4));
        i++; continue;
      }
      if (trimmed.startsWith('## ')) {
        widgets.add(_buildHeading(trimmed.substring(3), textColor, 15));
        widgets.add(const SizedBox(height: 4));
        i++; continue;
      }
      if (trimmed.startsWith('# ')) {
        widgets.add(_buildHeading(trimmed.substring(2), textColor, 16));
        widgets.add(const SizedBox(height: 4));
        i++; continue;
      }

      // ── Numbered list 1. 2. ──
      final numberedMatch = RegExp(r'^(\d+)\.\s+(.+)').firstMatch(trimmed);
      if (numberedMatch != null) {
        widgets.add(_buildNumberedItem(
          numberedMatch.group(1)!,
          numberedMatch.group(2)!,
          textColor, accentColor,
        ));
        widgets.add(const SizedBox(height: 4));
        i++; continue;
      }

      // ── Bullet list - * • ──
      if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
        final content = trimmed.replaceFirst(RegExp(r'^[-*•]\s+'), '');
        widgets.add(_buildBulletItem(content, textColor, accentColor));
        widgets.add(const SizedBox(height: 3));
        i++; continue;
      }

      // ── Divider --- ──
      if (RegExp(r'^-{3,}$').hasMatch(trimmed)) {
        widgets.add(Divider(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          height: 16,
        ));
        i++; continue;
      }

      // ── Normal text ──
      widgets.add(_buildRichText(trimmed, textColor, accentColor, isDark));
      widgets.add(const SizedBox(height: 3));
      i++;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildHeading(String text, Color color, double size) {
    return Text(text, style: TextStyle(
      color: color, fontSize: size, fontWeight: FontWeight.bold, height: 1.4,
    ));
  }

  Widget _buildNumberedItem(String number, String content, Color textColor, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22, height: 22,
          margin: const EdgeInsets.only(top: 1, right: 8),
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Center(child: Text(number,
            style: TextStyle(color: accentColor, fontSize: 11, fontWeight: FontWeight.bold),
          )),
        ),
        Expanded(child: _buildRichText(content, textColor, accentColor, false)),
      ],
    );
  }

  Widget _buildBulletItem(String content, Color textColor, Color accentColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, right: 8, left: 4),
          child: Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
          ),
        ),
        Expanded(child: _buildRichText(content, textColor, accentColor, false)),
      ],
    );
  }

  Widget _buildCodeBlock(String code, bool isDark, Color accentColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF4F4F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: Text(code, style: TextStyle(
        fontFamily: 'monospace', fontSize: 12,
        color: isDark ? const Color(0xFF00CED1) : Colors.black87,
        height: 1.6,
      )),
    );
  }

  Widget _buildRichText(String text, Color textColor, Color accentColor, bool isDark) {
    final spans = <InlineSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*|\*(.*?)\*|`(.*?)`');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: text.substring(lastEnd, match.start),
          style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
        ));
      }

      if (match.group(1) != null) {
        // **bold**
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            color: accentColor, fontSize: 15,
            fontWeight: FontWeight.bold, height: 1.5,
          ),
        ));
      } else if (match.group(2) != null) {
        // *italic*
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            color: textColor, fontSize: 15,
            fontStyle: FontStyle.italic, height: 1.5,
          ),
        ));
      } else if (match.group(3) != null) {
        // `inline code`
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(match.group(3)!, style: TextStyle(
              fontFamily: 'monospace', fontSize: 13, color: accentColor,
            )),
          ),
        ));
      }
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastEnd),
        style: TextStyle(color: textColor, fontSize: 15, height: 1.5),
      ));
    }

    if (spans.isEmpty) {
      return Text(text, style: TextStyle(color: textColor, fontSize: 15, height: 1.5));
    }

    return RichText(text: TextSpan(children: spans));
  }
}

// ✅ Blinking cursor khi streaming
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
      vsync: this, duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: const Text('▌', style: TextStyle(color: Color(0xFF00CED1), fontSize: 15)),
    );
  }
}