// lib/view/Budget/budget_detail_view.dart
// Budget Detail View - Chi tiết ngân sách

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './budget_model.dart';
import './budget_service.dart';
import './Create_budget_view.dart';

class BudgetDetailView extends StatefulWidget {
  final BudgetModel budget;

  const BudgetDetailView({Key? key, required this.budget}) : super(key: key);

  @override
  State<BudgetDetailView> createState() => _BudgetDetailViewState();
}

class _BudgetDetailViewState extends State<BudgetDetailView> {
  final BudgetService _budgetService = BudgetService();
  final NumberFormat _currencyFormat = NumberFormat("#,##0", "vi_VN");
  final NumberFormat _dateFormat = NumberFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.budget.categoryName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateBudgetView(
                    budgetToEdit: widget.budget,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _confirmDelete(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header Card
          _buildHeaderCard(isDark),
          const SizedBox(height: 16),

          // Stats Cards
          _buildStatsCards(isDark),
          const SizedBox(height: 16),

          // Progress Section
          _buildProgressSection(isDark),
          const SizedBox(height: 16),

          // Recent Transactions
          _buildRecentTransactions(isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.budget.statusColor,
            widget.budget.statusColor.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: widget.budget.statusColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            widget.budget.categoryIcon,
            size: 60,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            widget.budget.categoryName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.budget.statusText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_currencyFormat.format(widget.budget.spentAmount)}đ / ${_currencyFormat.format(widget.budget.limitAmount)}đ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.budget.percentage.toStringAsFixed(1)}% đã sử dụng',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Còn lại',
            '${_currencyFormat.format(widget.budget.remainingAmount)}đ',
            Icons.account_balance_wallet,
            Colors.green,
            isDark,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Còn',
            '${widget.budget.daysRemaining} ngày',
            Icons.calendar_today,
            Colors.blue,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ chi tiêu',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: widget.budget.percentage / 100,
              minHeight: 12,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                widget.budget.statusColor,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressLabel(
                'Đã chi',
                '${widget.budget.percentage.toStringAsFixed(1)}%',
                widget.budget.statusColor,
              ),
              _buildProgressLabel(
                'Còn lại',
                '${(100 - widget.budget.percentage).toStringAsFixed(1)}%',
                Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Chu kỳ',
            periodToString(widget.budget.period),
            isDark,
          ),
          _buildInfoRow(
            'Bắt đầu',
            _dateFormat.format(widget.budget.startDate),
            isDark,
          ),
          _buildInfoRow(
            'Kết thúc',
            _dateFormat.format(widget.budget.endDate),
            isDark,
          ),
          _buildInfoRow(
            'Cảnh báo ở',
            '${widget.budget.alertThreshold.toInt()}%',
            isDark,
          ),
          _buildInfoRow(
            'Tự động làm mới',
            widget.budget.autoReset ? 'Có' : 'Không',
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLabel(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Giao dịch gần đây',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('transactions')
                .where('categoryId', isEqualTo: widget.budget.categoryId)
                .where('type', isEqualTo: 'expense')
                .where('date',
                    isGreaterThanOrEqualTo:
                        Timestamp.fromDate(widget.budget.startDate))
                .where('date',
                    isLessThanOrEqualTo:
                        Timestamp.fromDate(widget.budget.endDate))
                .orderBy('date', descending: true)
                .limit(5)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Chưa có giao dịch',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ),
                );
              }

              return Column(
                children: snapshot.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final amount = (data['amount'] ?? 0.0) as num;
                  final note = data['note'] ?? 'Không có ghi chú';
                  final date = (data['date'] as Timestamp).toDate();

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: Colors.red.withOpacity(0.1),
                      child: const Icon(Icons.remove, color: Colors.red),
                    ),
                    title: Text(
                      note,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: Text(
                      _dateFormat.format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    trailing: Text(
                      '-${_currencyFormat.format(amount)}đ',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc muốn xóa ngân sách này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _budgetService.deleteBudget(widget.budget.id);
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa ngân sách')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e')),
          );
        }
      }
    }
  }
}