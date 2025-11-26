import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/TransactionModel.dart';
import '../service/TransactionService.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<TransactionModel> _transactions = [];
  Map<String, double> _balanceSummary = {
    'totalIncome': 0,
    'totalExpense': 0,
    'balance': 0,
  };

  bool _isLoading = false;
  String? _error;

  // Getters
  List<TransactionModel> get transactions => _transactions;
  Map<String, double> get balanceSummary => _balanceSummary;
  double get totalIncome => _balanceSummary['totalIncome'] ?? 0;
  double get totalExpense => _balanceSummary['totalExpense'] ?? 0;
  double get balance => _balanceSummary['balance'] ?? 0;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// 📌 Lắng nghe transactions realtime từ Firestore của user
  void listenToTransactions(String userId) {
    _isLoading = true;
    notifyListeners();

    _db.collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) async {
      
      _transactions = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.data()))
          .toList();

      await _calculateBalance(userId);
      _isLoading = false;
      notifyListeners();
    });
  }

  /// ⚡ Tính lại số dư và thống kê Total Income / Total Expense
  Future<void> _calculateBalance(String userId) async {
    double income = 0;
    double expense = 0;

    for (var tx in _transactions) {
      if (tx.type == "income") {
        income += tx.amount;
      } else {
        expense += tx.amount; // Lưu chi tiêu đã âm sẵn trong model
      }
    }

    double newBalance = income + expense;

    _balanceSummary = {
      'totalIncome': income,
      'totalExpense': expense.abs(),
      'balance': newBalance,
    };

    await _transactionService.ensureUserBalance(userId);
  } 

  

  /// ➕ Thêm Income
  Future<bool> addIncome({
    required String userId,
    required String categoryId,
    required String categoryName,
    required double amount,
    required String title,
    String? message,
    DateTime? date,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final tx = TransactionModel(
        id: _db.collection('tmp').doc().id,
        userId: userId,
        categoryId: categoryId,
        categoryName: categoryName,
        type: "income",
        amount: amount.abs(),
        title: title,
        message: message,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        isIncome: true,
      );

      await _db.collection('users').doc(userId).collection('transactions').doc(tx.id).set(tx.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// ➖ Thêm Expense
  Future<bool> addExpense({
    required String userId,
    required String categoryId,
    required String categoryName,
    required double amount,
    required String title,
    String? message,
    DateTime? date,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final tx = TransactionModel(
        id: _db.collection('tmp').doc().id,
        userId: userId,
        categoryId: categoryId,
        categoryName: categoryName,
        type: "expense",
        amount: -amount.abs(),
        title: title,
        message: message,
        date: date ?? DateTime.now(),
        createdAt: DateTime.now(),
        isIncome: false,
      );

      await _db.collection('users').doc(userId).collection('transactions').doc(tx.id).set(tx.toMap());

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 🗑 Xóa transaction
  Future<bool> deleteTransaction(String userId, String txId) async {
    try {
      await _db.collection('users').doc(userId).collection('transactions').doc(txId).delete();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // ✏ Update transaction
  Future<bool> updateTransaction(String userId, TransactionModel transaction) async {
    try {
      await _db.collection('users').doc(userId).collection('transactions').doc(transaction.id).update(
        transaction.toMap(),
      );
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 💰 Load spending of 1 category nếu cần hiển thị riêng
  Future<double> getCategorySpending(String categoryId) async { 
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return await _transactionService.getCategoryExpenseTotal(uid, categoryId);
  }
}
