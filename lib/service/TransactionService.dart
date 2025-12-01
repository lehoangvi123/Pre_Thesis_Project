import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project1/models/Category_model.dart';
import 'package:uuid/uuid.dart';
import '../models/TransactionModel.dart';
import '../models/Category_model.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  String get uid => _auth.currentUser?.uid ?? "";

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _txRef =>
      _db.collection('users').doc(uid).collection('transactions');

  // Đảm bảo user doc có field balance tồn tại trước khi update
 Future<void> ensureUserDoc() async {
  final uid = this.uid; // use getter value
  if (uid.isEmpty) throw Exception("User not logged in");

  final snap = await _userDoc.get();
  if (!snap.exists) {
    await _userDoc.set({'balance': 0.0});
  } else if (!(snap.data()?.containsKey('balance') ?? false)) {
    await _userDoc.update({'balance': 0.0});
  } 
}


  // ➕ Thêm INCOME transaction
  Future<void> addIncome({
    required CategoryModel category,
    required double amount,
    required String title,
    String? message,
    required DateTime date,
  }) async {
    await ensureUserDoc();
    
    final id = _uuid.v4();

    final tx = TransactionModel(
      id: id,
      userId: uid,
      categoryId: category.id,
      categoryName: category.name,
      type: "income",
      amount: amount.abs(),
      title: title,
      message: message,
      date: date,
      createdAt: DateTime.now(),
      iconName: category.iconName,
      colorHex: category.colorHex,
      isIncome: true,
    );

   await _txRef.doc(id).set(tx.toMap()); // ✅ correct


    // Cộng số dư
    await _userDoc.update({
      'balance': FieldValue.increment(amount.abs()),
    });
  }

  // ➖ Thêm EXPENSE transaction
  Future<void> addExpense({
    required CategoryModel category,
    required double amount,
    required String title,
    String? message,
    required DateTime date,
  }) async {
    await ensureUserDoc();
    
    final id = _uuid.v4();
    final delta = -amount.abs();

    final tx = TransactionModel(
      id: id,
      userId: uid,
      categoryId: category.id,
      categoryName: category.name,
      type: "expense",
      amount: delta,
      title: title,
      message: message,
      date: date,
      createdAt: DateTime.now(),
      iconName: category.iconName,
      colorHex: category.colorHex,
      isIncome: false,
    );

    await _txRef.doc(id).set(tx.toMap());

    // Trừ balance
    await _userDoc.update({
      'balance': FieldValue.increment(delta),
    });
  }

  // 🔍 Stream realtime tất cả transactions của user
  Stream<List<TransactionModel>> streamUserTransactions() async* {
    await ensureUserDoc();
    yield* _txRef
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransactionModel.fromMap(d.data())).toList());
  }

  // 🔍 Stream chi tiêu theo 1 category bất kỳ
  Stream<List<TransactionModel>> streamCategoryExpenses(String categoryId) async* {
    await ensureUserDoc();
    yield* _txRef
        .where('categoryId', isEqualTo: categoryId)
        .where('type', isEqualTo: 'expense')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TransactionModel.fromMap(d.data())).toList());
  }

  // 📊 Trả về summary (income, expense, balance)
  Future<Map<String, double>> getBalance() async {
    await ensureUserDoc();
    final snap = await _userDoc.get();
    final currentBalance = (snap.data()?['balance'] as num?)?.toDouble() ?? 0.0;

    // Nếu cần thêm các thống kê khác bạn mở rộng loop ở đây
    return {
      "balance": currentBalance,
    };
  }
}
