// lib/view/SpecialFeaturesView.dart

import 'package:flutter/material.dart';
import './HomeView.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './BudgetingPlanView.dart';
import './AnalysisView.dart';
import './AI_Chatbot/chatbot_view.dart';
import 'package:project1/view/Bill_Scanner_Service/Bill_scanner_view.dart';
import './SavingGoalsListView.dart';

class SpecialFeaturesView extends StatelessWidget {
  const SpecialFeaturesView({Key? key}) : super(key: key);

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(children: [
                const SizedBox(height: 40),

                // ── Icon lớn ─────────────────────────
                Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C8EEF), Color(0xFF5B7FE8)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                      color: const Color(0xFF6C8EEF).withOpacity(0.35),
                      blurRadius: 20, offset: const Offset(0, 8),
                    )],
                  ),
                  child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 40),
                ),

                const SizedBox(height: 20),

                // ── Tiêu đề ──────────────────────────
                Text('Trợ lý tài chính',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87)),
                const SizedBox(height: 8),
                Text(
                  'Chọn công cụ phù hợp để quản lý\ntài chính cá nhân hiệu quả hơn',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, height: 1.5,
                      color: isDark ? Colors.grey[400] : Colors.grey[500]),
                ),

                const SizedBox(height: 36),

                // ── Danh sách tính năng ───────────────
                _buildItem(
                  context: context, isDark: isDark,
                  icon: Icons.chat_bubble_outline_rounded,
                  iconColor: const Color(0xFF8B7CF6), iconBg: const Color(0xFFEDE9FE),
                  title: 'BuddyAI',
                  desc: 'Nhận tư vấn như hỏi bạn bè – không cần điền form',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ChatbotView())),
                ),
                
                _buildItem(
                  context: context, isDark: isDark,
                  icon: Icons.savings_outlined,
                  iconColor: const Color(0xFFFF9800), iconBg: const Color(0xFFFFF3E0),
                  title: 'Mục tiêu tiết kiệm',
                  desc: 'Đặt mục tiêu ngắn hạn & dài hạn – theo dõi tiến độ tiết kiệm từng tháng',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SavingGoalsView())),
                ),
                _buildItem(
                  context: context, isDark: isDark,
                  icon: Icons.document_scanner_outlined,
                  iconColor: const Color(0xFF00B894), iconBg: const Color(0xFFE0F7F4),
                  title: 'Chụp ảnh bill',
                  desc: 'Chụp hóa đơn và tự động nhận diện giao dịch chi tiêu',
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BillScannerViewSimple())),
                  isLast: true,
                ),

                const SizedBox(height: 24),
                Text('Bạn có thể đổi cách tiết kế lúc nào',
                    style: TextStyle(fontSize: 12, color: Colors.grey[400])),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildItem({
    required BuildContext context, required bool isDark,
    required IconData icon, required Color iconColor, required Color iconBg,
    required String title, required String desc, required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(children: [
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
          child: Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: isDark ? iconColor.withOpacity(0.15) : iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 3),
              Text(desc, style: TextStyle(fontSize: 12, height: 1.4,
                  color: isDark ? Colors.grey[400] : Colors.grey[500])),
            ])),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
          ]),
        ),
      ),
      if (!isLast)
        Divider(height: 1, color: isDark ? Colors.grey[800] : Colors.grey[100]),
    ]);
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navItem(context, Icons.home_rounded, 'Home', false, isDark,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const HomeView()))),
          _navItem(context, Icons.history_rounded, 'History', false, isDark,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const CategoriesView()))),
          // Center — active
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_teal, _purple]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _teal.withOpacity(0.5),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(height: 4),
            const Text('Tính năng', style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
          ]),
          _navItem(context, Icons.pie_chart_rounded, 'Plan', false, isDark,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const BudgetPlanView()))),
          _navItem(context, Icons.person_outline_rounded, 'Profile', false, isDark,
              () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const ProfileView()))),
        ]),
      )),
    );
  }

  Widget _navItem(BuildContext ctx, IconData icon, String label,
      bool active, bool isDark, VoidCallback onTap) {
    final color = active ? _teal : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: active ? _teal.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        Text(label, style: TextStyle(fontSize: 10,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: color)),
      ]),
    );
  }
}