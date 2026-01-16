// lib/service/TransactionService.dart
// THÊM METHODS NÀY VÀO FILE TRANSACTIONSERVICE CÓ SẴN

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

  // Đảm bảo user doc có field balance tồn tại trước khi update
  Future<void> ensureUserDoc() async {
    final uid = this.uid;
    if (uid.isEmpty) throw Exception("User not logged in.");

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

    await _txRef.doc(id).set(tx.toMap());

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

    return {
      "balance": currentBalance,
    };
  }

  // ========================================
  // 🎤 VOICE INPUT METHODS (THÊM MỚI)
  // ========================================

  /// 🎤 Save voice transaction - wrapper cho addIncome/addExpense
  // lib/service/TransactionService.dart
// FIXED VERSION - Tương thích với CategoryModel có sẵn

// ========================================
// 🎤 VOICE INPUT METHODS (THÊM VÀO CUỐI CLASS)
// ========================================

/// 🎤 Save voice transaction
Future<bool> saveVoiceTransaction({
  required String type,        // 'income' hoặc 'expense'
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

    // 1. Tìm hoặc tạo category
    final category = await _getOrCreateCategory(categoryName, type);
    
    // 2. Lưu transaction dùng methods có sẵn
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

/// Tìm category theo tên, hoặc tạo mới nếu chưa có
Future<CategoryModel> _getOrCreateCategory(String categoryName, String type) async {
  try {
    // Lấy tất cả categories của user theo type
    final categoriesSnap = await _db
        .collection('users')
        .doc(uid)
        .collection('categories')
        .where('name', isEqualTo: categoryName)
        .where('type', isEqualTo: type)
        .limit(1)
        .get();

    // Nếu tìm thấy category
    if (categoriesSnap.docs.isNotEmpty) {
      final data = categoriesSnap.docs.first.data();
      print('📂 Found existing category: $categoryName');
      return CategoryModel.fromMap(data);
    }

    // Nếu không có, tạo category mới
    print('📂 Creating new category: $categoryName ($type)');
    
    final newCategoryId = _uuid.v4();
    final iconName = _getDefaultIcon(categoryName);
    final colorHex = _getDefaultColor(type);
    
    // Dùng factory constructor phù hợp
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

    // Lưu category mới vào Firestore
    await _db
        .collection('users')
        .doc(uid)
        .collection('categories')
        .doc(newCategory.id)
        .set(newCategory.toMap());

    return newCategory;
    
  } catch (e) {
    print('⚠️ Error getting/creating category: $e');
    
    // Fallback: return default category
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

/// Get default icon dựa trên tên category
String _getDefaultIcon(String categoryName) {
  final lower = categoryName.toLowerCase();
  
  // Food & Dining
  if (lower.contains('food') || 
      lower.contains('ăn') || 
      lower.contains('cà phê') ||
      lower.contains('coffee') ||
      lower.contains('dining')) {
    return 'restaurant';
  }
  
  // Transportation
  if (lower.contains('transport') || 
      lower.contains('xe') || 
      lower.contains('grab') ||
      lower.contains('taxi') ||
      lower.contains('car')) {
    return 'directions_car';
  }
  
  // Housing
  if (lower.contains('house') || 
      lower.contains('housing') || 
      lower.contains('nhà') ||
      lower.contains('phòng') ||
      lower.contains('home')) {
    return 'home';
  }
  
  // Shopping
  if (lower.contains('shop') || 
      lower.contains('mua') ||
      lower.contains('shopping')) {
    return 'shopping_bag';
  }
  
  // Healthcare
  if (lower.contains('health') || 
      lower.contains('sức khỏe') ||
      lower.contains('healthcare') ||
      lower.contains('medical')) {
    return 'medical_services';
  }
  
  // Education
  if (lower.contains('education') || 
      lower.contains('học') ||
      lower.contains('sách')) {
    return 'school';
  }
  
  // Entertainment
  if (lower.contains('entertainment') ||
      lower.contains('vui chơi') ||
      lower.contains('phim') ||
      lower.contains('game')) {
    return 'movie';
  }
  
  // Gym & Sports
  if (lower.contains('gym') ||
      lower.contains('sport') ||
      lower.contains('thể thao')) {
    return 'fitness_center';
  }
  
  // Income categories
  if (lower.contains('salary') || lower.contains('lương')) {
    return 'attach_money';
  }
  
  if (lower.contains('freelance')) {
    return 'work';
  }
  
  if (lower.contains('gift') || lower.contains('quà')) {
    return 'card_giftcard';
  }
  
  if (lower.contains('investment') || lower.contains('đầu tư')) {
    return 'trending_up';
  }
  
  // Default
  return 'category';
}

/// Get default color dựa trên type
String _getDefaultColor(String type) {
  // Green cho income, Red cho expense (hex without #)
  return type == 'income' ? '4CAF50' : 'F44336';
}
}