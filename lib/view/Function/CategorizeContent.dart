// lib/view/CategorizeContent.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './HomeView.dart';
import './AnalysisView.dart';
import './Transaction.dart';
import '../notification/NotificationView.dart';
import './ProfileView.dart';
import '../FunctionCategorize/CategorizeDetailsView.dart';
import '../FunctionCategorize/AddCategorizeDialog.dart';
import '../Achivement/Achievement_service.dart';
import '../Achivement/Achievement_view.dart';
import '../Achivement/Achievement_popup.dart';

class CategoriesView extends StatefulWidget {
  final String? initialType;
  const CategoriesView({Key? key, this.initialType}) : super(key: key);
  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView>
    with SingleTickerProviderStateMixin {
  final _firestore  = FirebaseFirestore.instance;
  final _auth       = FirebaseAuth.instance;
  final _achievementService = AchievementService();
  final _scrollCtrl = ScrollController();
  final _expenseKey = GlobalKey();
  final _incomeKey  = GlobalKey();

  double _lastPct      = -1;
  double _totalIncome  = 0;
  double _totalExpense = 0;
  Map<String, double> _spentThis = {};
  Map<String, double> _spentLast = {};

  // Insights data
  Map<int, double> _spentByWeekday = {};
  double _avgDailySpend = 0;
  int    _daysWithSpend = 0;

  // Toast state
  bool   _toastVisible = false;
  String _toastMsg     = '';
  Color  _toastColor   = Colors.green;
  IconData _toastIcon  = Icons.check_circle_rounded;
  late AnimationController _toastCtrl;
  late Animation<double>   _toastAnim;

  static const _defaultExpense = [
    {'name': 'Food',          'icon': 0xe56c, 'color': 0xFFFF6B6B},
    {'name': 'Transport',     'icon': 0xe1d5, 'color': 0xFF4ECDC4},
    {'name': 'Medicine',      'icon': 0xf3f5, 'color': 0xFFFF8B94},
    {'name': 'Groceries',     'icon': 0xf1cc, 'color': 0xFFFFBE0B},
    {'name': 'Rent',          'icon': 0xe318, 'color': 0xFF8B5CF6},
    {'name': 'Gifts',         'icon': 0xe1f0, 'color': 0xFFFF6FC8},
    {'name': 'Savings',       'icon': 0xe586, 'color': 0xFF06D6A0},
    {'name': 'Entertainment', 'icon': 0xe417, 'color': 0xFF118AB2},
  ];

  static const _defaultIncome = [
    {'name': 'Salary',     'icon': 0xe84f, 'color': 0xFF2DC653},
    {'name': 'Freelance',  'icon': 0xe331, 'color': 0xFF00B4D8},
    {'name': 'Investment', 'icon': 0xe6e1, 'color': 0xFFFFB703},
  ];

  @override
  void initState() {
    super.initState();
    _toastCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _toastAnim = CurvedAnimation(parent: _toastCtrl, curve: Curves.easeOut);
    _loadData();
    _checkAchievements();
    if (widget.initialType == 'income') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _incomeKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        }
      });
    }
  }

  @override
  void dispose() {
    _toastCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── Show toast above bottom nav ───────────────────────
  void _showToast({
    required String msg,
    required Color color,
    required IconData icon,
    required int seconds,
  }) {
    if (!mounted) return;
    setState(() {
      _toastMsg     = msg;
      _toastColor   = color;
      _toastIcon    = icon;
      _toastVisible = true;
    });
    _toastCtrl.forward(from: 0);

    Future.delayed(Duration(seconds: seconds), () {
      if (!mounted) return;
      _toastCtrl.reverse().then((_) {
        if (mounted) setState(() => _toastVisible = false);
      });
    });
  }

  // ── 3-level spending check ────────────────────────────
  void _checkSpendingLevel(double expense, double income) {
    if (income <= 0) return;
    final pct = (expense / income * 100).clamp(0.0, 200.0);

    // Chỉ hiện 1 lần, không hiện lại nếu % không đổi nhiều
    if (_lastPct >= 0 && (pct - _lastPct).abs() < 5.0) return;
    _lastPct = pct;

    if (pct < 50) {
      _showToast(
        msg: 'Chi tiêu đang trong vùng an toàn. Tiếp tục duy trì nhé! ✅',
        color: Colors.green[600]!,
        icon: Icons.check_circle_rounded,
        seconds: 30,
      );
    } else if (pct < 90) {
      _showToast(
        msg: 'Bạn đã chi hơn nửa thu nhập tháng này. Hãy kiểm soát chi tiêu cẩn thận hơn! ⚠️',
        color: Colors.amber[700]!,
        icon: Icons.info_rounded,
        seconds: 30,
      );
      _saveNotif('⚠️ Cảnh báo chi tiêu',
          'Đã chi ${pct.toStringAsFixed(0)}% thu nhập tháng này.');
    } else {
      _showToast(
        msg: 'Cảnh báo! Bạn sắp vượt quá thu nhập. Dừng chi tiêu không cần thiết ngay! 🚨',
        color: Colors.red[600]!,
        icon: Icons.warning_rounded,
        seconds: 30,
      );
      _saveNotif('🚨 Cảnh báo nghiêm trọng',
          'Đã chi ${pct.toStringAsFixed(0)}% thu nhập! Nguy hiểm!');
    }
  }

  IconData _iconFromString(String s) {
    switch (s.toLowerCase()) {
      case 'restaurant': case 'food':              return Icons.restaurant;
      case 'directions_bus': case 'transport':     return Icons.directions_bus;
      case 'medical_services':                      return Icons.medical_services;
      case 'shopping_bag': case 'groceries':        return Icons.shopping_bag;
      case 'home': case 'rent':                     return Icons.home;
      case 'card_giftcard': case 'gifts':           return Icons.card_giftcard;
      case 'savings':                               return Icons.savings;
      case 'movie': case 'entertainment':           return Icons.movie;
      case 'account_balance_wallet': case 'salary': return Icons.account_balance_wallet;
      case 'laptop_mac': case 'freelance':          return Icons.laptop_mac;
      case 'trending_up': case 'investment':        return Icons.trending_up;
      default:                                      return Icons.category;
    }
  }

  IconData _iconFromCode(int code) =>
      IconData(code, fontFamily: 'MaterialIcons');

  Future<void> _loadData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final now = DateTime.now();
    final s1  = DateTime(now.year, now.month, 1);
    final e1  = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    final s2  = DateTime(now.year, now.month - 1, 1);
    final e2  = DateTime(now.year, now.month, 0, 23, 59, 59);

    Future<Map<String, double>> fetchCat(DateTime s, DateTime e) async {
      final snap = await _firestore
          .collection('users').doc(uid).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: s)
          .where('date', isLessThanOrEqualTo: e)
          .get();
      final map = <String, double>{};
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['type'] == 'expense' || d['isIncome'] == false) {
          final cat = (d['category'] ?? d['categoryName'] ?? 'Other').toString();
          final amt = (d['amount'] as num?)?.toDouble().abs() ?? 0;
          map[cat] = (map[cat] ?? 0) + amt;
        }
      }
      return map;
    }

    Future<void> fetchInsights() async {
      final snap = await _firestore
          .collection('users').doc(uid).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: s1)
          .where('date', isLessThanOrEqualTo: e1)
          .get();
      final weekdayMap = <int, double>{};
      final daySet     = <String>{};
      double total     = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['type'] == 'expense' || d['isIncome'] == false) {
          final date = (d['date'] as Timestamp?)?.toDate();
          if (date == null) continue;
          final amt = (d['amount'] as num?)?.toDouble().abs() ?? 0;
          weekdayMap[date.weekday] = (weekdayMap[date.weekday] ?? 0) + amt;
          daySet.add('${date.year}-${date.month}-${date.day}');
          total += amt;
        }
      }
      final days = daySet.length;
      if (mounted) setState(() {
        _spentByWeekday = weekdayMap;
        _daysWithSpend  = days;
        _avgDailySpend  = days > 0 ? total / days : 0;
      });
    }

    final [thisM, lastM] = await Future.wait([fetchCat(s1, e1), fetchCat(s2, e2)]);
    if (mounted) setState(() { _spentThis = thisM; _spentLast = lastM; });
    await fetchInsights();

    // Check spending level once after data loaded
    if (mounted && _totalIncome > 0) {
      // Reset lastPct to force showing toast
      _lastPct = -1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkSpendingLevel(_totalExpense, _totalIncome);
      });
    }
  }

  Future<void> _checkAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final p = await _achievementService.calculateProgress(user.uid);
      final unlocked = await _achievementService.checkAndUnlockAchievements(
        transactionCount: p['transactionCount'],
        savingsAmount:    p['savingsAmount'],
        streakDays:       p['streakDays'],
      );
      for (final a in unlocked) {
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          AchievementPopupSimple.show(context, a);
        }
      }
    } catch (e) { debugPrint('Achievement error: $e'); }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  Future<void> _saveNotif(String title, String body) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      await _firestore.collection('users').doc(uid)
          .collection('notifications').add({
        'title': title, 'body': body,
        'createdAt': FieldValue.serverTimestamp(),
        'isRead': false, 'type': 'spending_alert',
      });
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid    = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: uid == null
            ? const Center(child: Text('Please login'))
            : StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(uid).snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasData && snap.data!.exists) {
                    final d = snap.data!.data() as Map<String, dynamic>? ?? {};
                    _totalIncome  = (d['totalIncome']  ?? 0).toDouble();
                    _totalExpense = (d['totalExpense'] ?? 0).toDouble();
                  }
                  return SingleChildScrollView(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      _buildHeader(isDark),
                      const SizedBox(height: 16),
                      if (_totalIncome > 0) ...[
                        _buildSpendingAlert(isDark),
                        const SizedBox(height: 16),
                      ],
                      if (_spentThis.isNotEmpty) ...[
                        _buildTop3(isDark),
                        const SizedBox(height: 20),
                      ],
                      _buildSection(
                        key: _expenseKey,
                        title: 'Expense',
                        defaults: _defaultExpense,
                        type: 'expense',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 28),
                      _buildSection(
                        key: _incomeKey,
                        title: 'Income',
                        defaults: _defaultIncome,
                        type: 'income',
                        isDark: isDark,
                      ),
                      const SizedBox(height: 20),
                      _buildSpendingInsights(isDark),
                      const SizedBox(height: 100),
                    ]),
                  );
                },
              ),
      ),
      // ── Bottom nav + toast overlay ────────────────────
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Toast notification above nav bar
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
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
                    ),
                  )
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
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
        Text('Categories', style: TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
        const SizedBox(height: 4),
        Text('Manage your categories', style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600])),
      ])),
      _hBtn(
        gradient: const LinearGradient(
            colors: [Color(0xFF00D09E), Color(0xFF00A8AA)]),
        icon: Icons.emoji_events, iconColor: Colors.amber,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AchievementsView())),
        isDark: isDark,
      ),
      const SizedBox(width: 8),
      _hBtn(icon: Icons.swap_horiz_rounded,
          onTap: () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const TransactionView())),
          isDark: isDark),
      const SizedBox(width: 8),
      _hBtn(icon: Icons.notifications_outlined,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationView())),
          isDark: isDark),
    ]);
  }

  Widget _hBtn({LinearGradient? gradient, required IconData icon,
      Color? iconColor, required VoidCallback onTap, required bool isDark}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(
          gradient: gradient,
          color: gradient == null
              ? (isDark ? const Color(0xFF2C2C2C) : Colors.white) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon,
            color: iconColor ?? (isDark ? Colors.grey[300] : Colors.grey[700]),
            size: 21),
      ),
    );
  }

  // ── Spending alert card ───────────────────────────────
  Widget _buildSpendingAlert(bool isDark) {
    final pct = (_totalExpense / _totalIncome * 100).clamp(0.0, 100.0);
    final Color color;
    final IconData icon;
    final String text;
    if (pct >= 90) {
      color = Colors.red[600]!;
      icon  = Icons.warning_rounded;
      text  = 'Critical! Over budget!';
    } else if (pct >= 50) {
      color = Colors.amber[700]!;
      icon  = Icons.info_rounded;
      text  = 'Spent over half of income';
    } else {
      color = Colors.green[600]!;
      icon  = Icons.check_circle_rounded;
      text  = 'Spending looks good';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : Colors.grey[800]))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20)),
            child: Text('${pct.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold, color: color)),
          ),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct / 100, minHeight: 7,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Spent: ${_fmt(_totalExpense)}đ',
              style: TextStyle(fontSize: 11,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
          Text('Income: ${_fmt(_totalIncome)}đ',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700])),
        ]),
        if (pct >= 50) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.2)),
            ),
            child: Row(children: [
              Icon(pct >= 90
                  ? Icons.notifications_active_rounded
                  : Icons.tips_and_updates_rounded,
                  color: color, size: 14),
              const SizedBox(width: 8),
              Expanded(child: Text(
                pct >= 90
                    ? 'Bạn đã chi ${pct.toStringAsFixed(0)}% thu nhập! Dừng chi tiêu không cần thiết ngay.'
                    : 'Đã chi hơn 50% thu nhập. Kiểm soát chi tiêu cẩn thận hơn!',
                style: TextStyle(fontSize: 11, height: 1.4, color: color),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  // ── Top 3 ─────────────────────────────────────────────
  Widget _buildTop3(bool isDark) {
    final sorted = _spentThis.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top3   = sorted.take(3).toList();
    final maxAmt = top3.first.value;
    const colors = [Color(0xFFFF6B6B), Color(0xFFFFBE0B), Color(0xFF4ECDC4)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.bar_chart_rounded,
                color: Color(0xFFFF6B6B), size: 18),
          ),
          const SizedBox(width: 10),
          Text('Top spending this month', style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87)),
        ]),
        const SizedBox(height: 14),
        ...top3.asMap().entries.map((e) {
          final color  = colors[e.key];
          final ratio  = maxAmt > 0 ? e.value.value / maxAmt : 0.0;
          final pctStr = _totalExpense > 0
              ? (e.value.value / _totalExpense * 100).toStringAsFixed(0) : '0';
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('${e.key + 1}.',
                    style: TextStyle(fontSize: 12,
                        fontWeight: FontWeight.bold, color: Colors.grey[500])),
                const SizedBox(width: 6),
                Expanded(child: Text(e.value.key,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis)),
                Text('${_fmt(e.value.value)}đ',
                    style: TextStyle(fontSize: 13,
                        fontWeight: FontWeight.bold, color: color)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text('$pctStr%', style: TextStyle(
                      fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
              ]),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio, minHeight: 6,
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

  // ── Category section ──────────────────────────────────
  Widget _buildSection({
    Key? key,
    required String title,
    required List<Map<String, dynamic>> defaults,
    required String type,
    required bool isDark,
  }) {
    final sectionColor = type == 'income' ? Colors.green[600]! : Colors.red[500]!;
    final isHighlighted = widget.initialType == type;

    return Container(
      key: key,
      decoration: isHighlighted ? BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: sectionColor.withOpacity(0.5), width: 2)) : null,
      padding: isHighlighted ? const EdgeInsets.all(12) : EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: sectionColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(
              type == 'income'
                  ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: sectionColor, size: 20),
          ),
          const SizedBox(width: 12),
          Text(title, style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
        ]),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          Icon(Icons.swipe_rounded, size: 14, color: Colors.grey[400]),
          const SizedBox(width: 4),
          Text('Swipe for more',
              style: TextStyle(fontSize: 11, color: Colors.grey[400])),
          const SizedBox(width: 2),
          Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey[400]),
        ]),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_auth.currentUser?.uid)
              .collection('categories')
              .snapshots(),
          builder: (ctx, snap) {
            final custom = <Map<String, dynamic>>[];
            if (snap.hasData) {
              for (final doc in snap.data!.docs) {
                try {
                  final d = doc.data() as Map<String, dynamic>;
                  if ((d['type'] ?? 'expense') != type) continue;
                  IconData icon = Icons.category;
                  if (d['icon'] is int)
                    icon = IconData(d['icon'] as int, fontFamily: 'MaterialIcons');
                  else if (d['icon'] is String)
                    icon = _iconFromString(d['icon'] as String);
                  int colorVal = 0xFF00CED1;
                  if (d['color'] is int) colorVal = d['color'] as int;
                  else if (d['color'] is String)
                    colorVal = int.tryParse(d['color']) ?? colorVal;
                  custom.add({
                    'name': d['name'] ?? 'Untitled',
                    'iconData': icon,
                    'color': Color(colorVal),
                    'isCustom': true,
                  });
                } catch (_) {}
              }
            }
            final defaultItems = defaults.map((d) => {
              'name':     d['name'] as String,
              'iconData': _iconFromCode(d['icon'] as int),
              'color':    Color(d['color'] as int),
              'isCustom': false,
            }).toList();
            final all = [...defaultItems, ...custom];

            return Stack(alignment: Alignment.centerRight, children: [
              SizedBox(
                height: 108,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
                  itemCount: all.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (ctx, i) {
                    if (i == all.length)
                      return _buildAddBtn(type, isDark, sectionColor);
                    return _buildCatCard(all[i], type, isDark);
                  },
                ),
              ),
              if (all.length > 3)
                Positioned(
                  right: 0,
                  child: Container(
                    width: 36, height: 108,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA)).withOpacity(0),
                          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
                        ],
                      ),
                    ),
                    child: Center(child: Container(
                      width: 24, height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 6, offset: const Offset(0, 2))],
                      ),
                      child: Icon(Icons.chevron_right_rounded,
                          size: 16, color: sectionColor),
                    )),
                  ),
                ),
            ]);
          },
        ),
      ]),
    );
  }

  // ── Category card ─────────────────────────────────────
  Widget _buildCatCard(Map<String, dynamic> cat, String type, bool isDark) {
    final name  = cat['name'] as String;
    final icon  = cat['iconData'] as IconData;
    final color = cat['color'] as Color;
    final spent   = _spentThis[name] ?? 0;
    final budget  = _totalIncome > 0 ? _totalIncome * 0.15 : 0.0;
    final ringPct = budget > 0 ? (spent / budget).clamp(0.0, 1.0) : 0.0;
    final isOver  = spent > budget && budget > 0 && type == 'expense';
    final lastAmt   = _spentLast[name] ?? 0;
    final hasComp   = lastAmt > 0 && spent > 0 && type == 'expense';
    final changePct = hasComp ? ((spent - lastAmt) / lastAmt * 100).round() : 0;
    final isUp = changePct > 0;

    return GestureDetector(
      onTap: () {
        if (type == 'expense') {
          _showQuickAdd(name, color, icon, isDark);
        } else {
          Navigator.push(context, MaterialPageRoute(
              builder: (_) => CategoryDetailView(
                  categoryColor: color, categoryName: name, categoryIcon: icon)));
        }
      },
      onLongPress: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CategoryDetailView(
              categoryColor: color, categoryName: name, categoryIcon: icon))),
      child: SizedBox(
        width: 80,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Stack(alignment: Alignment.topRight, children: [
            Stack(alignment: Alignment.center, children: [
              SizedBox(
                width: 58, height: 58,
                child: CircularProgressIndicator(
                  value: type == 'expense' ? ringPct : 0,
                  strokeWidth: 3,
                  backgroundColor: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  valueColor: AlwaysStoppedAnimation(isOver ? Colors.red : color),
                ),
              ),
              Container(
                width: 46, height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      colors: [color.withOpacity(0.85), color],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 6, offset: const Offset(0, 3))],
                ),
                child: Icon(icon, size: 20, color: Colors.white),
              ),
            ]),
            if (isOver)
              Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: const Center(child: Text('!',
                    style: TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.bold))),
              ),
          ]),
          const SizedBox(height: 6),
          Text(name,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[100] : const Color(0xFF1A1A1A)),
              textAlign: TextAlign.center, maxLines: 1,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          if (hasComp)
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 9, color: isUp ? Colors.red : Colors.green),
              Text('${changePct.abs()}%',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                      color: isUp ? Colors.red : Colors.green)),
            ])
          else if (spent > 0 && type == 'expense')
            Text('${_fmt(spent)}đ',
                style: TextStyle(fontSize: 9,
                    color: isOver ? Colors.red : Colors.grey[500]),
                textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  // ── Add button ────────────────────────────────────────
  Widget _buildAddBtn(String type, bool isDark, Color color) {
    return GestureDetector(
      onTap: () async {
        final ok = await showDialog<bool>(context: context,
            builder: (_) => AddCategoryDialog(categoryType: type));
        if (ok == true) setState(() {});
      },
      child: SizedBox(
        width: 80,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: color.withOpacity(0.4), width: 1.5),
              boxShadow: [BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 6, offset: const Offset(0, 3))],
            ),
            child: Icon(Icons.add_rounded, size: 26, color: color),
          ),
          const SizedBox(height: 6),
          Text('Add', style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ]),
      ),
    );
  }

  // ── Quick add sheet ───────────────────────────────────
  void _showQuickAdd(String category, Color color, IconData icon, bool isDark) {
    final amtCtrl  = TextEditingController();
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final amt    = double.tryParse(amtCtrl.text.replaceAll(',', '')) ?? 0;
          final isOver = _totalIncome > 0 && amt > _totalIncome * 0.15;
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
                top: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),
              Row(children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: [color.withOpacity(0.8), color]),
                      borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Quick Add Expense',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(category, style: TextStyle(
                        fontSize: 11, color: color, fontWeight: FontWeight.w600)),
                  ),
                ])),
                GestureDetector(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.grey[200], shape: BoxShape.circle),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey[700]),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isOver ? Colors.red : color.withOpacity(0.2),
                      width: isOver ? 1.5 : 1),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Amount', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text('₫', style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold, color: color)),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: amtCtrl,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      onChanged: (_) => setS(() {}),
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                          hintText: '0', border: InputBorder.none,
                          isDense: true, contentPadding: EdgeInsets.zero),
                    )),
                  ]),
                  if (isOver) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.warning_rounded, color: Colors.red, size: 13),
                      const SizedBox(width: 4),
                      Text('Over 15% of monthly income!',
                          style: TextStyle(fontSize: 11, color: Colors.red[600])),
                    ]),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                style: TextStyle(fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Note (optional)...',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.grey[400]),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final amount = double.tryParse(amtCtrl.text.replaceAll(',', ''));
                    if (amount == null || amount <= 0) return;
                    await _saveExpense(amount: amount,
                        category: category, note: noteCtrl.text.trim());
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color, elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Save Expense',
                      style: TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Future<void> _saveExpense({
    required double amount, required String category, required String note,
  }) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;
      final title = note.isEmpty ? category : note;
      await _firestore.collection('users').doc(uid).collection('transactions').add({
        'type': 'expense', 'amount': amount,
        'category': category, 'categoryName': category,
        'title': title, 'note': title,
        'date': Timestamp.fromDate(DateTime.now()), 'createdAt': Timestamp.now(),
      });
      await _firestore.collection('users').doc(uid).update({
        'balance':      FieldValue.increment(-amount),
        'totalExpense': FieldValue.increment(amount),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Added ${_fmt(amount)}đ to $category'),
          backgroundColor: Colors.red[500],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  // ── Spending Insights ─────────────────────────────────
  Widget _buildSpendingInsights(bool isDark) {
    if (_spentThis.isEmpty) return const SizedBox.shrink();
    const teal   = Color(0xFF00CED1);
    const purple = Color(0xFF8B5CF6);
    final insights = <_InsightItem>[];

    if (_spentThis.isNotEmpty) {
      final top = _spentThis.entries.reduce((a, b) => a.value > b.value ? a : b);
      insights.add(_InsightItem(
        icon: '💸', color: const Color(0xFFFF6B6B),
        title: 'You spend the most on ${top.key}',
        desc: '${_fmt(top.value)}đ this month'
            '${_totalExpense > 0 ? ' — ${(top.value / _totalExpense * 100).toStringAsFixed(0)}% of all expenses' : ''}',
      ));
    }
    if (_spentLast.isNotEmpty && _spentThis.isNotEmpty) {
      final topThis = _spentThis.entries.reduce((a, b) => a.value > b.value ? a : b);
      final topLast = _spentLast.entries.reduce((a, b) => a.value > b.value ? a : b);
      if (topThis.key == topLast.key) {
        final diff = topThis.value - topLast.value;
        final pct  = topLast.value > 0
            ? (diff / topLast.value * 100).abs().toStringAsFixed(0) : '0';
        insights.add(_InsightItem(
          icon: diff > 0 ? '📈' : '📉',
          color: diff > 0 ? Colors.red[500]! : Colors.green[600]!,
          title: diff > 0
              ? '${topThis.key} spending increased by $pct%'
              : '${topThis.key} spending decreased by $pct%',
          desc: diff > 0
              ? 'Try to cut back on ${topThis.key} next month.'
              : 'Great job reducing ${topThis.key} spending!',
        ));
      }
    }
    if (_avgDailySpend > 0) {
      insights.add(_InsightItem(
        icon: '📅', color: teal,
        title: 'Average daily spending: ${_fmt(_avgDailySpend)}đ',
        desc: 'Based on $_daysWithSpend days with transactions this month.',
      ));
    }
    if (_spentByWeekday.isNotEmpty) {
      final busiest  = _spentByWeekday.entries.reduce((a, b) => a.value > b.value ? a : b);
      final quietest = _spentByWeekday.entries.reduce((a, b) => a.value < b.value ? a : b);
      const days = ['','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
      insights.add(_InsightItem(
        icon: '🗓️', color: purple,
        title: '${days[busiest.key]} is your biggest spending day',
        desc: '${_fmt(busiest.value)}đ on ${days[busiest.key]}s. ${days[quietest.key]} is your most frugal day.',
      ));
    }
    if (_spentLast.isNotEmpty) {
      int improved = 0;
      for (final cat in _spentThis.keys) {
        if ((_spentLast[cat] ?? 0) > 0 && (_spentThis[cat] ?? 0) < (_spentLast[cat] ?? 0))
          improved++;
      }
      if (improved > 0) {
        insights.add(_InsightItem(
          icon: '🏆', color: Colors.green[600]!,
          title: '$improved ${improved == 1 ? 'category' : 'categories'} improved vs last month',
          desc: 'You spent less in $improved ${improved == 1 ? 'area' : 'areas'} compared to last month. Keep it up!',
        ));
      }
    }
    if (_totalIncome > 0 && _totalExpense > 0) {
      final saved    = _totalIncome - _totalExpense;
      final saveRate = (saved / _totalIncome * 100);
      insights.add(saved > 0
          ? _InsightItem(
              icon: '💰', color: Colors.green[600]!,
              title: 'You\'ve saved ${_fmt(saved)}đ this month',
              desc: 'Saving rate: ${saveRate.toStringAsFixed(1)}%.'
                  '${saveRate >= 20 ? ' Excellent! You\'re on track.' : ' Try to reach 20% for a healthy budget.'}')
          : _InsightItem(
              icon: '⚠️', color: Colors.red[500]!,
              title: 'Spending exceeds income by ${_fmt(saved.abs())}đ',
              desc: 'You\'re overspending this month. Review your biggest categories to cut back.'));
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: teal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.lightbulb_outline_rounded, color: teal, size: 20),
        ),
        const SizedBox(width: 12),
        Text('Spending Insights', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
      ]),
      const SizedBox(height: 12),
      ...insights.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.color.withOpacity(0.2), width: 1),
            boxShadow: [BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.15 : 0.04),
                blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                  color: item.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Center(child: Text(item.icon,
                  style: const TextStyle(fontSize: 20))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 4),
              Text(item.desc, style: TextStyle(
                  fontSize: 12, height: 1.5,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ])),
          ]),
        ),
      )).toList(),
    ]);
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
            _navItem(Icons.layers_rounded, true, label: 'Category', onTap: () {}),
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
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
              color: const Color(0xFF00CED1).withOpacity(0.45),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
      ),
      const SizedBox(height: 4),
      const Text('Voice', style: TextStyle(fontSize: 10,
          fontWeight: FontWeight.w600, color: Color(0xFF00CED1))),
    ]),
  );

  Widget _navItem(IconData icon, bool isActive,
      {VoidCallback? onTap, String label = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const teal  = Color(0xFF00CED1);
    final color = isActive ? teal
        : (isDark ? Colors.grey[500]! : Colors.grey[400]!);
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

class _InsightItem {
  final String icon;
  final Color  color;
  final String title;
  final String desc;
  const _InsightItem({
    required this.icon, required this.color,
    required this.title, required this.desc,
  });
}