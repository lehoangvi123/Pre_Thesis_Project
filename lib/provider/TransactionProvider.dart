import 'package:flutter/material.dart';
import '../models/TransactionModel.dart';
import '../service/TransactionService.dart';
import '../models/Category_model.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();

  List<TransactionModel> txs = [];
  double balance = 0;
  bool loading = false;
  String? err;

  void listenAll() async {
    try {
      loading = true;
      notifyListeners();

      _service.streamUserTransactions().listen((data) async {
        txs = data;

        final summary = await _service.getBalance();
        balance = summary["balance"] ?? 0;

        notifyListeners();
      });

    } catch (e) {
      err = e.toString();
      notifyListeners();
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense({
    required String categoryId,
    required double amount,
    required String title,
    String? message,
    required DateTime date,
  }) async {
    await _service.addExpense(
  category: CategoryModel.expense(
    id: categoryId,
    name: categoryId,
    iconName: "",
    colorHex: "",
  ),
  amount: amount,
  title: title,
  message: message,
  date: date,
);

  }

  Future<void> addIncome({
    required String categoryId,
    required double amount,
    required String title,
    String? message,
    required DateTime date,
  }) async {
    await _service.addIncome(
  category: CategoryModel.income(
    id: categoryId,
    name: categoryId,
    iconName: "",
    colorHex: "",
  ),
  amount: amount,
  title: title,
  message: message,
  date: date,
);

  }

  Stream<List<TransactionModel>> watchCategoryExpenses(String categoryId) =>
      _service.streamCategoryExpenses(categoryId);
}
