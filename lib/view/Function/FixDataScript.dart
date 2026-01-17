// FIX_DATA_SCRIPT.dart
// Chạy script này 1 lần để fix data cũ đã bị sai

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FixDataScreen extends StatefulWidget {
  const FixDataScreen({Key? key}) : super(key: key);

  @override
  State<FixDataScreen> createState() => _FixDataScreenState();
}

class _FixDataScreenState extends State<FixDataScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool isFixing = false;
  String status = 'Chưa fix';
  String details = '';

  Future<void> _fixExistingData() async {
    setState(() {
      isFixing = true;
      status = 'Đang fix...';
      details = '';
    });

    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          status = 'Lỗi: Chưa đăng nhập';
          isFixing = false;
        });
        return;
      }

      String log = '';

      // STEP 1: Fix negative amounts in transactions
      log += '=== BƯỚC 1: Fix Negative Amounts ===\n';
      final transactions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      int fixedCount = 0;
      for (var doc in transactions.docs) {
        double amount = (doc.data()['amount'] as num).toDouble();
        
        if (amount < 0) {
          // Fix: Make positive
          await doc.reference.update({
            'amount': amount.abs(),
          });
          fixedCount++;
          log += '  - Fixed transaction ${doc.id}: $amount → ${amount.abs()}\n';
        }
      }
      log += 'Fixed $fixedCount negative amounts\n\n';

      // STEP 2: Recalculate totals from ALL transactions
      log += '=== BƯỚC 2: Recalculate Totals ===\n';
      double totalIncome = 0;
      double totalExpense = 0;
      int incomeCount = 0;
      int expenseCount = 0;

      final allTransactions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .get();

      for (var doc in allTransactions.docs) {
        double amount = (doc.data()['amount'] as num).abs().toDouble();
        String type = doc.data()['type'] ?? 'expense';

        if (type == 'income') {
          totalIncome += amount;
          incomeCount++;
        } else {
          totalExpense += amount;
          expenseCount++;
        }
      }

      double balance = totalIncome - totalExpense;

      log += 'Total Income: ${_formatCurrency(totalIncome)} ($incomeCount transactions)\n';
      log += 'Total Expense: ${_formatCurrency(totalExpense)} ($expenseCount transactions)\n';
      log += 'Balance: ${_formatCurrency(balance)}\n\n';

      // STEP 3: Update user document
      log += '=== BƯỚC 3: Update User Document ===\n';
      await _firestore.collection('users').doc(userId).update({
        'balance': balance,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      log += 'User document updated!\n\n';

      // STEP 4: Verify
      log += '=== BƯỚC 4: Verify ===\n';
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      
      log += 'Database Balance: ${_formatCurrency((userData['balance'] ?? 0).toDouble())}\n';
      log += 'Database Income: ${_formatCurrency((userData['totalIncome'] ?? 0).toDouble())}\n';
      log += 'Database Expense: ${_formatCurrency((userData['totalExpense'] ?? 0).toDouble())}\n';

      setState(() {
        status = '✅ Fix thành công!';
        details = log;
        isFixing = false;
      });

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('✅ Fix thành công!'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Income: ${_formatCurrency(totalIncome)}'),
                  Text('Expense: ${_formatCurrency(totalExpense)}'),
                  Text('Balance: ${_formatCurrency(balance)}'),
                  const SizedBox(height: 16),
                  const Text(
                    'Data đã được sửa! Bạn có thể quay lại app.',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }

    } catch (e) {
      setState(() {
        status = '❌ Lỗi: ${e.toString()}';
        isFixing = false;
      });
    }
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

  @override
  Widget build(BuildContext context) {
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
          'Fix Data Script',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Warning card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Cảnh báo',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Script này sẽ:\n'
                      '• Fix tất cả amount âm thành dương\n'
                      '• Tính lại tổng income/expense\n'
                      '• Cập nhật balance\n\n'
                      'Chỉ chạy 1 lần!',
                      style: TextStyle(height: 1.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status
              Text(
                'Trạng thái:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2C2C2C)
                      : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 15,
                    color: status.contains('✅')
                        ? Colors.green
                        : status.contains('❌')
                            ? Colors.red
                            : Colors.grey,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Details log
              if (details.isNotEmpty) ...[
                Text(
                  'Chi tiết:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2C2C2C)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    details,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.grey[400]
                          : Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Fix button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isFixing ? null : _fixExistingData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00CED1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isFixing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          '🔧 Fix Data Now',
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
    );
  }
}