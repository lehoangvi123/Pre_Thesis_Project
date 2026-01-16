// lib/view/TextVoice/Voice_confirm_dialog.dart
// AUTO TYPE DETECTION - Tự động chọn income/expense

import 'package:flutter/material.dart';

class VoiceconfirmDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onConfirm;
  
  const VoiceconfirmDialog({
    Key? key,
    required this.data,
    required this.onConfirm,
  }) : super(key: key);

  @override
  State<VoiceconfirmDialog> createState() => _VoiceconfirmDialogState();
}

class _VoiceconfirmDialogState extends State<VoiceconfirmDialog> {
  late String type;
  late double amount;
  late String category;
  late String note;
  
  final amountController = TextEditingController();
  final noteController = TextEditingController();
  
  final expenseCategories = [
    'Food & Dining',
    'Transportation',
    'Housing',
    'Shopping',
    'Healthcare',
    'Entertainment',
    'Education',
    'Gym & Sports',
    'Other Expenses',
  ];
  
  final incomeCategories = [
    'Salary',
    'Freelance',
    'Gift',
    'Investment',
    'Other Income',
  ];
  
  @override
  void initState() {
    super.initState();
    
    // ✨ TỰ ĐỘNG DETECT TYPE TỪ DATA
    type = widget.data['type'] ?? 'expense';
    amount = (widget.data['amount'] ?? 0).toDouble();
    category = widget.data['category'] ?? _getDefaultCategory();
    note = widget.data['note'] ?? '';
    
    // Đảm bảo category phù hợp với type
    if (type == 'income' && !incomeCategories.contains(category)) {
      category = 'Salary';
    } else if (type == 'expense' && !expenseCategories.contains(category)) {
      category = 'Other Expenses';
    }
    
    amountController.text = amount.toStringAsFixed(0);
    noteController.text = note;
    
    print('💡 Dialog auto-detected type: $type');
  }
  
  String _getDefaultCategory() {
    return type == 'income' ? 'Salary' : 'Other Expenses';
  }
  
  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
  
  List<String> get categories {
    return type == 'expense' ? expenseCategories : incomeCategories;
  }
  
  Color get primaryColor {
    return type == 'expense' ? Colors.red : Colors.green;
  }
  
  void _confirm() {
    final newAmount = double.tryParse(amountController.text) ?? 0;
    
    if (newAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Số tiền phải lớn hơn 0')),
      );
      return;
    }
    
    widget.onConfirm({
      'type': type,
      'amount': newAmount,
      'category': category,
      'note': noteController.text,
      'date': DateTime.now(),
    });
    
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with auto-detected badge
              Row(
                children: [
                  Icon(
                    type == 'income' 
                        ? Icons.trending_up 
                        : Icons.trending_down,
                    color: primaryColor,
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Xác nhận giao dịch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // AI badge nếu có
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type == 'income' ? 'THU' : 'CHI',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              
              // Type toggle (vẫn cho phép user đổi nếu cần)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            type = 'expense';
                            if (!expenseCategories.contains(category)) {
                              category = expenseCategories.first;
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'expense' 
                                ? Colors.red 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Chi tiêu',
                              style: TextStyle(
                                color: type == 'expense' 
                                    ? Colors.white 
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            type = 'income';
                            if (!incomeCategories.contains(category)) {
                              category = incomeCategories.first;
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: type == 'income' 
                                ? Colors.green 
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Thu nhập',
                              style: TextStyle(
                                color: type == 'income' 
                                    ? Colors.white 
                                    : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: 20),
              
              // Amount
              Text(
                'Số tiền',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
                decoration: InputDecoration(
                  prefixText: type == 'expense' ? '-' : '+',
                  suffixText: 'đ',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              SizedBox(height: 20),
              
              // Category
              Text(
                'Danh mục',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: category,
                  isExpanded: true,
                  underline: SizedBox(),
                  icon: Icon(Icons.keyboard_arrow_down),
                  items: categories.map((cat) {
                    return DropdownMenuItem(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      category = value!;
                    });
                  },
                ),
              ),
              
              SizedBox(height: 20),
              
              // Note
              Text(
                'Ghi chú',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              TextField(
                controller: noteController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Thêm ghi chú...',
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              
              SizedBox(height: 24),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text('Hủy'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _confirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Xác nhận',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
