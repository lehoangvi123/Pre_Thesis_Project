// lib/view/HomeView.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../login/LoginView.dart';
import '../notification/NotificationView.dart';
import './AnalysisView.dart';
import './Transaction.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './gamification_widgets.dart';
import '../Achivement/Achievement_view.dart';
import './Streak_update/Login_streak_service.dart';
import '../Calender_Part/Calender.dart';
import './Budget/budget_list_view.dart'; // ✅ Giờ là Báo cáo tháng
import './AddTransactionView.dart';
import '../TextVoice/AI_deep_analysis_view.dart';
import './AI_Chatbot/chatbot_view.dart';
import '../../view/Bill_Scanner_Service/Bill_scanner_view.dart';
import './HomeQuickAddExpense.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);
  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String selectedPeriod    = 'Monthly';
  String userName          = 'User';
  bool   isLoadingUserName = true;
  String? userId;
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "vi_VN");

  // Streak data
  int _currentStreak = 0;
  int _bestStreak    = 0;

  // Daily data: {day: expense}, {day: income}
  Map<int, double> _dailySpend  = {};
  Map<int, double> _dailyIncome = {};
  // Full transactions per day: {day: [tx, tx, ...]}
  Map<int, List<Map<String, dynamic>>> _dailyTxs = {};

  // Data báo cáo tháng
  double _monthIncome  = 0;
  double _monthExpense = 0;
  double _dailyBudget  = 0; // Số tiền có thể tiêu hôm nay
  List<Map<String, dynamic>> _recentTxs = [];
  bool _reportLoading = true;

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserName();
    _checkLoginStreak();
    _loadStreakData();
    _loadDailySpend().then((_) => _loadMonthReport());
  }

  Future<void> _loadUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users').doc(user.uid).get();
        if (mounted) setState(() {
          userName = doc.exists
              ? ((doc.data() as Map)['name'] ?? user.displayName ?? 'User')
              : (user.displayName ?? user.email?.split('@')[0] ?? 'User');
          isLoadingUserName = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoadingUserName = false);
    }
  }

  Future<void> _checkLoginStreak() async {
    try {
      final data   = await LoginStreakService().checkAndUpdateStreak();
      final streak = data['currentStreak'] ?? 0;
      if (mounted && streak > 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text('Login streak: $streak days! Keep it up!',
                style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (_) {}
  }

  // ── Load streak data ─────────────────────────────────
  Future<void> _loadStreakData() async {
    try {
      final data = await LoginStreakService().checkAndUpdateStreak();
      if (mounted) setState(() {
        _currentStreak = data['currentStreak'] ?? 0;
        _bestStreak    = data['bestStreak'] ?? 0;
      });
    } catch (_) {}
  }

  // ── Load daily spending for mini calendar ────────────
  Future<void> _loadDailySpend() async {
    final uid = userId;
    if (uid == null) return;
    final now   = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    final end   = Timestamp.fromDate(DateTime(now.year, now.month, now.day, 23, 59, 59));
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date', descending: true)
          .get();

      final expMap = <int, double>{};
      final incMap = <int, double>{};
      final txMap  = <int, List<Map<String, dynamic>>>{};

      for (final doc in snap.docs) {
        final d     = doc.data();
        final isInc = d['type'] == 'income' || d['isIncome'] == true;
        DateTime? date = (d['date'] as Timestamp?)?.toDate();
        date ??= (d['createdAt'] as Timestamp?)?.toDate();
        if (date == null) continue;
        final amt = (d['amount'] as num?)?.toDouble().abs() ?? 0;
        final day = date.day;

        if (isInc) {
          incMap[day] = (incMap[day] ?? 0) + amt;
        } else {
          expMap[day] = (expMap[day] ?? 0) + amt;
        }
        txMap[day] = [...(txMap[day] ?? []), d];
      }

      debugPrint('✅ Daily loaded: exp=${expMap.length}days, inc=${incMap.length}days');
      if (mounted) setState(() {
        _dailySpend  = expMap;
        _dailyIncome = incMap;
        _dailyTxs    = txMap;
      });
    } catch (e) {
      debugPrint('❌ Daily load error: $e');
    }
  }

  // ── Load báo cáo tháng hiện tại ─────────────────────
  Future<void> _loadMonthReport() async {
    final uid = userId;
    if (uid == null) return;
    if (mounted) setState(() => _reportLoading = true);

    final now   = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end   = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('transactions')
          .where('date', isGreaterThanOrEqualTo: start)
          .where('date', isLessThanOrEqualTo: end)
          .orderBy('date', descending: true)
          .get();

      double inc = 0, exp = 0;
      final txs = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final d     = doc.data();
        final isInc = d['type'] == 'income' || d['isIncome'] == true;
        final amt   = (d['amount'] as num?)?.toDouble().abs() ?? 0;
        if (isInc) inc += amt; else exp += amt;
        txs.add(d);
      }
      // Tính ngân sách hôm nay
      final now2        = DateTime.now();
      final daysInMonth = DateTime(now2.year, now2.month + 1, 0).day;
      final daysLeft    = daysInMonth - now2.day + 1; // bao gồm hôm nay
      final remaining   = inc - exp;
      final daily       = daysLeft > 0 ? (remaining / daysLeft) : 0.0;

      if (mounted) setState(() {
        _monthIncome  = inc;
        _monthExpense = exp;
        _recentTxs    = txs.take(5).toList();
        _reportLoading = false;
        _dailyBudget   = daily;
      });
    } catch (_) {
      if (mounted) setState(() => _reportLoading = false);
    }
  }

  String _fmt(double v) => v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');

  String _formatCurrency(double v) => _fmt(v);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBalanceCards(),
              const SizedBox(height: 14),
              _buildDailyBudgetCard(isDark),
              const SizedBox(height: 14),
              _buildAddButtons(isDark),
              const SizedBox(height: 16),
              _buildMiniCalendar(isDark),
              const SizedBox(height: 16),
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildPlanSection(isDark),
              const SizedBox(height: 20),
              _buildMonthReportSection(isDark),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ── Header ────────────────────────────────────────────
  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hi, Welcome Back', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.grey[800])),
          const SizedBox(height: 4),
          Text(userName, style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ]),
        Row(children: [
          _hIcon(Icons.swap_horiz_rounded, isDark,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TransactionView()))),
          const SizedBox(width: 8),
          _hIcon(Icons.notifications_outlined, isDark,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationView()))),
          const SizedBox(width: 8),
          _buildStreakBtn(),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showLogoutDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout,
                  color: isDark ? Colors.red[400] : Colors.red[600], size: 20),
            ),
          ),
        ]),
      ],
    );
  }

  // ── Streak icon button ───────────────────────────────
  Widget _buildStreakBtn() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showStreakDialog(isDark),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          gradient: _currentStreak > 0
              ? const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFF5722)])
              : null,
          color: _currentStreak == 0
              ? (isDark ? Colors.grey[800] : Colors.grey[100]) : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _currentStreak > 0 ? [BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 8, offset: const Offset(0, 2))] : [],
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('🔥', style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Text('$_currentStreak',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: _currentStreak > 0
                      ? Colors.white
                      : (isDark ? Colors.grey[400] : Colors.grey[600]))),
        ]),
      ),
    );
  }

  void _showStreakDialog(bool isDark) {
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('🔥', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        Text('Login Streak', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _streakStat('Hiện tại', '$_currentStreak ngày', Colors.orange),
          Container(width: 1, height: 40, color: Colors.grey[300]),
          _streakStat('Kỷ lục', '$_bestStreak ngày', Colors.red[600]!),
        ]),
        const SizedBox(height: 16),
        Text(
          _currentStreak == 0
              ? 'Hãy đăng nhập mỗi ngày để duy trì streak!'
              : _currentStreak >= 7
                  ? '🏆 Tuyệt vời! Bạn đang duy trì streak $_currentStreak ngày!'
                  : '💪 Còn ${7 - _currentStreak} ngày nữa để đạt 7 ngày!',
          style: TextStyle(fontSize: 13, color: Colors.grey[500]),
          textAlign: TextAlign.center,
        ),
      ]),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng', style: TextStyle(color: Color(0xFF00CED1))),
        ),
      ],
    ));
  }

  Widget _streakStat(String label, String value, Color color) =>
      Column(children: [
        Text(value, style: TextStyle(
            fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ]);

  // ── Mini Calendar widget ─────────────────────────────
  Widget _buildMiniCalendar(bool isDark) {
    final now          = DateTime.now();
    final firstWeekday = DateTime(now.year, now.month, 1).weekday % 7;
    final daysInMonth  = DateTime(now.year, now.month + 1, 0).day;
    const months   = ['','Tháng 1','Tháng 2','Tháng 3','Tháng 4','Tháng 5',
      'Tháng 6','Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12'];
    const weekdays = ['CN','T2','T3','T4','T5','T6','T7'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: const Color(0xFF00CED1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Color(0xFF00CED1), size: 16),
            ),
            const SizedBox(width: 8),
            Text('${months[now.month]} ${now.year}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87)),
          ]),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CalendarView())),
            child: const Text('Xem chi tiết',
                style: TextStyle(fontSize: 11,
                    color: Color(0xFF00CED1), fontWeight: FontWeight.w500)),
          ),
        ]),
        const SizedBox(height: 10),

        // Weekday headers
        Row(children: weekdays.map((d) => Expanded(
          child: Center(child: Text(d,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: d == 'CN' ? Colors.red[400] : Colors.grey[500]))),
        )).toList()),
        const SizedBox(height: 4),

        // Days grid — static, no data, no tap
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.2,
          ),
          itemCount: firstWeekday + daysInMonth,
          itemBuilder: (ctx, i) {
            if (i < firstWeekday) return const SizedBox.shrink();
            final day     = i - firstWeekday + 1;
            final isToday = day == now.day;
            final isSun   = (i % 7) == 0;
            return Center(
              child: Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFF00CED1) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(child: Text('$day',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                        color: isToday
                            ? Colors.white
                            : isSun
                                ? Colors.red[400]
                                : (isDark ? Colors.grey[300] : Colors.grey[700])))),
              ),
            );
          },
        ),

        // ── CTA banner ───────────────────────────────
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CalendarView())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00CED1), Color(0xFF0097A7)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Icon(Icons.touch_app_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              const Expanded(child: Text(
                '📊 Xem thu chi theo từng ngày chi tiết hơn',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: Colors.white),
              )),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('Mở ngay',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold,
                        color: Colors.white)),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _hIcon(IconData icon, bool isDark, {required VoidCallback onTap}) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: isDark ? Colors.grey[400] : Colors.grey[700]),
        ),
      );

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Đăng xuất', style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black)),
      content: Text('Bạn có chắc chắn muốn đăng xuất không?',
          style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600]))),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginView()),
                (r) => false);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8))),
          child: const Text('Đăng xuất',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ));
  }

  // ── Balance Cards ─────────────────────────────────────
  Widget _buildBalanceCards() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (userId == null) return const Center(child: Text('Please login'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(userId).snapshots(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || !snap.data!.exists) {
          return Row(children: [
            Expanded(child: _balCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total Balance', amount: 0,
                color: isDark ? Colors.white : Colors.black, isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _balCard(
                icon: Icons.trending_down, label: 'Total Expenses',
                amount: 0, color: Colors.red, isDark: isDark)),
          ]);
        }
        final d        = snap.data!.data() as Map<String, dynamic>? ?? {};
        final balance  = (d['balance']      ?? 0).toDouble();
        final income   = (d['totalIncome']  ?? 0).toDouble();
        final expense  = (d['totalExpense'] ?? 0).toDouble();
        return Column(children: [
          Row(children: [
            Expanded(child: _balCard(icon: Icons.trending_up,
                label: 'Total Income', amount: income,
                color: Colors.green[600]!, isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _balCard(icon: Icons.trending_down,
                label: 'Total Expenses', amount: expense,
                color: Colors.red[600]!, isDark: isDark)),
          ]),
          const SizedBox(height: 12),
          _balCard(icon: Icons.account_balance_wallet_outlined,
              label: 'Total Balance', amount: balance,
              color: Colors.blue[600]!, isDark: isDark, full: true),
        ]);
      },
    );
  }

  Widget _balCard({required IconData icon, required String label,
      required double amount, required Color color,
      required bool isDark, bool full = false}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: full
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(icon, size: 16,
                    color: isDark ? Colors.grey[500] : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ]),
              Text('${_fmt(amount)} đ', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ])
          : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(icon, size: 16,
                    color: isDark ? Colors.grey[500] : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ]),
              const SizedBox(height: 8),
              Text('${_fmt(amount)} đ', style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            ]),
    );
  }

  Widget _buildProgressBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.check_circle, size: 20, color: Colors.green[600]),
        const SizedBox(width: 8),
        Expanded(child: Text('30% Of Your Expenses, Looks Good',
            style: TextStyle(fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700]))),
        Text('\$20,000.00', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[800])),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════
  // PLAN SECTION
  // ══════════════════════════════════════════════════════
  Widget _buildPlanSection(bool isDark) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now   = DateTime.now();
    final start = Timestamp.fromDate(DateTime(now.year, now.month, 1));
    final end   = Timestamp.fromDate(DateTime(now.year, now.month + 1, 0, 23, 59, 59));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('plans').doc('current_plan').snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();
        final data      = snap.data!.data() as Map<String, dynamic>;
        final planData  = data['plan'] as Map<String, dynamic>? ?? {};
        final table     = (planData['expense_table'] as List? ?? []);
        final recIncome = (planData['recommended_income'] as num?)?.toDouble() ?? 0;
        final createdAt = data['createdAt'] as Timestamp?;
        final dateStr   = createdAt != null
            ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
            : '';

        // StreamBuilder thứ 2: lấy chi tiêu thực tế tháng này theo category
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users').doc(uid).collection('transactions')
              .where('date', isGreaterThanOrEqualTo: start)
              .where('date', isLessThanOrEqualTo: end)
              .snapshots(),
          builder: (ctx2, txSnap) {
            // Tính spending per category tháng này
            final spentMap = <String, double>{};
            if (txSnap.hasData) {
              for (final doc in txSnap.data!.docs) {
                final d    = doc.data() as Map<String, dynamic>;
                final isExp = d['type'] == 'expense' || d['isIncome'] == false;
                if (!isExp) continue;
                final cat = (d['category'] ?? d['categoryName'] ?? '').toString();
                final amt = (d['amount'] as num?)?.toDouble().abs() ?? 0;
                spentMap[cat] = (spentMap[cat] ?? 0) + amt;
              }
            }

            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Kế hoạch chi tiêu', style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const AnalysisView())),
                  child: const Text('Xem tất cả',
                      style: TextStyle(fontSize: 13,
                          color: Color(0xFF00CED1), fontWeight: FontWeight.w500)),
                ),
              ]),
              const SizedBox(height: 10),
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
                child: Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                            color: const Color(0xFF00CED1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.assignment_rounded,
                            color: Color(0xFF00CED1), size: 16),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('Mức thu nhập đề xuất',
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                        Text('${_fmt(recIncome)}đ / tháng',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.bold,
                                color: Color(0xFF00CED1))),
                      ])),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _showEditIncomeSheet(
                            uid, planData, table, recIncome, isDark),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                              color: const Color(0xFF00CED1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.edit_rounded,
                              size: 15, color: Color(0xFF00CED1)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Divider(height: 1, thickness: 0.5,
                      color: isDark ? Colors.grey[700] : Colors.grey[100]),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(children: [
                      Icon(Icons.touch_app_rounded, size: 13, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Text('Nhấn vào danh mục để thêm chi tiêu nhanh',
                          style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                    ]),
                  ),
                  ...table.asMap().entries.map((e) {
                    final row     = e.value as Map;
                    final cat     = row['category'] as String? ?? '';
                    final limit   = (row['amount'] as num?)?.toDouble() ?? 0;
                    final percent = (row['percent'] as num?)?.toInt() ?? 0;
                    final spent   = spentMap[cat] ?? 0;
                    final isOver  = spent > limit && limit > 0;
                    final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.0) : 0.0;

                    const colors  = [
                      Color(0xFF00CED1), Color(0xFF4CAF50), Color(0xFFFF9800),
                      Color(0xFF8B5CF6), Color(0xFFE91E63), Color(0xFF9C27B0),
                      Color(0xFFFF5722), Color(0xFF009688), Color(0xFFFFC107),
                      Color(0xFF607D8B),
                    ];
                    final color     = colors[e.key % colors.length];
                    final barColor  = isOver ? Colors.red : color;

                    return Column(children: [
                      InkWell(
                        onTap: () => QuickAddExpenseSheet.show(
                            context: context, category: cat,
                            budgetLimit: limit, isDark: isDark),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                // Dot màu
                                Container(width: 8, height: 8,
                                    decoration: BoxDecoration(
                                        color: barColor, shape: BoxShape.circle)),
                                const SizedBox(width: 10),

                                // Tên category
                                Expanded(child: Text(cat, style: const TextStyle(
                                    fontSize: 13, fontWeight: FontWeight.w500))),

                                // Spent / Limit
                                RichText(text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '${_fmt(spent)}đ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: isOver ? Colors.red : barColor),
                                    ),
                                    TextSpan(
                                      text: ' / ${_fmt(limit)}đ',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w400,
                                          color: isDark
                                              ? Colors.grey[400]
                                              : Colors.grey[500]),
                                    ),
                                  ],
                                )),

                                const SizedBox(width: 6),

                                // % badge
                                Container(
                                  width: 34, height: 20,
                                  decoration: BoxDecoration(
                                      color: barColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6)),
                                  child: Center(child: Text('$percent%',
                                      style: TextStyle(fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: barColor))),
                                ),

                                const SizedBox(width: 6),

                                // Edit button
                                GestureDetector(
                                  onTap: () => _editPlanAmount(uid, planData,
                                      table, e.key, cat, limit, recIncome),
                                  child: Container(
                                    width: 28, height: 28,
                                    decoration: BoxDecoration(
                                        color: isDark
                                            ? Colors.grey[700] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.edit_rounded, size: 14,
                                        color: isDark
                                            ? Colors.grey[300] : Colors.grey[600]),
                                  ),
                                ),
                              ]),

                              // Progress bar
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsets.only(left: 18),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 4,
                                    backgroundColor: isDark
                                        ? Colors.grey[700] : Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation(barColor),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (e.key < table.length - 1)
                        Divider(height: 1, thickness: 0.5,
                            color: isDark ? Colors.grey[700] : Colors.grey[100]),
                    ]);
                  }).toList(),

                  // ── Nút thêm category mới ─────────────
                  Divider(height: 1, thickness: 0.5,
                      color: isDark ? Colors.grey[700] : Colors.grey[100]),
                  InkWell(
                    onTap: () => _showAddPlanCategorySheet(
                        uid, planData, table, recIncome, isDark),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Container(
                          width: 24, height: 24,
                          decoration: BoxDecoration(
                              color: const Color(0xFF00CED1).withOpacity(0.12),
                              shape: BoxShape.circle),
                          child: const Icon(Icons.add_rounded,
                              size: 16, color: Color(0xFF00CED1)),
                        ),
                        const SizedBox(width: 8),
                        const Text('Thêm danh mục',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600,
                                color: Color(0xFF00CED1))),
                      ]),
                    ),
                  ),
                ]),
              ),
            ]);
          },
        );
      },
    );
  }

  // ── Edit recommended income sheet ───────────────────────
  void _showEditIncomeSheet(String uid, Map<String, dynamic> planData,
      List table, double currentIncome, bool isDark) {
    final amtCtrl = TextEditingController(
        text: currentIncome > 0 ? currentIncome.toInt().toString() : '');
    double tempAmt = currentIncome;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
              top: 20, left: 20, right: 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(width: 40, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2))),

            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.trending_up_rounded,
                    color: Color(0xFF00CED1), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Chỉnh mức thu nhập',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Text('Cập nhật thu nhập thực tế của bạn',
                    style: TextStyle(fontSize: 12, color: Colors.grey)),
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
            const SizedBox(height: 20),

            // Amount input
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [Color(0xFF00CED1), Color(0xFF0097A7)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(
                    color: const Color(0xFF00CED1).withOpacity(0.3),
                    blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(children: [
                const Text('Thu nhập / tháng',
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text('₫ ', style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold,
                      color: Colors.white)),
                  Expanded(child: TextField(
                    controller: amtCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    onChanged: (v) => setS(() =>
                        tempAmt = double.tryParse(v.replaceAll(',', '')) ?? 0),
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: Colors.white),
                    decoration: const InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(color: Colors.white38),
                        border: InputBorder.none,
                        isDense: true, contentPadding: EdgeInsets.zero),
                  )),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Quick presets
            Row(children: [5000000, 8000000, 12000000, 18000000, 25000000]
                .map((v) {
              final label = v >= 1000000 ? '${v ~/ 1000000}tr' : '${v}k';
              final isSel = (tempAmt - v).abs() < 1000;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => setS(() {
                    tempAmt = v.toDouble();
                    amtCtrl.text = v.toString();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSel
                          ? const Color(0xFF00CED1)
                          : const Color(0xFF00CED1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFF00CED1).withOpacity(0.3)),
                    ),
                    child: Center(child: Text(label,
                        style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600,
                            color: isSel ? Colors.white
                                : const Color(0xFF00CED1)))),
                  ),
                ),
              ));
            }).toList()),
            const SizedBox(height: 20),

            // Save button
            SizedBox(
              width: double.infinity, height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  final amt = double.tryParse(
                      amtCtrl.text.replaceAll(',', '')) ?? 0;
                  if (amt <= 0) return;

                  // Cập nhật recommended_income + tính lại % các khoản
                  final newTable = List<Map<String, dynamic>>.from(
                      table.map((r) => Map<String, dynamic>.from(r as Map)));
                  for (final row in newTable) {
                    final rowAmt = (row['amount'] as num?)?.toDouble() ?? 0;
                    row['percent'] = (rowAmt / amt * 100).round();
                  }
                  await FirebaseFirestore.instance
                      .collection('users').doc(uid)
                      .collection('plans').doc('current_plan')
                      .update({
                    'plan.recommended_income': amt.toInt(),
                    'plan.expense_table':      newTable,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Đã cập nhật thu nhập: ${_fmt(amt)}đ/tháng'),
                      backgroundColor: const Color(0xFF00CED1),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                      margin: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ));
                  }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CED1),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Lưu thu nhập',
                    style: TextStyle(color: Colors.white,
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ── Add plan category sheet ───────────────────────────
  void _showAddPlanCategorySheet(String uid, Map<String, dynamic> planData,
      List table, double recIncome, bool isDark) {
    final nameCtrl  = TextEditingController();
    final amtCtrl   = TextEditingController();
    double tempAmt  = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final pct = recIncome > 0 && tempAmt > 0
              ? (tempAmt / recIncome * 100).toStringAsFixed(1) : '0';
          return Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
                top: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Handle
              Container(width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2))),

              // Header
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: const Color(0xFF00CED1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.add_rounded,
                      color: Color(0xFF00CED1), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Thêm danh mục mới',
                    style: TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold))),
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
              const SizedBox(height: 20),

              // Tên danh mục
              TextField(
                controller: nameCtrl,
                style: TextStyle(fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Tên danh mục (VD: Gym, Thú cưng...)',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  prefixIcon: Icon(Icons.label_outline_rounded,
                      color: Colors.grey[400]),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
              ),
              const SizedBox(height: 12),

              // Số tiền giới hạn
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CED1).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF00CED1).withOpacity(0.2)),
                ),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Giới hạn chi tiêu / tháng',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[500])),
                      if (tempAmt > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              color: const Color(0xFF00CED1).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8)),
                          child: Text('≈ $pct% thu nhập',
                              style: const TextStyle(
                                  fontSize: 11, color: Color(0xFF00CED1),
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('₫', style: TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold,
                        color: Color(0xFF00CED1))),
                    const SizedBox(width: 8),
                    Expanded(child: TextField(
                      controller: amtCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (v) => setS(() =>
                          tempAmt = double.tryParse(v.replaceAll(',', '')) ?? 0),
                      style: TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87),
                      decoration: const InputDecoration(
                          hintText: '0', border: InputBorder.none,
                          isDense: true, contentPadding: EdgeInsets.zero),
                    )),
                  ]),
                ]),
              ),

              // Preset buttons
              if (recIncome > 0) ...[
                const SizedBox(height: 12),
                Row(children: [5, 10, 15, 20].map((p) {
                  final val = (recIncome * p / 100).round();
                  return Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: GestureDetector(
                      onTap: () => setS(() {
                        tempAmt = val.toDouble();
                        amtCtrl.text = val.toString();
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: (tempAmt - val).abs() < 1
                              ? const Color(0xFF00CED1)
                              : const Color(0xFF00CED1).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: const Color(0xFF00CED1).withOpacity(0.3)),
                        ),
                        child: Center(child: Text('$p%',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600,
                                color: (tempAmt - val).abs() < 1
                                    ? Colors.white : const Color(0xFF00CED1)))),
                      ),
                    ),
                  ));
                }).toList()),
              ],

              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity, height: 50,
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    final amt  = double.tryParse(
                        amtCtrl.text.replaceAll(',', '')) ?? 0;
                    if (name.isEmpty || amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: const Text('Vui lòng nhập tên và số tiền!'),
                        backgroundColor: Colors.red[400],
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                      return;
                    }
                    // Thêm vào expense_table
                    final newTable = List<Map<String, dynamic>>.from(
                        table.map((r) => Map<String, dynamic>.from(r as Map)));
                    newTable.add({
                      'category': name,
                      'amount':   amt.toInt(),
                      'percent':  recIncome > 0
                          ? (amt / recIncome * 100).round() : 0,
                      'note':     '',
                    });
                    await FirebaseFirestore.instance
                        .collection('users').doc(uid)
                        .collection('plans').doc('current_plan')
                        .update({'plan.expense_table': newTable});
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('Đã thêm "$name" vào kế hoạch!'),
                        backgroundColor: const Color(0xFF00CED1),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                        margin: const EdgeInsets.all(12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CED1),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Thêm vào kế hoạch',
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

  Future<void> _editPlanAmount(String uid, Map<String, dynamic> planData,
      List table, int index, String category,
      double currentAmount, double recIncome) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final double maxSlider =
        recIncome > 0 ? (recIncome * 0.6).clamp(1000000, 50000000) : 10000000;
    double tempAmount = currentAmount.clamp(0, maxSlider);

    final result = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final pct = recIncome > 0 ? (tempAmount / recIncome * 100) : 0.0;
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
                Container(padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                      color: const Color(0xFF00CED1).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.tune_rounded,
                      color: Color(0xFF00CED1), size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Chỉnh ngân sách',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  Text(category,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ])),
              ]),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFF00CED1), Color(0xFF0097A7)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(
                      color: const Color(0xFF00CED1).withOpacity(0.3),
                      blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Column(children: [
                  Text('${_fmt(tempAmount)}đ',
                      style: const TextStyle(fontSize: 32,
                          fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(recIncome > 0
                      ? '≈ ${pct.toStringAsFixed(1)}% thu nhập tháng'
                      : 'Kéo slider để điều chỉnh',
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              const SizedBox(height: 20),
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF00CED1),
                  thumbColor: const Color(0xFF00CED1),
                  inactiveTrackColor: const Color(0xFF00CED1).withOpacity(0.15),
                  overlayColor: const Color(0xFF00CED1).withOpacity(0.12),
                  trackHeight: 6,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
                ),
                child: Slider(
                  value: tempAmount, min: 0, max: maxSlider, divisions: 200,
                  onChanged: (v) => setS(() => tempAmount = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('0đ', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  Text('${_fmt(maxSlider)}đ',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ]),
              ),
              if (recIncome > 0) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [5, 10, 15, 20, 25].map((p) {
                  final val = recIncome * p / 100;
                  final isSel = (tempAmount - val).abs() < 1000;
                  return GestureDetector(
                    onTap: () => setS(() => tempAmount = val),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFF00CED1)
                            : const Color(0xFF00CED1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF00CED1).withOpacity(0.3)),
                      ),
                      child: Text('$p%', style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600,
                          color: isSel ? Colors.white : const Color(0xFF00CED1))),
                    ),
                  );
                }).toList()),
              ],
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  child: const Text('Hủy'),
                )),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, tempAmount),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CED1),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0),
                  child: const Text('Áp dụng', style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold, fontSize: 15)),
                )),
              ]),
            ]),
          );
        },
      ),
    );

    if (result == null) return;
    final newTable = List<Map<String, dynamic>>.from(
        table.map((r) => Map<String, dynamic>.from(r as Map)));
    newTable[index]['amount']  = result.toInt();
    newTable[index]['percent'] =
        recIncome > 0 ? (result / recIncome * 100).round() : 0;
    try {
      await FirebaseFirestore.instance
          .collection('users').doc(uid)
          .collection('plans').doc('current_plan')
          .update({'plan.expense_table': newTable});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã cập nhật "$category"'),
          backgroundColor: const Color(0xFF00CED1),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  // ══════════════════════════════════════════════════════
  // ✅ BÁO CÁO THÁNG — thay thế Ngân sách
  // ══════════════════════════════════════════════════════
  Widget _buildMonthReportSection(bool isDark) {
    final now = DateTime.now();
    const months = ['','Tháng 1','Tháng 2','Tháng 3','Tháng 4','Tháng 5',
      'Tháng 6','Tháng 7','Tháng 8','Tháng 9','Tháng 10','Tháng 11','Tháng 12'];
    final label  = '${months[now.month]} ${now.year}';
    final balance = _monthIncome - _monthExpense;
    final savingRate = _monthIncome > 0
        ? (balance / _monthIncome * 100).clamp(0.0, 100.0) : 0.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Báo cáo tháng', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87)),
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BudgetListView())),
          child: const Text('Xem chi tiết',
              style: TextStyle(fontSize: 13,
                  color: Color(0xFF00CED1), fontWeight: FontWeight.w500)),
        ),
      ]),
      const SizedBox(height: 12),

      if (_reportLoading)
        const Center(child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: Color(0xFF00CED1)),
        ))
      else ...[
        // ── Gradient summary card ────────────────────
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const BudgetListView())),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00CED1), Color(0xFF0097A7)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF00CED1).withOpacity(0.3),
                  blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.bar_chart_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(
                    color: Colors.white70, fontSize: 13)),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _rItem('Thu nhập',
                    _monthIncome, Colors.greenAccent[200]!)),
                Expanded(child: _rItem('Chi tiêu',
                    _monthExpense, Colors.red[200]!)),
                Expanded(child: _rItem('Còn lại',
                    balance, balance >= 0 ? Colors.white : Colors.red[200]!)),
              ]),
              const SizedBox(height: 14),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tỷ lệ tiết kiệm',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text('${savingRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                        color: savingRate >= 20 ? Colors.greenAccent : Colors.white,
                        fontWeight: FontWeight.bold, fontSize: 12)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: savingRate / 100, minHeight: 6,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation(
                      savingRate >= 20 ? Colors.greenAccent : Colors.white),
                ),
              ),
              if (_monthIncome == 0 && _monthExpense == 0) ...[
                const SizedBox(height: 10),
                const Center(child: Text('Chưa có giao dịch trong tháng',
                    style: TextStyle(color: Colors.white60, fontSize: 12))),
              ],
            ]),
          ),
        ),

        // ── Recent transactions preview ──────────────
        if (_recentTxs.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(children: [
                  Icon(Icons.receipt_long_rounded,
                      size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text('Giao dịch gần đây', style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.grey[700])),
                ]),
              ),
              Divider(height: 1, thickness: 0.5,
                  color: isDark ? Colors.grey[700] : Colors.grey[100]),
              ..._recentTxs.asMap().entries.map((e) {
                final t     = e.value;
                final isInc = t['type'] == 'income' || t['isIncome'] == true;
                final amt   = (t['amount'] as num?)?.toDouble().abs() ?? 0;
                final title = (t['title'] ?? t['note'] ?? t['category'] ?? 'Giao dịch').toString();
                final cat   = (t['category'] ?? 'Khác').toString();
                final date  = (t['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                final color = isInc ? Colors.green[600]! : Colors.red[500]!;
                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    child: Row(children: [
                      Container(width: 36, height: 36,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(isInc
                            ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: color, size: 16)),
                      const SizedBox(width: 10),
                      Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(title, style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white : Colors.black87),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(5)),
                            child: Text(cat, style: TextStyle(
                                fontSize: 9, color: color,
                                fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(width: 5),
                          Text('${date.day}/${date.month}',
                              style: TextStyle(fontSize: 10, color: Colors.grey[500])),
                        ]),
                      ])),
                      Text('${isInc ? '+' : '-'}${_fmt(amt)}đ',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.bold, color: color)),
                    ]),
                  ),
                  if (e.key < _recentTxs.length - 1)
                    Divider(height: 1, thickness: 0.5,
                        color: isDark ? Colors.grey[700] : Colors.grey[100]),
                ]);
              }).toList(),
              InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const BudgetListView())),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: Text('Xem báo cáo đầy đủ →',
                      style: TextStyle(fontSize: 13,
                          color: Color(0xFF00CED1), fontWeight: FontWeight.w500))),
                ),
              ),
            ]),
          ),
        ],
      ],
    ]);
  }

  Widget _rItem(String label, double amt, Color color) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        Text('${_fmt(amt)}đ', style: TextStyle(
            color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ]);

  // ── Add buttons ───────────────────────────────────────
  // ── Daily budget card ───────────────────────────────
  Widget _buildDailyBudgetCard(bool isDark) {
    final now         = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysLeft    = daysInMonth - now.day + 1;
    final remaining   = _monthIncome - _monthExpense;
    final isPositive  = _dailyBudget >= 0;

    // Màu theo trạng thái
    final Color mainColor;
    final String emoji;
    final String subMsg;
    if (_monthIncome == 0) {
      mainColor = Colors.grey[400]!;
      emoji     = '💡';
      subMsg    = 'Thêm thu nhập để tính ngân sách ngày';
    } else if (_dailyBudget >= 500000) {
      mainColor = const Color(0xFF00CED1);
      emoji     = '🟢';
      subMsg    = 'Thoải mái — còn $daysLeft ngày trong tháng';
    } else if (_dailyBudget >= 100000) {
      mainColor = Colors.orange[600]!;
      emoji     = '🟡';
      subMsg    = 'Cẩn thận — còn $daysLeft ngày trong tháng';
    } else if (_dailyBudget >= 0) {
      mainColor = Colors.red[500]!;
      emoji     = '🔴';
      subMsg    = 'Rất ít — cần tiết kiệm ngay!';
    } else {
      mainColor = Colors.red[700]!;
      emoji     = '⚠️';
      subMsg    = 'Đã vượt ngân sách tháng này!';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            mainColor.withOpacity(isDark ? 0.25 : 0.12),
            mainColor.withOpacity(isDark ? 0.10 : 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: mainColor.withOpacity(0.35), width: 1.5),
      ),
      child: Row(children: [
        // Icon + label bên trái
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Hôm nay có thể tiêu', style: TextStyle(
              fontSize: 12, color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 4),
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              _monthIncome == 0 ? '—' : '${_fmt(_dailyBudget.abs())}đ',
              style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.bold,
                  color: mainColor,
                  height: 1.0),
            ),
            if (_monthIncome > 0) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text('/ngày', style: TextStyle(
                    fontSize: 12, color: Colors.grey[500])),
              ),
            ],
          ]),
          const SizedBox(height: 4),
          Text(subMsg, style: TextStyle(
              fontSize: 11, color: Colors.grey[500])),
        ]),

        const Spacer(),

        // Right side: remaining + emoji
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          if (_monthIncome > 0) ...[
            Text('Còn lại tháng', style: TextStyle(
                fontSize: 10, color: Colors.grey[500])),
            const SizedBox(height: 2),
            Text(
              '${isPositive ? '' : '-'}${_fmt(remaining.abs())}đ',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold,
                  color: isPositive ? mainColor : Colors.red[500]),
            ),
          ],
        ]),
      ]),
    );
  }

  Widget _buildAddButtons(bool isDark) {
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => _showAddSheet(isIncome: true, isDark: isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2DC653), Color(0xFF00A86B)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: const Color(0xFF2DC653).withOpacity(0.45),
                blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Thu nhập', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 0.3)),
          ]),
        ),
      )),
      const SizedBox(width: 12),
      Expanded(child: GestureDetector(
        onTap: () => _showAddSheet(isIncome: false, isDark: isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF5252), Color(0xFFE53935)],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(
                color: const Color(0xFFFF5252).withOpacity(0.45),
                blurRadius: 12, offset: const Offset(0, 5))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle),
              child: const Icon(Icons.remove_rounded, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
            const Text('Chi tiêu', style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 0.3)),
          ]),
        ),
      )),
    ]);
  }

  void _showAddSheet({required bool isIncome, required bool isDark}) {
    final amtCtrl  = TextEditingController();
    final noteCtrl = TextEditingController();
    String selCat  = isIncome ? 'Lương' : 'Ăn uống';

    final expCats = [
      {'icon': '🍜', 'name': 'Ăn uống'},          {'icon': '🚗', 'name': 'Di chuyển'},
      {'icon': '🏠', 'name': 'Nhà ở'},             {'icon': '💊', 'name': 'Sức khoẻ'},
      {'icon': '🛍️', 'name': 'Mua sắm cá nhân'},  {'icon': '🎬', 'name': 'Giải trí & xã hội'},
      {'icon': '💡', 'name': 'Hóa đơn tiện ích'},  {'icon': '📚', 'name': 'Giáo dục'},
      {'icon': '💰', 'name': 'Tiết kiệm'},          {'icon': '📈', 'name': 'Đầu tư & học tập'},
      {'icon': '🛡️', 'name': 'Quỹ dự phòng'},      {'icon': '👨‍👩‍👧', 'name': 'Chi phí gia đình'},
      {'icon': '👶', 'name': 'Chi phí con cái'},    {'icon': '📦', 'name': 'Khác'},
    ];
    final incCats = [
      {'icon': '💼', 'name': 'Lương'},    {'icon': '🎁', 'name': 'Thưởng'},
      {'icon': '📈', 'name': 'Đầu tư'},   {'icon': '🏪', 'name': 'Kinh doanh'},
      {'icon': '🏡', 'name': 'Cho thuê'}, {'icon': '💻', 'name': 'Freelance'},
      {'icon': '💵', 'name': 'Khác'},
    ];
    final cats      = isIncome ? incCats : expCats;
    final mainColor = isIncome ? Colors.green[600]! : Colors.red[500]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Container(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 20),
                Row(children: [
                  Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(isIncome
                        ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: mainColor, size: 22)),
                  const SizedBox(width: 12),
                  Text(isIncome ? 'Thêm Thu nhập' : 'Thêm Chi tiêu',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.grey[200], shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey[700])),
                  ),
                ]),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: mainColor.withOpacity(0.2)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Số tiền', style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text('₫', style: TextStyle(fontSize: 26,
                          fontWeight: FontWeight.bold, color: mainColor)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(
                        controller: amtCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: const InputDecoration(
                            hintText: '0', border: InputBorder.none,
                            isDense: true, contentPadding: EdgeInsets.zero),
                      )),
                    ]),
                  ]),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: noteCtrl,
                  style: TextStyle(fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Mô tả...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.edit_note_rounded, color: Colors.grey[400]),
                    filled: true,
                    fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: mainColor, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Danh mục', style: TextStyle(fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
                const SizedBox(height: 10),
                Wrap(spacing: 8, runSpacing: 8, children: cats.map((c) {
                  final isSel = selCat == c['name'];
                  return GestureDetector(
                    onTap: () => setS(() => selCat = c['name']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSel ? mainColor.withOpacity(0.12)
                            : (isDark ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSel ? mainColor : Colors.transparent,
                            width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Text(c['icon']!, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(c['name']!, style: TextStyle(fontSize: 12,
                            fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                            color: isSel ? mainColor
                                : (isDark ? Colors.grey[300] : Colors.grey[700]))),
                      ]),
                    ),
                  );
                }).toList()),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(
                          amtCtrl.text.replaceAll(',', ''));
                      if (amount == null || amount <= 0) return;
                      await _saveTx(isIncome: isIncome, amount: amount,
                          note: noteCtrl.text.trim(), category: selCat);
                      if (ctx.mounted) Navigator.pop(ctx);
                      _loadMonthReport();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: mainColor, elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    child: Text(isIncome ? 'Thêm Thu nhập' : 'Thêm Chi tiêu',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveTx({required bool isIncome, required double amount,
      required String note, required String category}) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final title = note.isEmpty ? category : note;
      await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('transactions').add({
        'type': isIncome ? 'income' : 'expense', 'amount': amount,
        'category': category, 'categoryName': category,
        'title': title, 'note': title,
        'date': Timestamp.fromDate(DateTime.now()), 'createdAt': Timestamp.now(),
      });
      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'balance': FieldValue.increment(isIncome ? amount : -amount),
        if (isIncome)  'totalIncome':  FieldValue.increment(amount),
        if (!isIncome) 'totalExpense': FieldValue.increment(amount),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Đã thêm ${isIncome ? 'thu nhập' : 'chi tiêu'} ${_fmt(amount)}đ'),
          ]),
          backgroundColor: isIncome ? Colors.green[600] : Colors.red[500],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) { debugPrint('Error: $e'); }
  }

  // ── Bottom nav ────────────────────────────────────────
  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _navItem(Icons.home_rounded, true,
                const Color(0xFF00CED1), label: 'Home', onTap: () {}),
            _navItem(Icons.assignment_rounded, false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!, label: 'Plan',
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AnalysisView()))),
            _voiceNavItem(),
            _navItem(Icons.layers_rounded, false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!, label: 'Category',
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const CategoriesView()))),
            _navItem(Icons.person_outline_rounded, false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!, label: 'Profile',
                onTap: () => Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ProfileView()))),
          ]),
        ),
      ),
    );
  }

  Widget _voiceNavItem() => GestureDetector(
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

  Widget _navItem(IconData icon, bool isActive, Color color,
      {VoidCallback? onTap, String label = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        if (label.isNotEmpty)
          Text(label, style: TextStyle(fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? color
                  : isDark ? Colors.grey[500]! : Colors.grey[400]!)),
      ]),
    );
  }
}