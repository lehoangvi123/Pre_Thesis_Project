

import 'package:cloud_firestore/cloud_firestore.dart';

class SavingGoal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final String? icon; // Icon name or emoji
  final int? color; // Color value
  final DateTime createdAt;
  final DateTime? targetDate;
  final String? description;

  SavingGoal({
    required this.id,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.icon,
    this.color,
    required this.createdAt,
    this.targetDate,
    this.description,
  });

  // Progress percentage (0-100)
  double get progress {
    if (targetAmount <= 0) return 0;
    return ((currentAmount / targetAmount) * 100).clamp(0, 100);
  }

  // Remaining amount
  double get remainingAmount {
    return (targetAmount - currentAmount).clamp(0, double.infinity);
  }

  // Is goal completed?
  bool get isCompleted => currentAmount >= targetAmount;

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'icon': icon,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
      'targetDate': targetDate != null ? Timestamp.fromDate(targetDate!) : null,
      'description': description,
    };
  }

  // Create from Firestore document
  factory SavingGoal.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    
    return SavingGoal(
      id: doc.id,
      title: data['title'] ?? 'Untitled',
      targetAmount: (data['targetAmount'] ?? 0).toDouble(),
      currentAmount: (data['currentAmount'] ?? 0).toDouble(),
      icon: data['icon'],
      color: data['color'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      targetDate: data['targetDate'] != null 
          ? (data['targetDate'] as Timestamp).toDate() 
          : null,
      description: data['description'],
    );
  }

  // Copy with method for updates
  SavingGoal copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    String? icon,
    int? color,
    DateTime? createdAt,
    DateTime? targetDate,
    String? description,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      targetDate: targetDate ?? this.targetDate,
      description: description ?? this.description,
    );
  }
} 

