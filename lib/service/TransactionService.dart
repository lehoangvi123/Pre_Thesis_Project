import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/TransactionModel.dart';
import '../models/category_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = Uuid();

  String get _userId => _auth.currentUser!.uid;

  CollectionReference get _transactionsCollection =>
      _firestore.collection('transactions');

  // Add new transaction
  Future<void> addTransaction({
    required CategoryModel category,
    required double amount,
    required String title,
    String? message,
    required DateTime date,
  }) async {
    final transaction = TransactionModel(
      id: _uuid.v4(),
      userId: _userId,
      categoryId: category.id,
      categoryName: category.name,
      type: category.type,
      amount: amount,
      title: title,
      message: message,
      date: date,
      createdAt: DateTime.now(),
      iconName: category.iconName,
      colorHex: category.colorHex,
    );

    await _transactionsCollection.doc(transaction.id).set(transaction.toMap());
  }

  // Get all transactions for user
  Stream<List<TransactionModel>> getUserTransactions() {
    return _transactionsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get transactions by category
  Stream<List<TransactionModel>> getTransactionsByCategory(String categoryId) {
    return _transactionsCollection
        .where('userId', isEqualTo: _userId)
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get transactions by type (income/expense)
  Stream<List<TransactionModel>> getTransactionsByType(String type) {
    return _transactionsCollection
        .where('userId', isEqualTo: _userId)
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Update transaction
  Future<void> updateTransaction(TransactionModel transaction) async {
    await _transactionsCollection.doc(transaction.id).update(transaction.toMap());
  }

  // Delete transaction
  Future<void> deleteTransaction(String transactionId) async {
    await _transactionsCollection.doc(transactionId).delete();
  }

  // Get balance summary
  Future<Map<String, double>> getBalanceSummary() async {
    final transactions = await _transactionsCollection
        .where('userId', isEqualTo: _userId)
        .get();

    double totalIncome = 0;
    double totalExpense = 0;

    for (var doc in transactions.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final type = data['type'] as String;
      final amount = (data['amount'] as num).toDouble();

      if (type == 'income') {
        totalIncome += amount;
      } else if (type == 'expense') {
        totalExpense += amount;
      }
    }

    return {
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
      'balance': totalIncome - totalExpense,
    };
  }

  // Get category spending
  Future<double> getCategorySpending(String categoryId) async {
    final transactions = await _transactionsCollection
        .where('userId', isEqualTo: _userId)
        .where('categoryId', isEqualTo: categoryId)
        .where('type', isEqualTo: 'expense')
        .get();

    double total = 0;
    for (var doc in transactions.docs) {
      total += ((doc.data() as Map<String, dynamic>)['amount'] as num).toDouble();
    }

    return total;
  }
}