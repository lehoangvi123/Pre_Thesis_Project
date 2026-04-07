// lib/view/CategorizeContent.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './HomeView.dart';
import './AnalysisView.dart';
import './Transaction.dart';
import '../notification/NotificationView.dart';
import './ProfileView.dart';
import '../Achivement/Achievement_view.dart';

class CategoriesView extends StatefulWidget {
  final String? initialType;
  const CategoriesView({Key? key, this.initialType}) : super(key: key);
  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth      = FirebaseAuth.instance;
  final _searchCtrl = TextEditingController();

  static const _teal   = Color(0xFF00CED1);
  static const _purple = Color(0xFF8B5CF6);

  // Tab index: 0 = Giao dịch, 1 = 50/30/20
  int _tabIndex = 0;

  // Filter state
  String _filterType  = 'all';   // all / income / expense
  int    _filterMonth = DateTime.now().month;
  int    _filterYear  = DateTime.now().year;
  String _searchQuery = '';
  String _sortBy      = 'date';  // date / amount

  // Data
  List<Map<String, dynamic>> _allTxs    = [];
  bool                       _isLoading = true;
  double _monthIncome  = 0;
  double _monthExpense = 0;
  Map<String, double> _catExpense = {};  // chi tiêu theo danh mục

  // Toast
  bool     _toastVisible = false;
  String   _toastMsg     = '';
  Color    _toastColor   = Colors.green;
  IconData _toastIcon    = Icons.check_circle_rounded;
  late AnimationController _toastCtrl;
  late Animation<double>   _toastAnim;

  @override
  void initState() {
    super.initState();
    _toastCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _toastAnim = CurvedAnimation(parent: _toastCtrl, curve: Curves.easeOut);
    _loadTransactions();
  }

  @override
  void dispose() {
    _toastCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTransactions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    if (mounted) setState(() => _isLoading = true);

    try {
      final start = DateTime(_filterYear, _filterMonth, 1);
      final end   = DateTime(_filterYear, _filterMonth + 1, 0, 23, 59, 59);

      final snap = await _firestore
          .collection('users').doc(uid).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date', descending: true)
          .get(const GetOptions(source: Source.server));

      double inc = 0, exp = 0;
      final catMap = <String, double>{};
      final txs = snap.docs.map((doc) {
        final d     = doc.data();
        final isInc = d['type'] == 'income' || d['isIncome'] == true;
        final amt   = (d['amount'] as num?)?.toDouble().abs() ?? 0.0;
        final cat   = (d['category'] ?? d['categoryName'] ?? 'Khác').toString();
        if (isInc) inc += amt; else {
          exp += amt;
          catMap[cat] = (catMap[cat] ?? 0) + amt;
        }
        return {
          'id':       doc.id,
          'title':    (d['title'] ?? d['note'] ?? cat ?? 'Giao dịch').toString(),
          'category': cat,
          'amount':   amt,
          'isIncome': isInc,
          'date':     (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
          'note':     (d['note'] ?? '').toString(),
        };
      }).toList();

      if (mounted) setState(() {
        _allTxs      = txs;
        _isLoading   = false;
        _monthIncome  = inc;
        _monthExpense = exp;
        _catExpense   = catMap;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Filtered + searched list
  List<Map<String, dynamic>> get _filtered {
    var list = _allTxs.where((tx) {
      // Filter by type
      if (_filterType == 'income'  && !(tx['isIncome'] as bool)) return false;
      if (_filterType == 'expense' &&  (tx['isIncome'] as bool)) return false;
      // Search
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final title = (tx['title'] as String).toLowerCase();
        final cat   = (tx['category'] as String).toLowerCase();
        if (!title.contains(q) && !cat.contains(q)) return false;
      }
      return true;
    }).toList();

    // Sort
    if (_sortBy == 'amount') {
      list.sort((a, b) =>
          (b['amount'] as double).compareTo(a['amount'] as double));
    } else {
      list.sort((a, b) =>
          (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    }
    return list;
  }

  double get _totalIncome => _filtered
      .where((t) => t['isIncome'] as bool)
      .fold(0.0, (s, t) => s + (t['amount'] as double));

  double get _totalExpense => _filtered
      .where((t) => !(t['isIncome'] as bool))
      .fold(0.0, (s, t) => s + (t['amount'] as double));

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _fmtDate(DateTime d) =>
      '${d.hour.toString().padLeft(2,'0')}:${d.minute.toString().padLeft(2,'0')}'
      '  ${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}';

  String _monthLabel(int m) => [
    '','Tháng 1','Tháng 2','Tháng 3','Tháng 4','Tháng 5','Tháng 6',
    'Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12',
  ][m];

  IconData _catIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ăn') || c.contains('uống') || c.contains('food')) return Icons.restaurant_rounded;
    if (c.contains('di chuyển') || c.contains('xăng') || c.contains('xe')) return Icons.directions_car_rounded;
    if (c.contains('sức khoẻ') || c.contains('thuốc') || c.contains('y tế')) return Icons.medical_services_rounded;
    if (c.contains('mua sắm') || c.contains('quần áo')) return Icons.shopping_bag_rounded;
    if (c.contains('nhà') || c.contains('thuê')) return Icons.home_rounded;
    if (c.contains('giải trí') || c.contains('phim')) return Icons.movie_rounded;
    if (c.contains('tiết kiệm')) return Icons.savings_rounded;
    if (c.contains('hóa đơn') || c.contains('điện') || c.contains('nước')) return Icons.electric_bolt_rounded;
    if (c.contains('giáo dục') || c.contains('học')) return Icons.school_rounded;
    if (c.contains('đầu tư')) return Icons.trending_up_rounded;
    if (c.contains('lương')) return Icons.account_balance_wallet_rounded;
    if (c.contains('thưởng')) return Icons.card_giftcard_rounded;
    if (c.contains('freelance')) return Icons.laptop_mac_rounded;
    if (c.contains('kinh doanh')) return Icons.storefront_rounded;
    return Icons.category_rounded;
  }

  // Group transactions by date
  Map<String, List<Map<String, dynamic>>> _groupByDate() {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final tx in _filtered) {
      final d    = tx['date'] as DateTime;
      final key  = '${d.day.toString().padLeft(2,'0')}/${d.month.toString().padLeft(2,'0')}/${d.year}';
      groups[key] = [...(groups[key] ?? []), tx];
    }
    return groups;
  }

  Future<void> _deleteTx(String id) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _firestore
          .collection('users').doc(uid).collection('transactions').doc(id).get();
      if (!doc.exists) return;
      final d       = doc.data()!;
      final amount  = (d['amount'] as num?)?.toDouble().abs() ?? 0;
      final isInc   = d['type'] == 'income' || d['isIncome'] == true;

      await _firestore.collection('users').doc(uid)
          .collection('transactions').doc(id).delete();
      await _firestore.collection('users').doc(uid).update({
        'balance':      FieldValue.increment(isInc ? -amount : amount),
        if (isInc)  'totalIncome':  FieldValue.increment(-amount),
        if (!isInc) 'totalExpense': FieldValue.increment(-amount),
      });
      _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Đã xóa giao dịch'),
          backgroundColor: Colors.red[500],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) { debugPrint('Delete error: $e'); }
  }

  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildHeader(isDark),
          ),
          const SizedBox(height: 14),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildSearchBar(isDark),
          ),
          const SizedBox(height: 10),

          // Tab switcher — cố định, không di chuyển
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildTabSwitcher(isDark),
          ),
          const SizedBox(height: 10),

          // Filter chips — luôn chiếm không gian, chỉ ẩn opacity khi không dùng
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: AnimatedOpacity(
              opacity: _tabIndex == 0 ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: _tabIndex != 0,
                child: _buildFilterRow(isDark),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Content theo tab
          Expanded(child: _tabIndex == 0
              ? Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildSummaryBar(isDark),
                  ),
                  const SizedBox(height: 10),
                  Expanded(child: _buildTxList(isDark)),
                ])
              : _tabIndex == 1
                  ? _buildRuleTab(isDark)
                  : _buildZeroBasedTab(isDark)),
        ]),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _toastAnim,
            builder: (_, __) => _toastVisible
                ? Transform.translate(
                    offset: Offset(0, 20 * (1 - _toastAnim.value)),
                    child: Opacity(
                      opacity: _toastAnim.value,
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: _toastColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [BoxShadow(
                              color: _toastColor.withOpacity(0.4),
                              blurRadius: 12, offset: const Offset(0, 4))],
                        ),
                        child: Row(children: [
                          Icon(_toastIcon, color: Colors.white, size: 20),
                          const SizedBox(width: 10),
                          Expanded(child: Text(_toastMsg,
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 13, fontWeight: FontWeight.w600,
                                  height: 1.4))),
                          GestureDetector(
                            onTap: () => _toastCtrl.reverse().then((_) {
                              if (mounted) setState(() => _toastVisible = false);
                            }),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.white70, size: 18),
                          ),
                        ]),
                      ),
                    ))
                : const SizedBox.shrink(),
          ),
          _buildBottomNav(),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    return Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Lịch sử', style: TextStyle(
            fontSize: 26, fontWeight: FontWeight.bold)),
        Text('Tất cả giao dịch của bạn',
            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
      ])),
      // Month picker
      GestureDetector(
        onTap: () => _showMonthPicker(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _teal.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _teal.withOpacity(0.3)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.calendar_month_rounded, color: _teal, size: 16),
            const SizedBox(width: 6),
            Text('${_monthLabel(_filterMonth)} $_filterYear',
                style: const TextStyle(fontSize: 12,
                    fontWeight: FontWeight.w600, color: _teal)),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, color: _teal, size: 16),
          ]),
        ),
      ),
      const SizedBox(width: 8),
      GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AchievementsView())),
        child: Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00D09E), Color(0xFF00A8AA)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.emoji_events, color: Colors.amber, size: 21),
        ),
      ),
    ]);
  }

  // ── Search bar ────────────────────────────────────────
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(
            fontSize: 14, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm giao dịch...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded,
              color: Colors.grey[400], size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: Icon(Icons.close_rounded,
                      color: Colors.grey[400], size: 18))
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 13),
        ),
      ),
    );
  }

  // ── Filter row ────────────────────────────────────────
  Widget _buildFilterRow(bool isDark) {
    return Row(children: [
      // Type filters
      _filterChip('Tất cả', 'all', isDark),
      const SizedBox(width: 8),
      _filterChip('Thu nhập', 'income', isDark, color: Colors.green[600]!),
      const SizedBox(width: 8),
      _filterChip('Chi tiêu', 'expense', isDark, color: Colors.red[500]!),
      const Spacer(),
      // Sort
      GestureDetector(
        onTap: () => setState(() =>
            _sortBy = _sortBy == 'date' ? 'amount' : 'date'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.sort_rounded,
                size: 14, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(_sortBy == 'date' ? 'Ngày' : 'Số tiền',
                style: TextStyle(fontSize: 11,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400] : Colors.grey[600])),
          ]),
        ),
      ),
    ]);
  }

  Widget _filterChip(String label, String value, bool isDark,
      {Color? color}) {
    final active  = _filterType == value;
    final c       = color ?? _teal;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? c : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? c : (isDark ? Colors.grey[700]! : Colors.grey[200]!),
              width: active ? 1.5 : 1),
          boxShadow: active ? [BoxShadow(
              color: c.withOpacity(0.3),
              blurRadius: 6, offset: const Offset(0, 2))] : [],
        ),
        child: Text(label, style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600,
          color: active ? Colors.white
              : (isDark ? Colors.grey[400] : Colors.grey[600]),
        )),
      ),
    );
  }

  // ── Summary bar ───────────────────────────────────────
  Widget _buildSummaryBar(bool isDark) {
    final count = _filtered.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [_teal, Color(0xFF0097A7)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(
            color: _teal.withOpacity(0.3),
            blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Row(children: [
        Expanded(child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _summaryCol('↑ Thu nhập', _fmt(_totalIncome) + 'đ',
              Colors.greenAccent[200]!))),
        Container(width: 1, height: 36,
            color: Colors.white.withOpacity(0.3)),
        Expanded(child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _summaryCol('↓ Chi tiêu', _fmt(_totalExpense) + 'đ',
              Colors.red[200]!))),
        Container(width: 1, height: 36,
            color: Colors.white.withOpacity(0.3)),
        Expanded(child: FittedBox(
          fit: BoxFit.scaleDown,
          child: _summaryCol('📋 Giao dịch', '$count', Colors.white))),
      ]),
    );
  }

  Widget _summaryCol(String label, String value, Color color) =>
      Column(children: [
        Text(label, style: const TextStyle(
            fontSize: 10, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center),
      ]);

  // ── Transaction list ──────────────────────────────────
  Widget _buildTxList(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _teal));
    }

    final grouped = _groupByDate();

    if (grouped.isEmpty) {
      return Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.receipt_long_rounded, size: 64, color: Colors.grey[300]),
        const SizedBox(height: 16),
        Text('Không có giao dịch nào',
            style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text(_searchQuery.isNotEmpty
            ? 'Thử tìm kiếm với từ khóa khác'
            : 'Thêm giao dịch để xem lịch sử',
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]));
    }

    return RefreshIndicator(
      color: _teal,
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: grouped.length,
        itemBuilder: (_, i) {
          final dateKey = grouped.keys.elementAt(i);
          final txs     = grouped[dateKey]!;
          final dayInc  = txs.where((t) => t['isIncome'] as bool)
              .fold(0.0, (s, t) => s + (t['amount'] as double));
          final dayExp  = txs.where((t) => !(t['isIncome'] as bool))
              .fold(0.0, (s, t) => s + (t['amount'] as double));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(children: [
                  Text(dateKey, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: isDark ? Colors.grey[300] : Colors.grey[700])),
                  const Spacer(),
                  if (dayInc > 0)
                    Text('+${_fmt(dayInc)}đ',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[600])),
                  if (dayExp > 0) ...[
                    if (dayInc > 0) const SizedBox(width: 8),
                    Text('-${_fmt(dayExp)}đ',
                        style: TextStyle(fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.red[500])),
                  ],
                ]),
              ),

              // Transactions of this day
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                      blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(children: txs.asMap().entries.map((e) {
                  final j  = e.key;
                  final tx = e.value;
                  return _buildTxItem(tx, isDark, isLast: j == txs.length - 1);
                }).toList()),
              ),
              const SizedBox(height: 4),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTxItem(Map<String, dynamic> tx, bool isDark,
      {bool isLast = false}) {
    final isInc  = tx['isIncome'] as bool;
    final amount = tx['amount'] as double;
    final color  = isInc ? Colors.green[600]! : Colors.red[500]!;
    final cat    = tx['category'] as String;
    final title  = tx['title'] as String;
    final date   = tx['date'] as DateTime;

    return Column(children: [
      Dismissible(
        key: Key(tx['id'] as String),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red[500],
            borderRadius: isLast
                ? const BorderRadius.vertical(bottom: Radius.circular(16))
                : BorderRadius.zero,
          ),
          child: const Icon(Icons.delete_outline_rounded,
              color: Colors.white, size: 22),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text('Xóa giao dịch?',
                  style: TextStyle(fontSize: 16)),
              content: Text('Xóa "$title" - ${_fmt(amount)}đ?',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false),
                    child: Text('Hủy',
                        style: TextStyle(color: Colors.grey[500]))),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[500], elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  child: const Text('Xóa',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        onDismissed: (_) => _deleteTx(tx['id'] as String),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_catIcon(cat), color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // Title + category
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(cat, style: TextStyle(
                      fontSize: 10, color: color,
                      fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 6),
                Text(_fmtDate(date),
                    style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              ]),
            ])),

            // Amount
            Text(
              '${isInc ? '+' : '-'}${_fmt(amount)}đ',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: color),
            ),
          ]),
        ),
      ),
      if (!isLast)
        Divider(height: 1, indent: 72,
            color: isDark ? Colors.grey[700] : Colors.grey[100]),
    ]);
  }

  // ── Month picker ──────────────────────────────────────
  void _showMonthPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int selMonth = _filterMonth;
    int selYear  = _filterYear;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),

            // Year selector
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                onPressed: () => setS(() => selYear--),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text('$selYear', style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => setS(() => selYear++),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ]),
            const SizedBox(height: 12),

            // Month grid
            GridView.count(
              crossAxisCount: 4, shrinkWrap: true,
              mainAxisSpacing: 8, crossAxisSpacing: 8,
              childAspectRatio: 2,
              physics: const NeverScrollableScrollPhysics(),
              children: List.generate(12, (i) {
                final m       = i + 1;
                final isSelM  = m == selMonth && selYear == _filterYear;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _filterMonth = m;
                      _filterYear  = selYear;
                    });
                    _loadTransactions();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelM ? _teal : (isDark
                          ? const Color(0xFF3A3A3A) : Colors.grey[100]),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(child: Text('T$m', style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isSelM ? Colors.white
                            : (isDark ? Colors.grey[300] : Colors.grey[700])))),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  // ── Tab switcher ─────────────────────────────────────
  Widget _buildTabSwitcher(bool isDark) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        _tabBtn(0, '🧾  Giao dịch', isDark),
        _tabBtn(1, '📊  50/30/20', isDark),
        _tabBtn(2, '🎯  Zero', isDark),
      ]),
    );
  }

  Widget _tabBtn(int idx, String label, bool isDark) {
    final active = _tabIndex == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = idx),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? _teal : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: active ? [BoxShadow(
                color: _teal.withOpacity(0.3),
                blurRadius: 6, offset: const Offset(0, 2))] : [],
          ),
          child: Center(child: Text(label, style: TextStyle(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.normal,
            color: active ? Colors.white
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ))),
        ),
      ),
    );
  }

  // ── Tab 50/30/20 ──────────────────────────────────────
  Widget _buildRuleTab(bool isDark) {
    final income  = _monthIncome;
    final needs   = income * 0.50;
    final wants   = income * 0.30;
    final savings = income * 0.20;

    // Phân loại danh mục theo nhóm 50/30/20
    const needsCats = [
      'Ăn uống','Nhà ở','Di chuyển','Hóa đơn tiện ích',
      'Sức khoẻ','Chi phí gia đình','Chi phí con cái','Giáo dục'
    ];
    const wantsCats = [
      'Giải trí & xã hội','Mua sắm','Mua sắm cá nhân',
      'Du lịch','Ăn ngoài','Cafe','Thú vui'
    ];
    const savingsCats = [
      'Tiết kiệm','Đầu tư & học tập','Quỹ dự phòng','Đầu tư'
    ];

    double needsSpent = 0, wantsSpent = 0, savingsSpent = 0, otherSpent = 0;
    final needsDetail   = <String, double>{};
    final wantsDetail   = <String, double>{};
    final savingsDetail = <String, double>{};
    final otherDetail   = <String, double>{};

    for (final e in _catExpense.entries) {
      final cat = e.key;
      final amt = e.value;
      if (needsCats.any((n) => cat.toLowerCase().contains(n.toLowerCase()))) {
        needsSpent += amt; needsDetail[cat] = amt;
      } else if (savingsCats.any((n) => cat.toLowerCase().contains(n.toLowerCase()))) {
        savingsSpent += amt; savingsDetail[cat] = amt;
      } else if (wantsCats.any((n) => cat.toLowerCase().contains(n.toLowerCase()))) {
        wantsSpent += amt; wantsDetail[cat] = amt;
      } else {
        otherSpent += amt; otherDetail[cat] = amt;
        wantsSpent += amt;
      }
    }

    if (income == 0) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📊', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Chưa có thu nhập tháng này',
            style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('Thêm giao dịch thu nhập để xem phân tích',
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [_teal, Color(0xFF0097A7)],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: _teal.withOpacity(0.3),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(children: [
            const Row(children: [
              Text('🎯', style: TextStyle(fontSize: 20)),
              SizedBox(width: 8),
              Expanded(child: Text('Quy tắc 50/30/20',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold))),
            ]),
            const SizedBox(height: 4),
            Text('Thu nhập tháng: ${_fmt(income)}đ',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            // 3 cột
            Row(children: [
              _ruleCol('50%', 'Thiết yếu', _fmt(needs) + 'đ',
                  Colors.greenAccent[200]!),
              Container(width: 1, height: 44, color: Colors.white24),
              _ruleCol('30%', 'Linh hoạt', _fmt(wants) + 'đ',
                  Colors.amber[200]!),
              Container(width: 1, height: 44, color: Colors.white24),
              _ruleCol('20%', 'Tiết kiệm', _fmt(savings) + 'đ',
                  Colors.lightBlue[200]!),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        // 3 nhóm chi tiêu
        _ruleGroup(isDark,
          emoji: '🏠', label: '50% — Thiết yếu',
          budget: needs, spent: needsSpent,
          color: Colors.green[600]!,
          detail: needsDetail,
          tip: 'Ăn uống, nhà ở, đi lại, tiện ích, sức khỏe',
        ),
        const SizedBox(height: 12),
        _ruleGroup(isDark,
          emoji: '🎬', label: '30% — Linh hoạt',
          budget: wants, spent: wantsSpent,
          color: Colors.amber[700]!,
          detail: wantsDetail,
          tip: 'Giải trí, mua sắm, ăn ngoài, du lịch',
        ),
        const SizedBox(height: 12),
        _ruleGroup(isDark,
          emoji: '💰', label: '20% — Tiết kiệm',
          budget: savings, spent: savingsSpent,
          color: Colors.blue[600]!,
          detail: savingsDetail,
          tip: 'Tiết kiệm, đầu tư, quỹ dự phòng',
        ),
        const SizedBox(height: 12),

        // Nhận xét tổng quan
        _buildRuleInsight(isDark, needsSpent, wantsSpent, savingsSpent,
            needs, wants, savings, income),
      ]),
    );
  }

  Widget _ruleCol(String pct, String label, String amount, Color color) =>
      Expanded(child: Column(children: [
        Text(pct, style: TextStyle(
            color: color, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(
            color: Colors.white70, fontSize: 10)),
        const SizedBox(height: 4),
        Text(amount, style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ]));

  Widget _ruleGroup(bool isDark, {
    required String emoji, required String label,
    required double budget, required double spent,
    required Color color, required Map<String, double> detail,
    required String tip,
  }) {
    final progress  = budget > 0 ? (spent / budget).clamp(0.0, 1.2) : 0.0;
    final isOver    = spent > budget && budget > 0;
    final remaining = budget - spent;
    final pctUsed   = budget > 0 ? (spent / budget * 100) : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isOver ? Colors.red.withOpacity(0.4) : color.withOpacity(0.2)),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text(label, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isOver
                    ? Colors.red.withOpacity(0.1)
                    : color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isOver ? '⚠️ Vượt' : '${pctUsed.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                    color: isOver ? Colors.red : color),
              ),
            ),
          ]),
          const SizedBox(height: 4),
          Text(tip, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 12),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100],
              valueColor: AlwaysStoppedAnimation(
                  isOver ? Colors.red : color),
            ),
          ),
          const SizedBox(height: 8),

          // Số tiền
          Row(children: [
            Text('Đã chi: ${_fmt(spent)}đ',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isOver ? Colors.red : color)),
            const Spacer(),
            Text(
              isOver
                  ? 'Vượt ${_fmt(remaining.abs())}đ'
                  : 'Còn ${_fmt(remaining)}đ',
              style: TextStyle(fontSize: 12,
                  color: isOver ? Colors.red[400] : Colors.grey[500]),
            ),
          ]),
          Text('Ngân sách: ${_fmt(budget)}đ / tháng',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),

          // Detail categories
          if (detail.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...detail.entries.take(4).map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(children: [
                Container(width: 6, height: 6,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.6), shape: BoxShape.circle)),
                Expanded(child: Text(e.key, style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]))),
                Text('${_fmt(e.value)}đ', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: color)),
              ]),
            )),
            if (detail.length > 4)
              Text('+${detail.length - 4} danh mục khác',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ],
        ]),
      ),
    );
  }

  Widget _buildRuleInsight(bool isDark,
      double needsS, double wantsS, double savingsS,
      double needsB, double wantsB, double savingsB, double income) {
    final messages = <Map<String, dynamic>>[];

    if (needsS > needsB)
      messages.add({'icon': '⚠️', 'color': Colors.red[500]!,
        'text': 'Chi thiết yếu vượt 50% — xem lại nhà ở và ăn uống'});
    else
      messages.add({'icon': '✅', 'color': Colors.green[600]!,
        'text': 'Chi thiết yếu hợp lý — đang kiểm soát tốt'});

    if (wantsS > wantsB)
      messages.add({'icon': '🎯', 'color': Colors.amber[700]!,
        'text': 'Giải trí/mua sắm vượt 30% — cân nhắc cắt giảm'});

    if (savingsS >= savingsB)
      messages.add({'icon': '💪', 'color': Colors.blue[600]!,
        'text': 'Tiết kiệm đạt mục tiêu 20% — xuất sắc!'});
    else
      messages.add({'icon': '💡', 'color': Colors.blue[400]!,
        'text': 'Cần tiết kiệm thêm ${_fmt(savingsB - savingsS)}đ để đạt 20%'});

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🧠', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text('Nhận xét tháng này', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 12),
        ...messages.map((m) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m['icon'] as String,
                style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(m['text'] as String,
                style: TextStyle(fontSize: 13, height: 1.4,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]))),
          ]),
        )),
      ]),
    );
  }

  // ── Tab Zero-Based Budgeting ─────────────────────────
  Widget _buildZeroBasedTab(bool isDark) {
    final income         = _monthIncome;
    final totalAllocated = _catExpense.values.fold(0.0, (s, v) => s + v);
    final unallocated    = income - totalAllocated;
    final isBalanced     = unallocated.abs() < income * 0.02;

    if (income == 0) {
      return Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('🎯', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text('Chưa có thu nhập tháng này',
            style: TextStyle(fontSize: 16, color: Colors.grey[500])),
        const SizedBox(height: 8),
        Text('Thêm thu nhập để bắt đầu phân bổ ngân sách',
            style: TextStyle(fontSize: 13, color: Colors.grey[400])),
      ]));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
      child: Column(children: [
        // Header card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isBalanced
                  ? [Colors.green[600]!, Colors.green[800]!]
                  : unallocated > 0
                      ? [const Color(0xFF8B5CF6), const Color(0xFF6D28D9)]
                      : [Colors.red[600]!, Colors.red[800]!],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Text('🎯', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              const Expanded(child: Text('Zero-Based Budgeting',
                  style: TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.bold))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(
                  isBalanced ? '✅ Cân bằng!'
                      : unallocated > 0 ? '⚡ Còn dư' : '⚠️ Vượt ngân sách',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ]),
            const SizedBox(height: 4),
            const Text('Phân bổ 100% thu nhập — mỗi đồng đều có nhiệm vụ',
                style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 16),
            IntrinsicHeight(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _zeroStatCol('Thu nhập', '${_fmt(income)}đ', Colors.white)),
                  Container(width: 1, color: Colors.white24),
                  Expanded(child: _zeroStatCol('Đã chi', '${_fmt(totalAllocated)}đ',
                      Colors.greenAccent[200]!)),
                  Container(width: 1, color: Colors.white24),
                  Expanded(child: _zeroStatCol(
                      unallocated >= 0 ? 'Còn lại' : 'Vượt quá',
                      '${_fmt(unallocated.abs())}đ',
                      unallocated >= 0 ? Colors.amber[200]! : Colors.red[200]!)),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Tỷ lệ đã phân bổ',
                  style: TextStyle(color: Colors.white70, fontSize: 11)),
              Text(
                income > 0
                    ? '${(totalAllocated / income * 100).toStringAsFixed(1)}%'
                    : '0%',
                style: const TextStyle(color: Colors.white,
                    fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ]),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: income > 0
                    ? (totalAllocated / income).clamp(0.0, 1.0) : 0,
                minHeight: 8,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation(
                    isBalanced ? Colors.greenAccent : Colors.white),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Gợi ý
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0FAFA),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _teal.withOpacity(0.2)),
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💡', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              'Zero-Based Budgeting: Thu nhập − Tất cả chi tiêu = 0. '
              'Mỗi đồng được phân công nhiệm vụ cụ thể, không để tiền "thất lạc".',
              style: TextStyle(fontSize: 12, height: 1.5,
                  color: isDark ? Colors.grey[300] : const Color(0xFF2C7873)),
            )),
          ]),
        ),
        const SizedBox(height: 12),

        // Bảng phân bổ
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
          ),
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(children: [
                const Text('📋', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Expanded(child: Text('Phân bổ theo danh mục',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87))),
                Text('${_catExpense.length} mục',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500])),
              ]),
            ),
            Divider(height: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[100]),

            if (_catExpense.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Icon(Icons.inbox_rounded, size: 40, color: Colors.grey[300]),
                  const SizedBox(height: 8),
                  Text('Chưa có chi tiêu tháng này',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                ]),
              )
            else
              ..._buildCatAllocationList(isDark, income),

            // Dòng còn lại
            Divider(height: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[200]),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: unallocated >= 0
                        ? Colors.green.withOpacity(0.12)
                        : Colors.red.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    unallocated >= 0
                        ? Icons.savings_rounded : Icons.warning_rounded,
                    color: unallocated >= 0 ? Colors.green : Colors.red,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  unallocated >= 0
                      ? 'Chưa phân bổ / Tiết kiệm' : 'Vượt ngân sách',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                      color: unallocated >= 0 ? Colors.green : Colors.red),
                )),
                Text(
                  '${unallocated >= 0 ? '' : '-'}${_fmt(unallocated.abs())}đ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                      color: unallocated >= 0 ? Colors.green : Colors.red),
                ),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),

        // Nhận xét
        _buildZeroInsight(isDark, income, totalAllocated, unallocated),
      ]),
    );
  }

  Widget _zeroStatCol(String label, String value, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Text(label, textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10)),
        const SizedBox(height: 4),
        FittedBox(fit: BoxFit.scaleDown,
          child: Text(value, textAlign: TextAlign.center,
              style: TextStyle(color: color, fontSize: 12,
                  fontWeight: FontWeight.bold))),
      ]);

  Widget _buildZeroInsight(bool isDark, double income,
      double allocated, double unallocated) {
    final tips = <Map<String, String>>[];
    final pct  = income > 0 ? allocated / income * 100 : 0.0;

    if (pct < 80) {
      tips.add({'icon': '💡',
        'text': 'Bạn chưa phân bổ hết thu nhập — hãy lên kế hoạch cho phần còn lại'});
    } else if (pct > 100) {
      tips.add({'icon': '🚨',
        'text': 'Chi tiêu vượt thu nhập! Xem lại các khoản lớn nhất để cắt giảm'});
    } else {
      tips.add({'icon': '🏆',
        'text': 'Bạn đang phân bổ tốt! Phần còn lại nên cho vào tiết kiệm'});
    }

    if (_catExpense.isNotEmpty) {
      final top    = _catExpense.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      final topPct = income > 0 ? top.value / income * 100 : 0.0;
      if (topPct > 40) {
        tips.add({'icon': '⚠️',
          'text': '"\${top.key}" chiếm \${topPct.toStringAsFixed(0)}% thu nhập — khá cao'});
      }
    }

    tips.add({'icon': '🎯',
      'text': 'Mục tiêu: Thu nhập − Chi tiêu − Tiết kiệm = 0đ'});

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('🧠', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Text('Gợi ý cải thiện', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 12),
        ...tips.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t['icon']!, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Expanded(child: Text(t['text']!,
                style: TextStyle(fontSize: 12, height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]))),
          ]),
        )),
      ]),
    );
  }

  List<Widget> _buildCatAllocationList(bool isDark, double income) {
    const colors = [
      Color(0xFF00CED1), Color(0xFF4CAF50), Color(0xFFFF9800),
      Color(0xFF8B5CF6), Color(0xFFE91E63), Color(0xFFFF5722),
      Color(0xFF009688), Color(0xFF2196F3), Color(0xFFFFC107),
      Color(0xFF607D8B),
    ];
    final sorted = _catExpense.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.asMap().entries.map((entry) {
      final i     = entry.key;
      final e     = entry.value;
      final cat   = e.key;
      final amt   = e.value;
      final pct   = income > 0 ? amt / income * 100 : 0.0;
      final isLast = i == sorted.length - 1;
      final color = colors[i % colors.length];

      return Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(children: [
            Row(children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_catIcon(cat), color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(cat, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
                  Text('${pct.toStringAsFixed(1)}% thu nhập',
                      style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${_fmt(amt)}đ', style: TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                Text('/ ${_fmt(income)}đ',
                    style: TextStyle(fontSize: 10, color: Colors.grey[400])),
              ]),
            ]),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (pct / 100).clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[100],
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ]),
        ),
        if (!isLast)
          Divider(height: 1, indent: 62,
              color: isDark ? Colors.grey[700] : Colors.grey[100]),
      ]);
    }).toList();
  }

  // ── Bottom nav ────────────────────────────────────────
  Widget _buildBottomNav() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItem(Icons.home_rounded, false, label: 'Home',
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const HomeView()))),
            _navItem(Icons.assignment_rounded, false, label: 'Plan',
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AnalysisView()))),
            _voiceItem(),
            _navItem(Icons.history_rounded, true, label: 'History', onTap: () {}),
            _navItem(Icons.person_outline_rounded, false, label: 'Profile',
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ProfileView()))),
          ]),
        ),
      ),
    );
  }

  Widget _voiceItem() => GestureDetector(
    onTap: () => Navigator.pushNamed(context, '/test-voice'),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: const Color(0xFF00CED1).withOpacity(0.45),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26)),
      const SizedBox(height: 4),
      const Text('Voice', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w600, color: Color(0xFF00CED1))),
    ]),
  );

  Widget _navItem(IconData icon, bool isActive,
      {VoidCallback? onTap, String label = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const teal  = Color(0xFF00CED1);
    final color = isActive ? teal : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? teal.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        if (label.isNotEmpty)
          Text(label, style: TextStyle(fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: color)),
      ]),
    );
  }
}