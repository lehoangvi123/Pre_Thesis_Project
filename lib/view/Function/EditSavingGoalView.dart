import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './SavingGoals.dart';
import './SavingGoalsService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditSavingGoalView extends StatefulWidget {
  final SavingGoal goal;

  const EditSavingGoalView({Key? key, required this.goal}) : super(key: key);

  @override
  State<EditSavingGoalView> createState() => _EditSavingGoalViewState();
}

class _EditSavingGoalViewState extends State<EditSavingGoalView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _targetAmountController;
  late TextEditingController _descriptionController;
  final SavingGoalService _goalService = SavingGoalService();

  late String selectedIcon;
  late Color selectedColor;
  DateTime? targetDate;
  bool isLoading = false;

  // Predefined icons for goals
  final List<String> icons = [
    '🎯', '💰', '🏠', '🚗', '✈️', '📱', 
    '💻', '🎓', '💍', '🏖️', '🎮', '📷',
    '🎸', '⌚', '👟', '🎨', '📚', '🏋️'
  ];

  // Predefined colors
  final List<Color> colors = [
    const Color(0xFF00CED1), // Cyan
    const Color(0xFF4CAF50), // Green
    const Color(0xFF2196F3), // Blue
    const Color(0xFF9C27B0), // Purple
    const Color(0xFFFF9800), // Orange
    const Color(0xFFE91E63), // Pink
    const Color(0xFFF44336), // Red
    const Color(0xFF607D8B), // Blue Grey
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with current goal data
    _titleController = TextEditingController(text: widget.goal.title);
    _targetAmountController = TextEditingController(
      text: _formatCurrency(widget.goal.targetAmount.toString())
    );
    _descriptionController = TextEditingController(
      text: widget.goal.description ?? ''
    );
    selectedIcon = widget.goal.icon ?? '🎯';
    selectedColor = Color(widget.goal.color ?? 0xFF00CED1);
    targetDate = widget.goal.targetDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatCurrency(String value) {
    if (value.isEmpty) return '';
    value = value.replaceAll('.', '');
    return value.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 3650)), // 10 years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color(0xFF00CED1),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != targetDate) {
      setState(() {
        targetDate = picked;
      });
    }
  }

  Future<void> _updateSavingGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      Map<String, dynamic> updates = {
        'title': _titleController.text.trim(),
        'targetAmount': double.parse(_targetAmountController.text.replaceAll('.', '')),
        'icon': selectedIcon,
        'color': selectedColor.value,
        'targetDate': targetDate != null 
            ? Timestamp.fromDate(targetDate!) 
            : null,
        'description': _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      };

      bool success = await _goalService.updateSavingGoal(widget.goal.id, updates);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật mục tiêu thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.pop(context, true); // Return true to refresh parent
      } else if (mounted) {
        throw Exception('Failed to update goal');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Chỉnh sửa mục tiêu',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Icon & Color Selector
            _buildIconColorSelector(isDark),
            const SizedBox(height: 24),

            // Title Input
            _buildTextField(
              controller: _titleController,
              label: 'Tên mục tiêu',
              hint: 'Ví dụ: Mua iPad',
              icon: Icons.flag,
              isDark: isDark,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập tên mục tiêu';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Target Amount Input
            _buildTextField(
              controller: _targetAmountController,
              label: 'Số tiền mục tiêu',
              hint: '10.000.000',
              icon: Icons.attach_money,
              isDark: isDark,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              onChanged: (value) {
                String formatted = _formatCurrency(value);
                _targetAmountController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số tiền';
                }
                double? amount = double.tryParse(value.replaceAll('.', ''));
                if (amount == null || amount <= 0) {
                  return 'Số tiền phải lớn hơn 0';
                }
                // Warning if new target is less than current amount
                if (amount < widget.goal.currentAmount) {
                  return 'Mục tiêu phải lớn hơn số tiền đã tiết kiệm (${_formatCurrency(widget.goal.currentAmount.toString())}₫)';
                }
                return null;
              },
              suffix: const Text(
                '₫',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00CED1),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Current Progress Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: const Color(0xFF00CED1),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Đã tiết kiệm: ${_formatCurrency(widget.goal.currentAmount.toString())}₫',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Target Date
            _buildDateSelector(isDark),
            const SizedBox(height: 16),

            // Description (Optional)
            _buildTextField(
              controller: _descriptionController,
              label: 'Mô tả (tùy chọn)',
              hint: 'Thêm ghi chú cho mục tiêu...',
              icon: Icons.description,
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            // Save Button
            _buildSaveButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildIconColorSelector(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chọn biểu tượng',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: icons.map((icon) {
              bool isSelected = selectedIcon == icon;
              return GestureDetector(
                onTap: () => setState(() => selectedIcon = icon),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? selectedColor.withOpacity(0.2)
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          Text(
            'Chọn màu',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors.map((color) {
              bool isSelected = selectedColor == color;
              return GestureDetector(
                onTap: () => setState(() => selectedColor = color),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    void Function(String)? onChanged,
    int maxLines = 1,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        onChanged: onChanged,
        maxLines: maxLines,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffix != null ? Padding(
            padding: const EdgeInsets.only(right: 16),
            child: suffix,
          ) : null,
          prefixIcon: Icon(icon, color: const Color(0xFF00CED1)),
          labelStyle: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
          hintStyle: TextStyle(
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }

  Widget _buildDateSelector(bool isDark) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: const Color(0xFF00CED1)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ngày đích (tùy chọn)',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    targetDate != null
                        ? '${targetDate!.day}/${targetDate!.month}/${targetDate!.year}'
                        : 'Chọn ngày hoàn thành',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                      fontWeight: targetDate != null ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (targetDate != null)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[400]),
                onPressed: () => setState(() => targetDate = null),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : _updateSavingGoal,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00CED1),
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Text(
                'Lưu thay đổi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// Missing import
