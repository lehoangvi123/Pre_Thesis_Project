// lib/view/CategorizeContent.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './HomeView.dart';
import './AnalysisView.dart';
import './Transaction.dart';
import '../notification/NotificationView.dart';
import './ProfileView.dart';
import '../FunctionCategorize/CategorizeDetailsView.dart';
import '../FunctionCategorize/AddCategorizeDialog.dart';
import '../Achivement/Achievement_model.dart';
import '../Achivement/Achievement_service.dart';
import '../Achivement/Achievement_view.dart';
import '../Achivement/Achievement_popup.dart';

class CategoriesView extends StatefulWidget {
  final String? initialType;
  const CategoriesView({Key? key, this.initialType}) : super(key: key);

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AchievementService _achievementService = AchievementService();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _expenseKey = GlobalKey();
  final GlobalKey _incomeKey  = GlobalKey();

  // ✅ Alert flags — chỉ hiện 1 lần mỗi session
  bool _hasShownAlert50 = false;
  bool _hasShownAlert90 = false;

  final List<Map<String, dynamic>> _defaultExpenseCategories = [
    {'name': 'Food',          'icon': Icons.restaurant,       'color': Color(0xFFFF6B6B), 'type': 'expense'},
    {'name': 'Transport',     'icon': Icons.directions_bus,   'color': Color(0xFF4ECDC4), 'type': 'expense'},
    {'name': 'Medicine',      'icon': Icons.medical_services, 'color': Color(0xFFFF8B94), 'type': 'expense'},
    {'name': 'Groceries',     'icon': Icons.shopping_bag,     'color': Color(0xFFFFBE0B), 'type': 'expense'},
    {'name': 'Rent',          'icon': Icons.home,             'color': Color(0xFF8B5CF6), 'type': 'expense'},
    {'name': 'Gifts',         'icon': Icons.card_giftcard,    'color': Color(0xFFFF6FC8), 'type': 'expense'},
    {'name': 'Savings',       'icon': Icons.savings,          'color': Color(0xFF06D6A0), 'type': 'expense'},
    {'name': 'Entertainment', 'icon': Icons.movie,            'color': Color(0xFF118AB2), 'type': 'expense'},
  ];

  final List<Map<String, dynamic>> _defaultIncomeCategories = [
    {'name': 'Salary',     'icon': Icons.account_balance_wallet, 'color': Color(0xFF2DC653), 'type': 'income'},
    {'name': 'Freelance',  'icon': Icons.laptop_mac,             'color': Color(0xFF00B4D8), 'type': 'income'},
    {'name': 'Investment', 'icon': Icons.trending_up,            'color': Color(0xFFFFB703), 'type': 'income'},
  ];

  @override
  void initState() {
    super.initState();
    _checkInitialAchievements();
    if (widget.initialType == 'income') {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToIncome());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToIncome() {
    final ctx = _incomeKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut, alignment: 0.0);
    }
  }

  Future<void> _checkInitialAchievements() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final progress = await _achievementService.calculateProgress(user.uid);
      final newAchievements = await _achievementService.checkAndUnlockAchievements(
        transactionCount: progress['transactionCount'],
        savingsAmount: progress['savingsAmount'],
        streakDays: progress['streakDays'],
      );
      for (final achievement in newAchievements) {
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          AchievementPopupSimple.show(context, achievement);
        }
      }
    } catch (e) { print('Achievement check error: $e'); }
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }

  // ✅ Kiểm tra và hiện alert khi chi tiêu vượt ngưỡng
  void _checkSpendingAlert(double totalExpense, double totalIncome) {
    if (totalIncome <= 0) return;
    final pct = totalExpense / totalIncome * 100;

    // Alert 50%
    if (pct >= 50 && pct < 90 && !_hasShownAlert50) {
      _hasShownAlert50 = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.info_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text(
              '⚡ Bạn đã chi hơn 50% thu nhập tháng này!',
              style: TextStyle(fontWeight: FontWeight.w600),
            )),
          ]),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
        ));
      });
    }

    // Alert 90%
    if (pct >= 90 && !_hasShownAlert90) {
      _hasShownAlert90 = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.warning_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Expanded(child: Text(
              '🚨 Cảnh báo! Bạn đã chi gần hết thu nhập tháng này!',
              style: TextStyle(fontWeight: FontWeight.bold),
            )),
          ]),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(12),
          action: SnackBarAction(
            label: 'Xem chi tiết',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: userId == null
            ? const Center(child: Text('Please login'))
            : StreamBuilder<DocumentSnapshot>(
                stream: _firestore.collection('users').doc(userId).snapshots(),
                builder: (context, snapshot) {
                  double balance     = 0.0;
                  double totalIncome  = 0.0;
                  double totalExpense = 0.0;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    balance      = (userData['balance']      ?? 0).toDouble();
                    totalIncome  = (userData['totalIncome']  ?? 0).toDouble();
                    totalExpense = (userData['totalExpense'] ?? 0).toDouble();
                  }

                  // ✅ Kiểm tra alert mỗi khi data thay đổi
                  _checkSpendingAlert(totalExpense, totalIncome);

                  return SingleChildScrollView(
                    controller: _scrollController,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 28),
                          _buildBalanceCards(
                              balance, totalIncome, totalExpense, isDark),
                          const SizedBox(height: 32),
                          _buildCategoriesSection(
                            key: _expenseKey,
                            title: 'Expense',
                            categories: _defaultExpenseCategories,
                            categoryType: 'expense',
                          ),
                          const SizedBox(height: 40),
                          _buildCategoriesSection(
                            key: _incomeKey,
                            title: 'Income',
                            categories: _defaultIncomeCategories,
                            categoryType: 'income',
                          ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Categories', style: TextStyle(
              fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: -0.5,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
          const SizedBox(height: 6),
          Text('Manage your categories', style: TextStyle(
              fontSize: 15, fontWeight: FontWeight.w400,
              color: isDark ? Colors.grey[400] : Colors.grey[600])),
        ])),
        Row(mainAxisSize: MainAxisSize.min, children: [
          // Achievement
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF00D09E), Color(0xFF00A8AA)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: const Color(0xFF00D09E).withOpacity(0.25),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AchievementsView())),
                borderRadius: BorderRadius.circular(12),
                child: Center(child: Stack(clipBehavior: Clip.none, children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                  Positioned(right: -2, top: -2, child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle))),
                ])),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Transaction
          GestureDetector(
            onTap: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const TransactionView())),
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                    blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Icon(Icons.swap_horiz_rounded,
                  color: isDark ? Colors.grey[300] : Colors.grey[700], size: 22),
            ),
          ),
          const SizedBox(width: 8),
          // Notification
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Material(color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const NotificationView())),
                borderRadius: BorderRadius.circular(12),
                child: Center(child: Icon(Icons.notifications_outlined,
                    color: isDark ? Colors.grey[300] : Colors.grey[700], size: 22)),
              ),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildBalanceCards(double balance, double totalIncome,
      double totalExpense, bool isDark) {
    return Column(children: [
      Row(children: [
        Expanded(child: _buildInfoCard(
            title: 'Total Income',
            amount: '+${_formatCurrency(totalIncome)} đ',
            icon: Icons.trending_up_rounded,
            color: Colors.green[600]!, isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoCard(
            title: 'Total Expenses',
            amount: '${_formatCurrency(totalExpense)} đ',
            icon: Icons.trending_down_rounded,
            color: Colors.red[600]!, isDark: isDark)),
      ]),
      const SizedBox(height: 12),
      _buildInfoCard(
          title: 'Total Balance',
          amount: '${balance >= 0 ? '+' : ''}${_formatCurrency(balance.abs())} đ',
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.blue[600]!, isDark: isDark, isFullWidth: true),
      const SizedBox(height: 16),
      // ✅ Progress bar mới — dùng totalIncome thực tế
      _buildProgressBar(totalExpense, totalIncome, isDark),
    ]);
  }

  // ✅ Progress bar mới — theo totalIncome thực tế + 2 mức cảnh báo
  Widget _buildProgressBar(
      double totalExpense, double totalIncome, bool isDark) {

    // Nếu chưa có thu nhập thì ẩn
    if (totalIncome <= 0) return const SizedBox.shrink();

    final percentage = (totalExpense / totalIncome * 100).clamp(0.0, 100.0);

    // Màu + trạng thái theo mức %
    final Color barColor;
    final Color bgColor;
    final IconData statusIcon;
    final String statusText;

    if (percentage >= 90) {
      barColor   = Colors.red[600]!;
      bgColor    = Colors.red.withOpacity(0.08);
      statusIcon = Icons.warning_rounded;
      statusText = 'Vượt ngưỡng nguy hiểm!';
    } else if (percentage >= 50) {
      barColor   = Colors.orange[600]!;
      bgColor    = Colors.orange.withOpacity(0.08);
      statusIcon = Icons.info_rounded;
      statusText = 'Đã chi quá nửa thu nhập';
    } else {
      barColor   = Colors.green[600]!;
      bgColor    = Colors.green.withOpacity(0.08);
      statusIcon = Icons.check_circle_rounded;
      statusText = 'Chi tiêu đang ổn định';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: barColor.withOpacity(0.25), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                color: barColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(statusIcon, color: barColor, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(statusText, style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : Colors.grey[800]))),
          // % badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
                color: barColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(99)),
            child: Text('${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12,
                    fontWeight: FontWeight.bold, color: barColor)),
          ),
        ]),

        const SizedBox(height: 12),

        // Thanh progress
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),

        const SizedBox(height: 10),

        // Số tiền đã chi / thu nhập
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Đã chi: ${_formatCurrency(totalExpense)}đ',
              style: TextStyle(fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600])),
          Text('Thu nhập: ${_formatCurrency(totalIncome)}đ',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[300] : Colors.grey[700])),
        ]),

        // ✅ Alert box khi >= 50%
        if (percentage >= 50) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: barColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: barColor.withOpacity(0.3)),
            ),
            child: Row(children: [
              Icon(
                percentage >= 90
                    ? Icons.notifications_active_rounded
                    : Icons.tips_and_updates_rounded,
                color: barColor, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text(
                percentage >= 90
                    ? 'Bạn đã chi ${percentage.toStringAsFixed(0)}% thu nhập! Hãy dừng chi tiêu không cần thiết ngay.'
                    : 'Bạn đã chi hơn 50% thu nhập tháng này. Hãy kiểm soát chi tiêu cẩn thận hơn.',
                style: TextStyle(fontSize: 11, height: 1.4, color: barColor),
              )),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required bool isDark,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF2C2C2C), const Color(0xFF242424)]
              : [Colors.white, const Color(0xFFFAFAFA)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          const SizedBox(width: 6),
          Expanded(child: Text(title, style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey[400] : Colors.grey[600]))),
        ]),
        const SizedBox(height: 12),
        Text(amount, style: TextStyle(
            fontSize: isFullWidth ? 22 : 18,
            fontWeight: FontWeight.bold, color: color, letterSpacing: -0.5)),
      ]),
    );
  }

  Widget _buildCategoriesSection({
    Key? key,
    required String title,
    required List<Map<String, dynamic>> categories,
    required String categoryType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighlighted =
        widget.initialType != null && widget.initialType == categoryType;

    return Container(
      key: key,
      decoration: isHighlighted
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: categoryType == 'income'
                    ? Colors.green.withOpacity(0.5)
                    : Colors.red.withOpacity(0.5),
                width: 2,
              ),
            )
          : null,
      padding: isHighlighted ? const EdgeInsets.all(12) : EdgeInsets.zero,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: categoryType == 'income'
                    ? Colors.green.withOpacity(0.15)
                    : Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                categoryType == 'income'
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: categoryType == 'income'
                    ? Colors.green[600] : Colors.red[500],
                size: 20,
              ),
            ),
            Text(title, style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A1A))),
            if (isHighlighted) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: categoryType == 'income'
                      ? Colors.green.withOpacity(0.15)
                      : Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  categoryType == 'income' ? '💰 Thu nhập' : '💸 Chi tiêu',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: categoryType == 'income'
                          ? Colors.green[700] : Colors.red[600]),
                ),
              ),
            ],
          ]),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_auth.currentUser?.uid)
              .collection('categories')
              .snapshots(),
          builder: (context, snapshot) {
            final customCategories = snapshot.hasData
                ? snapshot.data!.docs.map((doc) {
                    try {
                      final data = doc.data() as Map<String, dynamic>;
                      IconData icon = Icons.category;
                      if (data['icon'] != null) {
                        if (data['icon'] is int)
                          icon = IconData(data['icon'] as int, fontFamily: 'MaterialIcons');
                        else if (data['icon'] is String)
                          icon = _getIconFromString(data['icon'] as String);
                      }
                      int colorValue = 0xFF00CED1;
                      if (data['color'] != null) {
                        if (data['color'] is int) colorValue = data['color'] as int;
                        else if (data['color'] is String)
                          colorValue = int.tryParse(data['color']) ?? 0xFF00CED1;
                      }
                      final docType = data['type'] ?? 'expense';
                      if (docType != categoryType) return null;
                      return {
                        'name': data['name'] ?? 'Untitled',
                        'icon': icon,
                        'color': Color(colorValue),
                        'type': docType,
                        'isCustom': true,
                      };
                    } catch (e) { return null; }
                  }).where((item) => item != null).cast<Map<String, dynamic>>().toList()
                : <Map<String, dynamic>>[];

            final allCategories = [...categories, ...customCategories];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3, childAspectRatio: 1.0,
                crossAxisSpacing: 16, mainAxisSpacing: 16,
              ),
              itemCount: allCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == allCategories.length) {
                  return _buildMoreButton(categoryType);
                }
                final category = allCategories[index];
                return _buildCategoryCard(
                  category['name'], category['icon'],
                  category['color'], category['isCustom'] ?? false,
                );
              },
            );
          },
        ),
      ]),
    );
  }

  Widget _buildCategoryCard(
      String name, IconData icon, Color color, bool isCustom) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => CategoryDetailView(
              categoryColor: color, categoryName: name, categoryIcon: icon))),
      onLongPress: isCustom ? () => _showDeleteDialog(name) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: color.withOpacity(isDark ? 0.25 : 0.18),
              blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.85), color],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 28, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(name,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                    color: isDark ? Colors.grey[100] : const Color(0xFF1A1A1A)),
                textAlign: TextAlign.center, maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant': case 'food': return Icons.restaurant;
      case 'directions_bus': case 'transport': return Icons.directions_bus;
      case 'medical_services': return Icons.medical_services;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'home': return Icons.home;
      case 'card_giftcard': return Icons.card_giftcard;
      case 'savings': return Icons.savings;
      case 'movie': return Icons.movie;
      case 'account_balance_wallet': return Icons.account_balance_wallet;
      case 'laptop_mac': return Icons.laptop_mac;
      case 'trending_up': return Icons.trending_up;
      default: return Icons.category;
    }
  }

  void _showDeleteDialog(String categoryName) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text('Xóa danh mục?'),
      content: Text('Bạn có chắc muốn xóa "$categoryName"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Hủy')),
        TextButton(
          onPressed: () { Navigator.pop(context); _deleteCategory(categoryName); },
          child: const Text('Xóa', style: TextStyle(color: Colors.red)),
        ),
      ],
    ));
  }

  Future<void> _deleteCategory(String categoryName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      final snapshot = await _firestore
          .collection('users').doc(userId).collection('categories')
          .where('name', isEqualTo: categoryName).get();
      for (var doc in snapshot.docs) { await doc.reference.delete(); }
    } catch (e) { print('Error deleting category: $e'); }
  }

  Widget _buildMoreButton(String categoryType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = categoryType == 'income'
        ? const Color(0xFF2DC653) : const Color(0xFF4ECDC4);
    return GestureDetector(
      onTap: () async {
        final result = await showDialog<bool>(context: context,
            builder: (_) => AddCategoryDialog(categoryType: categoryType));
        if (result == true) setState(() {});
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(
              color: color.withOpacity(0.2), blurRadius: 10,
              offset: const Offset(0, 4))],
          border: Border.all(color: color.withOpacity(0.4),
              width: 1.5, style: BorderStyle.solid),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [color.withOpacity(0.15), color.withOpacity(0.25)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.add_rounded, size: 28, color: color),
          ),
          const SizedBox(height: 10),
          Text('Add New', style: TextStyle(fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey[100] : const Color(0xFF1A1A1A))),
        ]),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, false,
                  isDark ? Colors.grey[400]! : Colors.grey[500]!,
                  label: 'Home',
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const HomeView()))),
              _buildNavItem(Icons.assignment_rounded, false,
                  isDark ? Colors.grey[400]! : Colors.grey[500]!,
                  label: 'Plan',
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const AnalysisView()))),
              _buildVoiceNavItem(),
              _buildNavItem(Icons.layers_rounded, true,
                  const Color(0xFF00CED1),
                  label: 'Category', onTap: () {}),
              _buildNavItem(Icons.person_outline_rounded, false,
                  isDark ? Colors.grey[400]! : Colors.grey[500]!,
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
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF00CED1), Color(0xFF8B5CF6)]),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(
                color: const Color(0xFF00CED1).withOpacity(0.45),
                blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: const Icon(Icons.mic_rounded, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 4),
        const Text('Voice', style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: Color(0xFF00CED1))),
      ]),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color,
      {VoidCallback? onTap, String label = ''}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isActive ? color.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: isActive ? color : color, size: 24),
        ),
        if (label.isNotEmpty)
          Text(label, style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? color
                  : isDark ? Colors.grey[500]! : Colors.grey[400]!)),
      ]),
    );
  }
}