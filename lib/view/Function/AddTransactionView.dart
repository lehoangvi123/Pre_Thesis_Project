// lib/view/Function/Add_transaction_view.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddTransactionView extends StatefulWidget {
  final String initialType; // 'income' hoặc 'expense'

  const AddTransactionView({Key? key, this.initialType = 'expense'})
      : super(key: key);

  @override
  State<AddTransactionView> createState() => _AddTransactionViewState();
}

class _AddTransactionViewState extends State<AddTransactionView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _selectedType = 'expense';
  String _selectedCategory = '';
  String _selectedCategoryIcon = 'shopping_cart';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  // Danh sách categories
  final List<Map<String, dynamic>> _expenseCategories = [
    {'name': 'Ăn uống', 'icon': Icons.restaurant, 'iconName': 'restaurant', 'color': Colors.orange},
    {'name': 'Di chuyển', 'icon': Icons.directions_car, 'iconName': 'directions_car', 'color': Colors.blue},
    {'name': 'Mua sắm', 'icon': Icons.shopping_cart, 'iconName': 'shopping_cart', 'color': Colors.pink},
    {'name': 'Giải trí', 'icon': Icons.movie, 'iconName': 'movie', 'color': Colors.purple},
    {'name': 'Sức khoẻ', 'icon': Icons.local_hospital, 'iconName': 'local_hospital', 'color': Colors.red},
    {'name': 'Nhà ở', 'icon': Icons.home, 'iconName': 'home', 'color': Colors.brown},
    {'name': 'Giáo dục', 'icon': Icons.school, 'iconName': 'school', 'color': Colors.teal},
    {'name': 'Hóa đơn', 'icon': Icons.receipt, 'iconName': 'receipt', 'color': Colors.indigo},
    {'name': 'Khác', 'icon': Icons.more_horiz, 'iconName': 'more_horiz', 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _incomeCategories = [
    {'name': 'Lương', 'icon': Icons.work, 'iconName': 'work', 'color': Colors.green},
    {'name': 'Thưởng', 'icon': Icons.card_giftcard, 'iconName': 'card_giftcard', 'color': Colors.amber},
    {'name': 'Đầu tư', 'icon': Icons.trending_up, 'iconName': 'trending_up', 'color': Colors.blue},
    {'name': 'Kinh doanh', 'icon': Icons.store, 'iconName': 'store', 'color': Colors.orange},
    {'name': 'Cho thuê', 'icon': Icons.house, 'iconName': 'house', 'color': Colors.brown},
    {'name': 'Freelance', 'icon': Icons.laptop, 'iconName': 'laptop', 'color': Colors.purple},
    {'name': 'Khác', 'icon': Icons.more_horiz, 'iconName': 'more_horiz', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialType == 'income' ? 1 : 0,
    );
    _tabController.addListener(() {
      setState(() {
        _selectedType = _tabController.index == 0 ? 'expense' : 'income';
        _selectedCategory = '';
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String get _userId => _auth.currentUser?.uid ?? '';

  Color get _typeColor =>
      _selectedType == 'income' ? Colors.green[600]! : Colors.red[500]!;

  List<Map<String, dynamic>> get _currentCategories =>
      _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

  // ── Lưu transaction ─────────────────────────────────────────
  Future<void> _save() async {
    if (_amountController.text.isEmpty) {
      _showSnack('Vui lòng nhập số tiền', isError: true);
      return;
    }
    if (_selectedCategory.isEmpty) {
      _showSnack('Vui lòng chọn danh mục', isError: true);
      return;
    }

    final amount = double.tryParse(
        _amountController.text.replaceAll(',', '').replaceAll('.', ''));
    if (amount == null || amount <= 0) {
      _showSnack('Số tiền không hợp lệ', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final batch = _firestore.batch();

      // 1. Thêm transaction
      final txRef = _firestore.collection('transactions').doc();
      batch.set(txRef, {
        'userId': _userId,
        'type': _selectedType,
        'amount': amount,
        'categoryName': _selectedCategory,
        'categoryIcon': _selectedCategoryIcon,
        'note': _noteController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate),
        'createdAt': Timestamp.now(),
      });

      // 2. Cập nhật balance trong users
      final userRef = _firestore.collection('users').doc(_userId);
      if (_selectedType == 'income') {
        batch.update(userRef, {
          'balance': FieldValue.increment(amount),
          'totalIncome': FieldValue.increment(amount),
        });
      } else {
        batch.update(userRef, {
          'balance': FieldValue.increment(-amount),
          'totalExpense': FieldValue.increment(amount),
        });
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context, true); // true = đã thêm thành công
        _showSnack(
          _selectedType == 'income'
              ? '✅ Đã thêm thu nhập ${_formatAmount(amount)}đ'
              : '✅ Đã thêm chi tiêu ${_formatAmount(amount)}đ',
        );
      }
    } catch (e) {
      _showSnack('Lỗi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

  // ── Chọn ngày ────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: _typeColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String _formatAmount(double amount) {
    return NumberFormat("#,##0", "vi_VN").format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      appBar: AppBar(
        title: const Text('Thêm giao dịch'),
        backgroundColor: _typeColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: '💸 Chi tiêu'),
            Tab(text: '💰 Thu nhập'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Input số tiền ──
            _buildAmountInput(isDark),
            const SizedBox(height: 20),

            // ── Chọn danh mục ──
            Text('Danh mục',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87)),
            const SizedBox(height: 12),
            _buildCategoryGrid(isDark),
            const SizedBox(height: 20),

            // ── Ngày ──
            _buildDatePicker(isDark),
            const SizedBox(height: 16),

            // ── Ghi chú ──
            _buildNoteInput(isDark),
            const SizedBox(height: 28),

            // ── Nút lưu ──
            _buildSaveButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ── Amount Input ─────────────────────────────────────────────
  Widget _buildAmountInput(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _typeColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _typeColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_selectedType == 'income'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
                  color: _typeColor, size: 20),
              const SizedBox(width: 8),
              Text(
                _selectedType == 'income' ? 'Thu nhập' : 'Chi tiêu',
                style: TextStyle(
                    color: _typeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('đ',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: _typeColor)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: '0',
                    hintStyle: TextStyle(
                        fontSize: 32,
                        color: isDark ? Colors.grey[600] : Colors.grey[400]),
                    border: InputBorder.none,
                  ),
                  onChanged: (val) => setState(() {}),
                ),
              ),
            ],
          ),
          if (_amountController.text.isNotEmpty)
            Text(
              '= ${_formatAmount(double.tryParse(_amountController.text.replaceAll(',', '')) ?? 0)}đ',
              style: TextStyle(fontSize: 13, color: _typeColor.withOpacity(0.7)),
            ),
        ],
      ),
    );
  }

  // ── Category Grid ────────────────────────────────────────────
  Widget _buildCategoryGrid(bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: _currentCategories.length,
      itemBuilder: (context, index) {
        final cat = _currentCategories[index];
        final isSelected = _selectedCategory == cat['name'];

        return GestureDetector(
          onTap: () => setState(() {
            _selectedCategory = cat['name'];
            _selectedCategoryIcon = cat['iconName'];
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isSelected
                  ? (cat['color'] as Color).withOpacity(0.15)
                  : isDark
                      ? Colors.grey[850]
                      : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? cat['color'] as Color
                    : isDark
                        ? Colors.grey[700]!
                        : Colors.grey[200]!,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (cat['color'] as Color).withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : [],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: isSelected
                      ? cat['color'] as Color
                      : isDark
                          ? Colors.grey[400]
                          : Colors.grey[600],
                  size: 28,
                ),
                const SizedBox(height: 6),
                Text(
                  cat['name'],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? cat['color'] as Color
                        : isDark
                            ? Colors.grey[400]
                            : Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Date Picker ──────────────────────────────────────────────
  Widget _buildDatePicker(bool isDark) {
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: _typeColor, size: 20),
            const SizedBox(width: 12),
            Text(
              DateFormat('EEEE, dd/MM/yyyy', 'vi').format(_selectedDate),
              style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w500),
            ),
            const Spacer(),
            Icon(Icons.chevron_right,
                color: isDark ? Colors.grey[500] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  // ── Note Input ────────────────────────────────────────────────
  Widget _buildNoteInput(bool isDark) {
    return TextField(
      controller: _noteController,
      maxLines: 2,
      decoration: InputDecoration(
        labelText: 'Ghi chú (tùy chọn)',
        hintText: 'VD: Ăn sáng với bạn bè...',
        prefixIcon: Icon(Icons.note_outlined, color: _typeColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: _typeColor, width: 2),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey[850] : Colors.white,
      ),
    );
  }

  // ── Save Button ───────────────────────────────────────────────
  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _save,
        style: ElevatedButton.styleFrom(
          backgroundColor: _typeColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        child: _isSaving
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedType == 'income'
                        ? Icons.add_circle_outline
                        : Icons.remove_circle_outline,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _selectedType == 'income'
                        ? 'Thêm thu nhập'
                        : 'Thêm chi tiêu',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
      ),
    );
  }
}