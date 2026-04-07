// lib/view/Function/Plan/plan_intro_view.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlanIntroView extends StatefulWidget {
  final VoidCallback onStartForm;
  final VoidCallback onFreeChat;
  final VoidCallback onAnalysis;
  final VoidCallback onBillScanner;

  const PlanIntroView({
    Key? key,
    required this.onStartForm,
    required this.onFreeChat,
    required this.onAnalysis,
    required this.onBillScanner,
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
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('plan_intro_seen', true);
  }

  void _goForm()        async { await _markSeen(); widget.onStartForm(); }
  void _goChat()        async { await _markSeen(); widget.onFreeChat(); }
  void _goAnalysis()    async { await _markSeen(); widget.onAnalysis(); }
  void _goBillScanner() async { await _markSeen(); widget.onBillScanner(); }

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
                Container(
                  width: 88, height: 88,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [_teal, _purple],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(
                        color: _teal.withOpacity(0.3),
                        blurRadius: 24, offset: const Offset(0, 8))],
                  ),
                  child: const Icon(Icons.assignment_rounded,
                      color: Colors.white, size: 44),
                ),
                const SizedBox(height: 28),
                Text('Trợ lý tài chính',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                        height: 1.25,
                        color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 14),
                Text('Chọn công cụ phù hợp để quản lý\ntài chính cá nhân hiệu quả hơn',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, height: 1.5,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
                const SizedBox(height: 36),

                _OptionCard(icon: Icons.format_list_bulleted_rounded,
                    iconColor: _teal, title: 'Lập Plan cho bạn',
                    desc: 'Trả lời 4 bước đơn giản — hệ thống tự lập bảng chi tiêu phù hợp cho bạn',
                    isDark: isDark, onTap: _goForm),
                const SizedBox(height: 12),

                _OptionCard(icon: Icons.chat_bubble_outline_rounded,
                    iconColor: _purple, title: 'Tạo plan tự do',
                    desc: 'Nhắn tin tự nhiên như hỏi bạn bè — không cần điền form',
                    isDark: isDark, onTap: _goChat),
                const SizedBox(height: 12),

                _OptionCard(icon: Icons.bar_chart_rounded,
                    iconColor: const Color(0xFFFF9800), title: 'Phân tích chi tiêu',
                    desc: 'Xem biểu đồ thống kê thu chi và cảnh báo chi tiêu theo tháng',
                    isDark: isDark, onTap: _goAnalysis),
                const SizedBox(height: 12),

                _OptionCard(icon: Icons.receipt_long_rounded,
                    iconColor: const Color(0xFF4CAF50), title: 'Chụp ảnh bill',
                    desc: 'Chụp hóa đơn và tự động nhận diện giao dịch chi tiêu',
                    isDark: isDark, onTap: _goBillScanner),

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
  final bool isDark;
  final VoidCallback onTap;

  const _OptionCard({
    required this.icon, required this.iconColor,
    required this.title, required this.desc,
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
              Text(title, style: TextStyle(fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
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