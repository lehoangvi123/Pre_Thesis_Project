// lib/view/AnalysisView.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './Transaction.dart';
import './HomeView.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './SavingGoals.dart';
import './SavingGoalsService.dart';
import './AddSavingGoalView.dart';
import './analysis_widgets.dart';
import './Chart/bar_chart_widgets.dart';
import './Chart/income_expense_pie_chart.dart';

class AnalysisView extends StatefulWidget {
  const AnalysisView({Key? key}) : super(key: key);

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SavingGoalService _goalService = SavingGoalService();

  String chartType = 'bar';
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return AnalysisWidgets.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Please login')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
          double balance = (userData['balance'] ?? 0).toDouble();
          double totalIncome = (userData['totalIncome'] ?? 0).toDouble();
          double totalExpense = (userData['totalExpense'] ?? 0).toDouble();

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(isDark),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(balance, totalIncome, totalExpense, isDark),
                      const SizedBox(height: 20),
                      _buildChartCard(totalIncome, totalExpense, isDark),
                      const SizedBox(height: 24),
                      _buildSummaryCards(totalIncome, totalExpense, isDark),
                      const SizedBox(height: 24),
                      _buildMyTargetsSection(totalExpense, isDark),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  // ✅ UPDATED HEADER - Thêm icon Transaction góc trên phải
  Widget _buildHeader(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Title
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Phân tích',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Text('Xem thông tin tài chính của bạn',
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),

            // ✅ Transaction icon + Chart menu
            Row(
              children: [
                // Nút Transaction
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const TransactionView())),
                  child: Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
                            blurRadius: 8, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Icon(Icons.swap_horiz_rounded,
                        color: isDark ? Colors.grey[300] : Colors.grey[700], size: 22),
                  ),
                ),
                const SizedBox(width: 8),
                // Chart type menu (đã có sẵn)
                _buildChartTypeMenu(isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeMenu(bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert,
          color: isDark ? Colors.grey[400] : Colors.grey[800], size: 24),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      onSelected: (value) {
        if (value == 'bar' || value == 'pie') {
          if (!mounted) return;
          setState(() => chartType = value);
        }
      },
      itemBuilder: (BuildContext context) => [
        _buildMenuItem('bar', Icons.bar_chart, 'Biểu đồ cột', isDark),
        const PopupMenuDivider(height: 1),
        _buildMenuItem('pie', Icons.pie_chart, 'Biểu đồ tròn', isDark),
      ],
    );
  }

  PopupMenuItem<String> _buildMenuItem(
      String value, IconData icon, String label, bool isDark) {
    bool isSelected = chartType == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              color: isSelected
                  ? const Color(0xFF00CED1)
                  : (isDark ? Colors.grey[500] : Colors.grey[600]),
              size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF00CED1)
                      : (isDark ? Colors.grey[300] : Colors.grey[800]),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      double balance, double totalIncome, double totalExpense, bool isDark) {
    double percentage = totalExpense > 0
        ? (totalExpense / (totalExpense + totalIncome) * 100)
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00CED1), Color(0xFF48D1CC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF00CED1).withOpacity(0.3),
              blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tổng số dư',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.9), fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: Row(children: const [
                  Icon(Icons.account_balance_wallet, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Tài khoản',
                      style: TextStyle(color: Colors.white, fontSize: 12)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(_formatCurrency(balance),
              style: const TextStyle(
                  color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _buildBalanceItem('Thu nhập', totalIncome, Icons.arrow_downward)),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildBalanceItem('Chi tiêu', totalExpense, Icons.arrow_upward)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                  '${percentage.toStringAsFixed(1)}% chi tiêu, ${percentage < 50 ? 'Tốt' : 'Chi nhiều'}',
                  style: const TextStyle(color: Colors.white, fontSize: 11)),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.9), fontSize: 12)),
        ]),
        const SizedBox(height: 4),
        Text(
            label == 'Chi tiêu'
                ? '-${_formatCurrency(amount)}'
                : _formatCurrency(amount),
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildChartCard(double totalIncome, double totalExpense, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Thu nhập & Chi tiêu',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey[800])),
              if (chartType == 'bar')
                Row(children: [
                  _buildLegend(const Color(0xFF00CED1), 'Thu'),
                  const SizedBox(width: 12),
                  _buildLegend(const Color(0xFFFF6B6B), 'Chi'),
                ]),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: chartType == 'bar'
                ? CustomBarChartWidget(
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    isDark: isDark)
                : IncomeExpensePieChart(
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(children: [
      Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
    ]);
  }

  Widget _buildSummaryCards(double totalIncome, double totalExpense, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF00CED1).withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: const Color(0xFF00CED1).withOpacity(isDark ? 0.2 : 0.3)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(isDark ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_wallet,
                    color: Color(0xFF00CED1), size: 24),
              ),
              const SizedBox(height: 12),
              Text('Thu nhập',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 4),
              Text(_formatCurrency(totalIncome),
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00CED1))),
            ]),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.withOpacity(isDark ? 0.2 : 0.3)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.red.withOpacity(isDark ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.trending_down, color: Colors.red[600], size: 24),
              ),
              const SizedBox(height: 12),
              Text('Chi tiêu',
                  style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 4),
              Text(_formatCurrency(totalExpense),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600])),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildMyTargetsSection(double totalExpense, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mục tiêu của tôi',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.grey[800])),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AddSavingGoalView()));
                if (result == true && mounted) setState(() {});
              },
              icon: const Icon(Icons.add_circle_outline,
                  color: Color(0xFF00CED1), size: 20),
              label: const Text('Thêm',
                  style: TextStyle(
                      color: Color(0xFF00CED1), fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<SavingGoal>>(
          stream: _goalService.getSavingGoalsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AnalysisWidgets.buildEmptyGoalsState(isDark);
            }
            return Column(
              children: snapshot.data!.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AnalysisWidgets.buildSavingGoalItem(
                  context: context,
                  goal: goal,
                  isDark: isDark,
                  userId: userId,
                  firestore: _firestore,
                  onGoalUpdated: () { if (!mounted) return; setState(() {}); },
                ),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Home', onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const HomeView()))),
              _buildNavItem(Icons.search_rounded, true,
                  const Color(0xFF00CED1),
                  label: 'Analysis', onTap: () {}),
              _buildVoiceNavItem(),
              _buildNavItem(Icons.layers_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Category', onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const CategoriesView()))),
              _buildNavItem(Icons.person_outline_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Profile', onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const ProfileView()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceNavItem() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/test-voice'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: const Color(0xFF00CED1).withOpacity(0.45),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          const Text('Voice',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: Color(0xFF00CED1))),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color,
      {VoidCallback? onTap, String label = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isActive ? color : color, size: 24),
          ),
          if (label.isNotEmpty)
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? color
                        : isDark ? Colors.grey[500]! : Colors.grey[400]!)),
        ],
      ),
    );
  }
}