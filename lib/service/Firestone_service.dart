import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

import '../models/TransactionModel.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> addTransaction(String userId, TransactionModel tx) async {
    await _db.collection('users').doc(userId)
      .collection('transactions').doc(tx.id)
      .set(tx.toJson());
  }

  Future<void> updateBalance(String userId, double newBalance) async {
    await _db.collection('users').doc(userId).update({
      'balance': newBalance,
    });
  }

  String generateId() => _uuid.v4();
  
  Future<double> getBalance(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return (doc.data()?['balance'] ?? 0).toDouble();
  }
}
