// ✅ SOLUTION: Remove orderBy to avoid index requirement
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
import './EditTransactionView.dart';
import '../../view/Bill_Scanner_Service/Bill_scanner_view.dart';
import './AI_Chatbot/chatbot_view.dart';
import '../Calender_Part/Calender.dart';

class TransactionView extends StatefulWidget {
  const TransactionView({Key? key}) : super(key: key);

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();

  String selectedFilter = 'All';
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
      double amount = ((data['amount'] ?? 0) as num).abs().toDouble();
      String type = (data['type'] ?? 'expense').toString().toLowerCase();

      await _firestore
          .collection('users').doc(userId)
          .collection('transactions').doc(transactionId)
          .delete();

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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Đã xóa giao dịch thành công'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
    }
  }

  void _showSearchDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Tìm kiếm giao dịch',
            style: TextStyle(color: isDark ? Colors.white : Colors.black)),
        content: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Nhập tên giao dịch...',
            hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
            prefixIcon: const Icon(Icons.search, color: Color(0xFF00CED1)),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
          onChanged: (value) {
            setState(() { searchQuery = value.toLowerCase(); });
            Navigator.pop(context);
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() { searchQuery = ''; _searchController.clear(); });
              Navigator.pop(context);
            },
            child: const Text('Xóa'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAIMenuBottomSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: isDark ? Colors.grey[600] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text('Tính năng phân tích nhanh bao gồm',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text('Chọn tính năng bạn muốn sử dụng (beta version)',
                style: TextStyle(fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(height: 24),
            _buildAIMenuOption(context: context, isDark: isDark,
                icon: Icons.analytics_outlined,
                iconColor: const Color(0xFF00CED1),
                title: 'Phân tích chi tiêu',
                subtitle: 'Phân tích sâu về thói quen chi tiêu của bạn',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const AIDeepAnalysisView()));
                }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[200], height: 1),
            ),
            _buildAIMenuOption(context: context, isDark: isDark,
                icon: Icons.chat_bubble_outline,
                iconColor: Colors.purple,
                title: 'Chat với AI',
                subtitle: 'Trò chuyện với trợ lý tài chính thông minh',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const ChatbotView()));
                }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[200], height: 1),
            ),
            _buildAIMenuOption(context: context, isDark: isDark,
                icon: Icons.receipt_long,
                iconColor: Colors.orange,
                title: 'Chụp Ảnh Bill',
                subtitle: 'Chụp hóa đơn và thêm giao dịch nhanh chóng',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const BillScannerViewSimple()));
                }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAIMenuOption({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Text(subtitle,
                      style: TextStyle(fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600])),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (userId == null) {
      return const Scaffold(body: Center(child: Text('Vui lòng đăng nhập')));
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
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
                  var userData = userSnapshot.data?.data() as Map<String, dynamic>? ?? {};
                  double balance = (userData['balance'] ?? 0).toDouble();
                  double totalIncome = (userData['totalIncome'] ?? 0).toDouble();
                  double totalExpense = (userData['totalExpense'] ?? 0).toDouble();

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildBalanceCard(balance, totalIncome, totalExpense, isDark),
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
        onPressed: () => _showAIMenuBottomSheet(isDark),
        backgroundColor: const Color(0xFF00CED1),
        icon: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
        label: const Text('Phân tích nhanh',
            style: TextStyle(color: Colors.white, fontSize: 14,
                fontWeight: FontWeight.w600)),
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
              Text('Giao dịch',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 4),
              Text(searchQuery.isEmpty
                  ? 'Theo dõi chi tiêu của bạn'
                  : 'Tìm kiếm: "$searchQuery"',
                  style: TextStyle(fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600])),
            ],
          ),
          Row(
            children: [
              _headerIcon(Icons.calendar_month, isDark,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CalendarView()))),
              const SizedBox(width: 8),
              _headerIcon(Icons.search, isDark,
                  onTap: () => _showSearchDialog(isDark)),
              const SizedBox(width: 8),
              _headerIcon(Icons.notifications_outlined, isDark,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const NotificationView()))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerIcon(IconData icon, bool isDark, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: Icon(icon, color: isDark ? Colors.grey[300] : Colors.grey[700]),
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
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [Color(0xFF00CED1), Color(0xFF00A8AA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: const Color(0xFF00CED1).withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Text('Tổng số dư',
              style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8))),
          const SizedBox(height: 8),
          Text(_formatCurrency(balance),
              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                  color: Colors.white)),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildBalanceItem(
                  'Tổng thu nhập', totalIncome, Icons.arrow_downward, Colors.green[300]!)),
              Container(height: 40, width: 1, color: Colors.white.withOpacity(0.3)),
              Expanded(child: _buildBalanceItem(
                  'Tổng chi tiêu', totalExpense, Icons.arrow_upward, Colors.red[300]!)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, double amount, IconData icon, Color iconColor) {
    return Column(
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
        ]),
        const SizedBox(height: 4),
        Text(_formatCurrency(amount),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                color: Colors.white)),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (percentage < 70 ? Colors.green : Colors.orange).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.check_circle,
                color: percentage < 70 ? Colors.green[600] : Colors.orange[600], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${percentage.toStringAsFixed(1)}% chi tiêu, ${percentage < 70 ? 'Tốt' : 'Cẩn thận'}',
                    style: TextStyle(fontSize: 13,
                        color: isDark ? Colors.grey[300] : Colors.grey[700])),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                        percentage < 70 ? Colors.green[600]! : Colors.red[600]!),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(_formatCurrency(budgetLimit),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black)),
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
        onTap: () => setState(() { selectedFilter = value; }),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00CED1)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [BoxShadow(color: const Color(0xFF00CED1).withOpacity(0.3), blurRadius: 10)]
                : null,
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.grey[400] : Colors.grey[700]))),
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
              child: Padding(padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Lỗi: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center),
            ]),
          ));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return TransactionWidgets.buildEmptyState(isDark, selectedFilter);
        }

        List<DocumentSnapshot> allDocs = snapshot.data!.docs;
        List<DocumentSnapshot> filteredDocs = allDocs.where((doc) {
          var data = doc.data() as Map<String, dynamic>;
          String type = (data['type'] ?? '').toString().toLowerCase();
          if (selectedFilter == 'Income' && type != 'income') return false;
          if (selectedFilter == 'Expense' && type != 'expense') return false;
          if (searchQuery.isNotEmpty) {
            String title = (data['title'] ?? '').toString().toLowerCase();
            String category = (data['category'] ?? '').toString().toLowerCase();
            if (!title.contains(searchQuery) && !category.contains(searchQuery)) return false;
          }
          return true;
        }).toList();

        if (filteredDocs.isEmpty) {
          return TransactionWidgets.buildEmptyState(isDark, selectedFilter);
        }

        double totalAmount = 0;
        for (var doc in filteredDocs) {
          var data = doc.data() as Map<String, dynamic>;
          totalAmount += (data['amount'] ?? 0).toDouble().abs();
        }

        Map<String, List<DocumentSnapshot>> groupedTransactions = {};
        for (var doc in filteredDocs) {
          var data = doc.data() as Map<String, dynamic>;
          var timestamp = data['date'] as Timestamp?;
          if (timestamp != null) {
            String monthKey = TransactionWidgets.getVietnameseMonth(timestamp.toDate());
            if (!groupedTransactions.containsKey(monthKey)) {
              groupedTransactions[monthKey] = [];
            }
            groupedTransactions[monthKey]!.add(doc);
          }
        }

        return Column(
          children: [
            if (selectedFilter != 'All')
              TransactionWidgets.buildStatisticsCard(
                transactionCount: filteredDocs.length,
                totalAmount: totalAmount,
                isIncome: selectedFilter == 'Income',
                isDark: isDark,
              ),
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
    return _firestore
        .collection('users').doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots();
  }

  Widget _buildMonthSection(
      String month, List<DocumentSnapshot> transactions, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(month,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[300] : Colors.grey[800])),
        ),
        ...transactions.map((doc) {
          var data = doc.data() as Map<String, dynamic>;
          return TransactionWidgets.buildTransactionItem(
            context: context,
            doc: doc,
            isDark: isDark,
            onDelete: () => _deleteTransaction(doc.id, data),
            onTap: () async {
              final result = await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => EditTransactionView(
                      transactionId: doc.id, transactionData: data)));
              if (result == true && mounted) setState(() {});
            },
          );
        }).toList(),
      ],
    );
  }

  // ✅ UPDATED: Voice ở giữa, xóa Transaction tab
  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Home',
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const HomeView()))),
              _buildNavItem(Icons.search_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Analysis',
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const AnalysisView()))),
              // ✅ Voice ở giữa
              _buildVoiceNavItem(),
              _buildNavItem(Icons.layers_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Category',
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const CategoriesView()))),
              _buildNavItem(Icons.person_outline_rounded, false,
                  isDark ? Colors.grey[500]! : Colors.grey[400]!,
                  label: 'Profile',
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const ProfileView()))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceNavItem() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/test-voice'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(
                  color: const Color(0xFF00CED1).withOpacity(0.45),
                  blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 4),
          const Text('Voice',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                  color: Color(0xFF00CED1))),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color,
      {VoidCallback? onTap, String label = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isActive ? color.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: isActive ? color : color, size: 24),
          ),
          if (label.isNotEmpty)
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                    color: isActive
                        ? color
                        : isDark ? Colors.grey[500]! : Colors.grey[400]!)),
        ],
      ),
    );
  }
}