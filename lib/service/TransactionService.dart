// lib/service/TransactionService.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:project1/models/Category_model.dart';
import 'package:uuid/uuid.dart';
import '../models/TransactionModel.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Uuid _uuid = const Uuid();

  String get uid => _auth.currentUser?.uid ?? "";

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _txRef =>
      _db.collection('users').doc(uid).collection('transactions');

  // Đảm bảo user doc có đủ các field trước khi update
  Future<void> ensureUserDoc() async {
    final uid = this.uid;
    if (uid.isEmpty) throw Exception("User not logged in.");

    final snap = await _userDoc.get();
    if (!snap.exists) {
      // ✅ FIX: Tạo đủ 3 fields ngay từ đầu
      await _userDoc.set({
        'balance': 0.0,
        'totalIncome': 0.0,
        'totalExpense': 0.0,
      });
    } else {
      final data = snap.data() ?? {};
      final Map<String, dynamic> missing = {};

      // ✅ FIX: Tự động thêm field nếu thiếu (cho user cũ)
      if (!data.containsKey('balance'))      missing['balance']      = 0.0;
      if (!data.containsKey('totalIncome'))  missing['totalIncome']  = 0.0;
      if (!data.containsKey('totalExpense')) missing['totalExpense'] = 0.0;

      if (missing.isNotEmpty) {
        await _userDoc.update(missing);
      }
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

    await _txRef.doc(id).set(tx.toMap());

    // ✅ FIX: Cập nhật cả balance VÀ totalIncome
    await _userDoc.update({
      'balance':     FieldValue.increment(amount.abs()),
      'totalIncome': FieldValue.increment(amount.abs()),
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

    // ✅ FIX: Cập nhật cả balance VÀ totalExpense
    await _userDoc.update({
      'balance':      FieldValue.increment(delta),
      'totalExpense': FieldValue.increment(amount.abs()),
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
    final data = snap.data() ?? {};

    return {
      "balance":      (data['balance']      as num?)?.toDouble() ?? 0.0,
      "totalIncome":  (data['totalIncome']  as num?)?.toDouble() ?? 0.0,
      "totalExpense": (data['totalExpense'] as num?)?.toDouble() ?? 0.0,
    };
  }

  // ✅ FIX DATA: Recalculate totalIncome & totalExpense từ transactions
  // Gọi hàm này 1 lần để sửa dữ liệu cũ bị sai
  Future<void> recalculateTotals() async {
    print('🔧 Recalculating totals from transactions...');

    final txSnap = await _txRef.get();
    double totalIncome  = 0.0;
    double totalExpense = 0.0;

    for (final doc in txSnap.docs) {
      final data = doc.data();
      final type   = data['type'] as String? ?? '';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

      if (type == 'income') {
        totalIncome += amount.abs();
      } else if (type == 'expense') {
        totalExpense += amount.abs();
      }
    }

    final balance = totalIncome - totalExpense;

    await _userDoc.update({
      'totalIncome':  totalIncome,
      'totalExpense': totalExpense,
      'balance':      balance,
    });

    print('✅ Recalculated → Income: $totalIncome | Expense: $totalExpense | Balance: $balance');
  }

  // ========================================
  // 🎤 VOICE INPUT METHODS
  // ========================================

  Future<bool> saveVoiceTransaction({
    required String type,
    required double amount,
    required String categoryName,
    required String note,
    DateTime? date,
  }) async {
    try {
      print('🎤 [Voice] Saving transaction...');
      print('   Type: $type');
      print('   Amount: $amount');
      print('   Category: $categoryName');
      print('   Note: $note');

      final category = await _getOrCreateCategory(categoryName, type);

      if (type == 'income') {
        await addIncome(
          category: category,
          amount: amount,
          title: note.isEmpty ? 'Voice transaction' : note,
          message: '🎤 Từ voice input',
          date: date ?? DateTime.now(),
        );
      } else {
        await addExpense(
          category: category,
          amount: amount,
          title: note.isEmpty ? 'Voice transaction' : note,
          message: '🎤 Từ voice input',
          date: date ?? DateTime.now(),
        );
      }

      print('✅ [Voice] Transaction saved successfully!');
      return true;
    } catch (e) {
      print('❌ [Voice] Error saving transaction: $e');
      return false;
    }
  }

  Future<CategoryModel> _getOrCreateCategory(String categoryName, String type) async {
    try {
      final categoriesSnap = await _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .where('type', isEqualTo: type)
          .limit(1)
          .get();

      if (categoriesSnap.docs.isNotEmpty) {
        final data = categoriesSnap.docs.first.data();
        print('📂 Found existing category: $categoryName');
        return CategoryModel.fromMap(data);
      }

      print('📂 Creating new category: $categoryName ($type)');

      final newCategoryId = _uuid.v4();
      final iconName  = _getDefaultIcon(categoryName);
      final colorHex  = _getDefaultColor(type);

      final CategoryModel newCategory;
      if (type == 'income') {
        newCategory = CategoryModel.income(
          id: newCategoryId,
          name: categoryName,
          iconName: iconName,
          colorHex: colorHex,
        );
      } else {
        newCategory = CategoryModel.expense(
          id: newCategoryId,
          name: categoryName,
          iconName: iconName,
          colorHex: colorHex,
        );
      }

      await _db
          .collection('users')
          .doc(uid)
          .collection('categories')
          .doc(newCategory.id)
          .set(newCategory.toMap());

      return newCategory;
    } catch (e) {
      print('⚠️ Error getting/creating category: $e');
      if (type == 'income') {
        return CategoryModel.income(
          id: 'default',
          name: categoryName,
          iconName: 'attach_money',
          colorHex: '4CAF50',
        );
      } else {
        return CategoryModel.expense(
          id: 'default',
          name: categoryName,
          iconName: 'category',
          colorHex: 'F44336',
        );
      }
    }
  }

  String _getDefaultIcon(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('food') || lower.contains('ăn') ||
        lower.contains('cà phê') || lower.contains('coffee') ||
        lower.contains('dining')) return 'restaurant';
    if (lower.contains('transport') || lower.contains('xe') ||
        lower.contains('grab') || lower.contains('taxi') ||
        lower.contains('car')) return 'directions_car';
    if (lower.contains('house') || lower.contains('housing') ||
        lower.contains('nhà') || lower.contains('phòng') ||
        lower.contains('home')) return 'home';
    if (lower.contains('shop') || lower.contains('mua') ||
        lower.contains('shopping')) return 'shopping_bag';
    if (lower.contains('health') || lower.contains('sức khỏe') ||
        lower.contains('healthcare') || lower.contains('medical')) return 'medical_services';
    if (lower.contains('education') || lower.contains('học') ||
        lower.contains('sách')) return 'school';
    if (lower.contains('entertainment') || lower.contains('vui chơi') ||
        lower.contains('phim') || lower.contains('game')) return 'movie';
    if (lower.contains('gym') || lower.contains('sport') ||
        lower.contains('thể thao')) return 'fitness_center';
    if (lower.contains('salary') || lower.contains('lương')) return 'attach_money';
    if (lower.contains('freelance')) return 'work';
    if (lower.contains('gift') || lower.contains('quà')) return 'card_giftcard';
    if (lower.contains('investment') || lower.contains('đầu tư')) return 'trending_up';
    return 'category';
  }

  String _getDefaultColor(String type) {
    return type == 'income' ? '4CAF50' : 'F44336';
  }
}