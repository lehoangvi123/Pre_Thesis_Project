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
  final bool isIncome; // ✅ sửa thành bool

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
    required this.isIncome, // ✅ đúng constructor
  });

  // Dùng để lưu Firestore
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
      'isIncome': isIncome, // ✅ thêm field
    };
  }

  // Alias cho chắc chắn bạn gọi ở UI/service không bị đỏ
  Map<String, dynamic> toJson() => toMap(); // ✅ trỏ lại toMap()

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      categoryId: map['categoryId'] ?? '',
      categoryName: map['categoryName'] ?? '',
      type: map['type'] ?? 'expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      title: map['title'] ?? '',
      message: map['message'],
      iconName: map['iconName'],
      colorHex: map['colorHex'],
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isIncome: map['isIncome'] ?? false, // ✅ đọc theo bool
    );
  }

  TransactionModel copyWith({
    String? categoryId,
    String? categoryName,
    double? amount,
    String? title,
    String? message,
    DateTime? date,
    bool? isIncome,
  }) {
    return TransactionModel(
      id: id,
      userId: userId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      type: type,
      amount: amount ?? this.amount,
      title: title ?? this.title,
      message: message ?? this.message,
      date: date ?? this.date,
      createdAt: createdAt,
      iconName: iconName,
      colorHex: colorHex,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}
