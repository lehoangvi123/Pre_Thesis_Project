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
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            _buildAppBar(),
            
            // Expanded để chứa phần scroll
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Balance Card
                      _buildBalanceCard(),
                      const SizedBox(height: 20),

                      // Progress Bar
                      _buildProgressBar(),
                      const SizedBox(height: 24),

                      // April Transactions
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

                      // March Transactions
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
                      
                      // Thêm khoảng trống để không bị che bởi bottom nav
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title ở giữa
          Center(
            child: Text(
              'Transaction',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          // Notification icon ở bên phải
          Positioned(
            right: 0,
            child: IconButton(
              icon: Icon(Icons.notifications_outlined, color: Colors.grey[800]),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            '\$7,783.00',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black,
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
                        Icon(Icons.account_balance_wallet, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Total Balance',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '\$20,000.00',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey[300],
              ),
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.trending_down, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Total Expense',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 20, color: Colors.green[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '30% Of Your Expenses, Looks Good',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthSection(String month, List<Widget> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          month,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
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
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
             _buildNavItem(Icons.home, false, Colors.grey[400]!, onTap: () {
                 Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeView()),
                    );
              }),
              _buildNavItem(Icons.search, false, Colors.grey[400]!, onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AnalysisView()),
                    );
                  }),
              // Trong _buildBottomNavBar()
             _buildNavItem(Icons.swap_horiz, true, const Color(0xFF00CED1), onTap: () {
  // Already on Transaction page
}),
              _buildNavItem(Icons.layers, false, Colors.grey[400]!, onTap:() {
                 Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoriesView()),
                );
              }),
             _buildNavItem(Icons.person_outline, false, Colors.grey[400]!, onTap: () {
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

  Widget _buildNavItem(IconData icon, bool isActive, Color color, {VoidCallback? onTap}) {
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