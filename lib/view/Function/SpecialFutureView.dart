// lib/view/SpecialFeaturesView.dart

import 'package:flutter/material.dart';
import './HomeView.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './BudgetingPlanView.dart';
import './AI_Chatbot/chatbot_view.dart';
import '../../view/Bill_Scanner_Service/Bill_scanner_view.dart';
import './AnalysisView.dart';

class SpecialFeaturesView extends StatelessWidget {
  const SpecialFeaturesView({Key? key}) : super(key: key);
  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tính năng', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text('Công cụ tài chính thông minh', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ])),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_teal, _purple]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22),
            ),
          ]),
        ),
        const SizedBox(height: 24),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── BuddyAI Hero ─────────────────────────────
            _heroCard(
              context: context, isDark: isDark,
              icon: '🤖', title: 'BuddyAI',
              subtitle: 'Trợ lý tài chính AI — hỏi bất cứ điều gì',
              gradient: const LinearGradient(colors: [_teal, _purple]),
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatbotView())),
            ),
            const SizedBox(height: 16),

            // ── Tạo plan AI Hero ─────────────────────────
            
            const SizedBox(height: 20),

            // ── Grid tính năng ────────────────────────────
            Text('Công cụ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white70 : Colors.grey[700])),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.25,
              children: [
                _featureCard(context: context, isDark: isDark, emoji: '📷', title: 'Chụp bill',
                    desc: 'Scan hóa đơn — tự nhận diện chi tiêu', color: const Color(0xFF4CAF50),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BillScannerViewSimple()))),
                _featureCard(context: context, isDark: isDark, emoji: '🎤', title: 'Ghi âm',
                    desc: 'Thêm chi tiêu bằng giọng nói', color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.pushNamed(context, '/test-voice')),
               
              ],
            ),
            const SizedBox(height: 20),

            // ── Phân tích ngân sách ───────────────────────
           
          ]),
        )),
      ])),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _heroCard({required BuildContext context, required bool isDark, required String icon,
      required String title, required String subtitle, required Gradient gradient, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(gradient: gradient, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: _teal.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))]),
        child: Row(children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 28)))),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
        ]),
      ),
    );
  }

  Widget _featureCard({required BuildContext context, required bool isDark, required String emoji,
      required String title, required String desc, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 20)))),
          const Spacer(),
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 3),
          Text(desc, style: TextStyle(fontSize: 11, color: Colors.grey[500], height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  Widget _listTile({required bool isDark, required String emoji, required String title,
      required String desc, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.1 : 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 22)))),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 3),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey[400]),
        ]),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _navItem(context, Icons.home_rounded, 'Home', false, isDark,
              () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeView()))),
          _navItem(context, Icons.history_rounded, 'History', false, isDark,
              () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CategoriesView()))),
          // Center — active
          Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_teal, _purple]),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: _teal.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26)),
            const SizedBox(height: 4),
            const Text('Tính năng', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
          ]),
          _navItem(context, Icons.pie_chart_rounded, 'Plan', false, isDark,
              () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const BudgetPlanView()))),
          _navItem(context, Icons.person_outline_rounded, 'Profile', false, isDark,
              () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ProfileView()))),
        ]),
      )),
    );
  }

  Widget _navItem(BuildContext ctx, IconData icon, String label, bool active, bool isDark, VoidCallback onTap) {
    final color = active ? _teal : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: active ? _teal.withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 24)),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.normal, color: color)),
    ]));
  }
}