// lib/view/Function/HomeQuickAddExpense.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// ── Thousand separator formatter ──────────────────────
class _ThousandsSeparator extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    final digits = newValue.text.replaceAll('.', '');
    final formatted = digits.replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class QuickAddExpenseSheet extends StatefulWidget {
  final String   category;
  final double   budgetLimit;
  final double   alreadySpent; // ← thêm: số đã chi trong tháng
  final bool     isDark;
  final VoidCallback? onSaved;

  const QuickAddExpenseSheet({
    Key? key,
    required this.category,
    required this.budgetLimit,
    this.alreadySpent = 0,
    required this.isDark,
    this.onSaved,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required String   category,
    required double   budgetLimit,
    double            alreadySpent = 0,
    required bool     isDark,
    VoidCallback?     onSaved,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickAddExpenseSheet(
        category:     category,
        budgetLimit:  budgetLimit,
        alreadySpent: alreadySpent,
        isDark:       isDark,
        onSaved:      onSaved,
      ),
    );
  }

  @override
  State<QuickAddExpenseSheet> createState() => _QuickAddExpenseSheetState();
}

class _QuickAddExpenseSheetState extends State<QuickAddExpenseSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl   = TextEditingController();
  bool  _isSaving        = false;
  bool  _warningShown    = false; // tránh show dialog liên tục khi gõ tiếp
  String? _lastWarningStatus; // 'near' | 'over' — trạng thái đã warn

  static const _categoryEmojis = {
    'Ăn uống':            '🍜',
    'Di chuyển':           '🚗',
    'Nhà ở':              '🏠',
    'Hóa đơn tiện ích':   '💡',
    'Mua sắm cá nhân':    '🛍️',
    'Giải trí & xã hội':  '🎬',
    'Tiết kiệm':          '💰',
    'Đầu tư & học tập':   '📚',
    'Quỹ dự phòng':       '🛡️',
    'Sức khoẻ':           '💊',
    'Trả nợ hàng tháng':  '📋',
    'Chi phí gia đình':   '👨‍👩‍👧',
  };

  String get _emoji => _categoryEmojis[widget.category] ?? '💸';

  double get _enteredAmount =>
      double.tryParse(_amountCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;

  // Tổng sau khi thêm = đã chi + sắp thêm
  double get _totalAfter => widget.alreadySpent + _enteredAmount;

  bool get _isOverBudget =>
      widget.budgetLimit > 0 && _enteredAmount > widget.budgetLimit;

  String _fmt(double amount) =>
      '${amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';

  // ── Kiểm tra ngưỡng ──────────────────────────────────
  String? _checkBudgetStatus() {
    if (widget.budgetLimit <= 0) return null;
    final ratio = _totalAfter / widget.budgetLimit;
    if (ratio > 1.0) return 'over';
    if (ratio >= 0.8) return 'near';
    return null;
  }

  // ── Realtime warning khi gõ số tiền ──────────────────
  void _onAmountChanged(void Function(void Function()) setSheetState) {
    setSheetState(() {}); // rebuild preview

    final status = _checkBudgetStatus();
    if (status == null) {
      // Reset khi user xoá xuống dưới ngưỡng
      _warningShown = false;
      _lastWarningStatus = null;
      return;
    }
    // Chỉ show nếu status thay đổi (near→over hoặc chưa show lần nào)
    if (_warningShown && _lastWarningStatus == status) return;
    _warningShown = true;
    _lastWarningStatus = status;

    // Delay nhỏ để tránh dialog bị gọi giữa chừng khi user đang gõ
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      // Kiểm tra lại sau delay — user có thể đã xoá số
      if (_checkBudgetStatus() != status) return;
      _showBudgetWarningDialog(status);
    });
  }

  Future<void> _save() async {
    final amount = _enteredAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vui lòng nhập số tiền'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final note  = _noteCtrl.text.trim();
      final title = note.isEmpty ? widget.category : note;

      await FirebaseFirestore.instance
          .collection('users').doc(uid).collection('transactions').add({
        'type':         'expense',
        'amount':       amount,
        'category':     widget.category,
        'categoryName': widget.category,
        'title':        title,
        'note':         title,
        'date':         Timestamp.fromDate(DateTime.now()),
        'createdAt':    Timestamp.now(),
      });

      await FirebaseFirestore.instance.collection('users').doc(uid).update({
        'balance':      FieldValue.increment(-amount),
        'totalExpense': FieldValue.increment(amount),
      });

      if (mounted) {
        Navigator.pop(context);
        widget.onSaved?.call();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            Text(_emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text('Đã thêm ${_fmt(amount)} vào ${widget.category}'),
          ]),
          backgroundColor: Colors.red[500],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(12),
        ));
      }
    } catch (e) {
      debugPrint('QuickAddExpense error: $e');
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Dialog cảnh báo ngân sách ─────────────────────────
  Future<bool> _showBudgetWarningDialog(String status) async {
    final isDark    = widget.isDark;
    final isOver    = status == 'over';
    final overAmt   = _totalAfter - widget.budgetLimit;
    final usedPct   = (_totalAfter / widget.budgetLimit * 100).toStringAsFixed(0);

    final Color accentColor = isOver ? Colors.red : Colors.orange;
    final String icon       = isOver ? '🚨' : '⚠️';
    final String title      = isOver ? 'Vượt ngân sách!' : 'Sắp đạt giới hạn!';
    final String body;

    if (isOver) {
      body = 'Sau khi thêm ${_fmt(_enteredAmount)}, danh mục '
          '"${widget.category}" sẽ vượt ${_fmt(overAmt)} so với kế hoạch '
          '(${_fmt(widget.budgetLimit)}/tháng).';
    } else {
      final remainAfter = widget.budgetLimit - _totalAfter;
      body = 'Sau khi thêm ${_fmt(_enteredAmount)}, bạn đã dùng $usedPct% '
          'ngân sách "${widget.category}". Còn lại ${_fmt(remainAfter)}.';
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          // Icon lớn
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(icon,
                style: const TextStyle(fontSize: 30))),
          ),
          const SizedBox(height: 14),

          // Tiêu đề
          Text(title, style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.bold,
              color: accentColor)),
          const SizedBox(height: 10),

          // Mô tả
          Text(body, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5,
                  color: isDark ? Colors.grey[300] : Colors.grey[700])),
          const SizedBox(height: 14),

          // Progress bar trực quan
          if (widget.budgetLimit > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_totalAfter / widget.budgetLimit).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation(accentColor),
              ),
            ),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('0đ', style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              Text(
                isOver
                    ? '${_fmt(_totalAfter)} / ${_fmt(widget.budgetLimit)}'
                    : '$usedPct% đã dùng',
                style: TextStyle(fontSize: 11,
                    fontWeight: FontWeight.w600, color: accentColor),
              ),
              Text(_fmt(widget.budgetLimit),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500])),
            ]),
            const SizedBox(height: 16),
          ],
        ]),
        actions: [
          // Xem lại
          SizedBox(width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context, false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Xem lại',
                  style: TextStyle(color: accentColor,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          const SizedBox(height: 8),
          // Vẫn lưu
          SizedBox(width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                isOver ? 'Vẫn lưu khoản này' : 'Vẫn lưu',
                style: const TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
        top: 20, left: 20, right: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),

            // ── Header ──────────────────────────────────
            Row(children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(child: Text(_emoji,
                    style: const TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Thêm Chi tiêu',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(widget.category,
                      style: TextStyle(fontSize: 12,
                          color: Colors.red[600], fontWeight: FontWeight.w600)),
                ),
              ])),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.grey[200], shape: BoxShape.circle),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: Colors.grey[700]),
                ),
              ),
            ]),

            const SizedBox(height: 16),

            // ── Giới hạn ngân sách ──────────────────────
            if (widget.budgetLimit > 0)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.orange[600], size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    widget.alreadySpent > 0
                        ? 'Đã chi: ${_fmt(widget.alreadySpent)} / ${_fmt(widget.budgetLimit)} tháng này'
                        : 'Ngân sách: ${_fmt(widget.budgetLimit)} / tháng',
                    style: TextStyle(fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w500),
                  )),
                ]),
              ),

            const SizedBox(height: 14),

            // ── Input số tiền ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOverBudget
                      ? Colors.red
                      : Colors.red.withOpacity(0.2),
                  width: _isOverBudget ? 1.5 : 1,
                ),
              ),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Số tiền',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[500])),
                const SizedBox(height: 6),
                Row(crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                  Text('₫', style: TextStyle(fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[600])),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _ThousandsSeparator(),
                    ],
                    onChanged: (_) => _onAmountChanged(setSheetState),
                    style: TextStyle(fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                    decoration: const InputDecoration(
                      hintText: '0',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  )),
                ]),



                // Cảnh báo inline khi gõ
                if (_isOverBudget) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.warning_rounded,
                        color: Colors.red, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      'Vượt ngân sách ${_fmt(widget.budgetLimit)}!',
                      style: TextStyle(
                          fontSize: 11, color: Colors.red[600]),
                    ),
                  ]),
                ],
              ]),
            ),

            const SizedBox(height: 12),

            // ── Ghi chú ──────────────────────────────────
            TextField(
              controller: _noteCtrl,
              style: TextStyle(fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Mô tả (tuỳ chọn)...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                prefixIcon: Icon(Icons.edit_note_rounded,
                    color: Colors.grey[400]),
                filled: true,
                fillColor: isDark
                    ? Colors.grey[800] : Colors.grey[50],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Colors.red[400]!, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),

            const SizedBox(height: 20),

            // ── Nút lưu ──────────────────────────────────
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[500],
                  disabledBackgroundColor: Colors.grey[300],
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Lưu Chi tiêu',
                        style: TextStyle(color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}