import 'package:flutter/material.dart';
import '../models/TransactionModel.dart';
import '../models/category_model.dart';
import '../service/TransactionService.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _transactionService = TransactionService();

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

  // Load all transactions
  void loadTransactions() {
    _transactionService.getUserTransactions().listen((transactions) {
      _transactions = transactions;
      _updateBalanceSummary();
      notifyListeners();
    });
  }

  // Load transactions by category
  void loadTransactionsByCategory(String categoryId) {
    _transactionService.getTransactionsByCategory(categoryId).listen((transactions) {
      _transactions = transactions;
      notifyListeners();
    });
  }

  // Add transaction
  Future<bool> addTransaction({
    required CategoryModel category,
    required double amount,
    required String title,
    String? message,
    required DateTime date,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _transactionService.addTransaction(
        category: category,
        amount: amount,
        title: title,
        message: message,
        date: date,
      );

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

  // Update transaction
  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      await _transactionService.updateTransaction(transaction);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete transaction
  Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _transactionService.deleteTransaction(transactionId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Update balance summary
  Future<void> _updateBalanceSummary() async {
    _balanceSummary = await _transactionService.getBalanceSummary();
    notifyListeners();
  }

  // Get category spending
  Future<double> getCategorySpending(String categoryId) async {
    return await _transactionService.getCategorySpending(categoryId);
  }

  // Get transactions for specific category
  List<TransactionModel> getTransactionsForCategory(String categoryId) {
    return _transactions.where((t) => t.categoryId == categoryId).toList();
  }
}