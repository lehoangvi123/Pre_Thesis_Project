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

class CategoriesView extends StatefulWidget {
  const CategoriesView({Key? key}) : super(key: key);

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
                          
                          // ✅ UPDATED: Balance Cards với real-time data
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

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
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
              'Manage your expense & income categories',
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            borderRadius: BorderRadius.circular(14),
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
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(
                  Icons.notifications_outlined,
                  color: isDark ? Colors.grey[300] : Colors.grey[700],
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ✅ UPDATED: Balance Cards với real-time data
  Widget _buildBalanceCards(double balance, double totalIncome, double totalExpense, bool isDark) {
    return Column(
      children: [
        // Row 1: Balance and Income
        Row(
          children: [
            // Total Balance Card
            Expanded(
              child: _buildInfoCard(
                title: 'Total Balance',
                amount: '${_formatCurrency(balance)} đ',
                icon: Icons.account_balance_wallet_rounded,
                color: balance >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFE53935),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            // Total Income Card
            Expanded(
              child: _buildInfoCard(
                title: 'Total Income',
                amount: '${_formatCurrency(totalIncome)} đ',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF4CAF50),
                isDark: isDark, 
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Row 2: Expenses (full width)
        _buildInfoCard(
          title: 'Total Expenses',
          amount: '${_formatCurrency(totalExpense)} đ',
          icon: Icons.trending_down_rounded,
          color: const Color(0xFF2196F3),
          isDark: isDark,
          isFullWidth: true,
        ),
        const SizedBox(height: 16),
        // Progress bar
        _buildProgressBar(totalExpense, isDark),
      ],
    );
  }

  // ✅ Progress Bar
  Widget _buildProgressBar(double totalExpense, bool isDark) {
    double budgetLimit = 20000000; // 20 triệu VND
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

  // ... REST OF THE CODE CONTINUES IN NEXT PART 
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

  // ... (Copy tất cả methods còn lại từ file cũ của bạn)
  // _buildCategoryCard, _getIconFromString, _showDeleteDialog, 
  // _deleteCategory, _buildMoreButton, _buildBottomNavBar, _buildNavItem 
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
      onLongPress: isCustom
          ? () {
              _showDeleteDialog(name);
            }
          : null,
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
              child: Icon(
                icon,
                size: 32,
                color: color,
              ),
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

  // Helper method to convert icon string names to IconData
  IconData _getIconFromString(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'restaurant':
      case 'food':
        return Icons.restaurant;
      case 'directions_bus':
      case 'transport':
      case 'bus':
        return Icons.directions_bus;
      case 'medical_services':
      case 'medicine':
      case 'health':
        return Icons.medical_services;
      case 'shopping_bag':
      case 'groceries':
      case 'shopping':
        return Icons.shopping_bag;
      case 'home':
      case 'rent':
      case 'house':
        return Icons.home;
      case 'card_giftcard':
      case 'gifts':
      case 'gift':
        return Icons.card_giftcard;
      case 'savings':
      case 'piggy_bank':
        return Icons.savings;
      case 'movie':
      case 'entertainment':
        return Icons.movie;
      case 'account_balance_wallet':
      case 'salary':
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'laptop_mac':
      case 'freelance':
      case 'laptop':
        return Icons.laptop_mac;
      case 'trending_up':
      case 'investment':
      case 'stocks':
        return Icons.trending_up;
      case 'category':
        return Icons.category;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'local_cafe':
      case 'cafe':
      case 'coffee':
        return Icons.local_cafe;
      case 'fitness_center':
      case 'gym':
        return Icons.fitness_center;
      case 'school':
      case 'education':
        return Icons.school;
      case 'work':
      case 'briefcase':
        return Icons.work;
      case 'pets':
        return Icons.pets;
      case 'sports_soccer':
      case 'soccer':
        return Icons.sports_soccer;
      case 'music_note':
      case 'music':
        return Icons.music_note;
      case 'book':
        return Icons.book;
      case 'computer':
        return Icons.computer;
      case 'phone_android':
      case 'phone':
        return Icons.phone_android;
      case 'weekend':
        return Icons.weekend;
      case 'flight':
        return Icons.flight;
      case 'hotel':
        return Icons.hotel;
      case 'spa':
        return Icons.spa;
      case 'beach_access':
      case 'beach':
        return Icons.beach_access;
      case 'child_care':
        return Icons.child_care;
      case 'local_hospital':
      case 'hospital':
        return Icons.local_hospital;
      case 'local_pharmacy':
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'local_bar':
      case 'bar':
        return Icons.local_bar;
      case 'local_pizza':
      case 'pizza':
        return Icons.local_pizza;
      case 'fastfood':
        return Icons.fastfood;
      case 'camera_alt':
      case 'camera':
        return Icons.camera_alt;
      case 'brush':
        return Icons.brush;
      case 'palette':
        return Icons.palette;
      case 'theaters':
        return Icons.theaters;
      case 'videogame_asset':
      case 'games':
        return Icons.videogame_asset;
      case 'headset':
        return Icons.headset;
      case 'celebration':
        return Icons.celebration;
      case 'cake':
        return Icons.cake;
      case 'local_florist':
      case 'flowers':
        return Icons.local_florist;
      default:
        return Icons.category;
    }
  }

  void _showDeleteDialog(String categoryName) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Delete Category',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "$categoryName"?\n\nThis will also delete all transactions in this category.',
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.grey[700],
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteCategory(categoryName);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCategory(String categoryName) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final categoriesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      final expensesSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('expenses')
          .where('category', isEqualTo: categoryName)
          .get();

      for (var doc in categoriesSnapshot.docs) {
        await doc.reference.delete();
      }

      for (var doc in expensesSnapshot.docs) {
        await doc.reference.delete();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category "$categoryName" deleted'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete category: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  // Just replace the _buildMoreButton method in your CategoriesView.dart with this:

  
Widget _buildMoreButton(String categoryType) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final color = categoryType == 'income' 
      ? const Color(0xFF4CAF50) 
      : const Color(0xFF90CAF9);

  return GestureDetector(
    onTap: () async {
      // ✅ FIXED: Pass categoryType to dialog
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AddCategoryDialog(
          categoryType: categoryType, // ✅ This is the fix!
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
          style: BorderStyle.solid,
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
            child: Icon(
              Icons.add_rounded,
              size: 32,
              color: color,
            ),
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
        child: Icon(
          icon,
          color: color,
          size: 26,
        ),
      ),
    );
  }
}