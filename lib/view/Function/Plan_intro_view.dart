// lib/view/Function/Plan/plan_intro_view.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanIntroView extends StatefulWidget {
  final VoidCallback onStartForm;
  final VoidCallback onFreeChat;

  const PlanIntroView({
    Key? key,
    required this.onStartForm,
    required this.onFreeChat,
  }) : super(key: key);

  @override
  State<PlanIntroView> createState() => _PlanIntroViewState();
}

class _PlanIntroViewState extends State<PlanIntroView>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>  _fade;
  late Animation<Offset>  _slide;

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('plan_intro_seen', true);
  }

  void _goForm() async {
    await _markSeen();
    widget.onStartForm();
  }

  void _goChat() async {
    await _markSeen();
    widget.onFreeChat();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(children: [
                const Spacer(flex: 2),

                // Icon
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_teal, _purple],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                        color: _teal.withOpacity(0.3),
                        blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: Colors.white, size: 44),
                ),

                const SizedBox(height: 28),

                Text('Lập kế hoạch\ntài chính cá nhân',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26,
                        fontWeight: FontWeight.bold, height: 1.25,
                        color: isDark ? Colors.white : Colors.black87)),

                const SizedBox(height: 14),

                Text('Chọn cách phù hợp với bạn để\nnhận kế hoạch chi tiêu chi tiết',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),

                const SizedBox(height: 36),

                // Card 1 — Form
                _OptionCard(
                  icon: Icons.format_list_bulleted_rounded,
                  iconColor: _teal,
                  title: 'Điền theo hướng dẫn',
                  desc: 'Trả lời 4 bước đơn giản — hệ thống tự lập bảng chi tiêu phù hợp cho bạn',
                  badge: 'Được dùng nhiều nhất',
                  badgeColor: _teal,
                  isDark: isDark,
                  onTap: _goForm,
                ),

                const SizedBox(height: 12),

                // Card 2 — Chat
                _OptionCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: _purple,
                  title: 'Tạo plan tự do',
                  desc: 'Nhắn tin tự nhiên như hỏi bạn bè — không cần điền form',
                  badge: null,
                  badgeColor: _purple,
                  isDark: isDark,
                  onTap: _goChat,
                ),

                const Spacer(flex: 3),

                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text('Bạn có thể đổi cách bất cứ lúc nào',
                      style: TextStyle(fontSize: 12,
                          color: isDark ? Colors.grey[600] : Colors.grey[400])),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  final String? badge;
  final Color badgeColor;
  final bool isDark;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon, required this.iconColor,
    required this.title, required this.desc,
    required this.badge, required this.badgeColor,
    required this.isDark, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(title, style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
                if (badge != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(99)),
                    child: Text(badge!, style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: badgeColor)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(fontSize: 12, height: 1.4,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ],
          )),
          const SizedBox(width: 8),
          Icon(Icons.arrow_forward_ios_rounded, size: 14,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
        ]),
      ),
    );
  }
}