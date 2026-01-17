import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import './Transaction.dart';
import './HomeView.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './SavingGoals.dart';
import './SavingGoalsService.dart';
import './AddSavingGoalView.dart';
import './analysis_widgets.dart';
import './Chart/bar_chart_widgets.dart';
import './Chart/pie_chart_widget.dart';

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
  String pieChartType = 'expense';
  String? userId;
  
  // ✅ Calendar variables
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // ✅ Data for selected day
  double selectedDayIncome = 0;
  double selectedDayExpense = 0;
  double selectedDayTotal = 0;
  
  Map<String, double> expenseByCategory = {};
  Map<String, double> incomeByCategory = {};
  bool isLoadingChartData = false;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
    _selectedDay = _focusedDay;
    _loadChartData();
    _loadSelectedDayData(_selectedDay!);
  }

  // ✅ Load data for selected day
  Future<void> _loadSelectedDayData(DateTime day) async {
    if (userId == null) return;

    try {
      DateTime startOfDay = DateTime(day.year, day.month, day.day);
      DateTime endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      double dayIncome = 0;
      double dayExpense = 0;

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String type = data['type'] ?? '';
        double amount = (data['amount'] ?? 0).toDouble().abs();

        if (type == 'income') {
          dayIncome += amount;
        } else if (type == 'expense') {
          dayExpense += amount;
        }
      }

      setState(() {
        selectedDayIncome = dayIncome;
        selectedDayExpense = dayExpense;
        selectedDayTotal = dayIncome - dayExpense;
      });
    } catch (e) {
      print('Error loading day data: $e');
    }
  }

  Future<void> _loadChartData() async {
    if (userId == null) return;
    
    setState(() {
      isLoadingChartData = true;
    });

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
        String categoryName = data['category'] ?? 'Khác';
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
        String categoryName = data['category'] ?? 'Khác';
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
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
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
                      _buildBalanceCard(balance, totalIncome, totalExpense, isDark),
                      const SizedBox(height: 24),
                      
                      // ✅ CALENDAR (thay thế Period Selector)
                      _buildCalendar(isDark),
                      
                      const SizedBox(height: 20),
                      
                      // ✅ Selected Day Summary
                      _buildSelectedDaySummary(isDark),
                      
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            '${_formatCurrency(balance)}đ',
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
              ? '-${_formatCurrency(amount)}đ'
              : '+${_formatCurrency(amount)}đ',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ✅ CALENDAR WIDGET
  Widget _buildCalendar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: CalendarFormat.month,
        startingDayOfWeek: StartingDayOfWeek.monday,
        
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left,
            color: isDark ? Colors.white : Colors.black,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF00CED1).withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          todayTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
          
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF00CED1),
            shape: BoxShape.circle,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          
          defaultTextStyle: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          
          weekendTextStyle: TextStyle(
            color: isDark ? Colors.red[300] : Colors.red[600],
          ),
          
          outsideTextStyle: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
        ),
        
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          weekendStyle: TextStyle(
            color: isDark ? Colors.red[300] : Colors.red[600],
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          _loadSelectedDayData(selectedDay);
        },
        
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
      ),
    );
  }

  // ✅ SELECTED DAY SUMMARY
  Widget _buildSelectedDaySummary(bool isDark) {
    String dateText = _selectedDay != null
        ? '${_selectedDay!.day}/${_selectedDay!.month}/${_selectedDay!.year}'
        : 'Chọn ngày';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Chi tiêu ngày $dateText',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDaySummaryItem(
                'Income',
                selectedDayIncome,
                const Color(0xFF00CED1),
                isDark,
              ),
              Container(
                height: 40,
                width: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              _buildDaySummaryItem(
                'Expense',
                selectedDayExpense,
                Colors.red[600]!,
                isDark,
              ),
              Container(
                height: 40,
                width: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              _buildDaySummaryItem(
                'Total',
                selectedDayTotal,
                selectedDayTotal >= 0 ? Colors.green[600]! : Colors.red[600]!,
                isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaySummaryItem(String label, double amount, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${amount >= 0 ? '+' : ''}${_formatCurrency(amount.abs())}đ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
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
              if (chartType == 'bar')
                Row(
                  children: [
                    _buildLegend(const Color(0xFF00CED1), 'Thu'),
                    const SizedBox(width: 12),
                    _buildLegend(const Color(0xFFFF6B6B), 'Chi'),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 280,
            child: chartType == 'bar'
                ? CustomBarChartWidget(
                    totalIncome: totalIncome,
                    totalExpense: totalExpense,
                    isDark: isDark,
                  )
                : _buildPieChart(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(bool isDark) {
    return Column(
      children: [
        _buildPieChartTypeSelector(isDark),
        const SizedBox(height: 16),
        Expanded(
          child: isLoadingChartData
              ? const Center(child: CircularProgressIndicator())
              : CustomPieChartWidget(
                  categoryData: pieChartType == 'expense'
                      ? expenseByCategory
                      : incomeByCategory,
                  type: pieChartType,
                  isDark: isDark,
                ),
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
              color: const Color(0xFF00CED1).withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF00CED1).withOpacity(isDark ? 0.2 : 0.3),
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
                  '${_formatCurrency(totalIncome)}đ',
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
                  '${_formatCurrency(totalExpense)}đ',
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
              return _buildEmptyGoalsState(isDark);
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

  Widget _buildEmptyGoalsState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.flag_outlined,
            size: 48,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có mục tiêu nào',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm mục tiêu tiết kiệm để theo dõi tiến độ',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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