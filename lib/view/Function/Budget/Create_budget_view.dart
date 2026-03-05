// lib/view/Budget/create_budget_view.dart
// Create Budget View - Tạo ngân sách mới
// UPDATED: Added income warning dialog

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './budget_model.dart';
import './budget_service.dart';

class CreateBudgetView extends StatefulWidget {
  final BudgetModel? budgetToEdit;

  const CreateBudgetView({Key? key, this.budgetToEdit}) : super(key: key);

  @override
  State<CreateBudgetView> createState() => _CreateBudgetViewState();
}

class _CreateBudgetViewState extends State<CreateBudgetView> {
  final _formKey = GlobalKey<FormState>();
  final BudgetService _budgetService = BudgetService();
  final TextEditingController _amountController = TextEditingController();

  // Form fields
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  IconData _selectedCategoryIcon = Icons.category;
  BudgetPeriod _selectedPeriod = BudgetPeriod.monthly;
  DateTime _startDate = DateTime.now();
  bool _autoReset = true;
  bool _alertEnabled = true;
  double _alertThreshold = 80.0;
  bool _isLoading = false;

  // ✅ NEW: Income tracking
  double _totalIncome = 0;
  double _currentTotalBudget = 0;
  double _enteredAmount = 0;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'food', 'name': 'Ăn uống', 'icon': Icons.restaurant},
    {'id': 'transport', 'name': 'Đi lại', 'icon': Icons.directions_car},
    {'id': 'shopping', 'name': 'Mua sắm', 'icon': Icons.shopping_bag},
    {'id': 'entertainment', 'name': 'Giải trí', 'icon': Icons.movie},
    {'id': 'health', 'name': 'Sức khỏe', 'icon': Icons.medical_services},
    {'id': 'education', 'name': 'Giáo dục', 'icon': Icons.school},
    {'id': 'bills', 'name': 'Hóa đơn', 'icon': Icons.receipt_long},
    {'id': 'housing', 'name': 'Nhà ở', 'icon': Icons.home},
    {'id': 'other', 'name': 'Khác', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.budgetToEdit != null) {
      _loadBudgetData();
    }
    _loadIncomeData(); // ✅ NEW
  }

  void _loadBudgetData() {
    final budget = widget.budgetToEdit!;
    _selectedCategoryId = budget.categoryId;
    _selectedCategoryName = budget.categoryName;
    _selectedCategoryIcon = budget.categoryIcon;
    _amountController.text = budget.limitAmount.toStringAsFixed(0);
    _selectedPeriod = budget.period;
    _startDate = budget.startDate;
    _autoReset = budget.autoReset;
    _alertEnabled = budget.alertEnabled;
    _alertThreshold = budget.alertThreshold;
    _enteredAmount = budget.limitAmount;
  }

  // ✅ NEW: Load income and existing budget total
  Future<void> _loadIncomeData() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);

      // Get total income this month
      final incomeSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      double totalIncome = 0;
      for (var doc in incomeSnapshot.docs) {
        totalIncome += (doc.data()['amount'] as num).toDouble();
      }

      // Get total existing budgets
      final budgetSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('budgets')
          .get();

      double totalBudget = 0;
      for (var doc in budgetSnapshot.docs) {
        if (widget.budgetToEdit != null && doc.id == widget.budgetToEdit!.id)
          continue;
        totalBudget += (doc.data()['limitAmount'] as num).toDouble();
      }

      if (mounted) {
        setState(() {
          _totalIncome = totalIncome;
          _currentTotalBudget = totalBudget;
        });
      }
    } catch (e) {
      debugPrint('Error loading income: $e');
    }
  }

  // ✅ NEW: Format VND
  String _formatVND(double amount) {
    return amount
        .toStringAsFixed(0)
        .replaceAllMapped(
            RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},') +
        'đ';
  }

  // ✅ NEW: Computed helpers
  double get _projectedTotal => _currentTotalBudget + _enteredAmount;
  bool get _exceedsIncome =>
      _totalIncome > 0 && _projectedTotal > _totalIncome;
  double get _remainingBudgetable =>
      (_totalIncome - _currentTotalBudget).clamp(0, double.infinity);
  double get _projectedPercent => _totalIncome > 0
      ? (_projectedTotal / _totalIncome * 100).clamp(0, 150)
      : 0;
  Color get _progressColor {
    if (_projectedPercent >= 100) return Colors.red;
    if (_projectedPercent >= 90) return Colors.deepOrange;
    if (_projectedPercent >= 80) return Colors.orange;
    return Colors.teal;
  }

  // ✅ NEW: Track amount as user types
  void _onAmountChanged(String value) {
    final amount = double.tryParse(value.replaceAll(',', '')) ?? 0;
    setState(() => _enteredAmount = amount);
  }

  // ✅ NEW: Show warning dialog when budget exceeds income
  Future<bool> _showIncomeWarningDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Vượt quá thu nhập!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tổng ngân sách của bạn sẽ vượt quá thu nhập hàng tháng.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 16),
                // Summary table
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      _dialogRow('💰 Thu nhập tháng',
                          _formatVND(_totalIncome), Colors.green),
                      const SizedBox(height: 8),
                      _dialogRow('📊 Đã ngân sách',
                          _formatVND(_currentTotalBudget), Colors.blue),
                      const SizedBox(height: 8),
                      _dialogRow('➕ Ngân sách mới',
                          _formatVND(_enteredAmount), Colors.orange),
                      const Divider(height: 16),
                      _dialogRow('⚠️ Tổng cộng',
                          _formatVND(_projectedTotal), Colors.red),
                      const SizedBox(height: 8),
                      _dialogRow('✅ Tối đa còn lại',
                          _formatVND(_remainingBudgetable), Colors.teal),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (_projectedPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: Colors.grey[300],
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tổng ngân sách chiếm ${_projectedPercent.toStringAsFixed(1)}% thu nhập',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              // Cancel - go back and fix
              OutlinedButton(
                onPressed: () => Navigator.pop(context, false),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.teal),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: const Text('Sửa lại',
                    style: TextStyle(color: Colors.teal)),
              ),
              const SizedBox(width: 8),
              // Force save anyway
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                ),
                child: const Text('Vẫn lưu',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  Widget _dialogRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.budgetToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Chỉnh sửa ngân sách' : 'Tạo ngân sách'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Category Selection
            _buildSectionTitle('Danh mục'),
            _buildCategorySelector(isDark),
            const SizedBox(height: 24),

            // Amount Input
            _buildSectionTitle('Giới hạn chi tiêu'),
            TextFormField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              onChanged: _onAmountChanged, // ✅ NEW
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                suffixText: 'đ',
                prefixIcon: const Icon(Icons.attach_money),
                // ✅ NEW: Red border when exceeds income
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _exceedsIncome
                        ? Colors.red
                        : Colors.grey.shade400,
                    width: _exceedsIncome ? 2 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _exceedsIncome ? Colors.red : Colors.teal,
                    width: 2,
                  ),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                if (double.tryParse(value.replaceAll(',', '')) == null) {
                  return 'Số tiền không hợp lệ';
                }
                if (double.parse(value.replaceAll(',', '')) <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                return null;
              },
            ),

            // ✅ NEW: Live warning banner below input
            if (_enteredAmount > 0 && _totalIncome > 0)
              _buildLiveWarningBanner(),

            const SizedBox(height: 24),

            // Period Selection
            _buildSectionTitle('Chu kỳ'),
            _buildPeriodSelector(isDark),
            const SizedBox(height: 24),

            // Start Date
            _buildSectionTitle('Ngày bắt đầu'),
            InkWell(
              onTap: _selectStartDate,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today),
                    const SizedBox(width: 12),
                    Text(
                      '${_startDate.day}/${_startDate.month}/${_startDate.year}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Alert Threshold
            _buildSectionTitle('Cảnh báo ở mức'),
            Slider(
              value: _alertThreshold,
              min: 50,
              max: 100,
              divisions: 10,
              label: '${_alertThreshold.toInt()}%',
              onChanged: (value) {
                setState(() {
                  _alertThreshold = value;
                });
              },
            ),
            Text(
              'Nhận cảnh báo khi đạt ${_alertThreshold.toInt()}% ngân sách',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Toggles
            SwitchListTile(
              title: const Text('Tự động làm mới'),
              subtitle: const Text('Tạo ngân sách mới khi hết hạn'),
              value: _autoReset,
              onChanged: (value) {
                setState(() {
                  _autoReset = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text('Bật thông báo'),
              subtitle: const Text('Nhận cảnh báo khi sắp hết ngân sách'),
              value: _alertEnabled,
              onChanged: (value) {
                setState(() {
                  _alertEnabled = value;
                });
              },
            ),
            const SizedBox(height: 32),

            // Submit Button
            ElevatedButton(
              onPressed: _isLoading ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                // ✅ NEW: Orange when warning, red when exceeded
                backgroundColor: _exceedsIncome
                    ? Colors.red.shade400
                    : Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2,
                          color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_exceedsIncome)
                          const Icon(Icons.warning_amber_rounded,
                              color: Colors.white, size: 20),
                        if (_exceedsIncome) const SizedBox(width: 8),
                        Text(
                          isEditing ? 'Cập nhật' : 'Tạo ngân sách',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Live warning banner under amount field
  Widget _buildLiveWarningBanner() {
    final color = _progressColor;
    final String statusText;
    final IconData statusIcon;

    if (_exceedsIncome) {
      statusText =
          '🚫 Vượt thu nhập ${_formatVND(_projectedTotal - _totalIncome)} — nhấn "Tạo ngân sách" để xem chi tiết';
      statusIcon = Icons.block;
    } else if (_projectedPercent >= 90) {
      statusText =
          '🔴 Rất cao (${_projectedPercent.toStringAsFixed(1)}%) — ít dư để tiết kiệm';
      statusIcon = Icons.warning_amber_rounded;
    } else if (_projectedPercent >= 80) {
      statusText =
          '🟡 Đang tiếp cận giới hạn (${_projectedPercent.toStringAsFixed(1)}%)';
      statusIcon = Icons.info_outline;
    } else {
      statusText =
          '🟢 Hợp lý — còn lại ${_formatVND(_totalIncome - _projectedTotal)}';
      statusIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(statusText,
                    style: TextStyle(
                        fontSize: 12.5,
                        color: color,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (_projectedPercent / 100).clamp(0.0, 1.0),
                    backgroundColor: color.withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_projectedPercent.toStringAsFixed(0)}%',
                style: TextStyle(
                    fontSize: 12,
                    color: color,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Thu nhập: ${_formatVND(_totalIncome)}  •  Đã phân bổ: ${_formatVND(_projectedTotal)}',
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategorySelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categories.map((category) {
        final isSelected = _selectedCategoryId == category['id'];
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedCategoryId = category['id'];
              _selectedCategoryName = category['name'];
              _selectedCategoryIcon = category['icon'];
            });
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.teal
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.teal : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  category['icon'],
                  color: isSelected ? Colors.white : null,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  category['name'],
                  style: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : null,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPeriodSelector(bool isDark) {
    return Column(
      children: BudgetPeriod.values.map((period) {
        return RadioListTile<BudgetPeriod>(
          title: Text(periodToString(period)),
          value: period,
          groupValue: _selectedPeriod,
          onChanged: (value) {
            setState(() {
              _selectedPeriod = value!;
            });
          },
          activeColor: Colors.teal,
        );
      }).toList(),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn danh mục')),
      );
      return;
    }

    // ✅ NEW: Show warning dialog if exceeds income
    if (_exceedsIncome) {
      final shouldContinue = await _showIncomeWarningDialog();
      if (!shouldContinue) return; // User chose "Sửa lại"
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final amount =
          double.parse(_amountController.text.replaceAll(',', ''));
      final endDate = calculateEndDate(_startDate, _selectedPeriod);

      final budget = BudgetModel(
        id: widget.budgetToEdit?.id ?? '',
        userId: userId,
        categoryId: _selectedCategoryId!,
        categoryName: _selectedCategoryName!,
        categoryIcon: _selectedCategoryIcon,
        limitAmount: amount,
        period: _selectedPeriod,
        startDate: _startDate,
        endDate: endDate,
        autoReset: _autoReset,
        alertEnabled: _alertEnabled,
        alertThreshold: _alertThreshold,
        createdAt: widget.budgetToEdit?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.budgetToEdit != null) {
        await _budgetService.updateBudget(budget.id, budget);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật ngân sách')),
          );
        }
      } else {
        await _budgetService.createBudget(budget);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã tạo ngân sách')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}