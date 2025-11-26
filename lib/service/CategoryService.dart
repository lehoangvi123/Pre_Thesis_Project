import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';

class CategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _categoriesCollection =>
      _firestore.collection('categories');

  String get _userId => _auth.currentUser!.uid;

  // Initialize default categories for new users
  Future<void> initializeDefaultCategories() async {
    final defaultCategories = _getDefaultCategories();
    
    for (var category in defaultCategories) {
      await _categoriesCollection.doc(category.id).set(category.toMap());
    }
  }

  // Get default categories list
  List<CategoryModel> _getDefaultCategories() {
    final userId = _userId;
    final now = DateTime.now();

    return [
      // Expense Categories
      CategoryModel(
        id: 'exp_food_$userId',
        name: 'Food',
        type: 'expense',
        iconName: 'restaurant',
        colorHex: '#FF6B6B',
        budgetLimit: 5000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_transport_$userId',
        name: 'Transport',
        type: 'expense',
        iconName: 'directions_bus',
        colorHex: '#4ECDC4',
        budgetLimit: 2000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_medicine_$userId',
        name: 'Medicine',
        type: 'expense',
        iconName: 'medical_services',
        colorHex: '#45B7D1',
        budgetLimit: 1000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_groceries_$userId',
        name: 'Groceries',
        type: 'expense',
        iconName: 'shopping_bag',
        colorHex: '#96CEB4',
        budgetLimit: 3000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_rent_$userId',
        name: 'Rent',
        type: 'expense',
        iconName: 'home',
        colorHex: '#FFEAA7',
        budgetLimit: 10000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_gifts_$userId',
        name: 'Gifts',
        type: 'expense',
        iconName: 'card_giftcard',
        colorHex: '#DFE6E9',
        budgetLimit: 1000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_savings_$userId',
        name: 'Savings',
        type: 'expense',
        iconName: 'savings',
        colorHex: '#74B9FF',
        budgetLimit: 5000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_entertainment_$userId',
        name: 'Entertainment',
        type: 'expense',
        iconName: 'movie',
        colorHex: '#A29BFE',
        budgetLimit: 2000000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'exp_notebook_$userId',
        name: 'Notebook',
        type: 'expense',
        iconName: 'menu_book',
        colorHex: '#FD79A8',
        budgetLimit: 500000,
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),

      // Income Categories
      CategoryModel(
        id: 'inc_salary_$userId',
        name: 'Salary',
        type: 'income',
        iconName: 'account_balance_wallet',
        colorHex: '#00B894',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'inc_freelance_$userId',
        name: 'Freelance',
        type: 'income',
        iconName: 'work',
        colorHex: '#00CEC9',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'inc_investment_$userId',
        name: 'Investment',
        type: 'income',
        iconName: 'trending_up',
        colorHex: '#81C784',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'inc_money_paper_$userId',
        name: 'Money paper',
        type: 'income',
        iconName: 'description',
        colorHex: '#A5D6A7',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
      CategoryModel(
        id: 'inc_money_forgot_$userId',
        name: 'Money I got...',
        type: 'income',
        iconName: 'card_giftcard',
        colorHex: '#C8E6C9',
        isDefault: true,
        userId: userId,
        createdAt: now,
      ),
    ];
  }

  // Get all categories for current user
  Stream<List<CategoryModel>> getUserCategories() {
    return _categoriesCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get categories by type
  Stream<List<CategoryModel>> getCategoriesByType(String type) {
    return _categoriesCollection
        .where('userId', isEqualTo: _userId)
        .where('type', isEqualTo: type)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromMap(doc.data() as Map<String, dynamic>))
            .toList());
  }

  // Get single category
  Future<CategoryModel?> getCategory(String categoryId) async {
    final doc = await _categoriesCollection.doc(categoryId).get();
    if (doc.exists) {
      return CategoryModel.fromMap(doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // Add custom category
  Future<void> addCategory(CategoryModel category) async {
    await _categoriesCollection.doc(category.id).set(category.toMap());
  }

  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    await _categoriesCollection.doc(category.id).update(category.toMap());
  }

  // Delete category
  Future<void> deleteCategory(String categoryId) async {
    final category = await getCategory(categoryId);
    if (category != null && !category.isDefault) {
      await _categoriesCollection.doc(categoryId).delete();
      await _reassignTransactions(categoryId);
    }
  }

  // Reassign transactions when category is deleted
  Future<void> _reassignTransactions(String oldCategoryId) async {
    final transactions = await _firestore
        .collection('transactions')
        .where('categoryId', isEqualTo: oldCategoryId)
        .get();

    for (var doc in transactions.docs) {
      await doc.reference.update({'categoryId': 'other'});
    }
  }

  // Get category statistics
  Future<Map<String, dynamic>> getCategoryStats(String categoryId) async {
    final transactions = await _firestore
        .collection('transactions')
        .where('userId', isEqualTo: _userId)
        .where('categoryId', isEqualTo: categoryId)
        .get();

    double totalAmount = 0;
    int transactionCount = transactions.docs.length;

    for (var doc in transactions.docs) {
      totalAmount += (doc.data()['amount'] as num).toDouble();
    }

    final category = await getCategory(categoryId);
    double percentageUsed = 0;
    
    if (category != null && category.budgetLimit > 0) {
      percentageUsed = (totalAmount / category.budgetLimit) * 100;
    }

    return {
      'totalAmount': totalAmount,
      'transactionCount': transactionCount,
      'budgetLimit': category?.budgetLimit ?? 0,
      'percentageUsed': percentageUsed,
      'remainingBudget': (category?.budgetLimit ?? 0) - totalAmount,
    };
  }
}