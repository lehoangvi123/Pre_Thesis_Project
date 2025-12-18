import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import './chart_service.dart';

/// Widget class for rendering charts
class ChartWidgets {
  
  /// Build Expense Pie Chart (Chi tiêu theo category)
  static Widget buildExpensePieChart({
    required Map<String, double> categoryData,
    required bool isDark,
  }) {
    if (categoryData.isEmpty) {
      return _buildEmptyChart('Chưa có dữ liệu chi tiêu', isDark);
    }

    double total = categoryData.values.reduce((a, b) => a + b);
    List<PieChartSectionData> sections = [];
    int index = 0;

    categoryData.forEach((category, amount) {
      Color color = ChartService.getCategoryColor(category, index);
      double percentage = (amount / total) * 100;

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
              ),
            ],
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
      index++;
    });

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 45,
              sections: sections,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegend(categoryData, isDark),
      ],
    );
  }

  /// Build Income Pie Chart (Thu nhập theo category)
  static Widget buildIncomePieChart({
    required Map<String, double> categoryData,
    required bool isDark,
  }) {
    if (categoryData.isEmpty) {
      return _buildEmptyChart('Chưa có dữ liệu thu nhập', isDark);
    }

    double total = categoryData.values.reduce((a, b) => a + b);
    List<PieChartSectionData> sections = [];
    int index = 0;

    categoryData.forEach((category, amount) {
      Color color = ChartService.getCategoryColor(category, index);
      double percentage = (amount / total) * 100;

      sections.add(
        PieChartSectionData(
          color: color,
          value: amount,
          title: percentage > 8 ? '${percentage.toStringAsFixed(0)}%' : '',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 2,
              ),
            ],
          ),
          titlePositionPercentageOffset: 0.6,
        ),
      );
      index++;
    });

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PieChart(
            PieChartData(
              sectionsSpace: 3,
              centerSpaceRadius: 45,
              sections: sections,
              borderData: FlBorderData(show: false),
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildLegend(categoryData, isDark),
      ],
    );
  }

  /// Build Legend for Pie Chart
  static Widget _buildLegend(Map<String, double> data, bool isDark) {
    List<Widget> legendItems = [];
    int index = 0;
    double total = data.values.reduce((a, b) => a + b);

    // Sort by amount descending
    var sortedEntries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var entry in sortedEntries) {
      String category = entry.key;
      double amount = entry.value;
      Color color = ChartService.getCategoryColor(category, index);
      double percentage = (amount / total) * 100;

      legendItems.add(
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Color indicator
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Icon
              Icon(
                ChartService.getCategoryIcon(category),
                size: 18,
                color: color,
              ),
              const SizedBox(width: 10),
              // Category name
              Expanded(
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Percentage
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Amount
              Text(
                ChartService.formatShortCurrency(amount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      );
      index++;
    }

    return Column(
      children: legendItems,
    );
  }

  /// Build empty chart state
  static Widget _buildEmptyChart(String message, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 64,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey[500] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thêm giao dịch để xem phân tích',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[600] : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Chart Type Selector (Income vs Expense)
  static Widget buildChartTypeSelector({
    required String selectedType,
    required Function(String) onTypeChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged('expense'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: selectedType == 'expense'
                      ? const LinearGradient(
                          colors: [Color(0xFFE91E63), Color(0xFFC2185B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedType == 'expense'
                      ? [
                          BoxShadow(
                            color: const Color(0xFFE91E63).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_down,
                      size: 18,
                      color: selectedType == 'expense'
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Chi tiêu',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selectedType == 'expense'
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selectedType == 'expense'
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: GestureDetector(
              onTap: () => onTypeChanged('income'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: selectedType == 'income'
                      ? const LinearGradient(
                          colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: selectedType == 'income'
                      ? [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.trending_up,
                      size: 18,
                      color: selectedType == 'income'
                          ? Colors.white
                          : (isDark ? Colors.grey[400] : Colors.grey[600]),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Thu nhập',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: selectedType == 'income'
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: selectedType == 'income'
                            ? Colors.white
                            : (isDark ? Colors.grey[400] : Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}