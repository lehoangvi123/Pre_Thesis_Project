import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to handle chart data processing
class ChartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get expense breakdown by category
  Future<Map<String, double>> getExpenseByCategory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .get();

      Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String category = data['category'] ?? 'Khác';
        double amount = (data['amount'] ?? 0).toDouble();

        if (categoryTotals.containsKey(category)) {
          categoryTotals[category] = categoryTotals[category]! + amount;
        } else {
          categoryTotals[category] = amount;
        }
      }

      return categoryTotals;
    } catch (e) {
      print('Error getting expense by category: $e');
      return {};
    }
  }

  /// Get income breakdown by category
  Future<Map<String, double>> getIncomeByCategory(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'income')
          .get();

      Map<String, double> categoryTotals = {};

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String category = data['category'] ?? 'Khác';
        double amount = (data['amount'] ?? 0).toDouble();

        if (categoryTotals.containsKey(category)) {
          categoryTotals[category] = categoryTotals[category]! + amount;
        } else {
          categoryTotals[category] = amount;
        }
      }

      return categoryTotals;
    } catch (e) {
      print('Error getting income by category: $e');
      return {};
    }
  }

  /// Get color for category
  static Color getCategoryColor(String category, int index) {
    // Predefined colors for categories
    const colors = [
      Color(0xFF00CED1), // Cyan
      Color(0xFF4CAF50), // Green
      Color(0xFF2196F3), // Blue
      Color(0xFF9C27B0), // Purple
      Color(0xFFFF9800), // Orange
      Color(0xFFE91E63), // Pink
      Color(0xFFF44336), // Red
      Color(0xFF607D8B), // Blue Grey
      Color(0xFF009688), // Teal
      Color(0xFFFF5722), // Deep Orange
      Color(0xFF795548), // Brown
      Color(0xFF3F51B5), // Indigo
    ];

    // Try to get specific color for known categories
    switch (category.toLowerCase()) {
      case 'food':
      case 'đồ ăn':
        return const Color(0xFF00CED1);
      case 'transport':
      case 'di chuyển':
        return const Color(0xFF64B5F6);
      case 'salary':
      case 'lương':
        return const Color(0xFF4CAF50);
      case 'groceries':
      case 'mua sắm':
        return const Color(0xFF9C27B0);
      case 'rent':
      case 'thuê nhà':
        return const Color(0xFFFF9800);
      case 'entertainment':
      case 'giải trí':
        return const Color(0xFFE91E63);
      case 'freelance':
        return const Color(0xFF2196F3);
      case 'investment':
      case 'đầu tư':
        return const Color(0xFF009688);
      default:
        return colors[index % colors.length];
    }
  }

  /// Format currency
  static String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    )}₫';
  }

  /// Format short currency for charts
  static String formatShortCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  /// Get icon for category
  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'đồ ăn':
        return Icons.restaurant;
      case 'transport':
      case 'di chuyển':
        return Icons.directions_car;
      case 'groceries':
      case 'mua sắm':
        return Icons.shopping_cart;
      case 'rent':
      case 'thuê nhà':
        return Icons.home;
      case 'salary':
      case 'lương':
        return Icons.attach_money;
      case 'entertainment':
      case 'giải trí':
        return Icons.movie;
      case 'medicine':
      case 'health':
      case 'sức khỏe':
        return Icons.medical_services;
      case 'gifts':
      case 'quà tặng':
        return Icons.card_giftcard;
      case 'freelance':
        return Icons.work;
      case 'investment':
      case 'đầu tư':
        return Icons.trending_up;
      default:
        return Icons.category;
    }
  }
}