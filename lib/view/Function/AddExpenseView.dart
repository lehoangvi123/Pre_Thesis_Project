import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import './SavingGoals.dart';
import './SavingGoalsService.dart';

// ─── Thousand separator formatter ────────────────────────────────────────────
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String newText = newValue.text.replaceAll('.', '');
    String formatted = _formatWithDots(newText);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDots(String value) {
    if (value.isEmpty) return '';
    String reversed = value.split('').reversed.join('');
    String result = '';
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) result += '.';
      result += reversed[i];
    }
    return result.split('').reversed.join('');
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class AddExpenseView extends StatefulWidget {
  final String? initialType;
  final String? categoryName;
  final IconData? categoryIcon;
  final Color? categoryColor;
  final bool hideToggle;

  const AddExpenseView({
    Key? key,
    this.initialType,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
    this.hideToggle = false,
  }) : super(key: key);

  @override
  State<AddExpenseView> createState() => _AddExpenseViewState();
}

class _AddExpenseViewState extends State<AddExpenseView> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _titleController = TextEditingController();
  final _noteController = TextEditingController();

  String transactionType = 'expense';
  String? selectedCategory;
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;

  // ── Saving goal selection ──
  SavingGoal? _selectedGoal;
  List<SavingGoal> _savingGoals = [];
  bool _loadingGoals = false;

  static const _savingsCategoryName = 'Tiết kiệm';

  bool get _isSavingsSelected => selectedCategory == _savingsCategoryName;

  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Ăn uống',         'icon': Icons.restaurant},
    {'name': 'Di chuyển',       'icon': Icons.directions_car},
    {'name': 'Nhà ở',           'icon': Icons.home},
    {'name': 'Sức khoẻ',        'icon': Icons.local_hospital},
    {'name': 'Mua sắm cá nhân', 'icon': Icons.shopping_bag},
    {'name': 'Giải trí & xã hội','icon': Icons.movie},
    {'name': 'Hoa đơn tiện ích','icon': Icons.receipt},
    {'name': 'Giáo dục',        'icon': Icons.school},
    {'name': 'Tiết kiệm',       'icon': Icons.savings},
    {'name': 'Đầu tư & học tập','icon': Icons.trending_up},
    {'name': 'Quỹ dự phòng',    'icon': Icons.security},
    {'name': 'Chi phí gia đình','icon': Icons.family_restroom},
    {'name': 'Chi phí con cái', 'icon': Icons.child_care},
    {'name': 'Khác',            'icon': Icons.more_horiz},
  ];

  final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Lương',     'icon': Icons.attach_money},
    {'name': 'Kinh doanh','icon': Icons.business},
    {'name': 'Đầu tư',   'icon': Icons.trending_up},
    {'name': 'Quà tặng', 'icon': Icons.card_giftcard},
    {'name': 'Khác',     'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    transactionType = widget.initialType ?? 'expense';
    if (widget.categoryName != null) {
      final incomeNames = ['Lương', 'Kinh doanh', 'Đầu tư', 'Quà tặng', 'Salary',
          'Business', 'Investment', 'Gift', 'Freelance'];
      transactionType =
          incomeNames.contains(widget.categoryName) ? 'income' : 'expense';
      selectedCategory = widget.categoryName;
      if (selectedCategory == _savingsCategoryName) _loadSavingGoals();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ── Load saving goals from Firestore ──────────────────────────────────────
  Future<void> _loadSavingGoals() async {
    setState(() => _loadingGoals = true);
    try {
      final service = SavingGoalService();
      final goals = await service.getSavingGoalsStream().first;
      setState(() {
        _savingGoals = goals.where((g) => !g.isCompleted).toList();
        _loadingGoals = false;
      });
    } catch (e) {
      setState(() => _loadingGoals = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  double _parseAmount(String formatted) {
    String cleaned = formatted.replaceAll('.', '');
    return double.tryParse(cleaned) ?? 0;
  }

  String _formatCurrency(double amount) {
    final f = NumberFormat('#,###', 'vi_VN');
    return '${f.format(amount)}₫';
  }

  Future<bool> _validateBalance(double amount) async {
    if (transactionType != 'expense') return true;
    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users').doc(uid).get();
      var data = doc.data() as Map<String, dynamic>? ?? {};
      double balance = (data['balance'] ?? 0).toDouble();
      if (amount > balance) {
        _showInsufficientFundsDialog(balance, amount);
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Save transaction + optionally update saving goal ─────────────────────
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedCategory == null) {
      _showErrorSnackBar('Vui lòng chọn danh mục');
      return;
    }
    if (_isSavingsSelected && _selectedGoal == null) {
      _showErrorSnackBar('Vui lòng chọn mục tiêu tiết kiệm');
      return;
    }
    if (isLoading) return;

    double amount = _parseAmount(_amountController.text.trim()).abs();
    bool canProceed = await _validateBalance(amount);
    if (!canProceed) return;

    setState(() => isLoading = true);

    try {
      String uid = FirebaseAuth.instance.currentUser!.uid;
      String txId = const Uuid().v4();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        DocumentSnapshot userDoc = await tx.get(
            FirebaseFirestore.instance.collection('users').doc(uid));
        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        double income  = (userData['totalIncome'] ?? 0).toDouble();
        double expense = (userData['totalExpense'] ?? 0).toDouble();

        if (transactionType == 'income') {
          income += amount;
        } else {
          expense += amount;
        }

        // Save transaction
        tx.set(
          FirebaseFirestore.instance
              .collection('users').doc(uid)
              .collection('transactions').doc(txId),
          {
            'id': txId,
            'type': transactionType,
            'isIncome': transactionType == 'income',
            'amount': amount,
            'category': selectedCategory,
            'title': _titleController.text.trim(),
            'note': _noteController.text.trim(),
            'date': Timestamp.fromDate(selectedDate),
            'createdAt': FieldValue.serverTimestamp(),
            // Link to saving goal if applicable
            if (_isSavingsSelected && _selectedGoal != null)
              'savingGoalId': _selectedGoal!.id,
          },
        );

        // Update user balance
        tx.update(
          FirebaseFirestore.instance.collection('users').doc(uid),
          {
            'balance': income - expense,
            'totalIncome': income,
            'totalExpense': expense,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      // ── Cộng tiền vào saving goal (ngoài transaction vì cần doc riêng) ──
      if (_isSavingsSelected && _selectedGoal != null) {
        final service = SavingGoalService();
        await service.addAmountToGoal(_selectedGoal!.id, amount);
      }

      if (mounted) {
        _showSuccessSnackBar(
          _isSavingsSelected && _selectedGoal != null
              ? '✅ Đã tiết kiệm ${_formatCurrency(amount)} vào "${_selectedGoal!.title}"!'
              : 'Đã lưu giao dịch!',
        );
        await Future.delayed(const Duration(milliseconds: 400));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar('Lỗi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────

  void _showErrorSnackBar(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));

  void _showSuccessSnackBar(String msg) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));

  void _showInsufficientFundsDialog(double balance, double amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.warning_rounded, color: Colors.red, size: 28),
          ),
          const SizedBox(width: 12),
          const Text('Không đủ tiền'),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3))),
            child: Column(children: [
              _dialogRow('Số dư hiện tại:', _formatCurrency(balance), Colors.green),
              const SizedBox(height: 8),
              _dialogRow('Số tiền muốn chi:', _formatCurrency(amount), Colors.red),
              const Divider(height: 24),
              _dialogRow('Thiếu:', _formatCurrency(amount - balance), Colors.red),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
        ],
      ),
    );
  }

  Widget _dialogRow(String label, String value, Color valueColor) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
      Text(value,
          style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: valueColor)),
    ]);
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF00CED1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          transactionType == 'income' ? 'Thêm Thu nhập' : 'Thêm Chi tiêu',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(children: [
        // Toggle income / expense
        if (!widget.hideToggle && widget.categoryName == null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(children: [
              _toggleBtn('Thu nhập', 'income', isDark),
              const SizedBox(width: 12),
              _toggleBtn('Chi tiêu', 'expense', isDark),
            ]),
          ),

        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Date ──────────────────────────────────────────────
                    _label('Ngày', isDark),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _selectDate,
                      child: _fieldBox(
                        isDark,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(selectedDate),
                                style: TextStyle(
                                    fontSize: 16,
                                    color: isDark ? Colors.white : Colors.black),
                              ),
                              Icon(Icons.calendar_today,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600]),
                            ]),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Category ──────────────────────────────────────────
                    _label('Danh mục', isDark),
                    const SizedBox(height: 8),
                    widget.categoryName == null
                        ? _categoryDropdown(isDark)
                        : _fixedCategory(isDark),
                    const SizedBox(height: 20),

                    // ── Saving goal picker (chỉ hiện khi chọn Tiết kiệm) ─
                    if (_isSavingsSelected) ...[
                      _label('Chọn mục tiêu tiết kiệm', isDark),
                      const SizedBox(height: 8),
                      _savingGoalPicker(isDark),
                      const SizedBox(height: 20),
                    ],

                    // ── Amount ────────────────────────────────────────────
                    _label('Số tiền', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                        prefixText: 'đ ',
                        prefixStyle: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF00CED1)),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Nhập số tiền';
                        if (_parseAmount(v) <= 0) return 'Số tiền không hợp lệ';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // ── Title ─────────────────────────────────────────────
                    _label(transactionType == 'income'
                        ? 'Tên khoản thu'
                        : 'Tên khoản chi', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: _isSavingsSelected
                            ? 'VD: Tiết kiệm tháng 4'
                            : 'VD: Ăn trưa',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'Nhập tên giao dịch' : null,
                    ),
                    const SizedBox(height: 20),

                    // ── Note ──────────────────────────────────────────────
                    _label('Ghi chú (tuỳ chọn)', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Thêm ghi chú...',
                        hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400]),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // ── Save button ───────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isSavingsSelected
                              ? const Color(0xFFFF9800)
                              : const Color(0xFF00CED1),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isSavingsSelected
                                        ? Icons.savings_rounded
                                        : Icons.check_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _isSavingsSelected
                                        ? 'Tiết kiệm ngay'
                                        : 'Lưu giao dịch',
                                    style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  // ── Saving goal picker widget ─────────────────────────────────────────────
  Widget _savingGoalPicker(bool isDark) {
    if (_loadingGoals) {
      return _fieldBox(isDark,
          child: const Center(
              child: CircularProgressIndicator(color: Color(0xFF00CED1))));
    }

    if (_savingGoals.isEmpty) {
      return _fieldBox(isDark,
          child: Row(children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text('Chưa có mục tiêu nào. Tạo ở mục Plan trước nhé!',
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ),
          ]));
    }

    return Column(
      children: _savingGoals.map((goal) {
        final isSelected = _selectedGoal?.id == goal.id;
        final goalColor = Color(goal.color ?? 0xFF00CED1);
        return GestureDetector(
          onTap: () => setState(() => _selectedGoal = goal),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? goalColor.withOpacity(0.1)
                  : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[100]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? goalColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(children: [
              Text(goal.icon ?? '🎯', style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(goal.title,
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87)),
                  const SizedBox(height: 2),
                  Text(
                      '${_formatCurrency(goal.currentAmount)} / ${_formatCurrency(goal.targetAmount)}',
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: goal.progress / 100,
                      backgroundColor:
                          isDark ? Colors.grey[700] : Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(goalColor),
                      minHeight: 5,
                    ),
                  ),
                ]),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                Icon(Icons.check_circle_rounded, color: goalColor, size: 22),
            ]),
          ),
        );
      }).toList(),
    );
  }

  // ── Helper widgets ────────────────────────────────────────────────────────
  Widget _toggleBtn(String label, String type, bool isDark) {
    final active = transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          transactionType = type;
          selectedCategory = null;
          _selectedGoal = null;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: active ? const Color(0xFF00CED1) : Colors.white)),
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool isDark) => Text(text,
      style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDark ? Colors.grey[400] : Colors.grey[600]));

  Widget _fieldBox(bool isDark, {required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _categoryDropdown(bool isDark) {
    final cats =
        transactionType == 'income' ? incomeCategories : expenseCategories;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedCategory,
          hint: Text('Chọn danh mục',
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
          dropdownColor:
              isDark ? const Color(0xFF2C2C2C) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down,
              color: isDark ? Colors.grey[400] : Colors.grey[600]),
          items: cats.map((cat) {
            return DropdownMenuItem<String>(
              value: cat['name'],
              child: Row(children: [
                Icon(cat['icon'] as IconData,
                    size: 20, color: const Color(0xFF00CED1)),
                const SizedBox(width: 12),
                Text(cat['name'],
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black)),
              ]),
            );
          }).toList(),
          onChanged: (val) {
            setState(() {
              selectedCategory = val;
              _selectedGoal = null;
            });
            if (val == _savingsCategoryName) _loadSavingGoals();
          },
        ),
      ),
    );
  }

  Widget _fixedCategory(bool isDark) => _fieldBox(isDark,
      child: Row(children: [
        Icon(widget.categoryIcon ?? Icons.category,
            size: 20,
            color: widget.categoryColor ?? const Color(0xFF00CED1)),
        const SizedBox(width: 12),
        Text(widget.categoryName!,
            style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.black)),
      ]));
}