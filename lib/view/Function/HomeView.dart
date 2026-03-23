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
import '../Achivement/Achievement_model.dart';
import '../Achivement/Achievement_view.dart';
import './Streak_update/Login_streak_service.dart';
import '../Calender_Part/Calender.dart';
import './Budget/budget_list_view.dart';
import './AddTransactionView.dart';
import '../TextVoice/AI_deep_analysis_view.dart';
import './AI_Chatbot/chatbot_view.dart';
import '../../view/Bill_Scanner_Service/Bill_scanner_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String selectedPeriod = 'Monthly';
  String userName = 'User';
  bool isLoadingUserName = true;
  String? userId;
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "vi_VN");

  @override
  void initState() {
    super.initState();
    userId = FirebaseAuth.instance.currentUser?.uid;
    _loadUserName();
    _checkLoginStreak();
  }

  Future<void> _loadUserName() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          if (mounted) setState(() {
            userName = userData['name'] ?? currentUser.displayName ?? 'User';
            isLoadingUserName = false;
          });
        } else {
          if (mounted) setState(() {
            userName = currentUser.displayName ??
                currentUser.email?.split('@')[0] ?? 'User';
            isLoadingUserName = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user name: $e');
      if (mounted) setState(() => isLoadingUserName = false);
    }
  }

  Future<void> _checkLoginStreak() async {
    try {
      final streakData = await LoginStreakService().checkAndUpdateStreak();
      final currentStreak = streakData['currentStreak'] ?? 0;
      if (mounted && currentStreak > 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(child: Text('Login streak: $currentStreak days! Keep it up!',
                style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) { print('Error checking streak: $e'); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildBalanceCards(),
                const SizedBox(height: 14),
                _buildAddButtons(isDark),
                const SizedBox(height: 16),
                const StreakTrackerCard(),
                const SizedBox(height: 16),
                _buildProgressBar(),
                const SizedBox(height: 20),
                _buildPlanSection(isDark),
                const SizedBox(height: 20),
                _buildBudgetSection(isDark),
              ],
            ),
          ),
        ),
      ),
      // ✅ Đã xóa floatingActionButton
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

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
          _headerIcon(Icons.swap_horiz_rounded, isDark,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const TransactionView()))),
          const SizedBox(width: 8),
          _headerIcon(Icons.calendar_month, isDark,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const CalendarView()))),
          const SizedBox(width: 8),
          _headerIcon(Icons.notifications_outlined, isDark,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const NotificationView()))),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showLogoutDialog,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50],
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

  Widget _headerIcon(IconData icon, bool isDark,
      {required VoidCallback onTap}) {
    return GestureDetector(
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
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(context: context, builder: (_) => AlertDialog(
      backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Đăng xuất', style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black)),
      content: Text('Bạn có chắc chắn muốn đăng xuất không?',
          style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.black)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Hủy', style: TextStyle(
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () { Navigator.of(context).pop(); _logout(); },
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

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginView()),
      (route) => false,
    );
  }

  Widget _buildBalanceCards() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (userId == null) return const Center(child: Text('Please login'));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyBalanceCards(isDark);
        }
        final userData =
            snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final balance     = (userData['balance']      ?? 0).toDouble();
        final totalIncome  = (userData['totalIncome']  ?? 0).toDouble();
        final totalExpense = (userData['totalExpense'] ?? 0).toDouble();

        return Column(children: [
          Row(children: [
            Expanded(child: _buildBalanceCard(
                icon: Icons.trending_up,
                label: 'Total Income',
                amount: totalIncome,
                color: Colors.green[600]!, isDark: isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildBalanceCard(
                icon: Icons.trending_down,
                label: 'Total Expenses',
                amount: totalExpense,
                color: Colors.red[600]!, isDark: isDark)),
          ]),
          const SizedBox(height: 12),
          _buildBalanceCard(
              icon: Icons.account_balance_wallet_outlined,
              label: 'Total Balance',
              amount: balance,
              color: Colors.blue[600]!, isDark: isDark,
              isFullWidth: true),
        ]);
      },
    );
  }

  Widget _buildBalanceCard({
    required IconData icon,
    required String label,
    required double amount,
    required Color color,
    required bool isDark,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: isFullWidth
          ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                Icon(icon, size: 16,
                    color: isDark ? Colors.grey[500] : Colors.grey[600]),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ]),
              Text('${_formatCurrency(amount)} đ',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold, color: color)),
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
              Text('${_formatCurrency(amount)} đ',
                  style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.bold, color: color)),
            ]),
    );
  }

  Widget _buildEmptyBalanceCards(bool isDark) {
    return Row(children: [
      Expanded(child: _buildBalanceCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'Total Balance', amount: 0,
          color: isDark ? Colors.white : Colors.black, isDark: isDark)),
      const SizedBox(width: 12),
      Expanded(child: _buildBalanceCard(
          icon: Icons.trending_down,
          label: 'Total Expenses', amount: 0,
          color: Colors.red, isDark: isDark)),
    ]);
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
  // PLAN SECTION — Hiển thị kế hoạch chi tiêu từ Firestore
  // ══════════════════════════════════════════════════════
  Widget _buildPlanSection(bool isDark) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plans')
          .doc('current_plan')
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || !snap.data!.exists) return const SizedBox.shrink();

        final data      = snap.data!.data() as Map<String, dynamic>;
        final planData  = data['plan'] as Map<String, dynamic>? ?? {};
        final table     = (planData['expense_table'] as List? ?? []);
        final recIncome = (planData['recommended_income'] as num?)
                ?.toDouble() ?? 0;
        final createdAt = data['createdAt'] as Timestamp?;
        final dateStr   = createdAt != null
            ? '${createdAt.toDate().day}/${createdAt.toDate().month}/${createdAt.toDate().year}'
            : '';

        final previewRows = table;
        final hasMore     = false;

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
                      color: Color(0xFF00CED1),
                      fontWeight: FontWeight.w500)),
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
              // Header thu nhập đề xuất
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
                    Text('${_formatCurrency(recIncome)}đ / tháng',
                        style: const TextStyle(fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00CED1))),
                  ])),
                  if (dateStr.isNotEmpty)
                    Text(dateStr, style: TextStyle(
                        fontSize: 10, color: Colors.grey[500])),
                ]),
              ),

              const SizedBox(height: 10),
              Divider(height: 1, thickness: 0.5,
                  color: isDark ? Colors.grey[700] : Colors.grey[100]),

              // Danh mục
              ...previewRows.asMap().entries.map((e) {
                final row     = e.value as Map;
                final cat     = row['category'] as String? ?? '';
                final amount  = (row['amount'] as num?)?.toDouble() ?? 0;
                final percent = (row['percent'] as num?)?.toInt() ?? 0;
                const colors  = [
                  Color(0xFF00CED1), Color(0xFF4CAF50),
                  Color(0xFFFF9800), Color(0xFF8B5CF6),
                  Color(0xFFE91E63), Color(0xFF9C27B0),
                  Color(0xFFFF5722), Color(0xFF009688),
                  Color(0xFFFFC107), Color(0xFF607D8B),
                ];
                final color = colors[e.key % colors.length];

                return Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    child: Row(children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(cat,
                          style: const TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w500))),
                      Text('${_formatCurrency(amount)}đ',
                          style: TextStyle(fontSize: 13,
                              fontWeight: FontWeight.w700, color: color)),
                      const SizedBox(width: 6),
                      Container(
                        width: 34, height: 20,
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Center(child: Text('$percent%',
                            style: TextStyle(fontSize: 9,
                                fontWeight: FontWeight.w700, color: color))),
                      ),
                      const SizedBox(width: 6),
                      // ✅ Nút chỉnh sửa
                      GestureDetector(
                        onTap: () => _editPlanAmount(
                            uid, planData, table, e.key, cat, amount, recIncome),
                        child: Container(
                          width: 28, height: 28,
                          decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[700] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8)),
                          child: Icon(Icons.edit_rounded,
                              size: 14,
                              color: isDark
                                  ? Colors.grey[300] : Colors.grey[600]),
                        ),
                      ),
                    ]),
                  ),
                  if (e.key < previewRows.length - 1)
                    Divider(height: 1, thickness: 0.5,
                        color: isDark ? Colors.grey[700] : Colors.grey[100]),
                ]);
              }).toList(),

              // Xem thêm
              if (hasMore)
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(
                          builder: (_) => const AnalysisView())),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Text('Xem ${table.length - 4} mục còn lại',
                          style: const TextStyle(fontSize: 12,
                              color: Color(0xFF00CED1),
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: Color(0xFF00CED1)),
                    ]),
                  ),
                ),
            ]),
          ),
        ]);
      },
    );
  }

  // ── Chỉnh sửa số tiền từng danh mục trong plan ────────
  Future<void> _editPlanAmount(
      String uid,
      Map<String, dynamic> planData,
      List table,
      int index,
      String category,
      double currentAmount,
      double recIncome) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl   = TextEditingController(
        text: currentAmount.toInt().toString());

    final result = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Chỉnh sửa: $category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Nhập số tiền mới (đồng)',
              style: TextStyle(fontSize: 13,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              suffixText: 'đ',
              suffixStyle: const TextStyle(
                  color: Color(0xFF00CED1), fontWeight: FontWeight.w600),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                      color: Color(0xFF00CED1), width: 2)),
            ),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(
                  ctrl.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
                Navigator.pop(context, val);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CED1),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Lưu',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == null) return;

    // Cập nhật amount + tính lại percent
    final newTable = List<Map<String, dynamic>>.from(
        table.map((r) => Map<String, dynamic>.from(r as Map)));
    newTable[index]['amount']  = result.toInt();
    newTable[index]['percent'] = recIncome > 0
        ? (result / recIncome * 100).round() : 0;

    // Lưu lại Firestore
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('plans')
          .doc('current_plan')
          .update({'plan.expense_table': newTable});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Đã cập nhật "$category"'),
          backgroundColor: const Color(0xFF00CED1),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) {
      print('Error updating plan: $e');
    }
  }

  Widget _buildBudgetSection(bool isDark) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final activeDocs = (snapshot.data?.docs ?? []).where((doc) {
          final endDate = (doc.data() as Map)['endDate'];
          if (endDate == null) return false;
          return (endDate as Timestamp).toDate().isAfter(now);
        }).toList();

        activeDocs.sort((a, b) {
          final aDate = ((a.data() as Map)['endDate'] as Timestamp).toDate();
          final bDate = ((b.data() as Map)['endDate'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        double totalBudget = 0, totalSpent = 0;
        for (var doc in activeDocs) {
          final d = doc.data() as Map<String, dynamic>;
          totalBudget += (d['limitAmount'] ?? 0.0).toDouble();
          totalSpent  += (d['spentAmount'] ?? 0.0).toDouble();
        }
        final usage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Ngân sách', style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87)),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const BudgetListView())),
              child: const Text('Xem tất cả'),
            ),
          ]),
          const SizedBox(height: 12),
          _buildOverviewCard(activeDocs, totalBudget, totalSpent, usage, isDark),
          const SizedBox(height: 12),
          if (activeDocs.isNotEmpty)
            ...activeDocs.take(3).map((doc) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPreviewCard(
                  doc.data() as Map<String, dynamic>, isDark),
            )).toList(),
        ]);
      },
    );
  }

  Widget _buildOverviewCard(List<QueryDocumentSnapshot> activeDocs,
      double totalBudget, double totalSpent, double usage, bool isDark) {
    if (activeDocs.isEmpty) return _buildEmptyBudgetCard(isDark);

    final exceededCount = activeDocs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final limit = (d['limitAmount'] ?? 0.0).toDouble();
      final spent = (d['spentAmount'] ?? 0.0).toDouble();
      return limit > 0 && spent >= limit;
    }).length;

    final warningCount = activeDocs.where((doc) {
      final d = doc.data() as Map<String, dynamic>;
      final limit = (d['limitAmount'] ?? 0.0).toDouble();
      final spent = (d['spentAmount'] ?? 0.0).toDouble();
      final pct = limit > 0 ? spent / limit * 100 : 0;
      return pct >= 80 && pct < 100;
    }).length;

    final gradientColors = exceededCount > 0
        ? [Colors.red[400]!, Colors.red[600]!]
        : usage >= 80
            ? [Colors.orange[400]!, Colors.orange[600]!]
            : [Colors.teal[400]!, Colors.teal[600]!];

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const BudgetListView())),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors,
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: (exceededCount > 0 ? Colors.red : Colors.teal)
                  .withOpacity(0.3),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Tổng quan ngân sách', style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Icon(exceededCount > 0 ? Icons.error
                : usage >= 80 ? Icons.warning : Icons.check_circle,
                color: Colors.white, size: 24),
          ]),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Tổng ngân sách',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${_currencyFormat.format(totalBudget)}đ',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const Text('Đã chi',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text('${_currencyFormat.format(totalSpent)}đ',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ]),
          ]),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (usage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Sử dụng: ${usage.toStringAsFixed(1)}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            if (exceededCount > 0)
              Text('$exceededCount vượt mức',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold))
            else if (warningCount > 0)
              Text('$warningCount cảnh báo',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 12, fontWeight: FontWeight.bold)),
          ]),
        ]),
      ),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> data, bool isDark) {
    final limitAmount = (data['limitAmount'] ?? 0.0).toDouble();
    final spentAmount = (data['spentAmount'] ?? 0.0).toDouble();
    final percentage  = limitAmount > 0 ? (spentAmount / limitAmount * 100) : 0.0;
    final remaining   = limitAmount - spentAmount;

    final Color statusColor = percentage >= 100 ? Colors.red
        : percentage >= 80 ? Colors.deepOrange
        : percentage >= 50 ? Colors.orange : Colors.green;

    final iconCode = data['categoryIcon'] as int?;
    final IconData icon = iconCode != null
        ? IconData(iconCode, fontFamily: 'MaterialIcons') : Icons.wallet;

    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const BudgetListView())),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: statusColor.withOpacity(0.3), width: 1),
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['categoryName'] ?? '',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor:
                    isDark ? Colors.grey[700] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${percentage.toStringAsFixed(0)}%',
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.bold, color: statusColor)),
            Text('${_currencyFormat.format(remaining)}đ',
                style: TextStyle(fontSize: 11,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ]),
        ]),
      ),
    );
  }

  Widget _buildEmptyBudgetCard(bool isDark) {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const BudgetListView())),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Column(children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 48,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
          const SizedBox(height: 12),
          Text('Chưa có ngân sách', style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[700])),
          const SizedBox(height: 4),
          Text('Tạo ngân sách để kiểm soát chi tiêu',
              style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.grey[500] : Colors.grey[600])),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BudgetListView())),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Tạo ngân sách'),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
          ),
        ]),
      ),
    );
  }

  // ══════════════════════════════════════════════════════
  // ADD INCOME / EXPENSE BUTTONS
  // ══════════════════════════════════════════════════════
  Widget _buildAddButtons(bool isDark) {
    return Row(children: [
      // Add Income
      Expanded(child: GestureDetector(
        onTap: () => _showAddTransactionSheet(isIncome: true, isDark: isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A3A2A) : const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green[400]!.withOpacity(0.5)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.trending_up_rounded,
                color: Colors.green[600], size: 18),
            const SizedBox(width: 8),
            Text('Thu nhập', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Colors.green[700])),
          ]),
        ),
      )),
      const SizedBox(width: 12),
      // Add Expense
      Expanded(child: GestureDetector(
        onTap: () => _showAddTransactionSheet(isIncome: false, isDark: isDark),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF3A1A1A) : const Color(0xFFFFEBEE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red[400]!.withOpacity(0.5)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.trending_down_rounded,
                color: Colors.red[600], size: 18),
            const SizedBox(width: 8),
            Text('Chi tiêu', style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: Colors.red[700])),
          ]),
        ),
      )),
    ]);
  }

  // ── Bottom sheet thêm giao dịch ────────────────────────
  void _showAddTransactionSheet({
    required bool isIncome,
    required bool isDark,
  }) {
    final amountCtrl = TextEditingController();
    final noteCtrl   = TextEditingController();
    String selectedCategory = isIncome ? 'Lương' : 'Ăn uống';

    // Danh mục theo loại
    final expenseCategories = [
      {'icon': '🍜', 'name': 'Ăn uống'},
      {'icon': '🚗', 'name': 'Di chuyển'},
      {'icon': '🏠', 'name': 'Nhà ở'},
      {'icon': '💊', 'name': 'Sức khoẻ'},
      {'icon': '🛍️', 'name': 'Mua sắm'},
      {'icon': '🎬', 'name': 'Giải trí'},
      {'icon': '💡', 'name': 'Hóa đơn'},
      {'icon': '📚', 'name': 'Giáo dục'},
      {'icon': '📦', 'name': 'Khác'},
    ];
    final incomeCategories = [
      {'icon': '💼', 'name': 'Lương'},
      {'icon': '🎁', 'name': 'Thưởng'},
      {'icon': '📈', 'name': 'Đầu tư'},
      {'icon': '🏪', 'name': 'Kinh doanh'},
      {'icon': '🏡', 'name': 'Cho thuê'},
      {'icon': '💻', 'name': 'Freelance'},
      {'icon': '💵', 'name': 'Khác'},
    ];
    final categories = isIncome ? incomeCategories : expenseCategories;
    final mainColor  = isIncome ? Colors.green[600]! : Colors.red[500]!;
    final bgColor    = isIncome
        ? (isDark ? const Color(0xFF0D2B1A) : const Color(0xFFF1FBF4))
        : (isDark ? const Color(0xFF2B0D0D) : const Color(0xFFFFF1F1));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                // Handle bar
                Center(child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2)),
                )),
                const SizedBox(height: 20),

                // Title
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12)),
                    child: Icon(
                      isIncome
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: mainColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text(isIncome ? 'Thêm Thu nhập' : 'Thêm Chi tiêu',
                      style: TextStyle(fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: Colors.grey[700]),
                    ),
                  ),
                ]),

                const SizedBox(height: 24),

                // Ô nhập số tiền — to, nổi bật
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: mainColor.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: mainColor.withOpacity(0.2)),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Số tiền', style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
                    const SizedBox(height: 6),
                    Row(crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                      Text('₫', style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold,
                          color: mainColor)),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87),
                        decoration: const InputDecoration(
                          hintText: '0',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )),
                    ]),
                  ]),
                ),

                const SizedBox(height: 16),

                // Ghi chú
                TextField(
                  controller: noteCtrl,
                  style: TextStyle(fontSize: 15,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Mô tả...',
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: Icon(Icons.edit_note_rounded,
                        color: Colors.grey[400]),
                    filled: true,
                    fillColor: isDark
                        ? Colors.grey[800] : Colors.grey[50],
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: mainColor, width: 1.5)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                ),

                const SizedBox(height: 16),

                // Category label
                Text('Danh mục', style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
                const SizedBox(height: 10),

                // Category chips
                Wrap(spacing: 8, runSpacing: 8,
                    children: categories.map((c) {
                  final isSelected = selectedCategory == c['name'];
                  return GestureDetector(
                    onTap: () => setSheetState(
                        () => selectedCategory = c['name']!),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? mainColor.withOpacity(0.12)
                            : (isDark
                                ? Colors.grey[800] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isSelected
                                ? mainColor : Colors.transparent,
                            width: 1.5),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min,
                          children: [
                        Text(c['icon']!,
                            style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(c['name']!, style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? mainColor
                                : (isDark
                                    ? Colors.grey[300] : Colors.grey[700]))),
                      ]),
                    ),
                  );
                }).toList()),

                const SizedBox(height: 24),

                // Nút thêm
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () async {
                      final amount = double.tryParse(
                          amountCtrl.text.replaceAll(',', ''));
                      if (amount == null || amount <= 0) return;

                      await _saveTransaction(
                        isIncome:  isIncome,
                        amount:    amount,
                        note:      noteCtrl.text.trim(),
                        category:  selectedCategory,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Text(
                      isIncome ? 'Thêm Thu nhập' : 'Thêm Chi tiêu',
                      style: const TextStyle(color: Colors.white,
                          fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Lưu transaction vào Firestore ─────────────────────
  Future<void> _saveTransaction({
    required bool isIncome,
    required double amount,
    required String note,
    required String category,
  }) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final title = note.isEmpty ? category : note;

      // ✅ Lưu vào users/{uid}/transactions — khớp với TransactionView
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .add({
        'type':         isIncome ? 'income' : 'expense',
        'amount':       amount,
        'category':     category,      // field 'category' — TransactionView dùng
        'categoryName': category,      // field 'categoryName' — AddTransactionView dùng
        'title':        title,         // field 'title' — TransactionView search dùng
        'note':         title,
        'date':         Timestamp.fromDate(DateTime.now()),
        'createdAt':    Timestamp.now(),
      });

      // Cập nhật balance
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'balance':    FieldValue.increment(isIncome ? amount : -amount),
        if (isIncome)  'totalIncome':  FieldValue.increment(amount),
        if (!isIncome) 'totalExpense': FieldValue.increment(amount),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Icon(isIncome
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Đã thêm ${isIncome ? 'thu nhập' : 'chi tiêu'} '
                '${_formatCurrency(amount)}đ'),
          ]),
          backgroundColor: isIncome ? Colors.green[600] : Colors.red[500],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) { print('Error saving transaction: $e'); }
  }

  Widget _buildQuickActions() {
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const CategoriesView())),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF00CED1), Color(0xFF009999)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
              color: const Color(0xFF00CED1).withOpacity(0.35),
              blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Quản lý Thu Chi', style: TextStyle(
                    color: Colors.white, fontSize: 16,
                    fontWeight: FontWeight.bold)),
                Text('Thêm thu nhập & chi tiêu',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.8), fontSize: 12)),
              ]),
            ]),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.arrow_forward_ios_rounded,
                  color: Colors.white, size: 16),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, true,
                  const Color(0xFF00CED1), label: 'Home', onTap: () {}),
              _buildNavItem(Icons.assignment_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Plan', onTap: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(
                          builder: (_) => const AnalysisView()))),
              _buildVoiceNavItem(),
              _buildNavItem(Icons.layers_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Category', onTap: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(
                          builder: (_) => const CategoriesView()))),
              _buildNavItem(Icons.person_outline_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Profile', onTap: () => Navigator.pushReplacement(
                      context, MaterialPageRoute(
                          builder: (_) => const ProfileView()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceNavItem() {
    return GestureDetector(
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
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color,
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
          child: Icon(icon, color: isActive ? color : color, size: 24),
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