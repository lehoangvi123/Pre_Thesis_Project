import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './SavingGoals.dart';
import './SavingGoalsService.dart';
import './EditSavingGoalView.dart';

class SavingGoalDetailView extends StatefulWidget {
  final SavingGoal goal;

  const SavingGoalDetailView({Key? key, required this.goal}) : super(key: key);

  @override
  State<SavingGoalDetailView> createState() => _SavingGoalDetailViewState();
}

class _SavingGoalDetailViewState extends State<SavingGoalDetailView> {
  final SavingGoalService _goalService = SavingGoalService();
  final TextEditingController _amountController = TextEditingController();
  bool isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}₫';
  }

  String _formatInputCurrency(String value) {
    if (value.isEmpty) return '';
    value = value.replaceAll('.', '');
    return value.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // ── Sync unlinked "Tiết kiệm" transactions into this goal ─────────────────
  Future<void> _syncSavingsTransactions() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 1. Query unlinked savings transactions
    setState(() => isLoading = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('category', isEqualTo: 'Tiết kiệm')
          .get();

      final unlinked = snapshot.docs
          .where((doc) => !doc.data().containsKey('savingGoalId') ||
              doc['savingGoalId'] == null ||
              doc['savingGoalId'] == '')
          .toList();

      if (unlinked.isEmpty) {
        setState(() => isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Không có giao dịch tiết kiệm nào chưa được link'),
            backgroundColor: Colors.orange,
          ));
        }
        return;
      }

      double totalUnlinked = unlinked.fold(
          0.0, (sum, doc) => sum + (doc['amount'] as num).toDouble());

      setState(() => isLoading = false);

      // 2. Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) {
          return AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.sync_rounded,
                    color: Color(0xFF00CED1), size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                  child: Text('Đồng bộ tiết kiệm',
                      style: TextStyle(fontSize: 17))),
            ]),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                'Tìm thấy ${unlinked.length} giao dịch "Tiết kiệm" chưa được gán vào mục tiêu nào.',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF00CED1).withOpacity(0.3))),
                child: Column(children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Số giao dịch:',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600])),
                        Text('${unlinked.length} giao dịch',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)),
                      ]),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Tổng tiền:',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600])),
                        Text(_formatCurrency(totalUnlinked),
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00CED1))),
                      ]),
                  const SizedBox(height: 8),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Gán vào:',
                            style: TextStyle(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600])),
                        Expanded(
                          child: Text(
                            '"${widget.goal.title}"',
                            textAlign: TextAlign.end,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF8B5CF6)),
                          ),
                        ),
                      ]),
                ]),
              ),
            ]),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Huỷ',
                    style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600])),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CED1),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: const Text('Đồng bộ',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;

      // 3. Batch update: link all unlinked transactions to this goal
      setState(() => isLoading = true);
      final batch = FirebaseFirestore.instance.batch();
      final uid2 = FirebaseAuth.instance.currentUser!.uid;

      for (final doc in unlinked) {
        batch.update(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid2)
              .collection('transactions')
              .doc(doc.id),
          {'savingGoalId': widget.goal.id},
        );
      }
      await batch.commit();

      // 4. Add total to goal
      await _goalService.addAmountToGoal(widget.goal.id, totalUnlinked);

      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '✅ Đã cộng ${_formatCurrency(totalUnlinked)} vào "${widget.goal.title}"!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _showAddMoneyDialog(bool isDark) async {
    _amountController.clear();
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF00CED1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8)),
              child:
                  const Icon(Icons.add_circle, color: Color(0xFF00CED1)),
            ),
            const SizedBox(width: 12),
            Text('Thêm tiền vào mục tiêu',
                style: TextStyle(
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black)),
          ]),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Nhập số tiền muốn thêm:',
                style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                String formatted = _formatInputCurrency(value);
                _amountController.value = TextEditingValue(
                  text: formatted,
                  selection:
                      TextSelection.collapsed(offset: formatted.length),
                );
              },
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                hintText: '0',
                suffixText: '₫',
                suffixStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00CED1)),
                filled: true,
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildQuickAmountButton('100k', 100000, isDark),
                _buildQuickAmountButton('500k', 500000, isDark),
                _buildQuickAmountButton('1M', 1000000, isDark),
                _buildQuickAmountButton('5M', 5000000, isDark),
              ],
            ),
          ]),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Hủy',
                  style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ),
            ElevatedButton(
              onPressed: () async {
                String amountText =
                    _amountController.text.replaceAll('.', '');
                double? amount = double.tryParse(amountText);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Vui lòng nhập số tiền hợp lệ'),
                      backgroundColor: Colors.red));
                  return;
                }
                Navigator.pop(context);
                await _addMoney(amount);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00CED1),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Thêm',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickAmountButton(String label, double amount, bool isDark) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _amountController.text = _formatInputCurrency(amount.toStringAsFixed(0));
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF00CED1).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF00CED1).withOpacity(0.3)),
        ),
        child: Text(label,
            style: const TextStyle(
                color: Color(0xFF00CED1), fontWeight: FontWeight.w600)),
      ),
    );
  }

  Future<void> _addMoney(double amount) async {
    setState(() => isLoading = true);
    bool success = await _goalService.addAmountToGoal(widget.goal.id, amount);
    setState(() => isLoading = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success
            ? 'Đã thêm ${_formatCurrency(amount)} vào mục tiêu!'
            : 'Có lỗi xảy ra. Vui lòng thử lại!'),
        backgroundColor: success ? Colors.green : Colors.red,
      ));
    }
  }

  Future<void> _deleteGoal() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xóa mục tiêu?',
            style:
                TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: Text(
            'Bạn có chắc muốn xóa "${widget.goal.title}"? Hành động này không thể hoàn tác.',
            style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Xóa',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      setState(() => isLoading = true);
      bool success = await _goalService.deleteSavingGoal(widget.goal.id);
      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã xóa mục tiêu thành công'),
            backgroundColor: Colors.green));
      }
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Chi tiết mục tiêu',
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold)),
        actions: [
          // ── Sync button ────────────────────────────────────────────────
          IconButton(
            tooltip: 'Đồng bộ giao dịch tiết kiệm',
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00CED1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.sync_rounded,
                  color: Color(0xFF00CED1), size: 20),
            ),
            onPressed: isLoading ? null : _syncSavingsTransactions,
          ),
          IconButton(
            icon: Icon(Icons.edit,
                color: isDark ? Colors.white : Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Chức năng đang phát triển')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _deleteGoal,
          ),
        ],
      ),
      body: StreamBuilder<SavingGoal?>(
        stream: _goalService
            .goalsCollection()
            .doc(widget.goal.id)
            .snapshots()
            .map((doc) =>
                doc.exists ? SavingGoal.fromFirestore(doc) : null),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          SavingGoal? goal = snapshot.data;
          if (goal == null) {
            return const Center(child: Text('Mục tiêu không tồn tại'));
          }
          Color goalColor = Color(goal.color ?? 0xFF00CED1);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              _buildGoalHeader(goal, goalColor, isDark),
              const SizedBox(height: 16),

              // ── Sync hint banner ────────────────────────────────────────
              _buildSyncBanner(isDark),
              const SizedBox(height: 16),

              _buildProgressCard(goal, goalColor, isDark),
              const SizedBox(height: 24),
              _buildInfoCard(goal, isDark),
              const SizedBox(height: 24),
              _buildActionButtons(isDark),
            ]),
          );
        },
      ),
    );
  }

  // ── Sync hint banner ───────────────────────────────────────────────────────
  Widget _buildSyncBanner(bool isDark) {
    return GestureDetector(
      onTap: isLoading ? null : _syncSavingsTransactions,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF00CED1).withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: const Color(0xFF00CED1).withOpacity(0.3)),
        ),
        child: Row(children: [
          const Icon(Icons.sync_rounded,
              color: Color(0xFF00CED1), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Có giao dịch "Tiết kiệm" chưa được gán? Nhấn để đồng bộ vào mục tiêu này.',
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey[300] : Colors.grey[700]),
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF00CED1), size: 18),
        ]),
      ),
    );
  }

  Widget _buildGoalHeader(SavingGoal goal, Color goalColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
            colors: [goalColor, goalColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: goalColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(children: [
        Text(goal.icon ?? '🎯',
            style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text(goal.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white)),
        if (goal.description != null && goal.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(goal.description!,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9))),
        ],
      ]),
    );
  }

  Widget _buildProgressCard(
      SavingGoal goal, Color goalColor, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Tiến độ',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black)),
          Text('${goal.progress.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: goalColor)),
        ]),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
              value: goal.progress / 100,
              backgroundColor:
                  isDark ? Colors.grey[700] : Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(goalColor),
              minHeight: 12),
        ),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(
              child: _buildStatItem('Đã tiết kiệm',
                  _formatCurrency(goal.currentAmount),
                  Icons.account_balance_wallet, Colors.green, isDark)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildStatItem('Còn lại',
                  _formatCurrency(goal.remainingAmount),
                  Icons.flag, Colors.orange, isDark)),
        ]),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: goalColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.stars, color: goalColor, size: 20),
            const SizedBox(width: 8),
            Text('Mục tiêu: ${_formatCurrency(goal.targetAmount)}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: goalColor)),
          ]),
        ),
      ]),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon,
      Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 4),
        Text(value,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color)),
      ]),
    );
  }

  Widget _buildInfoCard(SavingGoal goal, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Thông tin',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black)),
        const SizedBox(height: 16),
        _buildInfoRow(Icons.calendar_today, 'Ngày tạo',
            '${goal.createdAt.day}/${goal.createdAt.month}/${goal.createdAt.year}',
            isDark),
        if (goal.targetDate != null) ...[
          const SizedBox(height: 12),
          _buildInfoRow(Icons.event, 'Ngày đích',
              '${goal.targetDate!.day}/${goal.targetDate!.month}/${goal.targetDate!.year}',
              isDark),
        ],
        const SizedBox(height: 12),
        _buildInfoRow(Icons.trending_up, 'Trạng thái',
            goal.isCompleted ? 'Đã hoàn thành' : 'Đang thực hiện', isDark,
            valueColor: goal.isCompleted ? Colors.green : Colors.orange),
      ]),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark,
      {Color? valueColor}) {
    return Row(children: [
      Icon(icon,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600]),
      const SizedBox(width: 12),
      Expanded(
          child: Text(label,
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600]))),
      Text(value,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color:
                  valueColor ?? (isDark ? Colors.white : Colors.black))),
    ]);
  }

  Widget _buildActionButtons(bool isDark) {
    return Column(children: [
      // Add money manually
      SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton.icon(
          onPressed: isLoading ? null : () => _showAddMoneyDialog(isDark),
          style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00CED1),
              disabledBackgroundColor: Colors.grey,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0),
          icon: const Icon(Icons.add_circle, color: Colors.white),
          label: const Text('Thêm tiền vào mục tiêu',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white)),
        ),
      ),
      const SizedBox(height: 12),
      // Sync button
      SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: isLoading ? null : _syncSavingsTransactions,
          style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF00CED1)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16))),
          icon: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF00CED1)))
              : const Icon(Icons.sync_rounded,
                  color: Color(0xFF00CED1), size: 20),
          label: const Text('Đồng bộ giao dịch tiết kiệm',
              style: TextStyle(
                  color: Color(0xFF00CED1), fontWeight: FontWeight.w600)),
        ),
      ),
    ]);
  }
}