// lib/view/Budget/create_budget_view.dart
// Create Budget View - Tạo ngân sách mới

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './budget_model.dart';
import './budget_service.dart';

class CreateBudgetView extends StatefulWidget {
  final BudgetModel? budgetToEdit; // Null nếu tạo mới, có giá trị nếu edit

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

  // Predefined categories (giống với expense categories)
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
              decoration: InputDecoration(
                hintText: 'Nhập số tiền',
                suffixText: 'đ',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                if (double.tryParse(value) == null) {
                  return 'Số tiền không hợp lệ';
                }
                if (double.parse(value) <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                return null;
              },
            ),
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
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Cập nhật' : 'Tạo ngân sách',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        final isSelected = _selectedPeriod == period;
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

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      final amount = double.parse(_amountController.text);
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