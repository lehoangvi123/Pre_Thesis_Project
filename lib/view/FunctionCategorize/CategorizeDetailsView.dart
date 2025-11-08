import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 
import './AddExpenseView.dart';
import './AddIncomeView.dart'; // ✅ Import VND version
import './CurrencyFormatter.dart'; // ✅ Import currency formatter

class CategoryDetailView extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const CategoryDetailView({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  }) : super(key: key);

  @override
  State<CategoryDetailView> createState() => _CategoryDetailViewState();
}

class _CategoryDetailViewState extends State<CategoryDetailView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ UPDATED: Will be calculated from Firestore
  double totalBalance = 0.0;
  double categoryTotal = 0.0; // Total for this category
  bool isIncomeCategory = false;
  bool isLoadingTotals = true;

  @override
  void initState() {
    super.initState();
    _checkCategoryType();
    _calculateTotals(); // ✅ Calculate totals on init
  }

  // ✅ Check if this category is income or expense
  Future<void> _checkCategoryType() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final categoryDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .where('name', isEqualTo: widget.categoryName)
          .limit(1)
          .get();

      if (categoryDoc.docs.isNotEmpty) {
        final data = categoryDoc.docs.first.data();
        setState(() {
          isIncomeCategory = data['type'] == 'income';
        });
      } else {
        // Check if it's one of the default income categories
        final incomeCategories = ['Salary', 'Freelance', 'Investment'];
        setState(() {
          isIncomeCategory = incomeCategories.contains(widget.categoryName);
        });
      }
    } catch (e) {
      print('Error checking category type: $e');
    }
  }

  // ✅ NEW: Calculate totals from Firestore
  Future<void> _calculateTotals() async {
    setState(() => isLoadingTotals = true);

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() => isLoadingTotals = false);
      return;
    }

    try {
      // Get all transactions
      final allSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .get();

      double income = 0.0;
      double expenses = 0.0;
      double categoryAmount = 0.0;

      for (var doc in allSnapshot.docs) {
        final data = doc.data();
        final amount = (data['amount'] ?? 0).toDouble();
        final type = data['type'] ?? 'expense';
        final category = data['category'] ?? '';

        if (type == 'income') {
          income += amount;
        } else {
          expenses += amount;
        }

        // Calculate this category's total
        if (category == widget.categoryName) {
          categoryAmount += amount;
        }
      }

      setState(() {
        totalBalance = income - expenses;
        categoryTotal = categoryAmount;
        isLoadingTotals = false;
      });
    } catch (e) {
      print('Error calculating totals: $e');
      setState(() => isLoadingTotals = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: widget.categoryColor,
      appBar: AppBar(
        backgroundColor: widget.categoryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Balance Section
          Container(
            color: widget.categoryColor,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.account_balance_wallet_outlined,
                                size: 14, color: Colors.white70),
                            SizedBox(width: 4),
                            Text(
                              'Total Balance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ✅ UPDATED: Show in VND
                        Text(
                          isLoadingTotals 
                              ? 'Loading...' 
                              : CurrencyFormatter.formatVND(totalBalance),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isIncomeCategory 
                                  ? Icons.trending_up 
                                  : Icons.trending_down,
                              size: 14, 
                              color: Colors.white70
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isIncomeCategory ? 'Total Income' : 'Total Expenses',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        // ✅ UPDATED: Show in VND with sign
                        Text(
                          isLoadingTotals
                              ? 'Loading...'
                              : CurrencyFormatter.formatVNDWithSign(
                                  categoryTotal, 
                                  isIncomeCategory
                                ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        '30%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.3,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // ✅ UPDATED: Show in VND
                      Text(
                        CurrencyFormatter.formatVND(20000000),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  isIncomeCategory 
                      ? '30% Of Your Income, Looks Good'
                      : '30% Of Your Expenses, Looks Good',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          // Expenses/Income List Section
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _getExpensesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.categoryIcon,
                            size: 80,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isIncomeCategory 
                                ? 'No income in ${widget.categoryName}'
                                : 'No expenses in ${widget.categoryName}',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isIncomeCategory 
                                ? 'Add your first income below'
                                : 'Add your first expense below',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Group expenses by month
                  Map<String, List<DocumentSnapshot>> groupedExpenses = {};
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    final monthKey = DateFormat('MMMM').format(date);

                    if (!groupedExpenses.containsKey(monthKey)) {
                      groupedExpenses[monthKey] = [];
                    }
                    groupedExpenses[monthKey]!.add(doc);
                  }

                  return ListView(
                    padding: const EdgeInsets.all(20),
                    children: groupedExpenses.entries.map((entry) {
                      return _buildMonthSection(entry.key, entry.value, isDark);
                    }).toList(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // ✅ UPDATED: Wait for result and refresh
          final result = await _showAddDialog();
          if (result == true) {
            _calculateTotals(); // ✅ Refresh totals after adding
          }
        },
        backgroundColor: widget.categoryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildMonthSection(
      String month, List<DocumentSnapshot> expenses, bool isDark) {
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
        ...expenses.map((doc) => _buildExpenseItem(doc, isDark)).toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildExpenseItem(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Untitled';
    final amount = (data['amount'] ?? 0).toDouble();
    final date = (data['date'] as Timestamp).toDate();
    final dateStr = DateFormat('hh:mm a - MMM dd').format(date);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              widget.categoryIcon,
              color: widget.categoryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // ✅ UPDATED: Show in VND with sign
          Text(
            CurrencyFormatter.formatVNDWithSign(amount, isIncomeCategory),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.categoryColor,
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getExpensesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('category', isEqualTo: widget.categoryName)
        .orderBy('date', descending: true)
        .snapshots();
  }

  // ✅ UPDATED: Returns Future<bool?> to check if something was added
  Future<bool?> _showAddDialog() async {
    if (isIncomeCategory) {
      // Open AddIncomeView for income categories
      return await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddIncomeView(
            categoryName: widget.categoryName,
            categoryIcon: widget.categoryIcon,
            categoryColor: widget.categoryColor,
          ),
        ),
      );
    } else {
      // Open AddExpenseView for expense categories
      return await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => AddExpenseView(
            categoryName: widget.categoryName,
            categoryIcon: widget.categoryIcon,
            categoryColor: widget.categoryColor,
          ),
        ),
      );
    }
  }
}