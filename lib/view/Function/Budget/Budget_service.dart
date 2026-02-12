// lib/service/budget_service.dart
// Budget Service - CRUD operations và tính toán

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './budget_model.dart';

class BudgetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? '';

  // Collection reference
  CollectionReference get _budgetsCollection =>
      _firestore.collection('budgets');

  // CREATE: Tạo budget mới
  Future<String> createBudget(BudgetModel budget) async {
    try {
      final docRef = await _budgetsCollection.add(budget.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Không thể tạo ngân sách: $e');
    }
  }

  // READ: Lấy tất cả budgets của user
  Stream<List<BudgetModel>> getBudgets() {
    return _budgetsCollection
        .where('userId', isEqualTo: _userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      List<BudgetModel> budgets = [];
      
      for (var doc in snapshot.docs) {
        final budget = BudgetModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );
        
        // Tính spent amount real-time
        final spent = await _calculateSpentAmount(
          budget.categoryId,
          budget.startDate,
          budget.endDate,
        );
        
        budgets.add(budget.copyWith(spentAmount: spent));
      }
      
      return budgets;
    });
  }

  // READ: Lấy active budgets (chưa hết hạn)
  Stream<List<BudgetModel>> getActiveBudgets() {
    final now = DateTime.now();
    
    return _budgetsCollection
        .where('userId', isEqualTo: _userId)
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('endDate')
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
      
      return budgets;
    });
  }

  // READ: Lấy budget theo ID
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

  // UPDATE: Cập nhật budget
  Future<void> updateBudget(String budgetId, BudgetModel budget) async {
    try {
      await _budgetsCollection.doc(budgetId).update(
        budget.copyWith(updatedAt: DateTime.now()).toMap(),
      );
    } catch (e) {
      throw Exception('Không thể cập nhật ngân sách: $e');
    }
  }

  // DELETE: Xóa budget
  Future<void> deleteBudget(String budgetId) async {
    try {
      await _budgetsCollection.doc(budgetId).delete();
    } catch (e) {
      throw Exception('Không thể xóa ngân sách: $e');
    }
  }

  // CALCULATE: Tính tổng chi tiêu trong khoảng thời gian
  Future<double> _calculateSpentAmount(
    String categoryId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: _userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final amount = (doc.data()['amount'] ?? 0.0) as num;
        total += amount.toDouble();
      }

      return total;
    } catch (e) {
      print('Error calculating spent amount: $e');
      return 0.0;
    }
  }

  // GET: Lấy budget cho category cụ thể (nếu có)
  Future<BudgetModel?> getBudgetByCategory(String categoryId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .where('categoryId', isEqualTo: categoryId)
          .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final budget = BudgetModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data() as Map<String, dynamic>,
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

  // CHECK: Kiểm tra budget khi thêm transaction mới
  Future<Map<String, dynamic>> checkBudgetStatus(
    String categoryId,
    double newExpenseAmount,
  ) async {
    try {
      final budget = await getBudgetByCategory(categoryId);
      
      if (budget == null) {
        return {
          'hasBudget': false,
          'exceeded': false,
          'warning': false,
        };
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

  // AUTO RESET: Reset budgets hết hạn (chạy định kỳ)
  Future<void> autoResetExpiredBudgets() async {
    try {
      final now = DateTime.now();
      final snapshot = await _budgetsCollection
          .where('userId', isEqualTo: _userId)
          .where('autoReset', isEqualTo: true)
          .where('endDate', isLessThan: Timestamp.fromDate(now))
          .get();

      for (var doc in snapshot.docs) {
        final budget = BudgetModel.fromMap(
          doc.id,
          doc.data() as Map<String, dynamic>,
        );

        // Tạo budget mới cho kỳ tiếp theo
        final newStartDate = budget.endDate;
        final newEndDate = calculateEndDate(newStartDate, budget.period);

        final newBudget = budget.copyWith(
          startDate: newStartDate,
          endDate: newEndDate,
          spentAmount: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Xóa budget cũ và tạo mới
        await _budgetsCollection.doc(doc.id).delete();
        await createBudget(newBudget);
      }
    } catch (e) {
      print('Error auto-resetting budgets: $e');
    }
  }

  // STATISTICS: Thống kê tổng quan
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
      print('Error getting budget statistics: $e');
      return {};
    }
  }
}