import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './SavingGoals.dart';

class SavingGoalService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get userId => _auth.currentUser?.uid;

  // Get collection reference for current user's saving goals
  CollectionReference goalsCollection() {
    if (userId == null) throw Exception('User not logged in');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('savingGoals');
  } 

    /// ✅ Public stream method

  // Stream of all saving goals
  Stream<List<SavingGoal>> getSavingGoalsStream() {
    return goalsCollection()
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SavingGoal.fromFirestore(doc))
            .toList());
  }

  // Get single goal by ID
  Future<SavingGoal?> getSavingGoalById(String goalId) async {
    try {
      DocumentSnapshot doc = await goalsCollection().doc(goalId).get();
      if (doc.exists) {
        return SavingGoal.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting saving goal: $e');
      return null;
    }
  }

  // Add new saving goal
  Future<String?> addSavingGoal(SavingGoal goal) async {
    try {
      DocumentReference docRef = await goalsCollection().add(goal.toMap());
      return docRef.id;
    } catch (e) {
      print('Error adding saving goal: $e');
      return null;
    }
  }

  // Update saving goal
  Future<bool> updateSavingGoal(String goalId, Map<String, dynamic> updates) async {
    try {
      await goalsCollection().doc(goalId).update(updates);
      return true;
    } catch (e) {
      print('Error updating saving goal: $e');
      return false;
    }
  }

  // Update current amount (add money to goal)
  Future<bool> addAmountToGoal(String goalId, double amount) async {
    try {
      DocumentReference docRef = goalsCollection().doc(goalId);
      
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception('Goal does not exist');
        }

        double currentAmount = (snapshot.get('currentAmount') ?? 0).toDouble();
        double newAmount = currentAmount + amount;

        transaction.update(docRef, {'currentAmount': newAmount});
      });

      return true;
    } catch (e) {
      print('Error adding amount to goal: $e');
      return false;
    }
  }

  // Delete saving goal
  Future<bool> deleteSavingGoal(String goalId) async {
    try {
      await goalsCollection().doc(goalId).delete();
      return true;
    } catch (e) {
      print('Error deleting saving goal: $e');
      return false;
    }
  }

  // Get total saved amount across all goals
  Future<double> getTotalSavedAmount() async {
    try {
      QuerySnapshot snapshot = await goalsCollection().get();
      double total = 0;
      
      for (var doc in snapshot.docs) {
        double currentAmount = (doc.get('currentAmount') ?? 0).toDouble();
        total += currentAmount;
      }
      
      return total;
    } catch (e) {
      print('Error getting total saved amount: $e');
      return 0;
    }
  }

  // Get completed goals count
  Future<int> getCompletedGoalsCount() async {
    try {
      QuerySnapshot snapshot = await goalsCollection().get();
      int count = 0;
      
      for (var doc in snapshot.docs) {
        double current = (doc.get('currentAmount') ?? 0).toDouble();
        double target = (doc.get('targetAmount') ?? 0).toDouble();
        if (current >= target) {
          count++;
        }
      }
      
      return count;
    } catch (e) {
      print('Error getting completed goals count: $e');
      return 0;
    }
  }
}