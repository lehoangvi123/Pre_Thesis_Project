// lib/service/achievement_service.dart
// Service xử lý logic thành tích

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './Achievement_model.dart';

class AchievementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Kiểm tra và unlock achievement
  Future<List<Achievement>> checkAndUnlockAchievements({
    int? transactionCount,
    double? savingsAmount,
    int? streakDays,
    int? billCount,
    bool? isAIUsed,
    bool? isEarlyBird,
    bool? isNightOwl,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    List<Achievement> newlyUnlocked = [];

    // Get user achievements
    final userAchievements = await getUserAchievements(user.uid);

    for (final achievement in AchievementsData.allAchievements) {
      // Skip if already unlocked
      if (userAchievements.any((ua) => 
          ua.achievementId == achievement.id && ua.isUnlocked)) {
        continue;
      }

      bool shouldUnlock = false;

      // Check conditions based on category
      switch (achievement.category) {
        case 'transactions':
          if (transactionCount != null && 
              transactionCount >= achievement.requiredValue) {
            shouldUnlock = true;
          }
          break;

        case 'savings':
          if (savingsAmount != null && 
              savingsAmount >= achievement.requiredValue) {
            shouldUnlock = true;
          }
          break;

        case 'streak':
          if (streakDays != null && 
              streakDays >= achievement.requiredValue) {
            shouldUnlock = true;
          }
          break;

        case 'bills':
          if (billCount != null && 
              billCount >= achievement.requiredValue) {
            shouldUnlock = true;
          }
          break;

        case 'ai':
          if (isAIUsed == true) {
            shouldUnlock = true;
          }
          break;

        case 'special':
          if (achievement.id == 'early_bird' && isEarlyBird == true) {
            shouldUnlock = true;
          } else if (achievement.id == 'night_owl' && isNightOwl == true) {
            shouldUnlock = true;
          }
          break;
      }

      if (shouldUnlock) {
        await _unlockAchievement(user.uid, achievement);
        newlyUnlocked.add(achievement);
      }
    }

    return newlyUnlocked;
  }

  // ✅ Unlock achievement
  Future<void> _unlockAchievement(String userId, Achievement achievement) async {
    final userAchievement = UserAchievement(
      achievementId: achievement.id,
      unlockedAt: DateTime.now(),
      currentProgress: achievement.requiredValue,
      isUnlocked: true,
    );

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc(achievement.id)
        .set(userAchievement.toJson());

    // Update user points
    await _addPoints(userId, achievement.points);
  }

  // ✅ Get user achievements
  Future<List<UserAchievement>> getUserAchievements(String userId) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .get();

    return snapshot.docs
        .map((doc) => UserAchievement.fromJson(doc.data()))
        .toList();
  }

  // ✅ Get user points
  Future<int> getUserPoints(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .get();

    return (doc.data()?['totalPoints'] ?? 0) as int;
  }

  // ✅ Add points
  Future<void> _addPoints(String userId, int points) async {
    await _firestore.collection('users').doc(userId).update({
      'totalPoints': FieldValue.increment(points),
    });
  }

  // ✅ Calculate achievement progress
  Future<Map<String, dynamic>> calculateProgress(String userId) async {
    final user = _auth.currentUser;
    if (user == null) return {};

    // Get transaction count
    final transactionSnapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .get();
    final transactionCount = transactionSnapshot.docs.length;

    // Get user data
    final userDoc = await _firestore
        .collection('users')
        .doc(userId)
        .get();
    final userData = userDoc.data() ?? {};
    
    final balance = (userData['balance'] ?? 0).toDouble();
    final totalIncome = (userData['totalIncome'] ?? 0).toDouble();
    final totalExpense = (userData['totalExpense'] ?? 0).toDouble();
    final savingsAmount = balance;

    // Calculate streak
    final streakDays = await _calculateStreak(userId);

    // Count bills (transactions with note containing "Bill")
    final billCount = transactionSnapshot.docs
        .where((doc) => (doc.data()['note'] ?? '').toString().contains('Bill'))
        .length;

    return {
      'transactionCount': transactionCount,
      'savingsAmount': savingsAmount,
      'streakDays': streakDays,
      'billCount': billCount,
      'totalIncome': totalIncome,
      'totalExpense': totalExpense,
    };
  }

  // ✅ Calculate streak
  Future<int> _calculateStreak(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    if (snapshot.docs.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = today;

    while (true) {
      final hasTransactionOnDate = snapshot.docs.any((doc) {
        final transDate = (doc.data()['date'] as Timestamp).toDate();
        final transDay = DateTime(transDate.year, transDate.month, transDate.day);
        return transDay == checkDate;
      });

      if (hasTransactionOnDate) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // ✅ Get achievement statistics
  Future<Map<String, dynamic>> getAchievementStats(String userId) async {
    final userAchievements = await getUserAchievements(userId);
    final totalAchievements = AchievementsData.allAchievements.length;
    final unlockedCount = userAchievements.where((a) => a.isUnlocked).length;
    final totalPoints = await getUserPoints(userId);

    return {
      'total': totalAchievements,
      'unlocked': unlockedCount,
      'locked': totalAchievements - unlockedCount,
      'percentage': (unlockedCount / totalAchievements * 100).toStringAsFixed(1),
      'totalPoints': totalPoints,
    };
  }
}