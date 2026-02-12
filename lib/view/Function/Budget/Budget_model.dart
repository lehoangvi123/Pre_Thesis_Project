// lib/models/budget_model.dart
// Budget Model - Quản lý ngân sách chi tiêu

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BudgetPeriod {
  daily,
  weekly,
  monthly,
  yearly,
}

enum BudgetStatus {
  good,      // < 50%
  warning,   // 50-79%
  danger,    // 80-99%
  exceeded,  // >= 100%
}

class BudgetModel {
  String id;
  String userId;
  String categoryId;
  String categoryName;
  IconData categoryIcon;
  double limitAmount;
  BudgetPeriod period;
  DateTime startDate;
  DateTime endDate;
  bool autoReset;
  bool alertEnabled;
  double alertThreshold; // % để cảnh báo (default: 80)
  double spentAmount;    // Số tiền đã chi trong kỳ
  DateTime createdAt;
  DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.limitAmount,
    required this.period,
    required this.startDate,
    required this.endDate,
    this.autoReset = true,
    this.alertEnabled = true,
    this.alertThreshold = 80.0,
    this.spentAmount = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  // Calculated properties
  double get remainingAmount => limitAmount - spentAmount;
  
  double get percentage => limitAmount > 0 ? (spentAmount / limitAmount) * 100 : 0;
  
  BudgetStatus get status {
    if (percentage < 50) return BudgetStatus.good;
    if (percentage < 80) return BudgetStatus.warning;
    if (percentage < 100) return BudgetStatus.danger;
    return BudgetStatus.exceeded;
  }
  
  Color get statusColor {
    switch (status) {
      case BudgetStatus.good:
        return Colors.green;
      case BudgetStatus.warning:
        return Colors.orange;
      case BudgetStatus.danger:
        return Colors.deepOrange;
      case BudgetStatus.exceeded:
        return Colors.red;
    }
  }
  
  String get statusText {
    switch (status) {
      case BudgetStatus.good:
        return "Tốt";
      case BudgetStatus.warning:
        return "Cảnh báo";
      case BudgetStatus.danger:
        return "Nguy hiểm";
      case BudgetStatus.exceeded:
        return "Vượt mức";
    }
  }
  
  int get daysRemaining {
    final now = DateTime.now();
    if (endDate.isBefore(now)) return 0;
    return endDate.difference(now).inDays;
  }
  
  bool get isExpired => DateTime.now().isAfter(endDate);
  
  bool get shouldAlert => percentage >= alertThreshold && alertEnabled;

  // Firestore conversion
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'categoryIcon': categoryIcon.codePoint,
      'limitAmount': limitAmount,
      'period': period.toString(),
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'autoReset': autoReset,
      'alertEnabled': alertEnabled,
      'alertThreshold': alertThreshold,
      'spentAmount': spentAmount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory BudgetModel.fromMap(String id, Map<String, dynamic> map) {
    return BudgetModel(
      id: id,
      userId: map['userId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      categoryIcon: IconData(
        map['categoryIcon'] ?? Icons.category.codePoint,
        fontFamily: 'MaterialIcons',
      ),
      limitAmount: (map['limitAmount'] ?? 0.0).toDouble(),
      period: BudgetPeriod.values.firstWhere(
        (e) => e.toString() == map['period'],
        orElse: () => BudgetPeriod.monthly,
      ),
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: (map['endDate'] as Timestamp).toDate(),
      autoReset: map['autoReset'] ?? true,
      alertEnabled: map['alertEnabled'] ?? true,
      alertThreshold: (map['alertThreshold'] ?? 80.0).toDouble(),
      spentAmount: (map['spentAmount'] ?? 0.0).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  BudgetModel copyWith({
    String? id,
    String? userId,
    String? categoryId,
    String? categoryName,
    IconData? categoryIcon,
    double? limitAmount,
    BudgetPeriod? period,
    DateTime? startDate,
    DateTime? endDate,
    bool? autoReset,
    bool? alertEnabled,
    double? alertThreshold,
    double? spentAmount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      limitAmount: limitAmount ?? this.limitAmount,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      autoReset: autoReset ?? this.autoReset,
      alertEnabled: alertEnabled ?? this.alertEnabled,
      alertThreshold: alertThreshold ?? this.alertThreshold,
      spentAmount: spentAmount ?? this.spentAmount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// Helper functions
String periodToString(BudgetPeriod period) {
  switch (period) {
    case BudgetPeriod.daily:
      return "Hàng ngày";
    case BudgetPeriod.weekly:
      return "Hàng tuần";
    case BudgetPeriod.monthly:
      return "Hàng tháng";
    case BudgetPeriod.yearly:
      return "Hàng năm";
  }
}

DateTime calculateEndDate(DateTime startDate, BudgetPeriod period) {
  switch (period) {
    case BudgetPeriod.daily:
      return startDate.add(const Duration(days: 1));
    case BudgetPeriod.weekly:
      return startDate.add(const Duration(days: 7));
    case BudgetPeriod.monthly:
      return DateTime(startDate.year, startDate.month + 1, startDate.day);
    case BudgetPeriod.yearly:
      return DateTime(startDate.year + 1, startDate.month, startDate.day);
  }
}