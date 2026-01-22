import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/TransactionModel.dart';
import '../models/Category_model.dart';

class FinancialContextService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user ID
  String get userId => _auth.currentUser?.uid ?? '';

  // ✅ HELPER: Convert any number to double safely
  double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // Get user's financial summary
  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      // Get transactions for current month
      DateTime now = DateTime.now();
      DateTime startOfMonth = DateTime(now.year, now.month, 1);
      DateTime endOfMonth = DateTime(now.year, now.month + 1, 0);

      QuerySnapshot transactionSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: startOfMonth)
          .where('date', isLessThanOrEqualTo: endOfMonth)
          .get(); 
         
         
print('[DEBUG] ════════════════════════════════');
print('[DEBUG] 🔍 RAW FIRESTORE DATA:');
for (var doc in transactionSnapshot.docs) {
  var data = doc.data() as Map<String, dynamic>;
  print('[DEBUG] ${doc.id}: $data');
}
print('[DEBUG] ════════════════════════════════');

      List<TransactionModel> transactions = transactionSnapshot.docs
          .map((doc) => TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>))
          .toList();

      // Calculate totals
      double totalIncome = 0;
      double totalExpense = 0;
      Map<String, double> expenseByCategory = {};
      Map<String, double> incomeByCategory = {};

      // ✅ DEBUG: Print header
      print('[FinancialContext] ════════════════════════════════');
      print('[FinancialContext] 📊 PROCESSING ${transactions.length} TRANSACTIONS');
      print('[FinancialContext] ════════════════════════════════');
      
      for (var transaction in transactions) {
        // ✅ FIX: Convert to double safely
        double amount = _toDouble(transaction.amount);
        
        // ✅ DEBUG: Print each transaction
        print('[FinancialContext] Transaction: ${transaction.title}');
        print('[FinancialContext]   - Type: ${transaction.isIncome ? "INCOME ✅" : "EXPENSE ❌"}');
        print('[FinancialContext]   - Amount: $amount');
        print('[FinancialContext]   - Category: ${transaction.categoryName}');
            
        if (transaction.isIncome) {
          totalIncome += amount;
          incomeByCategory[transaction.categoryName] =
              (incomeByCategory[transaction.categoryName] ?? 0) + amount;
        } else {
          totalExpense += amount;
          expenseByCategory[transaction.categoryName] =
              (expenseByCategory[transaction.categoryName] ?? 0) + amount;
        }
      }

      // ✅ Get budget info and balance AFTER calculating totals
      double budgetLimit = await _getBudgetLimit();
      double currentBalance = await _getCurrentBalance();
      
      // ✅ DEBUG: Print totals
      print('[FinancialContext] ════════════════════════════════');
      print('[FinancialContext] 💰 TOTALS CALCULATED:');
      print('[FinancialContext]   - Total Income: $totalIncome');
      print('[FinancialContext]   - Total Expense: $totalExpense');
      print('[FinancialContext]   - Current Balance: $currentBalance');
      print('[FinancialContext] ════════════════════════════════');

      return {
        'currentBalance': currentBalance,
        'totalIncome': totalIncome,
        'totalExpense': totalExpense,
        'netChange': totalIncome - totalExpense,
        'budgetLimit': budgetLimit,
        'budgetRemaining': budgetLimit - totalExpense,
        'budgetUsage': budgetLimit > 0 ? (totalExpense / budgetLimit) * 100 : 0,
        'expenseByCategory': expenseByCategory,
        'incomeByCategory': incomeByCategory,
        'transactionCount': transactions.length,
        'averageDailySpending': totalExpense / (now.day > 0 ? now.day : 1),
        'topSpendingCategory': _getTopCategory(expenseByCategory),
        'savingsRate': totalIncome > 0 ? ((totalIncome - totalExpense) / totalIncome) * 100 : 0,
      };
    } catch (e, stack) {
      print('[FinancialContext] Error in getFinancialSummary: $e');
      print('[FinancialContext] Stack: $stack');
      return {};
    }
  }

  // Get current balance from user document
  Future<double> _getCurrentBalance() async {
    try {
      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        // ✅ FIX: Use _toDouble helper
        return _toDouble((userDoc.data() as Map<String, dynamic>)['balance']);
      }
      return 0;
    } catch (e) {
      print('[FinancialContext] Error getting balance: $e');
      return 0;
    }
  }

  // Get budget limit
  Future<double> _getBudgetLimit() async {
    try {
      DocumentSnapshot budgetDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('budget')
          .doc('monthly')
          .get();

      if (budgetDoc.exists) {
        // ✅ FIX: Use _toDouble helper
        return _toDouble((budgetDoc.data() as Map<String, dynamic>)['limit']);
      }
      return 0;
    } catch (e) {
      print('[FinancialContext] Error getting budget: $e');
      return 0;
    }
  }

  // Get top spending category
  String _getTopCategory(Map<String, double> expenseByCategory) {
    if (expenseByCategory.isEmpty) return 'Chưa có';
    
    return expenseByCategory.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Get recent transactions
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => TransactionModel.fromMap(
              doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('[FinancialContext] Error getting recent transactions: $e');
      return [];
    }
  }

  // Get saving goals
  Future<Map<String, dynamic>> getSavingGoals() async {
    try {
      QuerySnapshot goalsSnapshot = await _firestore
          .collection('users')
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
      print('[FinancialContext] Error getting goals: $e');
      return {'goals': [], 'totalGoals': 0, 'completedGoals': 0};
    }
  }

  // ✅ BUILD CONTEXT STRING - FORMAT CỰC KỲ RÕ RÀNG CHO AI
  Future<String> buildFinancialContext() async {
    try {
      // Debug: Check user auth
      print('[FinancialContext] User ID: $userId');
      if (userId.isEmpty) {
        print('[FinancialContext] ❌ User not logged in!');
        return '''
═══════════════════════════════════════════════════
⚠️ CHƯA ĐĂNG NHẬP

Vui lòng đăng nhập để xem dữ liệu tài chính.
═══════════════════════════════════════════════════
''';
      }

      print('[FinancialContext] Getting financial summary...');
      Map<String, dynamic> summary = await getFinancialSummary();
      
      print('[FinancialContext] Getting saving goals...');
      Map<String, dynamic> goals = await getSavingGoals();
      
      print('[FinancialContext] Getting recent transactions...');
      List<TransactionModel> recentTx = await getRecentTransactions(limit: 5);
      
      // ✅ CHECK: Nếu không có data, trả về message thân thiện
      if (summary.isEmpty || 
          ((_toDouble(summary['totalIncome']) == 0) && 
           (_toDouble(summary['totalExpense']) == 0) && 
           (_toDouble(summary['currentBalance']) == 0))) {
        print('[FinancialContext] ⚠️ No financial data found');
        return '''
═══════════════════════════════════════════════════
📊 DỮ LIỆU TÀI CHÍNH
═══════════════════════════════════════════════════

💡 CHƯA CÓ DỮ LIỆU TÀI CHÍNH

Bạn chưa có giao dịch nào trong tháng này.

Hãy bắt đầu bằng cách:
1. ➕ Thêm giao dịch đầu tiên
2. 💰 Nhập số dư ban đầu  
3. 🎯 Đặt ngân sách tháng

Sau đó tôi sẽ giúp bạn phân tích chi tiêu! 😊
═══════════════════════════════════════════════════
''';
      }
      
      print('[FinancialContext] Building context string...');
      
      DateTime now = DateTime.now();
      String monthName = _getVietnameseMonth(now.month);

      StringBuffer context = StringBuffer();
      
      context.writeln('═══════════════════════════════════════════════════');
      context.writeln('📊 DỮ LIỆU TÀI CHÍNH CỦA NGƯỜI DÙNG');
      context.writeln('═══════════════════════════════════════════════════');
      context.writeln('');
      
      // ✅ PHẦN 1: SỐ DƯ HIỆN TẠI
      context.writeln('💰 SỐ DƯ HIỆN TẠI TRONG TÀI KHOẢN:');
      context.writeln('   ${_formatMoney(_toDouble(summary['currentBalance']))}');
      context.writeln('   (Đây là số tiền còn lại trong tài khoản)');
      context.writeln('');
      
      context.writeln('📅 DỮ LIỆU THÁNG $monthName/${now.year}:');
      context.writeln('');
      
      // ✅ PHẦN 2: THU NHẬP
      context.writeln('📈 TỔNG THU NHẬP THÁNG NÀY:');
      double totalIncome = _toDouble(summary['totalIncome']);
      if (totalIncome > 0) {
        context.writeln('   ${_formatMoney(totalIncome)}');
        context.writeln('');
        
        Map<String, double> incomeByCategory = summary['incomeByCategory'] ?? {};
        if (incomeByCategory.isNotEmpty) {
          context.writeln('   Chi tiết thu nhập theo nguồn:');
          incomeByCategory.forEach((category, amount) {
            context.writeln('   • $category: ${_formatMoney(amount)}');
          });
        }
      } else {
        context.writeln('   CHƯA CÓ THU NHẬP NÀO trong tháng này');
      }
      context.writeln('');
      
      // ✅ PHẦN 3: CHI TIÊU
      context.writeln('📉 TỔNG CHI TIÊU THÁNG NÀY:');
      double totalExpense = _toDouble(summary['totalExpense']);
      if (totalExpense > 0) {
        context.writeln('   ${_formatMoney(totalExpense)}');
        context.writeln('   (Đây là tổng số tiền đã CHI trong tháng ${now.month})');
        context.writeln('');
        
        Map<String, double> expenseByCategory = summary['expenseByCategory'] ?? {};
        if (expenseByCategory.isNotEmpty) {
          context.writeln('   Chi tiết chi tiêu theo danh mục:');
          
          var sortedExpenses = expenseByCategory.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));
          
          for (var entry in sortedExpenses) {
            double percentage = (entry.value / totalExpense) * 100;
            context.writeln('   • ${entry.key}: ${_formatMoney(entry.value)} (${percentage.toStringAsFixed(1)}%)');
          }
        }
      } else {
        context.writeln('   CHƯA CÓ CHI TIÊU NÀO trong tháng này');
      }
      context.writeln('');
      
      // ✅ PHẦN 4: THAY ĐỔI RÒNG
      double netChange = _toDouble(summary['netChange']);
      context.writeln('📊 THAY ĐỔI RÒNG THÁNG NÀY:');
      if (netChange > 0) {
        context.writeln('   +${_formatMoney(netChange)} ✅');
        context.writeln('   (Thu nhiều hơn chi → Tích cực!)');
      } else if (netChange < 0) {
        context.writeln('   ${_formatMoney(netChange)} ⚠️');
        context.writeln('   (Chi nhiều hơn thu → Cần chú ý!)');
      } else {
        context.writeln('   ${_formatMoney(netChange)}');
        context.writeln('   (Thu chi cân bằng)');
      }
      context.writeln('');
      
      // ✅ PHẦN 5: NGÂN SÁCH
      double budgetLimit = _toDouble(summary['budgetLimit']);
      if (budgetLimit > 0) {
        context.writeln('🎯 NGÂN SÁCH THÁNG:');
        context.writeln('   Giới hạn: ${_formatMoney(budgetLimit)}');
        
        double budgetRemaining = _toDouble(summary['budgetRemaining']);
        double budgetUsage = _toDouble(summary['budgetUsage']);
        
        context.writeln('   Đã dùng: ${budgetUsage.toStringAsFixed(1)}%');
        context.writeln('   Còn lại: ${_formatMoney(budgetRemaining)}');
        
        if (budgetRemaining < 0) {
          context.writeln('   ⚠️ CẢNH BÁO: Đã vượt ngân sách ${_formatMoney(budgetRemaining.abs())}!');
        } else if (budgetUsage > 80) {
          context.writeln('   ⚠️ CHÚ Ý: Sắp hết ngân sách!');
        }
        context.writeln('');
      }
      
      // ✅ PHẦN 6: THỐNG KÊ
      context.writeln('📊 THỐNG KÊ THÁNG NÀY:');
      context.writeln('   • Số giao dịch: ${summary['transactionCount']}');
      
      double avgDaily = _toDouble(summary['averageDailySpending']);
      if (avgDaily > 0) {
        context.writeln('   • Chi tiêu trung bình/ngày: ${_formatMoney(avgDaily)}');
      }
      
      String topCategory = summary['topSpendingCategory'] ?? 'Chưa có';
      if (topCategory != 'Chưa có') {
        context.writeln('   • Danh mục chi nhiều nhất: $topCategory');
      }
      
      double savingsRate = _toDouble(summary['savingsRate']);
      if (totalIncome > 0) {
        context.writeln('   • Tỷ lệ tiết kiệm: ${savingsRate.toStringAsFixed(1)}%');
      }
      context.writeln('');
      
      // ✅ PHẦN 7: GIAO DỊCH GẦN ĐÂY
      if (recentTx.isNotEmpty) {
        context.writeln('📝 5 GIAO DỊCH GẦN NHẤT:');
        for (var tx in recentTx.take(5)) {
          String type = tx.isIncome ? '📈 Thu' : '📉 Chi';
          context.writeln('   $type: ${tx.title} - ${_formatMoney(_toDouble(tx.amount))} (${tx.categoryName})');
        }
        context.writeln('');
      }
      
      // ✅ PHẦN 8: MỤC TIÊU
      int totalGoals = goals['totalGoals'] ?? 0;
      if (totalGoals > 0) {
        context.writeln('🎯 MỤC TIÊU TIẾT KIỆM:');
        context.writeln('   • Tổng số mục tiêu: $totalGoals');
        context.writeln('   • Đã hoàn thành: ${goals['completedGoals']}');
        context.writeln('');
      }
      
      context.writeln('═══════════════════════════════════════════════════');
      context.writeln('');
      context.writeln('⚠️ LƯU Ý CỰC KỲ QUAN TRỌNG CHO AI:');
      context.writeln('');
      context.writeln('1. SỐ DƯ HIỆN TẠI ≠ TỔNG CHI TIÊU');
      context.writeln('   • Số dư = Tiền còn lại trong tài khoản NGAY LÚC NÀY');
      context.writeln('   • Tổng chi tiêu = Tổng số tiền đã CHI trong THÁNG ${now.month}');
      context.writeln('   • ĐỪNG BAO GIỜ NÓI: "Bạn đã chi [số dư]"');
      context.writeln('');
      context.writeln('2. KHI PHÂN TÍCH:');
      context.writeln('   • Dựa vào TỔNG CHI TIÊU, KHÔNG phải số dư');
      context.writeln('   • Nói rõ danh mục chi nhiều (%, số tiền cụ thể)');
      context.writeln('   • Đưa ra lời khuyên CỤ THỂ, có SỐ LIỆU');
      context.writeln('');
      context.writeln('3. GIỌNG ĐIỆU:');
      context.writeln('   • Thân thiện như BẠN BÈ, không máy móc');
      context.writeln('   • Ngắn gọn (2-4 câu), dùng emoji phù hợp');
      context.writeln('');
      context.writeln('═══════════════════════════════════════════════════');
      
      print('[FinancialContext] ✅ Context built successfully');
      
      // ✅ DEBUG: Print final context
      String finalContext = context.toString();
      print('[FinancialContext] ════════════════════════════════');
      print('[FinancialContext] 📤 FINAL CONTEXT TO SEND TO AI:');
      print('[FinancialContext] ════════════════════════════════');
      print(finalContext);
      print('[FinancialContext] ════════════════════════════════');
      
      return finalContext;
      
    } catch (e, stackTrace) {
      print('[FinancialContext] ❌ Error: $e');
      print('[FinancialContext] Stack trace: $stackTrace');
      
      String errorDetail = '';
      if (e.toString().contains('permission-denied')) {
        errorDetail = 'Lỗi: Không có quyền truy cập Firestore.\nKiểm tra Firestore Rules.';
      } else if (e.toString().contains('not-found')) {
        errorDetail = 'Lỗi: Không tìm thấy dữ liệu.';
      } else if (e.toString().contains('network')) {
        errorDetail = 'Lỗi: Không có kết nối mạng.';
      } else {
        errorDetail = 'Lỗi: ${e.toString()}';
      }
      
      return '''
═══════════════════════════════════════════════════
⚠️ KHÔNG THỂ TẢI DỮ LIỆU TÀI CHÍNH

$errorDetail

Vui lòng thử lại sau.
═══════════════════════════════════════════════════
''';
    }
  }

  // ✅ FORMAT TIỀN TỆ
  String _formatMoney(double amount) {
    if (amount.abs() >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)} triệu đồng';
    } else if (amount.abs() >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)} nghìn đồng';
    } else {
      return '${amount.toStringAsFixed(0)} đồng';
    }
  }

  // Get Vietnamese month name
  String _getVietnameseMonth(int month) {
    const months = [
      '', 'Tháng 1', 'Tháng 2', 'Tháng 3', 'Tháng 4', 'Tháng 5', 'Tháng 6',
      'Tháng 7', 'Tháng 8', 'Tháng 9', 'Tháng 10', 'Tháng 11', 'Tháng 12'
    ];
    return months[month];
  }
}