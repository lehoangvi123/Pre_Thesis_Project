// lib/view/Chart/income_expense_pie_chart.dart
// PIE CHART hiển thị tổng quan INCOME vs EXPENSE

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class IncomeExpensePieChart extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final bool isDark;

  const IncomeExpensePieChart({
    Key? key,
    required this.totalIncome,
    required this.totalExpense,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Nếu cả 2 đều = 0, hiển thị empty state
    if (totalIncome == 0 && totalExpense == 0) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // PIE CHART Ở TRÊN
        Expanded(
          child: _buildPieChart(),
        ),
        
        const SizedBox(height: 20),
        
        // LEGEND Ở DƯỚI
        _buildLegend(),
      ],
    );
  }

  Widget _buildPieChart() {
    double total = totalIncome + totalExpense;
    
    // Tính % cho từng loại
    double incomePercent = total > 0 ? (totalIncome / total) * 100 : 0;
    double expensePercent = total > 0 ? (totalExpense / total) * 100 : 0;

    List<PieChartSectionData> sections = [];

    // Chỉ thêm section nếu có giá trị > 0
    if (totalExpense > 0) {
      sections.add(
        PieChartSectionData(
          value: totalExpense,
          title: '${expensePercent.toStringAsFixed(0)}%',
          color: const Color(0xFFFF6B6B), // Red for expense
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    if (totalIncome > 0) {
      sections.add(
        PieChartSectionData(
          value: totalIncome,
          title: '${incomePercent.toStringAsFixed(0)}%',
          color: const Color(0xFF00CED1), // Cyan for income
          radius: 70,
          titleStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: 1.3,
        child: PieChart(
          PieChartData(
            sectionsSpace: 4,
            centerSpaceRadius: 50,
            sections: sections,
            borderData: FlBorderData(show: false),
            pieTouchData: PieTouchData(
              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                // Optional: Add touch interaction
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    double total = totalIncome + totalExpense;
    double incomePercent = total > 0 ? (totalIncome / total) * 100 : 0;
    double expensePercent = total > 0 ? (totalExpense / total) * 100 : 0;

    return Wrap(
      spacing: 20,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        // Expense Legend
        if (totalExpense > 0)
          _buildLegendItem(
            color: const Color(0xFFFF6B6B),
            label: 'Chi tiêu',
            percentage: expensePercent,
            amount: totalExpense,
          ),
        
        // Income Legend
        if (totalIncome > 0)
          _buildLegendItem(
            color: const Color(0xFF00CED1),
            label: 'Thu nhập',
            percentage: incomePercent,
            amount: totalIncome,
          ),
      ],
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required double percentage,
    required double amount,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Color indicator
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          
          // Percentage
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Thêm giao dịch để xem biểu đồ',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[600] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}₫';
  }
}