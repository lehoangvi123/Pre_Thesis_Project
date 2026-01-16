// lib/view/AnalysisView.dart
// FIXED VERSION - Pie chart không overlap

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

class AnalysisView extends StatefulWidget {
  const AnalysisView({Key? key}) : super(key: key);

  @override
  State<AnalysisView> createState() => _AnalysisViewState();
}

class _AnalysisViewState extends State<AnalysisView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SavingGoalService _goalService = SavingGoalService();

  String selectedPeriod = 'Weekly';
  String chartType = 'bar';
  String pieChartType = 'expense';
  String? userId;
  
  Map<String, double> expenseByCategory = {};
  Map<String, double> incomeByCategory = {};
  bool isLoadingChartData = false;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    if (userId == null) return;
    
    setState(() {
      isLoadingChartData = true;
    });

    // Get expense by category
    expenseByCategory = await _getExpenseByCategory();
    incomeByCategory = await _getIncomeByCategory();

    setState(() {
      isLoadingChartData = false;
    });
  }

  Future<Map<String, double>> _getExpenseByCategory() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .get();

      Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String categoryName = data['categoryName'] ?? 'Khác';
        double amount = (data['amount'] as num).abs().toDouble();

        categoryTotals[categoryName] = 
            (categoryTotals[categoryName] ?? 0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      print('Error: $e');
      return {};
    }
  }

  Future<Map<String, double>> _getIncomeByCategory() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .get();

      Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        String categoryName = data['categoryName'] ?? 'Khác';
        double amount = (data['amount'] as num).abs().toDouble();

        categoryTotals[categoryName] = 
            (categoryTotals[categoryName] ?? 0) + amount;
      }

      return categoryTotals;
    } catch (e) {
      print('Error: $e');
      return {};
    }
  }

  String _formatCurrency(double amount) {
    return AnalysisWidgets.formatCurrency(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Please login')),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(userId).snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          var userData =
              userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
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
                      _buildBalanceCard(
                          balance, totalIncome, totalExpense, isDark),
                      const SizedBox(height: 20),
                      _buildPeriodSelector(),
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

  Widget _buildHeader(bool isDark) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Phân tích',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Xem thông tin tài chính của bạn',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
            _buildChartTypeMenu(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeMenu(bool isDark) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: isDark ? Colors.grey[400] : Colors.grey[800],
        size: 24,
      ),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
      onSelected: (value) {
        if (value == 'bar' || value == 'pie') {
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
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF00CED1)
                : (isDark ? Colors.grey[500] : Colors.grey[600]),
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? const Color(0xFF00CED1)
                  : (isDark ? Colors.grey[300] : Colors.grey[800]),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: 14,
            ),
          ),
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
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng số dư',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.account_balance_wallet,
                        color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Tài khoản',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatCurrency(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                    'Thu nhập', totalIncome, Icons.arrow_downward),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildBalanceItem(
                    'Chi tiêu', totalExpense, Icons.arrow_upward),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  '${percentage.toStringAsFixed(1)}% chi tiêu, ${percentage < 50 ? 'Tốt' : 'Chi nhiều'}',
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label == 'Chi tiêu'
              ? '-${_formatCurrency(amount)}'
              : _formatCurrency(amount),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton('Ngày'),
        const SizedBox(width: 8),
        _buildPeriodButton('Tuần'),
        const SizedBox(width: 8),
        _buildPeriodButton('Tháng'),
        const SizedBox(width: 8),
        _buildPeriodButton('Năm'),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isSelected = (selectedPeriod == 'Daily' && period == 'Ngày') ||
        (selectedPeriod == 'Weekly' && period == 'Tuần') ||
        (selectedPeriod == 'Monthly' && period == 'Tháng') ||
        (selectedPeriod == 'Year' && period == 'Năm');

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (period == 'Ngày') {
              selectedPeriod = 'Daily';
            } else if (period == 'Tuần') {
              selectedPeriod = 'Weekly';
            } else if (period == 'Tháng') {
              selectedPeriod = 'Monthly';
            } else if (period == 'Năm') {
              selectedPeriod = 'Year';
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00CED1)
                : (isDark ? Colors.grey[800] : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              period,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard(
      double totalIncome, double totalExpense, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thu nhập & Chi tiêu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.grey[800],
                ),
              ),
              Row(
                children: [
                  _buildLegend(const Color(0xFF00CED1), 'Thu'),
                  const SizedBox(width: 12),
                  _buildLegend(const Color(0xFF7FFFD4), 'Chi'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300, // ✅ Fixed height
            child: chartType == 'bar'
                ? _buildBarChart(totalIncome, totalExpense, isDark)
                : _buildPieChart(totalIncome, totalExpense, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(
      double totalIncome, double totalExpense, bool isDark) {
    double weeklyIncome = totalIncome / 4;
    double weeklyExpense = totalExpense / 4;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (weeklyIncome > weeklyExpense ? weeklyIncome : weeklyExpense) *
            1.2,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const days = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                if (value.toInt() < days.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      days[value.toInt()],
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (index) {
          double incomeVariation = (index % 2 == 0 ? 1.1 : 0.9);
          double expenseVariation = (index % 3 == 0 ? 1.2 : 0.8);

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: (weeklyIncome / 7) * incomeVariation,
                color: const Color(0xFF00CED1),
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: (weeklyExpense / 7) * expenseVariation,
                color: const Color(0xFF7FFFD4),
                width: 12,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ✅ FIXED PIE CHART - Row layout để không overlap
  Widget _buildPieChart(
      double totalIncome, double totalExpense, bool isDark) {
    return Column(
      children: [
        // Selector
        _buildPieChartTypeSelector(isDark),
        const SizedBox(height: 20),
        
        // Loading or Chart
        Expanded(
          child: isLoadingChartData
              ? const Center(child: CircularProgressIndicator())
              : _buildPieChartWithLegend(isDark),
        ),
      ],
    );
  }

  Widget _buildPieChartTypeSelector(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTypeButton('Chi tiêu', 'expense', Colors.red, isDark),
        const SizedBox(width: 12),
        _buildTypeButton('Thu nhập', 'income', const Color(0xFF00CED1), isDark),
      ],
    );
  }

  Widget _buildTypeButton(
      String label, String type, Color color, bool isDark) {
    bool isSelected = pieChartType == type;
    return GestureDetector(
      onTap: () => setState(() => pieChartType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : (isDark ? Colors.grey[800] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? color
                : (isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
        ),
      ),
    );
  }

  // ✅ PIE CHART + LEGEND SIDE BY SIDE
  Widget _buildPieChartWithLegend(bool isDark) {
    Map<String, double> data =
        pieChartType == 'expense' ? expenseByCategory : incomeByCategory;

    if (data.isEmpty) {
      return Center(
        child: Text(
          'Chưa có dữ liệu',
          style: TextStyle(
            color: isDark ? Colors.grey[500] : Colors.grey[600],
          ),
        ),
      );
    }

    double total = data.values.fold(0, (sum, value) => sum + value);
    var sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topCategories = sortedEntries.take(5).toList();

    List<Color> colors = pieChartType == 'expense'
        ? [
            const Color(0xFFFF6B6B),
            const Color(0xFFFFBE0B),
            const Color(0xFF4ECDC4),
            const Color(0xFFFF006E),
            const Color(0xFF8338EC),
          ]
        : [
            const Color(0xFF00CED1),
            const Color(0xFF48D1CC),
            const Color(0xFF00FA9A),
            const Color(0xFF7FFFD4),
            const Color(0xFF40E0D0),
          ];

    return Row(
      children: [
        // PIE CHART - LEFT
        Expanded(
          flex: 2,
          child: AspectRatio(
            aspectRatio: 1,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: topCategories.asMap().entries.map((entry) {
                  int index = entry.key;
                  var category = entry.value;
                  double percentage = (category.value / total) * 100;

                  return PieChartSectionData(
                    value: category.value,
                    title: '${percentage.toStringAsFixed(0)}%',
                    color: colors[index % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),

        const SizedBox(width: 20),

        // LEGEND - RIGHT
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: topCategories.asMap().entries.map((entry) {
              int index = entry.key;
              var category = entry.value;
              double percentage = (category.value / total) * 100;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        category.key,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLegend(Color color, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
      double totalIncome, double totalExpense, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  const Color(0xFF00CED1).withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color:
                    const Color(0xFF00CED1).withOpacity(isDark ? 0.2 : 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CED1)
                        .withOpacity(isDark ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    color: Color(0xFF00CED1),
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Thu nhập',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(totalIncome),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00CED1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.red.withOpacity(isDark ? 0.2 : 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(isDark ? 0.3 : 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.trending_down,
                    color: Colors.red[600],
                    size: 24,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chi tiêu',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatCurrency(totalExpense),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[600],
                  ),
                ),
              ],
            ),
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
            Text(
              'Mục tiêu của tôi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[800],
              ),
            ),
            TextButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSavingGoalView(),
                  ),
                );
                if (result == true && mounted) {
                  setState(() {});
                }
              },
              icon: const Icon(
                Icons.add_circle_outline,
                color: Color(0xFF00CED1),
                size: 20,
              ),
              label: const Text(
                'Thêm',
                style: TextStyle(
                  color: Color(0xFF00CED1),
                  fontWeight: FontWeight.w600,
                ),
              ),
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
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return AnalysisWidgets.buildEmptyGoalsState(isDark);
            }

            List<SavingGoal> goals = snapshot.data!;

            return Column(
              children: goals.map((goal) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AnalysisWidgets.buildSavingGoalItem(
                    context: context,
                    goal: goal,
                    isDark: isDark,
                    userId: userId,
                    firestore: _firestore,
                    onGoalUpdated: () => setState(() {}),
                  ),
                );
              }).toList(),
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
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.home,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.search,
                true,
                const Color(0xFF00CED1),
                onTap: () {},
              ),
              _buildNavItem(
                Icons.swap_horiz,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const TransactionView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.layers,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const CategoriesView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.person_outline,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ProfileView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    bool isActive,
    Color color, {
    VoidCallback? onTap,
  }) {
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