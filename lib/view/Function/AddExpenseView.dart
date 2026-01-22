import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

// ✅ NEW: Custom formatter for thousand separator
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Remove all dots first
    String newText = newValue.text.replaceAll('.', '');

    // Format with dots
    String formatted = _formatWithDots(newText);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDots(String value) {
    if (value.isEmpty) return '';
    
    // Reverse the string to add dots from right to left
    String reversed = value.split('').reversed.join('');
    String result = '';
    
    for (int i = 0; i < reversed.length; i++) {
      if (i > 0 && i % 3 == 0) {
        result += '.';
      }
      result += reversed[i];
    }
    
    // Reverse back
    return result.split('').reversed.join('');
  }
}

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
    transactionType = widget.initialType ?? 'expense';
    
    if (widget.categoryName != null) {
      final incomeCategories = ['Salary', 'Business', 'Investment', 'Gift', 'Freelance'];
      
      if (incomeCategories.contains(widget.categoryName)) {
        transactionType = 'income';
      } else {
        transactionType = 'expense';
      }
      
      selectedCategory = widget.categoryName;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ✅ HELPER: Parse amount from formatted string
  double _parseAmount(String formattedAmount) {
    // Remove dots and parse
    String cleaned = formattedAmount.replaceAll('.', '');
    return double.tryParse(cleaned) ?? 0;
  }

  Future<bool> _validateBalance(double amount) async {
    if (transactionType != 'expense') {
      return true;
    }
    
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      double currentBalance = (userData['balance'] ?? 0).toDouble();
      
      if (amount > currentBalance) {
        _showInsufficientFundsDialog(currentBalance, amount);
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bạn không thể chi tiêu vượt quá số dư hiện tại.',
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Số dư hiện tại:',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatCurrency(balance),
                        style: const TextStyle(
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
                      Text(
                        'Số tiền muốn chi:',
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                      Text(
                        _formatCurrency(amount),
                        style: const TextStyle(
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
                      Text(
                        'Thiếu:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        _formatCurrency(amount - balance),
                        style: const TextStyle(
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
    // ✅ Format with thousand separator
    final formatter = NumberFormat('#,###', 'vi_VN');
    return '${formatter.format(amount)}₫';
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (selectedCategory == null) {
      _showErrorSnackBar('Please select a category');
      return;
    }

    if (isLoading) return;

    // ✅ Parse amount from formatted string
    double amount;
    try {
      amount = _parseAmount(_amountController.text.trim()).abs();
    } catch (e) {
      _showErrorSnackBar('Invalid amount');
      return;
    }

    bool canProceed = await _validateBalance(amount);
    if (!canProceed) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      String transactionId = const Uuid().v4();

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(
          FirebaseFirestore.instance.collection('users').doc(userId)
        );

        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        double currentIncome = (userData['totalIncome'] ?? 0).toDouble();
        double currentExpense = (userData['totalExpense'] ?? 0).toDouble();

        double newIncome = currentIncome;
        double newExpense = currentExpense;

        if (transactionType == 'income') {
          newIncome += amount;
        } else {
          newExpense += amount;
        }

        double newBalance = newIncome - newExpense;

        transaction.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(transactionId),
          {
            'id': transactionId,
            'type': transactionType,
            'amount': amount,
            'category': selectedCategory,
            'title': _titleController.text.trim(),
            'note': _noteController.text.trim(),
            'date': Timestamp.fromDate(selectedDate),
            'createdAt': FieldValue.serverTimestamp(),
          },
        );

        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {
            'balance': newBalance,
            'totalIncome': newIncome,
            'totalExpense': newExpense,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      if (mounted) {
        _showSuccessSnackBar('Transaction added successfully!');
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      print('Error saving transaction: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save: ${e.toString()}');
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
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
        title: Text(
          transactionType == 'income' ? 'Add Income' : 'Add Expense',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          if (!widget.hideToggle && widget.categoryName == null)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          transactionType = 'income';
                          selectedCategory = null;
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
                            'Income',
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
                          selectedCategory = null;
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
                            'Expense',
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
                        'Date',
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
                                DateFormat('MMMM dd, yyyy').format(selectedDate),
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
                      widget.categoryName == null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
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
                                        'Select category',
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
                              ],
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        widget.categoryIcon ?? Icons.category,
                                        size: 20,
                                        color: widget.categoryColor ?? const Color(0xFF00CED1),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        widget.categoryName!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 20),
                      
                      // ✅ Amount - WITH THOUSAND SEPARATOR
                      Text(
                        'Amount',
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
                        // ✅ ADD FORMATTER HERE
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          ThousandsSeparatorInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          hintText: '0',
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
                            return 'Please enter amount';
                          }
                          // ✅ Parse formatted value
                          double? amount = _parseAmount(value);
                          if (amount == null || amount <= 0) {
                            return 'Please enter valid amount';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Expense Title
                      Text(
                        transactionType == 'income' ? 'Income Title' : 'Expense Title',
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
                          hintText: 'E.g., Dinner',
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
                            return 'Please enter title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Enter Message
                      Text(
                        'Enter Message (Optional)',
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
                          hintText: 'Add notes (optional)',
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
                      
                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00CED1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text(
                                  'Save',
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