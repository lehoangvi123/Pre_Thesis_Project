// lib/view/Function/Budget/Budget_list_view.dart
// ✅ Đã thay thế Ngân sách → Báo cáo tháng

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetListView extends StatefulWidget {
  const BudgetListView({Key? key}) : super(key: key);
  @override
  State<BudgetListView> createState() => _BudgetListViewState();
}

class _BudgetListViewState extends State<BudgetListView> {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  // Tháng đang xem (default = tháng hiện tại)
  DateTime _viewMonth = DateTime(DateTime.now().year, DateTime.now().month);

  // Data
  double _income   = 0;
  double _expense  = 0;
  Map<String, double> _expenseByCategory = {};
  Map<String, double> _incomeByCategory  = {};
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  // So sánh tháng trước
  double _prevIncome  = 0;
  double _prevExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  DateTime get _prevMonth =>
      DateTime(_viewMonth.year, _viewMonth.month - 1);

  String _monthLabel(DateTime d) {
    const months = [
      '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4',
      'Tháng 5', 'Tháng 6', 'Tháng 7', 'Tháng 8',
      'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12',
    ];
    return '${months[d.month]} ${d.year}';
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final uid = _auth.currentUser?.uid;
    if (uid == null) { setState(() => _isLoading = false); return; }

    final start = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final end   = DateTime(_viewMonth.year, _viewMonth.month + 1, 0, 23, 59, 59);
    final ps    = DateTime(_prevMonth.year, _prevMonth.month, 1);
    final pe    = DateTime(_prevMonth.year, _prevMonth.month + 1, 0, 23, 59, 59);

    Future<List<Map<String, dynamic>>> fetch(DateTime s, DateTime e) async {
      final snap = await _firestore
          .collection('users').doc(uid).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: s)
          .where('date', isLessThanOrEqualTo: e)
          .orderBy('date', descending: true)
          .get();
      return snap.docs.map((d) => d.data()).toList();
    }

    final [thisTxs, prevTxs] = await Future.wait([
      fetch(start, end),
      fetch(ps, pe),
    ]);

    double inc = 0, exp = 0, pi = 0, pe2 = 0;
    final expCat = <String, double>{};
    final incCat = <String, double>{};

    for (final t in thisTxs) {
      final isIncome = t['type'] == 'income' || t['isIncome'] == true;
      final amt = (t['amount'] as num?)?.toDouble().abs() ?? 0;
      final cat = (t['category'] ?? t['categoryName'] ?? 'Khác').toString();
      if (isIncome) {
        inc += amt;
        incCat[cat] = (incCat[cat] ?? 0) + amt;
      } else {
        exp += amt;
        expCat[cat] = (expCat[cat] ?? 0) + amt;
      }
    }
    for (final t in prevTxs) {
      final isIncome = t['type'] == 'income' || t['isIncome'] == true;
      final amt = (t['amount'] as num?)?.toDouble().abs() ?? 0;
      if (isIncome) pi += amt; else pe2 += amt;
    }

    if (mounted) setState(() {
      _income = inc; _expense = exp;
      _prevIncome = pi; _prevExpense = pe2;
      _expenseByCategory = expCat;
      _incomeByCategory  = incCat;
      _transactions = thisTxs;
      _isLoading = false;
    });
  }

  void _prevM() {
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1));
    _loadData();
  }

  void _nextM() {
    final now = DateTime.now();
    if (_viewMonth.year == now.year && _viewMonth.month == now.month) return;
    setState(() => _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1));
    _loadData();
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _viewMonth.year == now.year && _viewMonth.month == now.month;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Báo cáo tháng',
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // ── Chọn tháng ──────────────────────────
                _buildMonthSelector(isDark),
                const SizedBox(height: 20),

                // ── Tổng quan ───────────────────────────
                _buildSummaryCard(isDark),
                const SizedBox(height: 16),

                // ── So sánh tháng trước ─────────────────
                _buildCompareCard(isDark),
                const SizedBox(height: 16),

                // ── Chi tiêu theo danh mục ──────────────
                if (_expenseByCategory.isNotEmpty) ...[
                  _buildCategoryCard(
                    title: '💸 Chi tiêu theo danh mục',
                    data: _expenseByCategory,
                    total: _expense,
                    color: Colors.red[500]!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Thu nhập theo danh mục ──────────────
                if (_incomeByCategory.isNotEmpty) ...[
                  _buildCategoryCard(
                    title: '💰 Thu nhập theo danh mục',
                    data: _incomeByCategory,
                    total: _income,
                    color: Colors.green[600]!,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Giao dịch tháng này ─────────────────
                if (_transactions.isNotEmpty) ...[
                  _buildTransactionList(isDark),
                ],

                const SizedBox(height: 40),
              ]),
            ),
    );
  }

  // ── Month selector ────────────────────────────────────
  Widget _buildMonthSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        IconButton(
          onPressed: _prevM,
          icon: const Icon(Icons.chevron_left_rounded),
          color: _teal, iconSize: 28,
        ),
        Expanded(
          child: Text(_monthLabel(_viewMonth),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
        ),
        IconButton(
          onPressed: _isCurrentMonth ? null : _nextM,
          icon: const Icon(Icons.chevron_right_rounded),
          color: _isCurrentMonth ? Colors.grey[400] : _teal,
          iconSize: 28,
        ),
      ]),
    );
  }

  // ── Summary card ──────────────────────────────────────
  Widget _buildSummaryCard(bool isDark) {
    final balance = _income - _expense;
    final savingRate = _income > 0
        ? ((balance / _income) * 100).clamp(0.0, 100.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF00CED1), Color(0xFF0097A7)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: _teal.withOpacity(0.3),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.summarize_rounded, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text('Tổng kết ${_monthLabel(_viewMonth)}',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ]),
        const SizedBox(height: 16),

        // Thu / Chi / Còn lại
        Row(children: [
          _summaryItem('Thu nhập', _income, Colors.greenAccent[200]!),
          const SizedBox(width: 12),
          _summaryItem('Chi tiêu', _expense, Colors.red[200]!),
          const SizedBox(width: 12),
          _summaryItem('Còn lại', balance,
              balance >= 0 ? Colors.white : Colors.red[200]!),
        ]),

        const SizedBox(height: 16),

        // Saving rate bar
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tỷ lệ tiết kiệm',
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text('${savingRate.toStringAsFixed(1)}%',
              style: TextStyle(
                  color: savingRate >= 20 ? Colors.greenAccent : Colors.white,
                  fontWeight: FontWeight.bold, fontSize: 12)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: savingRate / 100,
            minHeight: 6,
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation(
                savingRate >= 20 ? Colors.greenAccent : Colors.white),
          ),
        ),

        if (_income == 0 && _expense == 0) ...[
          const SizedBox(height: 16),
          Center(child: Text('Chưa có giao dịch nào trong tháng này',
              style: TextStyle(color: Colors.white60, fontSize: 13))),
        ],
      ]),
    );
  }

  Widget _summaryItem(String label, double amount, Color color) {
    return Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 4),
      Text('${_fmt(amount)}đ',
          style: TextStyle(color: color,
              fontSize: 15, fontWeight: FontWeight.bold)),
    ]));
  }

  // ── Compare with previous month ───────────────────────
  Widget _buildCompareCard(bool isDark) {
    if (_prevIncome == 0 && _prevExpense == 0) return const SizedBox.shrink();

    final incChange = _prevIncome > 0
        ? ((_income - _prevIncome) / _prevIncome * 100).round() : 0;
    final expChange = _prevExpense > 0
        ? ((_expense - _prevExpense) / _prevExpense * 100).round() : 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: _purple.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.compare_arrows_rounded,
                color: _purple, size: 18),
          ),
          const SizedBox(width: 10),
          Text('So với ${_monthLabel(_prevMonth)}',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _compareItem(
            label: 'Thu nhập',
            current: _income,
            change: incChange,
            positiveIsGood: true,
            isDark: isDark,
          )),
          Container(width: 1, height: 50,
              color: isDark ? Colors.grey[700] : Colors.grey[200]),
          Expanded(child: _compareItem(
            label: 'Chi tiêu',
            current: _expense,
            change: expChange,
            positiveIsGood: false,
            isDark: isDark,
          )),
        ]),
      ]),
    );
  }

  Widget _compareItem({
    required String label,
    required double current,
    required int change,
    required bool positiveIsGood,
    required bool isDark,
  }) {
    final isPositive = change > 0;
    final isGood     = positiveIsGood ? isPositive : !isPositive;
    final color      = change == 0
        ? Colors.grey : (isGood ? Colors.green[600]! : Colors.red[500]!);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(
            fontSize: 12, color: Colors.grey[500])),
        const SizedBox(height: 4),
        Text('${_fmt(current)}đ',
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Row(children: [
          if (change != 0) Icon(
            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 12, color: color),
          Text(change == 0 ? 'Không đổi' : '${change.abs()}%',
              style: TextStyle(fontSize: 12, color: color,
                  fontWeight: FontWeight.w600)),
        ]),
      ]),
    );
  }

  // ── Category breakdown ────────────────────────────────
  Widget _buildCategoryCard({
    required String title,
    required Map<String, double> data,
    required double total,
    required Color color,
    required bool isDark,
  }) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 14),
        ...sorted.map((e) {
          final pct = total > 0 ? e.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(e.key,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black87))),
                Text('${_fmt(e.value)}đ',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold,
                        color: color)),
                const SizedBox(width: 8),
                Container(
                  width: 36, height: 20,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Center(child: Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: TextStyle(fontSize: 9,
                        fontWeight: FontWeight.bold, color: color),
                  )),
                ),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100],
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
          );
        }),
      ]),
    );
  }

  // ── Transaction list ──────────────────────────────────
  Widget _buildTransactionList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                  color: _teal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.receipt_long_rounded,
                  color: _teal, size: 18),
            ),
            const SizedBox(width: 10),
            Text('Giao dịch (${_transactions.length})',
                style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
          ]),
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _transactions.length,
          separatorBuilder: (_, __) => Divider(
              height: 1, thickness: 0.5,
              color: isDark ? Colors.grey[700] : Colors.grey[100]),
          itemBuilder: (ctx, i) {
            final t       = _transactions[i];
            final isInc   = t['type'] == 'income' || t['isIncome'] == true;
            final amt     = (t['amount'] as num?)?.toDouble().abs() ?? 0;
            final title   = (t['title'] ?? t['note'] ?? t['category'] ?? 'Giao dịch').toString();
            final cat     = (t['category'] ?? t['categoryName'] ?? 'Khác').toString();
            final date    = (t['date'] as Timestamp?)?.toDate() ?? DateTime.now();
            final color   = isInc ? Colors.green[600]! : Colors.red[500]!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(
                    isInc ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black87),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(cat, style: TextStyle(
                          fontSize: 10, color: color, fontWeight: FontWeight.w500)),
                    ),
                    const SizedBox(width: 6),
                    Text('${date.day}/${date.month} ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ]),
                ])),
                Text('${isInc ? '+' : '-'}${_fmt(amt)}đ',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold,
                        color: color)),
              ]),
            );
          },
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}