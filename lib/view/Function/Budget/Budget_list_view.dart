// lib/view/Function/Budget/Budget_list_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './budget_model.dart';
import './Create_budget_view.dart';
import './Budget_detail_view.dart';
import './Budget_detail_view.dart';

class BudgetListView extends StatefulWidget {
  const BudgetListView({Key? key}) : super(key: key);

  @override
  State<BudgetListView> createState() => _BudgetListViewState();
}

class _BudgetListViewState extends State<BudgetListView> {
  final NumberFormat _fmt = NumberFormat("#,##0", "vi_VN");
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // ── Load budgets trực tiếp từ Firestore (không dùng service) ──
  Stream<List<Map<String, dynamic>>> _getBudgets() {
    if (_userId.isEmpty) return Stream.value([]);

    return _firestore
        .collection('budgets')
        .where('userId', isEqualTo: _userId)
        .snapshots()
        .map((snapshot) {
      final now = DateTime.now();
      final list = snapshot.docs
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .where((data) {
            // Filter active budgets ở client
            final endDate = (data['endDate'] as Timestamp?)?.toDate();
            return endDate != null && endDate.isAfter(now);
          })
          .toList();

      // Sort theo endDate ở client
      list.sort((a, b) {
        final aDate = (a['endDate'] as Timestamp).toDate();
        final bDate = (b['endDate'] as Timestamp).toDate();
        return aDate.compareTo(bDate);
      });

      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Ngân sách'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _goToCreate,
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _getBudgets(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.teal),
            );
          }

          // Lỗi - hiện chi tiết
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.orange, size: 56),
                    const SizedBox(height: 16),
                    const Text(
                      'Không thể tải ngân sách',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                      child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ),
            );
          }

          final budgets = snapshot.data ?? [];

          // Trống
          if (budgets.isEmpty) return _buildEmptyState();

          // Tính tổng
          double totalBudget = 0;
          double totalSpent = 0;
          for (var b in budgets) {
            totalBudget += (b['limitAmount'] ?? 0.0) as double;
            totalSpent += (b['spentAmount'] ?? 0.0) as double;
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(totalBudget, totalSpent, budgets.length, isDark),
              const SizedBox(height: 20),
              Text(
                'Danh sách (${budgets.length})',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              ...budgets.map((b) => _buildCard(b, isDark)).toList(),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal,
        onPressed: _goToCreate,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _goToDetail(Map<String, dynamic> budget) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BudgetDetailView(
          budget: budget,
          budgetId: budget['id'] ?? '',
        ),
      ),
    ).then((_) => setState(() {}));
  }

  void _goToCreate() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateBudgetView()),
    ).then((_) => setState(() {}));
  }

  // ── Summary Card ──────────────────────────────────────────────
  Widget _buildSummaryCard(double totalBudget, double totalSpent, int count, bool isDark) {
    final usage = totalBudget > 0 ? (totalSpent / totalBudget * 100) : 0.0;
    final progressColor = usage >= 100 ? Colors.red : usage >= 80 ? Colors.orange : Colors.white;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal[400]!, Colors.teal[700]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tổng quan ngân sách',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Text('$count ngân sách', style: const TextStyle(color: Colors.white, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sumItem('Tổng ngân sách', '${_fmt.format(totalBudget)}đ'),
              _sumItem('Đã chi', '${_fmt.format(totalSpent)}đ'),
              _sumItem('Còn lại', '${_fmt.format(totalBudget - totalSpent)}đ'),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (usage / 100).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white30,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 6),
          Text('Sử dụng: ${usage.toStringAsFixed(1)}%',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _sumItem(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 3),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      );

  // ── Budget Card ───────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> data, bool isDark) {
    final String categoryName = data['categoryName'] ?? 'Không rõ';
    final double limitAmount = (data['limitAmount'] ?? 0.0).toDouble();
    final double spentAmount = (data['spentAmount'] ?? 0.0).toDouble();
    final double remaining = limitAmount - spentAmount;
    final double percentage = limitAmount > 0 ? (spentAmount / limitAmount * 100) : 0.0;
    final String period = _periodLabel(data['period'] ?? '');

    // Ngày còn lại
    final endDate = (data['endDate'] as Timestamp?)?.toDate();
    final int daysLeft = endDate != null
        ? endDate.difference(DateTime.now()).inDays.clamp(0, 9999)
        : 0;

    // Icon
    final iconCode = data['categoryIcon'] as int?;
    final IconData icon = iconCode != null
        ? IconData(iconCode, fontFamily: 'MaterialIcons')
        : Icons.wallet;

    // Màu theo trạng thái
    final Color statusColor = percentage >= 100
        ? Colors.red
        : percentage >= 80
            ? Colors.deepOrange
            : percentage >= 50
                ? Colors.orange
                : Colors.green;

    final String statusText = percentage >= 100
        ? 'Vượt mức'
        : percentage >= 80
            ? 'Nguy hiểm'
            : percentage >= 50
                ? 'Cảnh báo'
                : 'Tốt';

    return GestureDetector(
      onTap: () => _goToDetail(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: statusColor, width: 4)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: statusColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Budget $categoryName',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          period,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText,
                      style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Số tiền
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _amountItem('Giới hạn', '${_fmt.format(limitAmount)}đ',
                      isDark ? Colors.white : Colors.black87, isDark),
                  _amountItem('Đã chi', '${_fmt.format(spentAmount)}đ', statusColor, isDark),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),

              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                ),
              ),

              const SizedBox(height: 8),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(children: [
                    Icon(Icons.savings_outlined, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('Còn lại: ${_fmt.format(remaining)}đ',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ]),
                  Row(children: [
                    Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text('$daysLeft ngày còn lại',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ]),
                ],
              ),

              // Cảnh báo
              if (percentage >= 80) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        percentage >= 100 ? Icons.warning_rounded : Icons.info_outline,
                        size: 14,
                        color: statusColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        percentage >= 100
                            ? '⚠️ Đã vượt ngân sách ${(percentage - 100).toStringAsFixed(0)}%!'
                            : '⚡ Đã dùng ${percentage.toStringAsFixed(0)}% ngân sách',
                        style: TextStyle(fontSize: 12, color: statusColor, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _amountItem(String label, String value, Color valueColor, bool isDark) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      );

  String _periodLabel(String period) {
    switch (period) {
      case 'BudgetPeriod.daily': return 'Hàng ngày';
      case 'BudgetPeriod.weekly': return 'Hàng tuần';
      case 'BudgetPeriod.monthly': return 'Hàng tháng';
      case 'BudgetPeriod.yearly': return 'Hàng năm';
      default: return 'Hàng tháng';
    }
  }

  // ── Empty State ───────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Chưa có ngân sách',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('Tạo ngân sách để kiểm soát chi tiêu',
              style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _goToCreate,
            icon: const Icon(Icons.add),
            label: const Text('Tạo ngân sách'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}