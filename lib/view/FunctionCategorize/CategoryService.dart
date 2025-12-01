import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/Category_model.dart';

class CategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? "";

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      _db.collection('users').doc(_uid);

  CollectionReference<Map<String, dynamic>> get _catRef =>
      _db.collection('users').doc(_uid).collection('categories');

  // Initialize default categories for new users
  Future<void> initializeDefaultCategories() async {
    if (_uid.isEmpty) throw Exception("User not logged in");

    final cats = _getDefaultCategories();

    await _db.runTransaction((tx) async {
      for (var c in cats) {
        tx.set(_catRef.doc(c.id), c.toMap());
      }
    });
  }

  // Get default categories list
 List<CategoryModel> _getDefaultCategories() {
  final userId = _uid;

  return [
    // 💸 Expense Categories
    CategoryModel.expense(
      id: 'exp_food_$userId',
      name: 'Food',
      iconName: 'restaurant',
      colorHex: '#FF6B6B',
    ),
    CategoryModel.expense(
      id: 'exp_transport_$userId',
      name: 'Transport',
      iconName: 'directions_bus',
      colorHex: '#4ECDC4',
    ),
    CategoryModel.expense(
      id: 'exp_medicine_$userId',
      name: 'Medicine',
      iconName: 'medical_services',
      colorHex: '#45B7D1',
    ),
    CategoryModel.expense(
      id: 'exp_savings_$userId',
      name: 'Savings',
      iconName: 'savings',
      colorHex: '#74B9FF',
    ),

    // 💰 Income Categories
    CategoryModel.income(
      id: 'inc_salary_$userId',
      name: 'Salary',
      iconName: 'account_balance_wallet',
      colorHex: '#00B894',
    ),
    CategoryModel.income(
      id: 'inc_freelance_$userId',
      name: 'Freelance',
      iconName: 'work',
      colorHex: '#00CEC9',
    ),
  ];
}

  // 💎 Stream realtime categories của user
  Stream<List<CategoryModel>> getUserCategories() async* {
    if (_uid.isEmpty) {
      yield [];
      return;
    }

    yield* _catRef.orderBy('name').snapshots().map(
          (snap) => snap.docs.map((d) =>
              CategoryModel.fromMap(d.data())).toList(),
        );
  }

  // 🧾 Stream categories theo type
  Stream<List<CategoryModel>> getCategoriesByType(String type) async* {
    if (_uid.isEmpty) {
      yield [];
      return;
    }

    yield* _catRef
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => CategoryModel.fromMap(doc.data()))
            .toList());
  }

  // 🔍 Lấy 1 category
  Future<CategoryModel?> getCategory(String catId) async {
    if (_uid.isEmpty) return null;
    final doc = await _catRef.doc(catId).get();
    if (!doc.exists) return null;
    return CategoryModel.fromMap(doc.data()!);
  }

  // ➕ Thêm category tự tạo
  Future<void> addCategory(CategoryModel c) async {
    if (_uid.isEmpty) throw Exception("User not logged in");
    await _catRef.doc(c.id).set(c.toMap());
  }

  // ✏ Update category
  Future<void> updateCategory(CategoryModel c) async {
    if (_uid.isEmpty) throw Exception("User not logged in");
    await _catRef.doc(c.id).update(c.toMap());
  }

  // ❌ Xoá category + reassign transactions
  Future<void> deleteCategory(String catId) async {
    final c = await getCategory(catId);
    if (c == null) return;

    await _catRef.doc(catId).delete();
    await _reassignTransactions(catId);
  }

  // 🔁 Update lại categoryId trong transactions của user
  Future<void> _reassignTransactions(String oldCatId) async {
    if (_uid.isEmpty) return;

    final snap = await _db
        .collection('users').doc(_uid)
        .collection('transactions')
        .where('categoryId', isEqualTo: oldCatId)
        .get();

    for (var doc in snap.docs) {
      await doc.reference.update({'categoryId': 'other'});
    }
  }
}
