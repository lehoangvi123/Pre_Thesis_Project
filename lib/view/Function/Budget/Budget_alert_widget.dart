// lib/view/Budget/budget_alert_widget.dart
// Budget Alert Widget - Cảnh báo ngân sách khi thêm giao dịch

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './Budget_service.dart';

class BudgetAlertWidget {
  final BudgetService _budgetService = BudgetService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "vi_VN");

  // Kiểm tra budget trước khi thêm transaction
  Future<bool> checkAndShowAlert(
    BuildContext context,
    String categoryId,
    double expenseAmount,
  ) async {
    final status = await _budgetService.checkBudgetStatus(
      categoryId,
      expenseAmount,
    );

    if (!status['hasBudget']) {
      return true; // Không có budget, cho phép thêm
    }

    final budget = status['budget'];
    final newPercentage = status['newPercentage'];
    final exceeded = status['exceeded'];
    final warning = status['warning'];
    final remainingAmount = status['remainingAmount'];

    // Nếu không vượt ngưỡng cảnh báo, cho phép thêm
    if (!warning && !exceeded) {
      return true;
    }

    // Hiển thị dialog cảnh báo
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => _buildAlertDialog(
            context,
            budget.categoryName,
            budget.limitAmount,
            budget.spentAmount,
            expenseAmount,
            newPercentage,
            remainingAmount,
            exceeded,
          ),
        ) ??
        false;
  }

  Widget _buildAlertDialog(
    BuildContext context,
    String categoryName,
    double limitAmount,
    double currentSpent,
    double newExpense,
    double newPercentage,
    double remainingAmount,
    bool exceeded,
  ) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            exceeded ? Icons.error : Icons.warning,
            color: exceeded ? Colors.red : Colors.orange,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              exceeded ? 'Vượt ngân sách!' : 'Cảnh báo ngân sách',
              style: TextStyle(
                color: exceeded ? Colors.red : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category
            Text(
              'Danh mục: $categoryName',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Current Status
            _buildInfoRow(
              'Ngân sách:',
              '${_currencyFormat.format(limitAmount)}đ',
            ),
            _buildInfoRow(
              'Đã chi:',
              '${_currencyFormat.format(currentSpent)}đ',
            ),
            _buildInfoRow(
              'Chi tiêu này:',
              '${_currencyFormat.format(newExpense)}đ',
              color: Colors.orange,
            ),
            const Divider(height: 24),

            // New Status
            _buildInfoRow(
              'Tổng sau khi chi:',
              '${_currencyFormat.format(currentSpent + newExpense)}đ',
              color: exceeded ? Colors.red : Colors.orange,
              bold: true,
            ),
            _buildInfoRow(
              'Tỷ lệ:',
              '${newPercentage.toStringAsFixed(1)}%',
              color: exceeded ? Colors.red : Colors.orange,
              bold: true,
            ),

            if (!exceeded)
              _buildInfoRow(
                'Còn lại:',
                '${_currencyFormat.format(remainingAmount)}đ',
                color: Colors.green,
              ),

            if (exceeded)
              _buildInfoRow(
                'Vượt mức:',
                '${_currencyFormat.format(-remainingAmount)}đ',
                color: Colors.red,
                bold: true,
              ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: newPercentage > 100 ? 1.0 : newPercentage / 100,
                minHeight: 12,
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  exceeded ? Colors.red : Colors.orange,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Warning Message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: exceeded
                    ? Colors.red.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    exceeded ? Icons.error : Icons.info,
                    color: exceeded ? Colors.red : Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      exceeded
                          ? 'Chi tiêu này sẽ vượt ngân sách đã đặt!'
                          : 'Chi tiêu này sẽ làm bạn gần hết ngân sách.',
                      style: TextStyle(
                        fontSize: 12,
                        color: exceeded ? Colors.red[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: exceeded ? Colors.red : Colors.orange,
          ),
          child: Text(exceeded ? 'Vẫn chi tiêu' : 'Tiếp tục'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Show simple notification (không block user)
  void showBudgetNotification(
    BuildContext context,
    String categoryName,
    double percentage,
    bool exceeded,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              exceeded ? Icons.error : Icons.warning,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                exceeded
                    ? 'Đã vượt ngân sách $categoryName!'
                    : 'Ngân sách $categoryName đã dùng ${percentage.toStringAsFixed(0)}%',
              ),
            ),
          ],
        ),
        backgroundColor: exceeded ? Colors.red : Colors.orange,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () {
            // Navigate to budget detail
          },
        ),
      ),
    );
  }
}