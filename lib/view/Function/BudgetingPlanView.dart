// lib/view/BudgetPlanView.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './HomeView.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './SpecialFutureView.dart';
class BudgetPlanView extends StatefulWidget {
  final int initialTab;
  const BudgetPlanView({Key? key, this.initialTab = 0}) : super(key: key);
  @override
  State<BudgetPlanView> createState() => _BudgetPlanViewState();
}

class _BudgetPlanViewState extends State<BudgetPlanView> {
  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  int _tabIndex = 0;

  int    _filterMonth = DateTime.now().month;
  int    _filterYear  = DateTime.now().year;
  bool   _isLoading   = true;

  double _monthIncome  = 0;
  double _catExpense_total = 0;
  Map<String, double> _catExpense = {};

  @override
  void initState() {
    super.initState();
    _tabIndex = widget.initialTab;
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    if (mounted) setState(() => _isLoading = true);
    try {
      final start = DateTime(_filterYear, _filterMonth, 1);
      final end   = DateTime(_filterYear, _filterMonth + 1, 0, 23, 59, 59);
      final snap  = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date', descending: true).get();
      double inc = 0;
      final catMap = <String, double>{};
      for (final doc in snap.docs) {
        final d     = doc.data();
        final isInc = d['type'] == 'income' || d['isIncome'] == true;
        final amt   = (d['amount'] as num?)?.toDouble().abs() ?? 0;
        final cat   = (d['category'] ?? d['categoryName'] ?? 'Khác').toString();
        if (isInc) { inc += amt; }
        else { catMap[cat] = (catMap[cat] ?? 0) + amt; }
      }
      if (mounted) setState(() {
        _monthIncome = inc;
        _catExpense  = catMap;
        _catExpense_total = catMap.values.fold(0, (s, v) => s + v);
        _isLoading   = false;
      });
    } catch (_) { if (mounted) setState(() => _isLoading = false); }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _monthLabel(int m) => ['','Tháng 1','Tháng 2','Tháng 3','Tháng 4',
    'Tháng 5','Tháng 6','Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12'][m];

  IconData _catIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ăn') || c.contains('uống')) return Icons.restaurant_rounded;
    if (c.contains('di chuyển') || c.contains('xe')) return Icons.directions_car_rounded;
    if (c.contains('sức khoẻ') || c.contains('y tế')) return Icons.medical_services_rounded;
    if (c.contains('mua sắm')) return Icons.shopping_bag_rounded;
    if (c.contains('nhà')) return Icons.home_rounded;
    if (c.contains('giải trí')) return Icons.movie_rounded;
    if (c.contains('tiết kiệm')) return Icons.savings_rounded;
    if (c.contains('hóa đơn') || c.contains('điện')) return Icons.electric_bolt_rounded;
    if (c.contains('giáo dục') || c.contains('học')) return Icons.school_rounded;
    if (c.contains('đầu tư')) return Icons.trending_up_rounded;
    return Icons.category_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA);
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(child: Column(children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Kế hoạch', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
              Text('Phân tích ngân sách thông minh', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            ])),
            // Month picker
            GestureDetector(
              onTap: _showMonthPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _teal.withOpacity(0.3)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.calendar_month_rounded, color: _teal, size: 15),
                  const SizedBox(width: 5),
                  Text('${_monthLabel(_filterMonth)} $_filterYear',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _teal)),
                  const SizedBox(width: 3),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _teal, size: 15),
                ]),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        // Tab switcher
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _buildTabSwitcher(isDark),
        ),
        const SizedBox(height: 10),
        // Content
        Expanded(child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _teal))
            : _tabIndex == 0 ? _buildRuleTab(isDark) : _buildZeroTab(isDark)),
      ])),
      bottomNavigationBar: _buildBottomNav(context, isDark),
    );
  }

  Widget _buildTabSwitcher(bool isDark) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        _tabBtn(0, '📊  50/30/20', isDark),
        _tabBtn(1, '🎯  Zero-Based', isDark),
      ]),
    );
  }

  Widget _tabBtn(int idx, String label, bool isDark) {
    final active = _tabIndex == idx;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tabIndex = idx),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: active ? _teal : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: active ? [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.normal,
          color: active ? Colors.white : (isDark ? Colors.grey[400] : Colors.grey[600]),
        ))),
      ),
    ));
  }

  // ── 50/30/20 Tab ─────────────────────────────────────
  Widget _buildRuleTab(bool isDark) {
    final income  = _monthIncome;
    final needs   = income * 0.50;
    final wants   = income * 0.30;
    final savings = income * 0.20;
    const needsCats = ['Ăn uống','Nhà ở','Di chuyển','Hóa đơn tiện ích','Sức khoẻ','Chi phí gia đình','Chi phí con cái','Giáo dục'];
    const savingsCats = ['Tiết kiệm','Đầu tư & học tập','Quỹ dự phòng','Đầu tư'];
    double needsS = 0, wantsS = 0, savingsS = 0;
    final needsD = <String, double>{}, wantsD = <String, double>{}, savingsD = <String, double>{};
    for (final e in _catExpense.entries) {
      final cat = e.key; final amt = e.value;
      if (needsCats.any((n) => cat.toLowerCase().contains(n.toLowerCase()))) { needsS += amt; needsD[cat] = amt; }
      else if (savingsCats.any((n) => cat.toLowerCase().contains(n.toLowerCase()))) { savingsS += amt; savingsD[cat] = amt; }
      else { wantsS += amt; wantsD[cat] = amt; }
    }

    if (income == 0) return _emptyState('📊', 'Chưa có thu nhập tháng này', 'Thêm giao dịch thu nhập để xem phân tích');

    return RefreshIndicator(
      color: _teal, onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_teal, Color(0xFF0097A7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(children: [
              const Row(children: [Text('🎯', style: TextStyle(fontSize: 20)), SizedBox(width: 8),
                Expanded(child: Text('Quy tắc 50/30/20', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))]),
              const SizedBox(height: 4),
              Text('Thu nhập tháng: ${_fmt(income)}đ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 16),
              Row(children: [
                _ruleCol('50%', 'Thiết yếu', _fmt(needs) + 'đ', Colors.greenAccent[200]!),
                Container(width: 1, height: 44, color: Colors.white24),
                _ruleCol('30%', 'Linh hoạt', _fmt(wants) + 'đ', Colors.amber[200]!),
                Container(width: 1, height: 44, color: Colors.white24),
                _ruleCol('20%', 'Tiết kiệm', _fmt(savings) + 'đ', Colors.lightBlue[200]!),
              ]),
            ]),
          ),
          const SizedBox(height: 16),
          _ruleGroup(isDark, emoji: '🏠', label: '50% — Thiết yếu', budget: needs, spent: needsS, color: Colors.green[600]!, detail: needsD, tip: 'Ăn uống, nhà ở, đi lại, tiện ích, sức khỏe'),
          const SizedBox(height: 12),
          _ruleGroup(isDark, emoji: '🎬', label: '30% — Linh hoạt', budget: wants, spent: wantsS, color: Colors.amber[700]!, detail: wantsD, tip: 'Giải trí, mua sắm, ăn ngoài, du lịch'),
          const SizedBox(height: 12),
          _ruleGroup(isDark, emoji: '💰', label: '20% — Tiết kiệm', budget: savings, spent: savingsS, color: Colors.blue[600]!, detail: savingsD, tip: 'Tiết kiệm, đầu tư, quỹ dự phòng'),
          const SizedBox(height: 12),
          _ruleInsight(isDark, needsS, wantsS, savingsS, needs, wants, savings),
        ]),
      ),
    );
  }

  Widget _ruleCol(String pct, String label, String amount, Color color) =>
      Expanded(child: Column(children: [
        Text(pct, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));

  Widget _ruleGroup(bool isDark, {required String emoji, required String label, required double budget, required double spent, required Color color, required Map<String, double> detail, required String tip}) {
    final progress = budget > 0 ? (spent / budget).clamp(0.0, 1.2) : 0.0;
    final isOver   = spent > budget && budget > 0;
    final remaining = budget - spent;
    final pctUsed = budget > 0 ? (spent / budget * 100) : 0.0;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isOver ? Colors.red.withOpacity(0.4) : color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.15 : 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: isOver ? Colors.red.withOpacity(0.1) : color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(isOver ? '⚠️ Vượt' : '${pctUsed.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOver ? Colors.red : color)),
            ),
          ]),
          const SizedBox(height: 4),
          Text(tip, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 12),
          ClipRRect(borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 8,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(isOver ? Colors.red : color))),
          const SizedBox(height: 8),
          Row(children: [
            Text('Đã chi: ${_fmt(spent)}đ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOver ? Colors.red : color)),
            const Spacer(),
            Text(isOver ? 'Vượt ${_fmt(remaining.abs())}đ' : 'Còn ${_fmt(remaining)}đ', style: TextStyle(fontSize: 12, color: isOver ? Colors.red[400] : Colors.grey[500])),
          ]),
          Text('Ngân sách: ${_fmt(budget)}đ / tháng', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...detail.entries.take(4).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(children: [
                Container(width: 6, height: 6, margin: const EdgeInsets.only(right: 8), decoration: BoxDecoration(color: color.withOpacity(0.6), shape: BoxShape.circle)),
                Expanded(child: Text(e.key, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[300] : Colors.grey[700]))),
                Text('${_fmt(e.value)}đ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ]),
            )),
            if (detail.length > 4) Text('+${detail.length - 4} danh mục khác', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ]),
      ),
    );
  }

  Widget _ruleInsight(bool isDark, double nS, double wS, double sS, double nB, double wB, double sB) {
    final msgs = <Map<String, dynamic>>[];
    if (nS > nB) msgs.add({'icon':'⚠️','color':Colors.red[500]!,'text':'Chi thiết yếu vượt 50% — xem lại nhà ở và ăn uống'});
    else msgs.add({'icon':'✅','color':Colors.green[600]!,'text':'Chi thiết yếu hợp lý — đang kiểm soát tốt'});
    if (wS > wB) msgs.add({'icon':'🎯','color':Colors.amber[700]!,'text':'Giải trí/mua sắm vượt 30% — cân nhắc cắt giảm'});
    if (sS >= sB) msgs.add({'icon':'💪','color':Colors.blue[600]!,'text':'Tiết kiệm đạt mục tiêu 20% — xuất sắc!'});
    else msgs.add({'icon':'💡','color':Colors.blue[400]!,'text':'Cần tiết kiệm thêm ${_fmt(sB - sS)}đ để đạt 20%'});
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('🧠', style: TextStyle(fontSize: 20)), const SizedBox(width: 8),
          Text('Nhận xét tháng này', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))]),
        const SizedBox(height: 12),
        ...msgs.map((m) => Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m['icon'] as String, style: const TextStyle(fontSize: 16)), const SizedBox(width: 8),
            Expanded(child: Text(m['text'] as String, style: TextStyle(fontSize: 13, height: 1.4, color: isDark ? Colors.grey[300] : Colors.grey[700]))),
          ]))),
      ]),
    );
  }

  // ── Zero-Based Tab ────────────────────────────────────
  Widget _buildZeroTab(bool isDark) {
    final income      = _monthIncome;
    final allocated   = _catExpense_total;
    final unallocated = income - allocated;
    final isBalanced  = unallocated.abs() < income * 0.02;

    if (income == 0) return _emptyState('🎯', 'Chưa có thu nhập tháng này', 'Thêm thu nhập để bắt đầu phân bổ ngân sách');

    return RefreshIndicator(
      color: _teal, onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(children: [
          // Hero card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isBalanced ? [Colors.green[600]!, Colors.green[800]!]
                    : unallocated > 0 ? [_purple, const Color(0xFF6D28D9)]
                    : [Colors.red[600]!, Colors.red[800]!],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('🎯', style: TextStyle(fontSize: 22)), const SizedBox(width: 8),
                const Expanded(child: Text('Zero-Based Budgeting', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(isBalanced ? '✅ Cân bằng!' : unallocated > 0 ? '⚡ Còn dư' : '⚠️ Vượt ngân sách',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 4),
              const Text('Phân bổ 100% thu nhập — mỗi đồng đều có nhiệm vụ', style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 16),
              IntrinsicHeight(child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: _zeroCol('Thu nhập', '${_fmt(income)}đ', Colors.white)),
                Container(width: 1, color: Colors.white24),
                Expanded(child: _zeroCol('Đã chi', '${_fmt(allocated)}đ', Colors.greenAccent[200]!)),
                Container(width: 1, color: Colors.white24),
                Expanded(child: _zeroCol(unallocated >= 0 ? 'Còn lại' : 'Vượt quá', '${_fmt(unallocated.abs())}đ', unallocated >= 0 ? Colors.amber[200]! : Colors.red[200]!)),
              ])),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tỷ lệ đã phân bổ', style: TextStyle(color: Colors.white70, fontSize: 11)),
                Text(income > 0 ? '${(allocated / income * 100).toStringAsFixed(1)}%' : '0%',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: income > 0 ? (allocated / income).clamp(0.0, 1.0) : 0, minHeight: 8,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(isBalanced ? Colors.greenAccent : Colors.white))),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0FAFA),
                borderRadius: BorderRadius.circular(14), border: Border.all(color: _teal.withOpacity(0.2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('💡', style: TextStyle(fontSize: 18)), const SizedBox(width: 10),
              Expanded(child: Text('Zero-Based Budgeting: Thu nhập − Tất cả chi tiêu = 0. Mỗi đồng được phân công nhiệm vụ cụ thể, không để tiền "thất lạc".',
                  style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.grey[300] : const Color(0xFF2C7873)))),
            ]),
          ),
          const SizedBox(height: 12),
          // Category list
          Container(
            decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
            child: Column(children: [
              Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 10), child: Row(children: [
                const Text('📋', style: TextStyle(fontSize: 16)), const SizedBox(width: 8),
                Expanded(child: Text('Phân bổ theo danh mục', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))),
                Text('${_catExpense.length} mục', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ])),
              Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[100]),
              if (_catExpense.isEmpty)
                Padding(padding: const EdgeInsets.all(24), child: Column(children: [
                  Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('Chưa có chi tiêu tháng này', style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ]))
              else
                ..._buildCatList(isDark, income),
              Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
              Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                child: Row(children: [
                  Container(width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: unallocated >= 0 ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10)),
                    child: Icon(unallocated >= 0 ? Icons.savings_rounded : Icons.warning_rounded,
                        color: unallocated >= 0 ? Colors.green : Colors.red, size: 18)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(unallocated >= 0 ? 'Chưa phân bổ / Tiết kiệm' : 'Vượt ngân sách',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: unallocated >= 0 ? Colors.green : Colors.red))),
                  Text('${unallocated >= 0 ? '' : '-'}${_fmt(unallocated.abs())}đ',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: unallocated >= 0 ? Colors.green : Colors.red)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          _zeroInsight(isDark, income, allocated, unallocated),
        ]),
      ),
    );
  }

  Widget _zeroCol(String label, String value, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(label, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown, child: Text(value, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold))),
      ]);

  List<Widget> _buildCatList(bool isDark, double income) {
    const colors = [Color(0xFF00CED1),Color(0xFF4CAF50),Color(0xFFFF9800),Color(0xFF8B5CF6),Color(0xFFE91E63),Color(0xFFFF5722),Color(0xFF009688),Color(0xFF2196F3),Color(0xFFFFC107),Color(0xFF607D8B)];
    final sorted = _catExpense.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return sorted.asMap().entries.map((entry) {
      final i = entry.key; final e = entry.value;
      final cat = e.key; final amt = e.value;
      final pct = income > 0 ? amt / income * 100 : 0.0;
      final isLast = i == sorted.length - 1;
      final color = colors[i % colors.length];
      return Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 10, 16, 10), child: Column(children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(_catIcon(cat), color: color, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
              Text('${pct.toStringAsFixed(1)}% thu nhập', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('${_fmt(amt)}đ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              Text('/ ${_fmt(income)}đ', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
            ]),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(value: (pct / 100).clamp(0.0, 1.0), minHeight: 5,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(color))),
        ])),
        if (!isLast) Divider(height: 1, indent: 62, color: isDark ? Colors.grey[700] : Colors.grey[100]),
      ]);
    }).toList();
  }

  Widget _zeroInsight(bool isDark, double income, double allocated, double unallocated) {
    final pct = income > 0 ? allocated / income * 100 : 0.0;
    final tips = <Map<String, String>>[];
    if (pct < 80) tips.add({'icon':'💡','text':'Bạn chưa phân bổ hết thu nhập — hãy lên kế hoạch cho phần còn lại'});
    else if (pct > 100) tips.add({'icon':'🚨','text':'Chi tiêu vượt thu nhập! Xem lại các khoản lớn nhất để cắt giảm'});
    else tips.add({'icon':'🏆','text':'Bạn đang phân bổ tốt! Phần còn lại nên cho vào tiết kiệm'});
    tips.add({'icon':'🎯','text':'Mục tiêu: Thu nhập − Chi tiêu − Tiết kiệm = 0đ'});
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16), border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Text('🧠', style: TextStyle(fontSize: 18)), const SizedBox(width: 8),
          Text('Gợi ý cải thiện', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black87))]),
        const SizedBox(height: 12),
        ...tips.map((t) => Padding(padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['icon']!, style: const TextStyle(fontSize: 16)), const SizedBox(width: 8),
            Expanded(child: Text(t['text']!, style: TextStyle(fontSize: 12, height: 1.5, color: isDark ? Colors.grey[300] : Colors.grey[700]))),
          ]))),
      ]),
    );
  }

  Widget _emptyState(String emoji, String title, String sub) =>
      Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(emoji, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text(sub, style: TextStyle(fontSize: 13, color: Colors.grey[400]), textAlign: TextAlign.center),
      ]));

  void _showMonthPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selMonth = _filterMonth, selYear = _filterYear;
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 20), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            IconButton(onPressed: () => setS(() => selYear--), icon: const Icon(Icons.chevron_left_rounded)),
            Text('$selYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            IconButton(onPressed: () => setS(() => selYear++), icon: const Icon(Icons.chevron_right_rounded)),
          ]),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 4, shrinkWrap: true, mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: 2,
            physics: const NeverScrollableScrollPhysics(),
            children: List.generate(12, (i) {
              final m = i + 1;
              final isSel = m == selMonth && selYear == _filterYear;
              return GestureDetector(
                onTap: () { Navigator.pop(ctx); setState(() { _filterMonth = m; _filterYear = selYear; }); _loadData(); },
                child: Container(
                  decoration: BoxDecoration(color: isSel ? _teal : (isDark ? const Color(0xFF3A3A3A) : Colors.grey[100]), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('T$m', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSel ? Colors.white : (isDark ? Colors.grey[300] : Colors.grey[700])))),
                ),
              );
            }),
          ),
        ]),
      )),
    );
  }

  // ── Bottom Nav ────────────────────────────────────────
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
          _centerBtn(context),
          _navItem(context, Icons.pie_chart_rounded, 'Plan', true, isDark, () {}),
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

  Widget _centerBtn(BuildContext ctx) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacement(ctx, MaterialPageRoute(builder: (_) => const SpecialFeaturesView())),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [_teal, _purple]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: _teal.withOpacity(0.45), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26)),
        const SizedBox(height: 4),
        const Text('Tính năng', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _teal)),
      ]),
    );
  }
}