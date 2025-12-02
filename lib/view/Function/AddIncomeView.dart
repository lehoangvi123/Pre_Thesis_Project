import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AddIncomeView extends StatefulWidget {
  final String? categoryName;
  final IconData? categoryIcon;
  final Color? categoryColor;
  
  const AddIncomeView({
    Key? key,
    this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  }) : super(key: key);

  @override
  State<AddIncomeView> createState() => _AddIncomeViewState();
}

class _AddIncomeViewState extends State<AddIncomeView> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: widget.categoryColor ?? const Color(0xFF00CED1),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncome() async {
    if (_amountController.text.trim().isEmpty || _titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in amount and title'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_isLoading) return; // ✅ Prevent double-tap

    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      // ✅ Parse amount
      final cleanedAmount = _amountController.text.trim().replaceAll(RegExp(r'[^\d]'), '');
      final amount = double.tryParse(cleanedAmount);
      
      if (amount == null || amount <= 0) {
        throw Exception('Please enter a valid amount');
      }

      // ✅ Use Firestore Transaction for atomic update
      await _firestore.runTransaction((transaction) async {
        // Get user doc
        DocumentSnapshot userDoc = await transaction.get(
          _firestore.collection('users').doc(userId)
        );

        var userData = userDoc.data() as Map<String, dynamic>? ?? {};
        double currentIncome = (userData['totalIncome'] ?? 0).toDouble();
        double currentExpense = (userData['totalExpense'] ?? 0).toDouble();

        // Calculate new totals
        double newIncome = currentIncome + amount;
        double newBalance = newIncome - currentExpense;

        // Add transaction
        DocumentReference transactionRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc();

        transaction.set(transactionRef, {
          'id': transactionRef.id,
          'title': _titleController.text.trim(),
          'amount': amount,
          'category': widget.categoryName ?? 'Other',
          'note': _messageController.text.trim(),
          'date': Timestamp.fromDate(_selectedDate),
          'type': 'income',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update user totals
        transaction.update(
          _firestore.collection('users').doc(userId),
          {
            'balance': newBalance,
            'totalIncome': newIncome,
            'totalExpense': currentExpense,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Income added: ${_formatCurrency(amount)} đ'),
            backgroundColor: Colors.green,
          ),
        );
        
        await Future.delayed(const Duration(milliseconds: 300));
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: widget.categoryColor ?? const Color(0xFF4CAF50),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add Income',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top colored section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 30),
              decoration: BoxDecoration(
                color: widget.categoryColor ?? const Color(0xFF4CAF50),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: const SizedBox.shrink(),
            ),

            // Form section
            Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Date Field
                    _buildLabel('Date', isDark),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _selectDate(context),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM dd, yyyy').format(_selectedDate),
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: widget.categoryColor ?? const Color(0xFF4CAF50),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Category Field - ✅ FIXED OVERFLOW
                    _buildLabel('Category', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.categoryIcon ?? Icons.attach_money,
                            color: widget.categoryColor ?? const Color(0xFF4CAF50),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(  // ✅ FIX: Wrap with Expanded
                            child: Text(
                              widget.categoryName ?? 'Select Category',  // ✅ FIX: Proper default
                              style: TextStyle(
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                              overflow: TextOverflow.ellipsis,  // ✅ FIX: Handle long text
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: widget.categoryColor ?? const Color(0xFF4CAF50),
                            size: 24,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Amount Field
                    _buildLabel('Amount', isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        _VNDInputFormatter(),
                      ],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.categoryColor ?? const Color(0xFF4CAF50),
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        suffixText: 'đ',
                        suffixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.categoryColor ?? const Color(0xFF4CAF50),
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Income Title
                    _buildLabel('Income Title', isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _titleController,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Salary',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Message
                    _buildLabel('Enter Message (Optional)', isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _messageController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add notes (optional)',
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[600] : Colors.grey[400],
                        ),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF3C3C3C) : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveIncome,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.categoryColor ?? const Color(0xFF4CAF50),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
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
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? Colors.grey[400] : Colors.grey[700],
      ),
    );
  }
}

// ✅ VND Input Formatter
class _VNDInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final number = int.tryParse(newValue.text.replaceAll(',', ''));
    if (number == null) {
      return oldValue;
    }

    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}