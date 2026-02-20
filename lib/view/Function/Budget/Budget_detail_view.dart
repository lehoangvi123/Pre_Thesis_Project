// lib/view/Function/Budget/Budget_detail_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BudgetDetailView extends StatefulWidget {
  final Map<String, dynamic> budget;
  final String budgetId;

  const BudgetDetailView({
    Key? key,
    required this.budget,
    required this.budgetId,
  }) : super(key: key);

  @override
  State<BudgetDetailView> createState() => _BudgetDetailViewState();
}

class _BudgetDetailViewState extends State<BudgetDetailView> {
  final NumberFormat _fmt = NumberFormat("#,##0", "vi_VN");
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late Map<String, dynamic> _budget;
  bool _isEditing = false;
  final _limitController = TextEditingController();
  final _spentController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _budget = Map<String, dynamic>.from(widget.budget);
    _limitController.text = (_budget['limitAmount'] ?? 0.0).toStringAsFixed(0);
  }

  @override
  void dispose() {
    _limitController.dispose();
    _spentController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _userId => _auth.currentUser?.uid ?? '';
  double get _limitAmount => (_budget['limitAmount'] ?? 0.0).toDouble();
  double get _spentAmount => (_budget['spentAmount'] ?? 0.0).toDouble();
  double get _remaining => _limitAmount - _spentAmount;
  double get _percentage => _limitAmount > 0 ? (_spentAmount / _limitAmount * 100) : 0.0;

  Color get _statusColor {
    if (_percentage >= 100) return Colors.red;
    if (_percentage >= 80) return Colors.deepOrange;
    if (_percentage >= 50) return Colors.orange;
    return Colors.green;
  }

  String get _statusText {
    if (_percentage >= 100) return 'Vượt mức';
    if (_percentage >= 80) return 'Nguy hiểm';
    if (_percentage >= 50) return 'Cảnh báo';
    return 'Tốt';
  }

  // ── Thêm số tiền đã chi ──────────────────────────────────────
  Future<void> _addSpentAmount() async {
    final amountText = _spentController.text.replaceAll(',', '').replaceAll('.', '');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      _showSnack('Vui lòng nhập số tiền hợp lệ', isError: true);
      return;
    }

    final note = _noteController.text.trim();
    final newSpent = _spentAmount + amount;

    try {
      // Cập nhật spentAmount trong budget
      await _firestore.collection('budgets').doc(widget.budgetId).update({
        'spentAmount': newSpent,
        'updatedAt': Timestamp.now(),
      });

      // Thêm transaction
      await _firestore.collection('transactions').add({
        'userId': _userId,
        'categoryId': _budget['categoryId'] ?? '',
        'categoryName': _budget['categoryName'] ?? '',
        'type': 'expense',
        'amount': amount,
        'title': note.isNotEmpty ? note : 'Chi tiêu ${_budget['categoryName']}',
        'note': note,
        'date': Timestamp.now(),
        'createdAt': Timestamp.now(),
        'fromBudget': true,
        'budgetId': widget.budgetId,
      });

      setState(() {
        _budget['spentAmount'] = newSpent;
        _spentController.clear();
        _noteController.clear();
      });

      if (mounted) Navigator.pop(context); // đóng bottom sheet
      _showSnack('✅ Đã thêm ${_fmt.format(amount)}đ vào chi tiêu!');
    } catch (e) {
      _showSnack('Lỗi: $e', isError: true);
    }
  }

  // ── Bottom sheet nhập tiền ────────────────────────────────────
  void _showAddSpentSheet() {
    _spentController.clear();
    _noteController.clear();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: StatefulBuilder(
            builder: (ctx, setSheet) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.add_shopping_cart, color: _statusColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nhập chi tiêu',
                            style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            )),
                        Text('Budget ${_budget['categoryName']}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[500])),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Còn lại
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Còn lại trong ngân sách:',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                      Text('${_fmt.format(_remaining)}đ',
                          style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold,
                            color: _statusColor,
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Input số tiền
                TextField(
                  controller: _spentController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  onChanged: (_) => setSheet(() {}),
                  decoration: InputDecoration(
                    labelText: 'Số tiền (đ)',
                    hintText: '0',
                    prefixIcon: const Icon(Icons.attach_money, color: Colors.teal),
                    suffixText: 'đ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Input ghi chú
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú (tùy chọn)',
                    hintText: 'VD: Ăn sáng, cafe, ...',
                    prefixIcon: const Icon(Icons.note_outlined, color: Colors.teal),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.teal, width: 2),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Nút xác nhận
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _addSpentAmount,
                    icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                    label: Text(
                      () {
                        final val = double.tryParse(
                            _spentController.text.replaceAll(',', '').replaceAll('.', ''));
                        return val != null && val > 0
                            ? 'Xác nhận -${_fmt.format(val)}đ'
                            : 'Xác nhận';
                      }(),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Lưu giới hạn mới ─────────────────────────────────────────
  Future<void> _saveLimit() async {
    final newLimit = double.tryParse(_limitController.text.replaceAll(',', ''));
    if (newLimit == null || newLimit <= 0) {
      _showSnack('Vui lòng nhập số tiền hợp lệ', isError: true);
      return;
    }
    try {
      await _firestore.collection('budgets').doc(widget.budgetId).update({
        'limitAmount': newLimit,
        'updatedAt': Timestamp.now(),
      });
      setState(() {
        _budget['limitAmount'] = newLimit;
        _isEditing = false;
      });
      _showSnack('✅ Đã cập nhật giới hạn ngân sách');
    } catch (e) {
      _showSnack('Lỗi: $e', isError: true);
    }
  }

  // ── Xóa ngân sách ─────────────────────────────────────────────
  Future<void> _deleteBudget() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xóa ngân sách?'),
        content: Text('Bạn có chắc muốn xóa "${_budget['categoryName']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await _firestore.collection('budgets').doc(widget.budgetId).delete();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Lỗi: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : Colors.teal,
      duration: const Duration(seconds: 2),
    ));
  }

  String _periodLabel(String p) {
    switch (p) {
      case 'BudgetPeriod.daily': return 'Hàng ngày';
      case 'BudgetPeriod.weekly': return 'Hàng tuần';
      case 'BudgetPeriod.monthly': return 'Hàng tháng';
      case 'BudgetPeriod.yearly': return 'Hàng năm';
      default: return 'Hàng tháng';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconCode = _budget['categoryIcon'] as int?;
    final IconData icon = iconCode != null
        ? IconData(iconCode, fontFamily: 'MaterialIcons')
        : Icons.wallet;
    final endDate = (_budget['endDate'] as Timestamp?)?.toDate();
    final startDate = (_budget['startDate'] as Timestamp?)?.toDate();
    final int daysLeft = endDate != null
        ? endDate.difference(DateTime.now()).inDays.clamp(0, 9999)
        : 0;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: Text('Budget ${_budget['categoryName'] ?? ''}'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
            onPressed: () => setState(() {
              _isEditing = !_isEditing;
              if (!_isEditing) {
                _limitController.text =
                    (_budget['limitAmount'] ?? 0.0).toStringAsFixed(0);
              }
            }),
          ),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteBudget),
        ],
      ),

      // ── FAB nhập chi tiêu ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddSpentSheet,
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Nhập chi tiêu', style: TextStyle(color: Colors.white)),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(icon, daysLeft),
            const SizedBox(height: 16),
            if (_isEditing) _buildEditSection(isDark),
            _buildStatsRow(isDark),
            const SizedBox(height: 16),
            _buildInfoCard(isDark, startDate, endDate),
            const SizedBox(height: 16),
            _buildTransactionHistory(isDark),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(IconData icon, int daysLeft) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_statusColor.withOpacity(0.8), _statusColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: _statusColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Budget ${_budget['categoryName'] ?? ''}',
                        style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
                    Text(_periodLabel(_budget['period'] ?? ''),
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: Text(_statusText,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Giới hạn ngân sách', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text('${_fmt.format(_limitAmount)}đ',
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: (_percentage / 100).clamp(0.0, 1.0),
              minHeight: 12,
              backgroundColor: Colors.white30,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_percentage.toStringAsFixed(1)}% đã dùng',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text('$daysLeft ngày còn lại',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.teal.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✏️ Chỉnh sửa giới hạn',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _limitController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Giới hạn mới (đ)',
              prefixIcon: const Icon(Icons.attach_money, color: Colors.teal),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Colors.teal, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveLimit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _statCard('Đã chi', '${_fmt.format(_spentAmount)}đ', _statusColor, isDark),
        const SizedBox(width: 12),
        _statCard('Còn lại', '${_fmt.format(_remaining)}đ',
            _remaining >= 0 ? Colors.teal : Colors.red, isDark),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, DateTime? startDate, DateTime? endDate) {
    final df = DateFormat('dd/MM/yyyy');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📋 Thông tin ngân sách',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const Divider(height: 20),
          _infoRow(Icons.category_outlined, 'Danh mục', _budget['categoryName'] ?? '-', isDark),
          _infoRow(Icons.repeat, 'Chu kỳ', _periodLabel(_budget['period'] ?? ''), isDark),
          if (startDate != null)
            _infoRow(Icons.calendar_today, 'Bắt đầu', df.format(startDate), isDark),
          if (endDate != null)
            _infoRow(Icons.event, 'Kết thúc', df.format(endDate), isDark),
          _infoRow(Icons.notifications_outlined, 'Cảnh báo tại',
              '${_budget['alertThreshold'] ?? 80}%', isDark),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.teal),
          const SizedBox(width: 10),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[500])),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTransactionHistory(bool isDark) {
    final categoryId = _budget['categoryId'] ?? '';
    final startDate = (_budget['startDate'] as Timestamp?)?.toDate();
    final endDate = (_budget['endDate'] as Timestamp?)?.toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('💳 Giao dịch liên quan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('transactions')
              .where('userId', isEqualTo: _userId)
              .where('categoryId', isEqualTo: categoryId)
              .where('type', isEqualTo: 'expense')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.teal));
            }

            final docs = snapshot.data?.docs ?? [];
            final filtered = docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final date = (data['date'] as Timestamp?)?.toDate();
              if (date == null) return false;
              if (startDate != null && date.isBefore(startDate)) return false;
              if (endDate != null && date.isAfter(endDate)) return false;
              return true;
            }).toList();

            // Sort mới nhất lên trên
            filtered.sort((a, b) {
              final aDate = ((a.data() as Map)['date'] as Timestamp).toDate();
              final bDate = ((b.data() as Map)['date'] as Timestamp).toDate();
              return bDate.compareTo(aDate);
            });

            if (filtered.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text('Chưa có giao dịch nào',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
                itemBuilder: (context, index) {
                  final data = filtered[index].data() as Map<String, dynamic>;
                  final amount = (data['amount'] ?? 0.0).toDouble();
                  final title = data['title'] ?? data['note'] ?? 'Giao dịch';
                  final date = (data['date'] as Timestamp?)?.toDate();
                  final df = DateFormat('dd/MM HH:mm');

                  return ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.arrow_downward, color: Colors.red, size: 18),
                    ),
                    title: Text(title,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: date != null
                        ? Text(df.format(date),
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]))
                        : null,
                    trailing: Text('-${_fmt.format(amount)}đ',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold, fontSize: 14)),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}