import 'package:flutter/material.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({Key? key}) : super(key: key);

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  // Dữ liệu mẫu thông báo
  final List<Map<String, dynamic>> notifications = [
    {
      'section': 'Today',
      'items': [
        {
          'icon': Icons.notifications_active,
          'iconColor': Color(0xFF00CED1),
          'title': 'Reminder!',
          'description': 'Set up your automatic savings to meet your savings goal.',
          'time': '17:00 - April 24',
        },
        {
          'icon': Icons.update,
          'iconColor': Color(0xFF00CED1),
          'title': 'New Updates',
          'description': 'Set up your automatic savings to meet your savings goal.',
          'time': '17:00 - April 24',
        },
      ],
    },
    {
      'section': 'Yesterday',
      'items': [
        {
          'icon': Icons.swap_horiz,
          'iconColor': Color(0xFF00CED1),
          'title': 'Transactions',
          'description': 'A new transaction has been registered\nGroceries | Pantry | - 3,000.00',
          'time': '17:00 - April 24',
        },
        {
          'icon': Icons.notifications_active,
          'iconColor': Color(0xFF00CED1),
          'title': 'Reminder!',
          'description': 'Set up your automatic savings to meet your savings goal.',
          'time': '17:00 - April 24',
        },
      ],
    },
    {
      'section': 'This Weekend',
      'items': [
        {
          'icon': Icons.receipt_long,
          'iconColor': Color(0xFF00CED1),
          'title': 'Expense Record',
          'description': 'We recommend that you list more expenses to track',
          'time': '17:00 - April 24',
        },
        {
          'icon': Icons.swap_horiz,
          'iconColor': Color(0xFF00CED1),
          'title': 'Transactions',
          'description': 'A new transaction has been registered\nRent | Rental | - 945.00',
          'time': '17:00 - April 24',
        },
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification',
          style: TextStyle(
            color: Colors.grey[800],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.green[600]),
            onPressed: () {
              // Xử lý khi nhấn icon thông báo
            },
          ),
        ],
      ),
      body: Scrollbar(
        thumbVisibility: true,
        thickness: 6,
        radius: const Radius.circular(10),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          physics: const BouncingScrollPhysics(),
          itemCount: notifications.length,
          itemBuilder: (context, sectionIndex) {
            final section = notifications[sectionIndex];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12, top: 8),
                  child: Text(
                    section['section'],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
                // Notification Items
                ...List.generate(
                  section['items'].length,
                  (itemIndex) {
                    final item = section['items'][itemIndex];
                    return _buildNotificationCard(
                      icon: item['icon'],
                      iconColor: item['iconColor'],
                      title: item['title'],
                      description: item['description'],
                      time: item['time'],
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildNotificationCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required String time,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
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
              _buildNavItem(Icons.home, false, Colors.grey[400]!),
              _buildNavItem(Icons.search, false, Colors.grey[400]!),
              _buildNavItem(Icons.swap_horiz, false, Colors.grey[400]!),
              _buildNavItem(Icons.layers, false, Colors.grey[400]!),
              _buildNavItem(Icons.person_outline, false, Colors.grey[400]!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}