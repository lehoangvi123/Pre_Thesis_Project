import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/TransactionModel.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // ✅ Thêm transaction và tự động update balance
  Future<void> addTransaction(String userId, TransactionModel tx) async {
    try {
      // 1. Thêm transaction vào subcollection
      await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(tx.id)
          .set(tx.toJson());

      // 2. Lấy totals hiện tại (KHÔNG lấy balance)
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
      var userData = (userDoc.data() as Map<String, dynamic>?) ?? {};
      double currentIncome = (userData['totalIncome'] ?? 0).toDouble();
      double currentExpense = (userData['totalExpense'] ?? 0).toDouble();

      // 3. Cập nhật totals dựa trên type
      double newIncome = currentIncome;
      double newExpense = currentExpense;

      if (tx.type.toLowerCase() == 'income') {
        newIncome += tx.amount;
      } else if (tx.type.toLowerCase() == 'expense') {
        newExpense += tx.amount;
      }

      // 4. Tính balance từ công thức: Balance = Income - Expense
      double newBalance = newIncome - newExpense;

      // 5. Update user document
      await _db.collection('users').doc(userId).update({
        'balance': newBalance,
        'totalIncome': newIncome,
        'totalExpense': newExpense,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Transaction added.');
      print('   Income: $newIncome, Expense: $newExpense, Balance: $newBalance');
    } catch (e) {
      print('❌ Error adding transaction: $e');
      rethrow;
    }
  }

  // ✅ Xóa transaction và cập nhật balance
  Future<void> deleteTransaction(String userId, TransactionModel tx) async {
    try {
      // 1. Xóa transaction
      await _db
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(tx.id)
          .delete();

      // 2. Lấy totals hiện tại
      DocumentSnapshot userDoc = await _db.collection('users').doc(userId).get();
      var userData = (userDoc.data() as Map<String, dynamic>?) ?? {};
      double currentIncome = (userData['totalIncome'] ?? 0).toDouble();
      double currentExpense = (userData['totalExpense'] ?? 0).toDouble();

      // 3. Hoàn tác số tiền
      double newIncome = currentIncome;
      double newExpense = currentExpense;

      if (tx.type.toLowerCase() == 'income') {
        newIncome -= tx.amount;
      } else if (tx.type.toLowerCase() == 'expense') {
        newExpense -= tx.amount;
      }

      // 4. Tính lại balance
      double newBalance = newIncome - newExpense;

      // 5. Update
      await _db.collection('users').doc(userId).update({
        'balance': newBalance,
        'totalIncome': newIncome,
        'totalExpense': newExpense,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Transaction deleted.');
      print('   Income: $newIncome, Expense: $newExpense, Balance: $newBalance');
    } catch (e) {
      print('❌ Error deleting transaction: $e');
      rethrow;
    }
  }

  // ✅ Update transaction (xóa cũ + thêm mới)
  Future<void> updateTransaction(
    String userId,
    TransactionModel oldTx,
    TransactionModel newTx,
  ) async {
    try {
      await deleteTransaction(userId, oldTx);
      await addTransaction(userId, newTx);
      print('✅ Transaction updated successfully');
    } catch (e) {
      print('❌ Error updating transaction: $e');
      rethrow;
    }
  }

  // ✅ Lấy balance từ Firestore
  Future<double> getBalance(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return (doc.data()?['balance'] ?? 0).toDouble();
    } catch (e) {
      print('Error getting balance: $e');
      return 0.0;
    }
  }

  // ✅ Lấy total income
  Future<double> getTotalIncome(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return (doc.data()?['totalIncome'] ?? 0).toDouble();
    } catch (e) {
      print('Error getting total income: $e');
      return 0.0;
    }
  }

  // ✅ Lấy total expense
  Future<double> getTotalExpense(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return (doc.data()?['totalExpense'] ?? 0).toDouble();
    } catch (e) {
      print('Error getting total expense: $e');
      return 0.0;
    }
  }

  // ✅ Stream để realtime update
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db.collection('users').doc(userId).snapshots();
  }

  // ✅ Stream transactions
  Stream<QuerySnapshot> getTransactionsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }

  // ✅ Generate unique ID
  String generateId() => _uuid.v4();

  // ✅ Khởi tạo balance cho user mới (gọi khi đăng ký)
  Future<void> initializeUserBalance(String userId) async {
    try {
      await _db.collection('users').doc(userId).update({
        'balance': 0.0,
        'totalIncome': 0.0,
        'totalExpense': 0.0,
      });
    } catch (e) {
      print('Error initializing balance: $e');
    }
  }
}