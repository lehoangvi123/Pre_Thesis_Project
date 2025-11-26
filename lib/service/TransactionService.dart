import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/TransactionModel.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  User? get currentUser => _auth.currentUser;
  String get userId => currentUser!.uid;

  /// 📌 Collection đúng nơi cho 1 user: users/{uid}/transactions
  CollectionReference<Map<String, dynamic>> transactionsRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('transactions');

  /// 💾 Đảm bảo user có document balance
  Future<void> ensureUserBalance(String uid) async {
    final ref = _firestore.collection('users').doc(uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({'balance': 0.0});
    }
  }

  /// ➕ Add Income
  Future<void> addIncome({
    required String userId,
    required double amount,
    required String title,
    required String categoryId,
    required String categoryName,
    String? message,
    DateTime? date,
    String? iconName,
    String? colorHex,
  }) async {
    final uid = this.userId;
    await ensureUserBalance(uid);

    final tx = TransactionModel(
      id: _uuid.v4(),
      userId: uid,
      categoryId: categoryId,
      categoryName: categoryName,
      type: "income",
      amount: amount.abs(),
      title: title,
      message: message,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      iconName: iconName,
      colorHex: colorHex,
      isIncome: true,
    );

    await transactionsRef(uid).doc(tx.id).set(tx.toMap());
    await _applyDeltaToBalance(uid, tx.amount);
  }

  /// ➖ Add Expense
  Future<void> addExpense({
    required String userId,
    required double amount,
    required String title,
    required String categoryId,
    required String categoryName,
    String? message,
    DateTime? date,
    String? iconName,
    String? colorHex,
  }) async {
    final uid = this.userId;
    await ensureUserBalance(uid);

    final tx = TransactionModel(
      id: _uuid.v4(),
      userId: uid,
      categoryId: categoryId,
      categoryName: categoryName,
      type: "expense",
      amount: -amount.abs(),
      title: title,
      message: message,
      date: date ?? DateTime.now(),
      createdAt: DateTime.now(),
      iconName: iconName,
      colorHex: colorHex,
      isIncome: false,
    );

    await transactionsRef(uid).doc(tx.id).set(tx.toMap());
    await _applyDeltaToBalance(uid, tx.amount);
  }

  /// 💰 Cộng/trừ balance dựa trên delta âm/dương có sẵn
  Future<void> _applyDeltaToBalance(String uid, double delta) async {
    await ensureUserBalance(uid);
    await _firestore.collection('users').doc(uid).update({
      'balance': FieldValue.increment(delta),
    });
  }

  /// 📊 Stream realtime của 1 user
  Stream<List<TransactionModel>> streamUserTransactions(String uid) {
    return transactionsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => TransactionModel.fromMap(doc.data())).toList());
  }

  /// ✏ Update
  Future<void> updateTransaction(String uid, TransactionModel tx) async {
    await transactionsRef(uid).doc(tx.id).update(tx.toMap());
  }

  /// 🗑 Delete
  Future<void> deleteTransaction(String uid, String txId) async {
    await transactionsRef(uid).doc(txId).delete();
  }

  /// 🥧 Total spent của 1 category expense
  Future<double> getCategoryExpenseTotal(String uid, String categoryId) async {
    final snap = await transactionsRef(uid)
        .where('categoryId', isEqualTo: categoryId)
        .where('type', isEqualTo: 'expense')
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      total += (doc.data()['amount'] as num).toDouble();
    }
    return total;
  }
}

