// lib/service/budget_service.dart
// Budget Service - FIXED: Không cần composite index

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './budget_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  CollectionReference get _budgetsCollection =>
      _firestore.collection('budgets');

  // CREATE
  Future<String> createBudget(BudgetModel budget) async {
    try {
      final docRef = await _budgetsCollection.add(budget.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo ngân sách: $e');
    }
  }

  // READ: Active budgets - FIX: bỏ orderBy để tránh lỗi index
  Stream<List<BudgetModel>> getActiveBudgets() {
    final now = DateTime.now();

    return _budgetsCollection
        .where('userId', isEqualTo: _userId)
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        // ❌ Bỏ .orderBy('endDate') để tránh lỗi Firestore index
        .snapshots()
        .asyncMap((snapshot) async {
      List<BudgetModel> budgets = [];

      for (var doc in snapshot.docs) {
        final budget = BudgetModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        final spent = await _calculateSpentAmount(
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );

        budgets.add(budget.copyWith(spentAmount: spent));
      }

      // ✅ Sort ở client thay vì Firestore
      budgets.sort((a, b) => a.endDate.compareTo(b.endDate));

      return budgets;
    });
  }

  // READ: Tất cả budgets
  Stream<List<BudgetModel>> getBudgets() {
    return _budgetsCollection
        .where('userId', isEqualTo: _userId)
        // ❌ Bỏ .orderBy('createdAt') để tránh lỗi index
        .snapshots()
        .asyncMap((snapshot) async {
      List<BudgetModel> budgets = [];

      for (var doc in snapshot.docs) {
        final budget = BudgetModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        final spent = await _calculateSpentAmount(
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );

        budgets.add(budget.copyWith(spentAmount: spent));
      }

      // ✅ Sort ở client
      budgets.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return budgets;
    });
  }

  // READ by ID
  Future<BudgetModel?> getBudgetById(String budgetId) async {
    try {
      final doc = await _budgetsCollection.doc(budgetId).get();
      if (!doc.exists) return null;

      final budget = BudgetModel.fromMap(
        doc.id,
        doc.data() as Map<String, dynamic>,
      );

      final spent = await _calculateSpentAmount(
        budget.categoryId,
        budget.startDate,
        budget.endDate,
      );

      return budget.copyWith(spentAmount: spent);
    } catch (e) {
      throw Exception('Không thể lấy ngân sách: $e');
    }
  }

  // UPDATE
  Future<void> updateBudget(String budgetId, BudgetModel budget) async {
    try {
      await _budgetsCollection.doc(budgetId).update(
        budget.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Không thể cập nhật ngân sách: $e');
    }
  }

  // DELETE
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _budgetsCollection.doc(budgetId).delete();
    } catch (e) {
      throw Exception('Không thể xóa ngân sách: $e');
    }
  }

  // CALCULATE spent amount
  Future<double> _calculateSpentAmount(
    String categoryId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      // ✅ Chỉ dùng where đơn giản, không orderBy
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('type', isEqualTo: 'expense')
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final date = (data['date'] as Timestamp).toDate();

        // ✅ Filter theo ngày ở client
        if (date.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
            date.isBefore(endDate.add(const Duration(seconds: 1)))) {
          final amount = (data['amount'] ?? 0.0) as num;
          total += amount.toDouble();
        }
      }

      return total;
    } catch (e) {
      print('Error calculating spent: $e');
      return 0.0;
    }
  }

  // GET by category
  Future<BudgetModel?> getBudgetByCategory(String categoryId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .where('categoryId', isEqualTo: categoryId)
          .get();

      // ✅ Filter ở client
      final activeDocs = snapshot.docs.where((doc) {
        final endDate = (doc.data() as Map<String, dynamic>)['endDate'];
        if (endDate == null) return false;
        return (endDate as Timestamp).toDate().isAfter(now);
      }).toList();

      if (activeDocs.isEmpty) return null;

      final budget = BudgetModel.fromMap(
        activeDocs.first.id,
        activeDocs.first.data() as Map<String, dynamic>,
      );

      final spent = await _calculateSpentAmount(
        budget.categoryId,
        budget.startDate,
        budget.endDate,
      );

      return budget.copyWith(spentAmount: spent);
    } catch (e) {
      print('Error getting budget by category: $e');
      return null;
    }
  }

  // CHECK budget khi thêm transaction
  Future<Map<String, dynamic>> checkBudgetStatus(
    String categoryId,
    double newExpenseAmount,
  ) async {
    try {
      final budget = await getBudgetByCategory(categoryId);

      if (budget == null) {
        return {'hasBudget': false, 'exceeded': false, 'warning': false};
      }

      final newSpentAmount = budget.spentAmount + newExpenseAmount;
      final newPercentage = (newSpentAmount / budget.limitAmount) * 100;

      return {
        'hasBudget': true,
        'budget': budget,
        'newSpentAmount': newSpentAmount,
        'newPercentage': newPercentage,
        'exceeded': newPercentage >= 100,
        'warning': newPercentage >= budget.alertThreshold,
        'remainingAmount': budget.limitAmount - newSpentAmount,
      };
    } catch (e) {
      print('Error checking budget status: $e');
      return {'hasBudget': false};
    }
  }

  // STATISTICS
  Future<Map<String, dynamic>> getBudgetStatistics() async {
    try {
      final budgets = await getActiveBudgets().first;

      if (budgets.isEmpty) {
        return {
          'totalBudget': 0.0,
          'totalSpent': 0.0,
          'totalRemaining': 0.0,
          'averageUsage': 0.0,
          'exceededCount': 0,
          'warningCount': 0,
          'budgetCount': 0,
        };
      }

      double totalBudget = 0.0;
      double totalSpent = 0.0;
      int exceededCount = 0;
      int warningCount = 0;

      for (var budget in budgets) {
        totalBudget += budget.limitAmount;
        totalSpent += budget.spentAmount;
        if (budget.status == BudgetStatus.exceeded) exceededCount++;
        if (budget.status == BudgetStatus.warning ||
            budget.status == BudgetStatus.danger) warningCount++;
      }

      return {
        'totalBudget': totalBudget,
        'totalSpent': totalSpent,
        'totalRemaining': totalBudget - totalSpent,
        'averageUsage': totalBudget > 0 ? (totalSpent / totalBudget) * 100 : 0,
        'exceededCount': exceededCount,
        'warningCount': warningCount,
        'budgetCount': budgets.length,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }
}