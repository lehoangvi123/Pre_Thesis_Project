import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/TransactionModel.dart';
import '../models/Category_model.dart';

class FinancialContextService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user ID
  String get userId => _auth.currentUser?.uid ?? '';

  // Get user's financial summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      // Get transactions for current month
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

      QuerySnapshot transactionSnapshot = await _firestore
          .collection('users')  // ✅ FIXED: lowercase 'users'
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .get();

      // ✅ FIXED: Use fromMap instead of fromJson
      List<TransactionModel> transactions = transactionSnapshot.docs
          .map((doc) => TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>))
          .toList();

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> expenseByCategory = {};

      for (var transaction in transactions) {
        // ✅ FIXED: Check isIncome field (bool) instead of type string
        if (transaction.isIncome) {
          totalIncome += transaction.amount;
        } else {
          totalExpense += transaction.amount;
          // ✅ FIXED: Use categoryName instead of category
          expenseByCategory[transaction.categoryName] =
              (expenseByCategory[transaction.categoryName] ?? 0) +
                  transaction.amount;
        }
      }

      // Get budget info
      double budgetLimit = await _getBudgetLimit();

      return {
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'balance': totalIncome - totalExpense,
        'budgetLimit': budgetLimit,
        'budgetUsage': budgetLimit > 0 ? (totalExpense / budgetLimit) * 100 : 0,
        'expenseByCategory': expenseByCategory,
        'transactionCount': transactions.length,
        'averageDailySpending': totalExpense / now.day,
        'topSpendingCategory': _getTopCategory(expenseByCategory),
      };
    } catch (e) {
      print('Error getting financial summary: $e');
      return {};
    }
  }

  // Get budget limit
  Future<double> _getBudgetLimit() async {
    try {
      DocumentSnapshot budgetDoc = await _firestore
          .collection('users')  // ✅ FIXED: lowercase 'users'
          .doc(userId)
          .collection('budget')
          .doc('monthly')
          .get();

      if (budgetDoc.exists) {
        return (budgetDoc.data() as Map<String, dynamic>)['limit'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Get top spending category
  String _getTopCategory(Map<String, double> expenseByCategory) {
    if (expenseByCategory.isEmpty) return 'N/A';
    
    return expenseByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get recent transactions
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')  // ✅ FIXED: lowercase 'users'
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      // ✅ FIXED: Use fromMap instead of fromJson
      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting recent transactions: $e');
      return [];
    }
  }

  // Get saving goals
  Future<Map<String, dynamic>> getSavingGoals() async {
    try {
      QuerySnapshot goalsSnapshot = await _firestore
          .collection('users')  // ✅ FIXED: lowercase 'users'
          .doc(userId)
          .collection('saving_goals')
          .get();

      List<Map<String, dynamic>> goals = goalsSnapshot.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();

      return {
        'goals': goals,
        'totalGoals': goals.length,
        'completedGoals': goals.where((g) => g['isCompleted'] == true).length,
      };
    } catch (e) {
      return {'goals': [], 'totalGoals': 0, 'completedGoals': 0};
    }
  }

  // Build context string for AI
  Future<String> buildFinancialContext() async {
    Map<String, dynamic> summary = await getFinancialSummary();
    Map<String, dynamic> goals = await getSavingGoals();
    List<TransactionModel> recentTx = await getRecentTransactions(limit: 5);

    return '''
User Financial Context (Current Month):
- Total Income: ${summary['totalIncome']} VND
- Total Expense: ${summary['totalExpense']} VND
- Current Balance: ${summary['balance']} VND
- Budget Limit: ${summary['budgetLimit']} VND
- Budget Usage: ${summary['budgetUsage']?.toStringAsFixed(1)}%
- Average Daily Spending: ${summary['averageDailySpending']?.toStringAsFixed(0)} VND
- Top Spending Category: ${summary['topSpendingCategory']}
- Total Transactions: ${summary['transactionCount']}

Expense Breakdown by Category:
${_formatExpenseBreakdown(summary['expenseByCategory'])}

Recent Transactions (Last 5):
${_formatRecentTransactions(recentTx)}

Saving Goals:
- Total Goals: ${goals['totalGoals']}
- Completed: ${goals['completedGoals']}
${_formatGoals(goals['goals'])}
''';
  }

  String _formatExpenseBreakdown(Map<String, double>? expenses) {
    if (expenses == null || expenses.isEmpty) return '- No expenses yet';
    return expenses.entries
        .map((e) => '- ${e.key}: ${e.value.toStringAsFixed(0)} VND')
        .join('\n');
  }

  String _formatRecentTransactions(List<TransactionModel> transactions) {
    if (transactions.isEmpty) return '- No recent transactions';
    return transactions
        .map((t) =>
            // ✅ FIXED: Use categoryName instead of category
            '- ${t.title}: ${t.amount.toStringAsFixed(0)} VND (${t.categoryName})')
        .join('\n');
  }

  String _formatGoals(List<dynamic>? goals) {
    if (goals == null || goals.isEmpty) return '- No active goals';
    return goals
        .map((g) =>
            '- ${g['name']}: ${g['currentAmount']}/${g['targetAmount']} VND')
        .join('\n');
  }
}