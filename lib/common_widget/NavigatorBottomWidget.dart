import 'package:flutter/material.dart';

class NavigatorBottomWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const NavigatorBottomWidget({
    Key? key,
    required this.currentIndex,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(
                icon: Icons.home,
                index: 0,
                label: 'Home',
              ),
              _buildNavItem(
                icon: Icons.search,
                index: 1,
                label: 'Search',
              ),
              _buildNavItem(
                icon: Icons.swap_horiz,
                index: 2,
                label: 'Transaction',
              ),
              _buildNavItem(
                icon: Icons.layers,
                index: 3,
                label: 'Category',
              ),
              _buildNavItem(
                icon: Icons.person_outline,
                index: 4,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required int index,
    required String label,
  }) {
    final isActive = currentIndex == index;
    final activeColor = const Color(0xFF00CED1); // Cyan color
    final inactiveColor = Colors.grey[400]!;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : inactiveColor,
              size: 26,
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}