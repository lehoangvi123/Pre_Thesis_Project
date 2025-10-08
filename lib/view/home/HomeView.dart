import 'package:flutter/material.dart'; 
import '../login/LoginView.dart'; 
import '../notification/NotificationView.dart';

class HomeView extends StatefulWidget {
  const HomeView({Key? key}) : super(key: key);

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  String selectedPeriod = 'Monthly';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                const SizedBox(height: 24),

                // Balance Cards Row
                _buildBalanceCards(),
                const SizedBox(height: 12),

                // Progress Indicator
                _buildProgressIndicator(),
                const SizedBox(height: 12),

                // Progress Text
                _buildProgressText(),
                const SizedBox(height: 20),

                // Green Card with Goals and Spending
                _buildGreenCard(),
                const SizedBox(height: 20),

                // Period Selector
                _buildPeriodSelector(),
                const SizedBox(height: 16),

                // Transaction List
                _buildTransactionList(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi, Welcome Back',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Lehoangvi',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        Row(
          children: [
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.notifications_outlined, color: Colors.grey[700], size: 20),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _showLogoutDialog,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.logout, color: Colors.red[600], size: 18),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Hủy',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (Route<dynamic> route) => false,
    );
  }

  Widget _buildBalanceCards() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Total Balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '7,783,000 VND',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.circle, size: 8, color: Colors.grey[400]),
                  const SizedBox(width: 6),
                  Text(
                    'Total Expense',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                '-1,455,444 VND',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        Expanded(
          flex: 40,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          flex: 60,
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressText() {
    return Row(
      children: [
        Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '35% Of Your Expenses, Looks Good.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ),
        Text(
          '\$20,000.00',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildGreenCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF7FFFD4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Left Side - On Goals Icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.track_changes,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  'On Goals',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          
          // Right Side - Spending Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Groceries Last Week
                Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Groceries Last Week',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '4,000,000 VND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Food Last Week
                Row(
                  children: [
                    Icon(Icons.restaurant_outlined, size: 18, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    Text(
                      'Food Last Week',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '100,000 VND',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        _buildPeriodButton('Daily'),
        const SizedBox(width: 8),
        _buildPeriodButton('Weekly'),
        const SizedBox(width: 8),
        _buildPeriodButton('Monthly'),
      ],
    );
  }

  Widget _buildPeriodButton(String period) {
    bool isSelected = selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            selectedPeriod = period;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00D09E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF00D09E) : Colors.grey[300]!,
            ),
          ),
          child: Center(
            child: Text(
              period,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList() {
    return Column(
      children: [
        _buildTransactionItem(
          icon: Icons.attach_money_rounded,
          iconColor: const Color(0xFF4A90E2),
          iconBg: const Color(0xFFE3F2FD),
          title: 'Salary',
          date: '16-27 - April 30',
          category: 'Monthly',
          amount: '5,000,000 VND',
          isPositive: false,
        ),
        const SizedBox(height: 10),
        _buildTransactionItem(
          icon: Icons.shopping_cart_outlined,
          iconColor: const Color(0xFF5C9FD6),
          iconBg: const Color(0xFFE1F5FE),
          title: 'Groceries',
          date: '17-30 - April 24',
          category: 'Pantry',
          amount: '-10,000,000 VND',
          isPositive: false,
        ),
        const SizedBox(height: 10),
        _buildTransactionItem(
          icon: Icons.home_outlined,
          iconColor: const Color(0xFF64B5F6),
          iconBg: const Color(0xFFE3F2FD),
          title: 'Rent',
          date: '8-30 - April 18',
          category: 'Rent',
          amount: '-3,000,000 VND',
          isPositive: false,
        ),
      ],
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String date,
    required String category,
    required String amount,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? Colors.green[600] : Colors.red[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}