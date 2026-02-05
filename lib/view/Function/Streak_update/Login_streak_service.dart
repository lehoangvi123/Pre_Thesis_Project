// lib/view/Streak_update/Login_streak_service.dart
// Service xử lý login streak - UPDATED WITH BETTER MESSAGES

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginStreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ CHECK & UPDATE STREAK KHI VÀO APP
  Future<Map<String, int>> checkAndUpdateStreak() async {
    final user = _auth.currentUser;
    if (user == null) return {'currentStreak': 0, 'maxStreak': 0};

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final userDoc = await userRef.get();

      if (!userDoc.exists) {
        // User mới, tạo streak đầu tiên
        await userRef.set({
          'currentStreak': 1,
          'maxStreak': 1,
          'lastLoginDate': Timestamp.now(),
        }, SetOptions(merge: true));

        print('🎉 Welcome! First login - Streak: 1');
        return {'currentStreak': 1, 'maxStreak': 1};
      }

      final data = userDoc.data() as Map<String, dynamic>;
      final lastLoginTimestamp = data['lastLoginDate'] as Timestamp?;
      int currentStreak = data['currentStreak'] ?? 0;
      int maxStreak = data['maxStreak'] ?? 0;

      // Ngày hôm nay (chỉ lấy ngày, bỏ giờ)
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (lastLoginTimestamp != null) {
        final lastLoginDate = lastLoginTimestamp.toDate();
        final lastLogin = DateTime(
          lastLoginDate.year,
          lastLoginDate.month,
          lastLoginDate.day,
        );

        final daysDifference = today.difference(lastLogin).inDays;

        if (daysDifference == 0) {
          // ✅ CÙNG NGÀY - Không làm gì
          print('🔥 Same day login - Streak unchanged: $currentStreak');
          return {'currentStreak': currentStreak, 'maxStreak': maxStreak};
        } else if (daysDifference == 1) {
          // ✅ NGÀY HÔM SAU - Tăng streak
          currentStreak += 1;

          // Update max streak nếu vượt qua
          if (currentStreak > maxStreak) {
            maxStreak = currentStreak;
            print('🎉 NEW RECORD! Current: $currentStreak, Max: $maxStreak');
          } else {
            print('🔥 Streak increased! Current: $currentStreak, Max: $maxStreak');
          }

          await userRef.update({
            'currentStreak': currentStreak,
            'maxStreak': maxStreak,
            'lastLoginDate': Timestamp.now(),
          });

          return {'currentStreak': currentStreak, 'maxStreak': maxStreak};
        } else {
          // ❌ BỎ QUA >=2 NGÀY - Reset về 1
          print('💔 Streak lost! Resetting to 1. Previous max: $maxStreak');
          currentStreak = 1;

          // Max streak không thay đổi
          await userRef.update({
            'currentStreak': 1,
            'maxStreak': maxStreak,
            'lastLoginDate': Timestamp.now(),
          });

          return {'currentStreak': 1, 'maxStreak': maxStreak};
        }
      } else {
        // Không có lastLoginDate, khởi tạo
        await userRef.update({
          'currentStreak': 1,
          'maxStreak': 1,
          'lastLoginDate': Timestamp.now(),
        });

        return {'currentStreak': 1, 'maxStreak': 1};
      }
    } catch (e) {
      print('❌ Error updating streak: $e');
      return {'currentStreak': 0, 'maxStreak': 0};
    }
  }

  // ✅ GET CURRENT STREAK
  Future<int> getCurrentStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return 0;

      final data = userDoc.data() as Map<String, dynamic>;
      return data['currentStreak'] ?? 0;
    } catch (e) {
      print('Error getting current streak: $e');
      return 0;
    }
  }

  // ✅ GET MAX STREAK
  Future<int> getMaxStreak() async {
    final user = _auth.currentUser;
    if (user == null) return 0;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return 0;

      final data = userDoc.data() as Map<String, dynamic>;
      return data['maxStreak'] ?? 0;
    } catch (e) {
      print('Error getting max streak: $e');
      return 0;
    }
  }

  // ✅ GET BOTH STREAKS
  Future<Map<String, int>> getStreakData() async {
    final user = _auth.currentUser;
    if (user == null) return {'currentStreak': 0, 'maxStreak': 0};

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) return {'currentStreak': 0, 'maxStreak': 0};

      final data = userDoc.data() as Map<String, dynamic>;
      return {
        'currentStreak': data['currentStreak'] ?? 0,
        'maxStreak': data['maxStreak'] ?? 0,
      };
    } catch (e) {
      print('Error getting streak data: $e');
      return {'currentStreak': 0, 'maxStreak': 0};
    }
  }

  // ✅ STREAM REAL-TIME STREAK
  Stream<Map<String, int>> streakStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value({'currentStreak': 0, 'maxStreak': 0});
    }

    return _firestore
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return {'currentStreak': 0, 'maxStreak': 0};

      final data = doc.data() as Map<String, dynamic>;
      return {
        'currentStreak': data['currentStreak'] ?? 0,
        'maxStreak': data['maxStreak'] ?? 0,
      };
    });
  }

  // ✅ RESET STREAK (For testing)
  Future<void> resetStreak() async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('users').doc(user.uid).update({
      'currentStreak': 0,
      'maxStreak': 0,
      'lastLoginDate': null,
    });
    
    print('🔄 Streak reset to 0');
  }
} 