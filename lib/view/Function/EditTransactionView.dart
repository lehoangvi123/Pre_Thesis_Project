// lib/view/EditTransactionView.dart
// EDIT TRANSACTION - Sửa giao dịch đã nhập nhầm

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EditTransactionView extends StatefulWidget {
  final String transactionId;
  final Map<String, dynamic> transactionData;
  
  const EditTransactionView({
    Key? key,
    required this.transactionId,
    required this.transactionData,
  }) : super(key: key);

  @override
  State<EditTransactionView> createState() => _EditTransactionViewState();
}

class _EditTransactionViewState extends State<EditTransactionView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _titleController;
  late TextEditingController _noteController;
  
  late String transactionType;
  late String? selectedCategory;
  late DateTime selectedDate;
  bool isLoading = false;
  
  // Original values for comparison
  late double originalAmount;
  late String originalType;
  
  // Categories
  final List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Shopping', 'icon': Icons.shopping_cart},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Health', 'icon': Icons.local_hospital},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Bills', 'icon': Icons.receipt},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];
  
  final List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.attach_money},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Other', 'icon': Icons.more_horiz},
  ];

  @override
  void initState() {
    super.initState();
    
    // Load existing data
    originalAmount = (widget.transactionData['amount'] as num).toDouble();
    originalType = widget.transactionData['type'] ?? 'expense';
    
    transactionType = originalType;
    selectedCategory = widget.transactionData['category'];
    
    // Parse date
    Timestamp? timestamp = widget.transactionData['date'] as Timestamp?;
    selectedDate = timestamp?.toDate() ?? DateTime.now();
    
    // Initialize controllers with existing values
    _amountController = TextEditingController(
      text: originalAmount.toString(),
    );
    _titleController = TextEditingController(
      text: widget.transactionData['title'] ?? '',
    );
    _noteController = TextEditingController(
      text: widget.transactionData['note'] ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ✅ VALIDATE BALANCE (for expense only)
  Future<bool> _validateBalance(double newAmount) async {
    // Income doesn't need validation
    if (transactionType != 'expense') {
      return true;
    }
    
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      // Get current balance
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      double currentBalance = (userData['balance'] ?? 0).toDouble();
      
      // Calculate available balance considering we're editing
      double availableBalance = currentBalance;
      
      // If editing an existing expense, add it back first
      if (originalType == 'expense') {
        availableBalance += originalAmount;
      } else if (originalType == 'income') {
        availableBalance -= originalAmount;
      }
      
      // Check if new amount is affordable
      if (transactionType == 'expense' && newAmount > availableBalance) {
        _showInsufficientFundsDialog(availableBalance, newAmount);
        return false;
      }
      
      return true;
    } catch (e) {
      print('Error validating balance: $e');
      return false;
    }
  }

  void _showInsufficientFundsDialog(double balance, double amount) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.warning_rounded,
                color: Colors.red,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Không đủ tiền'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Số dư khả dụng không đủ để sửa thành số tiền này.',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số dư khả dụng:', style: TextStyle(fontSize: 13)),
                      Text(
                        _formatCurrency(balance),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Số tiền muốn chi:', style: TextStyle(fontSize: 13)),
                      Text(
                        _formatCurrency(amount),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Thiếu:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text(
                        _formatCurrency(amount - balance),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K₫';
    }
    return '${amount.toStringAsFixed(0)}₫';
  }

  Future<void> _updateTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (selectedCategory == null) {
      _showErrorSnackBar('Vui lòng chọn danh mục');
      return;
    }

    if (isLoading) return;

    // Parse new amount
    double newAmount;
    try {
      newAmount = double.parse(_amountController.text.trim());
    } catch (e) {
      _showErrorSnackBar('Số tiền không hợp lệ');
      return;
    }

    // ✅ VALIDATE BALANCE
    bool canProceed = await _validateBalance(newAmount);
    if (!canProceed) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Use Firestore Transaction for atomic update
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // 1. Get user document
        DocumentSnapshot userDoc = await transaction.get(
          FirebaseFirestore.instance.collection('users').doc(userId)
        );

        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        double currentIncome = (userData['totalIncome'] ?? 0).toDouble();
        double currentExpense = (userData['totalExpense'] ?? 0).toDouble();

        // 2. Reverse old transaction
        if (originalType == 'income') {
          currentIncome -= originalAmount;
        } else {
          currentExpense -= originalAmount;
        }

        // 3. Apply new transaction
        if (transactionType == 'income') {
          currentIncome += newAmount;
        } else {
          currentExpense += newAmount;
        }

        double newBalance = currentIncome - currentExpense;

        // 4. Update transaction document
        transaction.update(
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(widget.transactionId),
          {
            'type': transactionType,
            'amount': newAmount,
            'category': selectedCategory,
            'title': _titleController.text.trim(),
            'note': _noteController.text.trim(),
            'date': Timestamp.fromDate(selectedDate),
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );

        // 5. Update user totals
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {
            'balance': newBalance,
            'totalIncome': currentIncome,
            'totalExpense': currentExpense,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      if (mounted) {
        _showSuccessSnackBar('Đã cập nhật giao dịch!');
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('Error updating transaction: $e');
      if (mounted) {
        _showErrorSnackBar('Lỗi: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

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
        title: const Text(
          'Chỉnh sửa giao dịch',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          // Type Toggle
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        transactionType = 'income';
                        selectedCategory = null;  // ✅ RESET category when changing type
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: transactionType == 'income'
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Thu nhập',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: transactionType == 'income'
                                ? const Color(0xFF00CED1)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        transactionType = 'expense';
                        selectedCategory = null;  // ✅ RESET category when changing type
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: transactionType == 'expense'
                            ? Colors.white
                            : Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Chi tiêu',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: transactionType == 'expense'
                                ? const Color(0xFF00CED1)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Form Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      Text(
                        'Ngày',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                DateFormat('dd/MM/yyyy').format(selectedDate),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Icon(
                                Icons.calendar_today,
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Category
                      Text(
                        'Danh mục',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedCategory,
                            hint: Text(
                              'Chọn danh mục',
                              style: TextStyle(
                                color: isDark ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            dropdownColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            items: (transactionType == 'income'
                                    ? incomeCategories
                                    : expenseCategories)
                                .map((category) {
                              return DropdownMenuItem<String>(
                                value: category['name'],
                                child: Row(
                                  children: [
                                    Icon(
                                      category['icon'],
                                      size: 20,
                                      color: const Color(0xFF00CED1),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      category['name'],
                                      style: TextStyle(
                                        color: isDark ? Colors.white : Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                selectedCategory = newValue;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Amount
                      Text(
                        'Số tiền',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: '0.00',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          prefixText: 'đ ',
                          prefixStyle: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black,
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
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        'Tiêu đề',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'VD: Ăn trưa',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập tiêu đề';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Note
                      Text(
                        'Ghi chú (Tùy chọn)',
                        style: TextStyle(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _noteController,
                        maxLines: 3,
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Thêm ghi chú...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                          ),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      
                      // Update Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _updateTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00CED1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Cập nhật',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}