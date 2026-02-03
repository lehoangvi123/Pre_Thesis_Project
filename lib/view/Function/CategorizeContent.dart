// lib/view/CategoriesView.dart
// UPDATED VERSION - Tích hợp Gamification

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

// ✅ THÊM IMPORTS CHO GAMIFICATION
import '../Achivement/Achievement_model.dart';
import '../Achivement/Achievement_service.dart';
import '../Achivement/Achievement_view.dart';
import '../Achivement/Achievement_popup.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({Key? key}) : super(key: key);

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ THÊM ACHIEVEMENT SERVICE
  final AchievementService _achievementService = AchievementService();

  // Expense Categories
  final List<Map<String, dynamic>> _defaultExpenseCategories = [
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Color(0xFF00CED1), 'type': 'expense'},
    {'name': 'Transport', 'icon': Icons.directions_bus, 'color': Color(0xFF00CED1), 'type': 'expense'},
    {'name': 'Medicine', 'icon': Icons.medical_services, 'color': Color(0xFF00CED1), 'type': 'expense'},
    {'name': 'Groceries', 'icon': Icons.shopping_bag, 'color': Color(0xFF64B5F6), 'type': 'expense'},
    {'name': 'Rent', 'icon': Icons.home, 'color': Color(0xFF64B5F6), 'type': 'expense'},
    {'name': 'Gifts', 'icon': Icons.card_giftcard, 'color': Color(0xFF64B5F6), 'type': 'expense'},
    {'name': 'Savings', 'icon': Icons.savings, 'color': Color(0xFF90CAF9), 'type': 'expense'},
    {'name': 'Entertainment', 'icon': Icons.movie, 'color': Color(0xFF90CAF9), 'type': 'expense'},
  ];

  // Income Categories
  final List<Map<String, dynamic>> _defaultIncomeCategories = [
    {'name': 'Salary', 'icon': Icons.account_balance_wallet, 'color': Color(0xFF4CAF50), 'type': 'income'},
    {'name': 'Freelance', 'icon': Icons.laptop_mac, 'color': Color(0xFF66BB6A), 'type': 'income'},
    {'name': 'Investment', 'icon': Icons.trending_up, 'color': Color(0xFF81C784), 'type': 'income'},
  ];

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // ✅ CHECK ACHIEVEMENTS WHEN VIEW LOADS
  @override
  void initState() {
    super.initState();
    _checkInitialAchievements();
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

      // Show popups for new achievements
      for (final achievement in newAchievements) {
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 500));
          AchievementPopupSimple.show(context, achievement);
        }
      }
    } catch (e) {
      print('Achievement check error: $e');
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
                  double balance = 0.0;
                  double totalIncome = 0.0;
                  double totalExpense = 0.0;

                  if (snapshot.hasData && snapshot.data!.exists) {
                    var userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
                    balance = (userData['balance'] ?? 0).toDouble();
                    totalIncome = (userData['totalIncome'] ?? 0).toDouble();
                    totalExpense = (userData['totalExpense'] ?? 0).toDouble();
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 28),
                          
                          _buildBalanceCards(balance, totalIncome, totalExpense, isDark),
                          
                          const SizedBox(height: 32),
                          
                          // Expense Categories Section
                          _buildCategoriesSection(
                            title: 'Expense',
                            categories: _defaultExpenseCategories,
                            categoryType: 'expense',
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Income Categories Section
                          _buildCategoriesSection(
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

  // ✅ UPDATED HEADER WITH ACHIEVEMENTS BUTTON
  // ✅ FIXED VERSION - Replace _buildHeader() method

Widget _buildHeader() {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Row 1: Title + Buttons
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categories',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Manage your categories',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          // Buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Achievements Button
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D09E), Color(0xFF00A8AA)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00D09E).withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AchievementsView(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.amber,
                            size: 22,
                          ),
                          // Red dot badge
                          Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Notifications Button
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NotificationView(),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Center(
                      child: Icon(
                        Icons.notifications_outlined,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

  // ✅ GIỮ NGUYÊN TẤT CẢ CÁC METHODS CÒN LẠI
  Widget _buildBalanceCards(double balance, double totalIncome, double totalExpense, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: 'Total Income',
                amount: '+${_formatCurrency(totalIncome)} đ',
                icon: Icons.trending_up_rounded,
                color: Colors.green[600]!,
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                title: 'Total Expenses',
                amount: '${_formatCurrency(totalExpense)} đ',
                icon: Icons.trending_down_rounded,
                color: Colors.red[600]!,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: 'Total Balance',
          amount: '${balance >= 0 ? '+' : ''}${_formatCurrency(balance.abs())} đ',
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.blue[600]!,
          isDark: isDark,
          isFullWidth: true,
        ),
        const SizedBox(height: 16),
        _buildProgressBar(totalExpense, isDark),
      ],
    );
  }

  Widget _buildProgressBar(double totalExpense, bool isDark) {
    double budgetLimit = 20000000;
    double percentage = totalExpense > 0 
        ? (totalExpense / budgetLimit * 100).clamp(0, 100) 
        : 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark 
            ? Colors.green.withOpacity(0.12) 
            : Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.green.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.check_circle_rounded,
              color: Colors.green[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}% Of Your Expenses',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    percentage < 70 ? Colors.green[600]! : Colors.red[600]!,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${_formatCurrency(budgetLimit)} đ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: isFullWidth ? 22 : 18,
              fontWeight: FontWeight.bold,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ... (Copy TẤT CẢ các methods còn lại từ code cũ của bạn)
  // _buildCategoriesSection, _buildCategoryCard, _getIconFromString, 
  // _showDeleteDialog, _deleteCategory, _buildMoreButton, 
  // _buildBottomNavBar, _buildNavItem

  Widget _buildCategoriesSection({
    required String title,
    required List<Map<String, dynamic>> categories,
    required String categoryType,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(
            children: [
              if (categoryType == 'income')
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.green[600],
                    size: 20,
                  ),
                ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('users')
              .doc(_auth.currentUser?.uid)
              .collection('categories')
              .snapshots(),
          builder: (context, snapshot) {
            final customCategories = snapshot.hasData
                ? snapshot.data!.docs
                    .map((doc) {
                      try {
                        final data = doc.data() as Map<String, dynamic>;
                        
                        IconData icon = Icons.category;
                        if (data['icon'] != null) {
                          if (data['icon'] is int) {
                            icon = IconData(data['icon'] as int, fontFamily: 'MaterialIcons');
                          } else if (data['icon'] is String) {
                            icon = _getIconFromString(data['icon'] as String);
                          }
                        }
                        
                        int colorValue = 0xFF00CED1;
                        if (data['color'] != null) {
                          if (data['color'] is int) {
                            colorValue = data['color'] as int;
                          } else if (data['color'] is String) {
                            colorValue = int.tryParse(data['color']) ?? 0xFF00CED1;
                          }
                        }
                        
                        String docType = data['type'] ?? 'expense';
                        
                        if (docType != categoryType) {
                          return null;
                        }
                        
                        return {
                          'name': data['name'] ?? 'Untitled',
                          'icon': icon,
                          'color': Color(colorValue),
                          'type': docType,
                          'isCustom': true,
                        };
                      } catch (e) {
                        print('Error parsing category: $e');
                        return null;
                      }
                    })
                    .where((item) => item != null)
                    .cast<Map<String, dynamic>>()
                    .toList()
                : <Map<String, dynamic>>[];

            final allCategories = [...categories, ...customCategories];

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.0,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: allCategories.length + 1,
              itemBuilder: (context, index) {
                if (index == allCategories.length) {
                  return _buildMoreButton(categoryType);
                }

                final category = allCategories[index];
                return _buildCategoryCard(
                  category['name'],
                  category['icon'],
                  category['color'],
                  category['isCustom'] ?? false,
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryCard(
      String name, IconData icon, Color color, bool isCustom) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryDetailView( 
              categoryColor: color,
              categoryName: name, 
              categoryIcon: icon,
            ),
          ),
        );
      },
      onLongPress: isCustom ? () => _showDeleteDialog(name) : null,
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? color.withOpacity(0.12)
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.3 : 0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    // ... (Copy từ code cũ - quá dài nên tôi không paste lại)
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      // ... etc
      default:
        return Icons.category;
    }
  }

  void _showDeleteDialog(String categoryName) {
    // ... (Copy từ code cũ)
  }

  Future<void> _deleteCategory(String categoryName) async {
    // ... (Copy từ code cũ)
  }

  Widget _buildMoreButton(String categoryType) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = categoryType == 'income' 
        ? const Color(0xFF4CAF50) 
        : const Color(0xFF90CAF9);

    return GestureDetector(
      onTap: () async {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) => AddCategoryDialog(
            categoryType: categoryType,
          ),
        );

        if (result == true) {
          setState(() {});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark 
              ? color.withOpacity(0.12) 
              : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.35 : 0.25),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.add_rounded, size: 32, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              'Add New',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[200] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                Icons.home_rounded,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[500]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.search_rounded,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[500]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalysisView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.swap_horiz_rounded,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[500]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.layers_rounded,
                true,
                const Color(0xFF00CED1),
                onTap: () {},
              ),
              _buildNavItem(
                Icons.person_outline_rounded,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[500]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ProfileView()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    bool isActive,
    Color color, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}