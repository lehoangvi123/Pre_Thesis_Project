// lib/view/HomeView.dart
// UPDATED VERSION - Budget data nhất quán

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
import './CategorizeContent.dart';

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
            .collection('users')
            .doc(currentUser.uid)
            .get();
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          if (mounted) {
            setState(() {
              userName = userData['name'] ?? currentUser.displayName ?? 'User';
              isLoadingUserName = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              userName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
              isLoadingUserName = false;
            });
          }
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
      final maxStreak = streakData['maxStreak'] ?? 0;
      print('🔥 Streak updated! Current: $currentStreak, Max: $maxStreak');
      if (mounted && currentStreak > 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Login streak: $currentStreak days! Keep it up!',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
          backgroundColor: Colors.orange[600],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      print('Error checking streak: $e');
    }
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
                const SizedBox(height: 20),
                _buildQuickActions(),
                const SizedBox(height: 16),
                const AchievementProgressCard(),
                const StreakTrackerCard(),
                const SizedBox(height: 16),
                _buildProgressBar(),
                const SizedBox(height: 20),
                _buildBudgetSection(isDark),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'testVoiceBtn',
        onPressed: () => Navigator.pushNamed(context, '/test-voice'),
        backgroundColor: Colors.deepPurple,
        icon: const Icon(Icons.mic, color: Colors.white),
        label: const Text('Test Voice', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, Welcome Back',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800])),
            const SizedBox(height: 4),
            Text(userName,
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
        Row(
          children: [
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
                  color: isDark ? Colors.red[900]?.withOpacity(0.3) : Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.logout,
                    color: isDark ? Colors.red[400] : Colors.red[600], size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerIcon(IconData icon, bool isDark, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: isDark ? Colors.grey[400] : Colors.grey[700]),
      ),
    );
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Đăng xuất',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black)),
        content: Text('Bạn có chắc chắn muốn đăng xuất không?',
            style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black)),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Hủy',
                  style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600]))),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8))),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
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
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return _buildEmptyBalanceCards(isDark);
        }
        var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        double balance = (userData['balance'] ?? 0).toDouble();
        double totalIncome = (userData['totalIncome'] ?? 0).toDouble();
        double totalExpense = (userData['totalExpense'] ?? 0).toDouble();

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _buildBalanceCard(
                        icon: Icons.trending_up,
                        label: 'Total Income',
                        amount: totalIncome,
                        color: Colors.green[600]!,
                        isDark: isDark)),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildBalanceCard(
                        icon: Icons.trending_down,
                        label: 'Total Expenses',
                        amount: totalExpense,
                        color: Colors.red[600]!,
                        isDark: isDark)),
              ],
            ),
            const SizedBox(height: 12),
            _buildBalanceCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total Balance',
                amount: balance,
                color: Colors.blue[600]!,
                isDark: isDark,
                isFullWidth: true),
          ],
        );
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
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: isFullWidth
          ? Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  Icon(icon, size: 16, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ]),
                Text('${_formatCurrency(amount)} đ',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(icon, size: 16, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ]),
                const SizedBox(height: 8),
                Text('${_formatCurrency(amount)} đ',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
    );
  }

  Widget _buildEmptyBalanceCards(bool isDark) {
    return Row(
      children: [
        Expanded(
            child: _buildBalanceCard(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Total Balance',
                amount: 0,
                color: isDark ? Colors.white : Colors.black,
                isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _buildBalanceCard(
                icon: Icons.trending_down,
                label: 'Total Expenses',
                amount: 0,
                color: Colors.red,
                isDark: isDark)),
      ],
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
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text('30% Of Your Expenses, Looks Good',
                style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
          ),
          Text('\$20,000.00',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[800])),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // BUDGET SECTION - Dùng 1 StreamBuilder duy nhất cho cả 2 widget
  // → Đảm bảo số liệu NHẤT QUÁN với Budget_list_view.dart
  // ══════════════════════════════════════════════════════════════
  Widget _buildBudgetSection(bool isDark) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        // Filter active budgets ở client (không cần Firestore index)
        final activeDocs = (snapshot.data?.docs ?? []).where((doc) {
          final endDate = (doc.data() as Map)['endDate'];
          if (endDate == null) return false;
          return (endDate as Timestamp).toDate().isAfter(now);
        }).toList();

        // Sort theo endDate
        activeDocs.sort((a, b) {
          final aDate = ((a.data() as Map)['endDate'] as Timestamp).toDate();
          final bDate = ((b.data() as Map)['endDate'] as Timestamp).toDate();
          return aDate.compareTo(bDate);
        });

        // Tính tổng từ cùng 1 nguồn dữ liệu
        double totalBudget = 0;
        double totalSpent = 0;
        for (var doc in activeDocs) {
          final d = doc.data() as Map<String, dynamic>;
          totalBudget += (d['limitAmount'] ?? 0.0).toDouble();
          totalSpent += (d['spentAmount'] ?? 0.0).toDouble();
        }
        final usage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Ngân sách',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BudgetListView())),
                  child: const Text('Xem tất cả'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Overview Card
            _buildOverviewCard(
                activeDocs, totalBudget, totalSpent, usage, isDark),

            const SizedBox(height: 12),

            // Preview List (top 3) - dùng cùng activeDocs
            if (activeDocs.isNotEmpty)
              ...activeDocs.take(3).map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildPreviewCard(data, isDark),
                );
              }).toList(),
          ],
        );
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
          gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: (exceededCount > 0 ? Colors.red : Colors.teal)
                    .withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tổng quan ngân sách',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Icon(
                  exceededCount > 0
                      ? Icons.error
                      : usage >= 80
                          ? Icons.warning
                          : Icons.check_circle,
                  color: Colors.white,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Tổng ngân sách',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${_currencyFormat.format(totalBudget)}đ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ]),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('Đã chi',
                      style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text('${_currencyFormat.format(totalSpent)}đ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ]),
              ],
            ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Sử dụng: ${usage.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                if (exceededCount > 0)
                  Text('$exceededCount vượt mức',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold))
                else if (warningCount > 0)
                  Text('$warningCount cảnh báo',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> data, bool isDark) {
    final limitAmount = (data['limitAmount'] ?? 0.0).toDouble();
    final spentAmount = (data['spentAmount'] ?? 0.0).toDouble();
    final percentage = limitAmount > 0 ? (spentAmount / limitAmount * 100) : 0.0;
    final remaining = limitAmount - spentAmount;

    final Color statusColor = percentage >= 100
        ? Colors.red
        : percentage >= 80
            ? Colors.deepOrange
            : percentage >= 50
                ? Colors.orange
                : Colors.green;

    final iconCode = data['categoryIcon'] as int?;
    final IconData icon = iconCode != null
        ? IconData(iconCode, fontFamily: 'MaterialIcons')
        : Icons.wallet;

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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: statusColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['categoryName'] ?? '',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                  ),
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${percentage.toStringAsFixed(0)}%',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
                Text('${_currencyFormat.format(remaining)}đ',
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          ],
        ),
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
              color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              style: BorderStyle.solid),
        ),
        child: Column(
          children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 48, color: isDark ? Colors.grey[600] : Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Chưa có ngân sách',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.grey[300] : Colors.grey[700])),
            const SizedBox(height: 4),
            Text('Tạo ngân sách để kiểm soát chi tiêu',
                style: TextStyle(
                    fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CategoriesView()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF00CED1), Color(0xFF009999)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00CED1).withOpacity(0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.swap_horiz_rounded,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quản lý Thu Chi',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Thêm thu nhập & chi tiêu',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8), fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
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
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, true, const Color(0xFF00CED1),
                  onTap: () {}),
              _buildNavItem(Icons.search, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const AnalysisView()));
              }),
              _buildNavItem(Icons.swap_horiz, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const TransactionView()));
              }),
              _buildNavItem(Icons.layers, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const CategoriesView()));
              }),
              _buildNavItem(Icons.person_outline, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const ProfileView()));
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}