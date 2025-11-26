import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  final String id;
  final String userId;
  final String categoryId;
  final String categoryName;
  final String type; // 'income' or 'expense'
  final double amount;
  final String title;
  final String? message;
  final DateTime date;
  final DateTime createdAt;
  final String? iconName;
  final String? colorHex;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.categoryName,
    required this.type,
    required this.amount,
    required this.title,
    this.message,
    required this.date,
    required this.createdAt,
    this.iconName,
    this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'type': type,
      'amount': amount,
      'title': title,
      'message': message,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      type: map['type'] ?? 'expense',
      amount: (map['amount'] ?? 0).toDouble(),
      title: map['title'] ?? '',
      message: map['message'],
      date: (map['date'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      iconName: map['iconName'],
      colorHex: map['colorHex'],
    );
  }

  TransactionModel copyWith({
    String? categoryId,
    String? categoryName,
    double? amount,
    String? title,
    String? message,
    DateTime? date,
  }) {
    return TransactionModel(
      id: this.id,
      userId: this.userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      type: this.type,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      createdAt: this.createdAt,
      iconName: this.iconName,
      colorHex: this.colorHex,
    );
  }
}