// lib/view/Chart/pie_chart_widget.dart
// PIE CHART với LEGEND Ở DƯỚI

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomPieChartWidget extends StatelessWidget {
  final Map<String, double> categoryData;
  final String type; // 'expense' or 'income'
  final bool isDark;

  const CustomPieChartWidget({
    Key? key,
    required this.categoryData,
    required this.type,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categoryData.isEmpty) {
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
    double total = categoryData.values.fold(0, (sum, value) => sum + value);
    var sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topCategories = sortedEntries.take(5).toList();

    List<Color> colors = _getColors();

    return Center(
      child: AspectRatio(
        aspectRatio: 1.3,
        child: PieChart(
          PieChartData(
            sectionsSpace: 3,
            centerSpaceRadius: 50,
            sections: topCategories.asMap().entries.map((entry) {
              int index = entry.key;
              var category = entry.value;
              double percentage = (category.value / total) * 100;

              return PieChartSectionData(
                value: category.value,
                title: '${percentage.toStringAsFixed(0)}%',
                color: colors[index % colors.length],
                radius: 60,
                titleStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    double total = categoryData.values.fold(0, (sum, value) => sum + value);
    var sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var topCategories = sortedEntries.take(5).toList();

    List<Color> colors = _getColors();

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: topCategories.asMap().entries.map((entry) {
        int index = entry.key;
        var category = entry.value;
        double percentage = (category.value / total) * 100;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Color dot
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: colors[index % colors.length],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              
              // Category name
              Text(
                category.key,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              
              // Percentage
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[500] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
        ],
      ),
    );
  }

  List<Color> _getColors() {
    if (type == 'expense') {
      return const [
        Color(0xFFFF6B6B), // Red
        Color(0xFFFFBE0B), // Yellow
        Color(0xFF4ECDC4), // Teal
        Color(0xFFFF006E), // Pink
        Color(0xFF8338EC), // Purple
      ];
    } else {
      return const [
        Color(0xFF00CED1), // Cyan
        Color(0xFF48D1CC), // Turquoise
        Color(0xFF00FA9A), // Spring Green
        Color(0xFF7FFFD4), // Aquamarine
        Color(0xFF40E0D0), // Turquoise
      ];
    }
  }
}