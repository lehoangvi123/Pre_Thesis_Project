import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './HomeView.dart';
import './AnalysisView.dart';
import './CategorizeContent.dart';
import './ProfileView.dart';
import './AddExpenseView.dart';
import '../notification/NotificationView.dart';
import './transaction_widgets.dart';
import '../TextVoice/AI_deep_analysis_view.dart';
import './EditTransactionView.dart';  // ✅ ADD THIS

class TransactionView extends StatefulWidget {
  const TransactionView({Key? key}) : super(key: key);

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All'; // All, Income, Expense
  String? userId;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    return TransactionWidgets.formatCurrency(amount);
  }

  Future<void> _deleteTransaction(String transactionId, Map<String, dynamic> data) async {
    try {
      // ✅ Get absolute value
      double amount = ((data['amount'] ?? 0) as num).abs().toDouble();
      String type = (data['type'] ?? 'expense').toString().toLowerCase();

      // Delete transaction
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();

      // Update user balance
      DocumentReference userRef = _firestore.collection('users').doc(userId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot userDoc = await transaction.get(userRef);

        double currentBalance = (userDoc.get('balance') ?? 0).toDouble();
        double totalIncome = (userDoc.get('totalIncome') ?? 0).toDouble();
        double totalExpense = (userDoc.get('totalExpense') ?? 0).toDouble();

        if (type == 'income') {
          currentBalance -= amount;
          totalIncome -= amount;
        } else {
          currentBalance += amount;
          totalExpense -= amount;
        }

        transaction.update(userRef, {
          'balance': currentBalance,
          'totalIncome': totalIncome,
          'totalExpense': totalExpense,
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch thành công'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSearchDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Tìm kiếm giao dịch',
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Nhập tên giao dịch...',
              hintStyle: TextStyle(
                color: isDark ? Colors.grey[600] : Colors.grey[400],
              ),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF00CED1)),
              filled: true,
              fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value.toLowerCase();
              });
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  searchQuery = '';
                  _searchController.clear();
                });
                Navigator.pop(context);
              },
              child: const Text('Xóa'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Đóng',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userId == null) {
      return const Scaffold(
        body: Center(child: Text('Vui lòng đăng nhập')),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(
              child: StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(userId).snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var userData =
                      userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  double balance = (userData['balance'] ?? 0).toDouble();
                  double totalIncome =
                      (userData['totalIncome'] ?? 0).toDouble();
                  double totalExpense =
                      (userData['totalExpense'] ?? 0).toDouble();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildBalanceCard(
                            balance, totalIncome, totalExpense, isDark),
                        const SizedBox(height: 16),
                        _buildProgressBar(totalExpense, isDark),
                        const SizedBox(height: 16),
                        _buildFilterChips(isDark),
                        const SizedBox(height: 8),
                        _buildTransactionsList(isDark),
                        const SizedBox(height: 80),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIDeepAnalysisView(),
            ),
          );
        },
        backgroundColor: const Color(0xFF00CED1),
        icon: const Icon(Icons.psychology, color: Colors.white),
        label: const Text(
          'AI Phân tích',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Giao dịch',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                searchQuery.isEmpty
                    ? 'Theo dõi chi tiêu của bạn'
                    : 'Tìm kiếm: "$searchQuery"',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => _showSearchDialog(isDark),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.search,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationView(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(
      double balance, double totalIncome, double totalExpense, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00CED1),
            Color(0xFF00A8AA),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00CED1).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Tổng số dư',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _formatCurrency(balance),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceItem(
                  'Tổng thu nhập',
                  totalIncome,
                  Icons.arrow_downward,
                  Colors.green[300]!,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildBalanceItem(
                  'Tổng chi tiêu',
                  totalExpense,
                  Icons.arrow_upward,
                  Colors.red[300]!,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(
      String label, double amount, IconData icon, Color iconColor) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatCurrency(amount),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double totalExpense, bool isDark) {
    double budgetLimit = 20000000;
    double percentage = (totalExpense / budgetLimit * 100).clamp(0, 100);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (percentage < 70 ? Colors.green : Colors.orange)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle,
              color: percentage < 70 ? Colors.green[600] : Colors.orange[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% chi tiêu, ${percentage < 70 ? 'Tốt' : 'Cẩn thận'}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      percentage < 70 ? Colors.green[600]! : Colors.red[600]!,
                    ),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            _formatCurrency(budgetLimit),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('All', 'Tất cả', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Income', 'Thu nhập', isDark),
          const SizedBox(width: 8),
          _buildFilterChip('Expense', 'Chi tiêu', isDark),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark) {
    bool isSelected = selectedFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedFilter = value;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00CED1)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF00CED1).withOpacity(0.3),
                      blurRadius: 10,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return TransactionWidgets.buildEmptyState(isDark, selectedFilter);
        }

        // Filter by search query
        List<DocumentSnapshot> filteredDocs = snapshot.data!.docs.where((doc) {
          if (searchQuery.isEmpty) return true;

          var data = doc.data() as Map<String, dynamic>;
          String title = (data['title'] ?? '').toString().toLowerCase();
          String category = (data['category'] ?? '').toString().toLowerCase();

          return title.contains(searchQuery) || category.contains(searchQuery);
        }).toList();

        if (filteredDocs.isEmpty) {
          return TransactionWidgets.buildEmptyState(isDark, selectedFilter);
        }

        // Calculate statistics
        double totalAmount = 0;
        for (var doc in filteredDocs) {
          var data = doc.data() as Map<String, dynamic>;
          totalAmount += (data['amount'] ?? 0).toDouble();
        }

        // Group by month
        Map<String, List<DocumentSnapshot>> groupedTransactions = {};

        for (var doc in filteredDocs) {
          var data = doc.data() as Map<String, dynamic>;
          var timestamp = data['date'] as Timestamp?;

          if (timestamp != null) {
            String monthKey =
                TransactionWidgets.getVietnameseMonth(timestamp.toDate());

            if (!groupedTransactions.containsKey(monthKey)) {
              groupedTransactions[monthKey] = [];
            }
            groupedTransactions[monthKey]!.add(doc);
          }
        }

        return Column(
          children: [
            // Statistics card
            if (selectedFilter != 'All')
              TransactionWidgets.buildStatisticsCard(
                transactionCount: filteredDocs.length,
                totalAmount: totalAmount,
                isIncome: selectedFilter == 'Income',
                isDark: isDark,
              ),
            // Transactions list
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: groupedTransactions.entries.map((entry) {
                  return _buildMonthSection(entry.key, entry.value, isDark);
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getTransactionsStream() {
    var query = _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true);

    if (selectedFilter == 'Income') {
      query = query.where('type', isEqualTo: 'income');
    } else if (selectedFilter == 'Expense') {
      query = query.where('type', isEqualTo: 'expense');
    }

    return query.snapshots();
  }

  Widget _buildMonthSection(
      String month, List<DocumentSnapshot> transactions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            month,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ),
        ...transactions.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return TransactionWidgets.buildTransactionItem(
            context: context,
            doc: doc,
            isDark: isDark,
            onDelete: () => _deleteTransaction(doc.id, data),
            onTap: () async {
              // ✅ NAVIGATE TO EDIT SCREEN
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTransactionView(
                    transactionId: doc.id,
                    transactionData: data,
                  ),
                ),
              );
              
              // ✅ REFRESH LIST IF EDITED
              if (result == true && mounted) {
                setState(() {});
              }
            },
          );
        }).toList(),
      ],
    );
  }

  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
              }),
              _buildNavItem(Icons.search, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AnalysisView()),
                );
              }),
              _buildNavItem(Icons.swap_horiz, true, const Color(0xFF00CED1),
                  onTap: () {}),
              _buildNavItem(Icons.layers, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const CategoriesView()),
                );
              }),
              _buildNavItem(Icons.person_outline, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfileView()),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}