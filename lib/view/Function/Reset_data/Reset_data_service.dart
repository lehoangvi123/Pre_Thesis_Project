// lib/service/reset_data_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ResetDataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> resetAllUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final userRef = _firestore.collection('users').doc(uid);

    // 1. Xóa tất cả transactions
    await _deleteSubCollection(userRef, 'transactions');

    // 2. Xóa tất cả budgets
    await _deleteSubCollection(userRef, 'budgets');
    // Xóa root budgets nếu có
    await _deleteRootCollectionByUID('budgets', uid);

    // 3. Xóa tất cả saving goals
    await _deleteSubCollection(userRef, 'savingGoals');

    // 4. Xóa achievements
    await _deleteSubCollection(userRef, 'achievements');

    // 5. Reset tất cả field về 0
    await userRef.update({
      'balance': 0,
      'totalBalance': 0,
      'totalIncome': 0,
      'totalExpense': 0,
      // ✅ Reset streak
      'currentStreak': 0,
      'maxStreak': 0,
      'lastLoginDate': null,
      // ✅ Reset points
      'totalPoints': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _deleteSubCollection(
      DocumentReference docRef, String subCollection) async {
    final snapshot = await docRef.collection(subCollection).get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  Future<void> _deleteRootCollectionByUID(
      String collection, String uid) async {
    final snapshot = await _firestore
        .collection(collection)
        .where('userId', isEqualTo: uid)
        .get();
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}