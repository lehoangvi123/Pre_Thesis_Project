import 'package:flutter/material.dart'; 
import 'AnalysisView.dart';
import 'HomeView.dart'; 
import './CategorizeContent.dart'; 
import './ProfileView.dart';

class TransactionView extends StatefulWidget {
  const TransactionView({Key? key}) : super(key: key);

  @override
  State<TransactionView> createState() => _TransactionViewState();
}

class _TransactionViewState extends State<TransactionView> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBalanceCard(),
                      const SizedBox(height: 20),

                      _buildProgressBar(),
                      const SizedBox(height: 24),

                      _buildMonthSection('April', [
                        _buildTransactionItem(
                          icon: Icons.attach_money,
                          iconColor: Colors.blue[400]!,
                          backgroundColor: Colors.blue[50]!,
                          title: 'Salary',
                          date: '8-27 - April 30',
                          category: 'Monthly',
                          amount: '\$4,000.00',
                          isPositive: true,
                        ),
                        _buildTransactionItem(
                          icon: Icons.shopping_cart,
                          iconColor: Colors.blue[600]!,
                          backgroundColor: Colors.blue[100]!,
                          title: 'Groceries',
                          date: '17-30 - April 24',
                          category: 'Pantry',
                          amount: '-\$100.00',
                          isPositive: false,
                        ),
                        _buildTransactionItem(
                          icon: Icons.home,
                          iconColor: Colors.blue[400]!,
                          backgroundColor: Colors.blue[50]!,
                          title: 'Rent',
                          date: '8-30 - April 18',
                          category: 'Rent',
                          amount: '-\$674.40',
                          isPositive: false,
                        ),
                        _buildTransactionItem(
                          icon: Icons.directions_bus,
                          iconColor: Colors.blue[300]!,
                          backgroundColor: Colors.blue[50]!,
                          title: 'Transport',
                          date: '8-27 - April 8',
                          category: 'Fuel',
                          amount: '-\$4.19',
                          isPositive: false,
                        ),
                      ]),
                      const SizedBox(height: 24),

                      _buildMonthSection('March', [
                        _buildTransactionItem(
                          icon: Icons.restaurant,
                          iconColor: Colors.blue[300]!,
                          backgroundColor: Colors.blue[50]!,
                          title: 'Food',
                          date: '18-25 - March 18',
                          category: 'Dinner',
                          amount: '-\$70.40',
                          isPositive: false,
                        ),
                      ]),
                      
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Center(
            child: Text(
              'Transaction',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.grey[400] : Colors.grey[800],
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Balance',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$7,783.00',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 16,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total Balance',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '\$20,000.00',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.trending_down,
                          size: 16,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Total Expense',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '-\$1,187.40',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '30% Of Your Expenses, Looks Good',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(String month, List<Widget> transactions) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        ...transactions.map((transaction) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: transaction,
        )),
      ],
    );
  }

  Widget _buildTransactionItem({
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required String title,
    required String date,
    required String category,
    required String amount,
    required bool isPositive,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark
                  ? backgroundColor.withOpacity(0.3)
                  : backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                  color: isDark ? Colors.grey[700] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 14,
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

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
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
              _buildNavItem(
                Icons.home,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.search,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalysisView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.swap_horiz,
                true,
                const Color(0xFF00CED1),
                onTap: () {},
              ),
              _buildNavItem(
                Icons.layers,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CategoriesView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.person_outline,
                false,
                isDark ? Colors.grey[500]! : Colors.grey[400]!,
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