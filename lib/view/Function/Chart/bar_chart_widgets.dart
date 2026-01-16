// lib/view/Chart/bar_chart_widget.dart
// SIMPLE 2-COLUMN CHART - Chỉ THU vs CHI

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CustomBarChartWidget extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final bool isDark;

  const CustomBarChartWidget({
    Key? key,
    required this.totalIncome,
    required this.totalExpense,
    required this.isDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get max value để tính maxY
    double maxValue = totalIncome > totalExpense ? totalIncome : totalExpense;
    
    // MaxY với buffer 10%
    double maxY = maxValue * 1.1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: isDark ? Colors.grey[800]! : Colors.white,
              tooltipBorder: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  _formatCurrency(rod.toY),
                  TextStyle(
                    color: rod.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                );
              },
            ),
          ),
          
          titlesData: FlTitlesData(
            show: true,
            
            // ✅ BOTTOM TITLES - Thu / Chi
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Thu nhập',
                        style: TextStyle(
                          color: const Color(0xFF00CED1),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  } else if (value == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Chi tiêu',
                        style: TextStyle(
                          color: const Color(0xFFFF6B6B),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            
            // ✅ LEFT TITLES - Amounts
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 65,
                interval: maxY / 5,
                getTitlesWidget: (value, meta) {
                  if (value < maxY * 0.01) {
                    return const SizedBox();
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Text(
                      _formatAxisLabel(value),
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  );
                },
              ),
            ),
            
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          
          // ✅ GRID LINES
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                strokeWidth: 1,
                dashArray: [5, 5],
              );
            },
          ),
          
          borderData: FlBorderData(
            show: true,
            border: Border(
              left: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
              bottom: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                width: 1,
              ),
            ),
          ),
          
          // ✅ CHỈ 2 CỘT
          barGroups: [
            // Cột 1: Thu nhập
            BarChartGroupData(
              x: 0,
              barRods: [
                BarChartRodData(
                  toY: totalIncome,
                  color: const Color(0xFF00CED1),
                  width: 50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
            // Cột 2: Chi tiêu
            BarChartGroupData(
              x: 1,
              barRods: [
                BarChartRodData(
                  toY: totalExpense,
                  color: const Color(0xFFFF6B6B),
                  width: 50,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Format for tooltips
  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K₫';
    }
    return '${amount.toStringAsFixed(0)}₫';
  }

  // Format for axis labels
  String _formatAxisLabel(double amount) {
    if (amount >= 1000000000) {
      double billions = amount / 1000000000;
      if (billions == billions.floor()) {
        return '${billions.toStringAsFixed(0)}B';
      }
      return '${billions.toStringAsFixed(1)}B';
    } else if (amount >= 1000000) {
      double millions = amount / 1000000;
      if (millions == millions.floor()) {
        return '${millions.toStringAsFixed(0)}M';
      }
      return '${millions.toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return '0';
  }
}