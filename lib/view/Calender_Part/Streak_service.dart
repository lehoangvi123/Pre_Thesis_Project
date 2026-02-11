// lib/service/streak_service.dart
// ✅ STREAK SYSTEM - Thưởng cho người dùng ghi chép đều đặn

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  // ✅ CHECK VÀ UPDATE STREAK
  Future<Map<String, dynamic>> checkAndUpdateStreak() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) return {'currentStreak': 0, 'maxStreak': 0, 'isNewRecord': false};

      var userData = userDoc.data() as Map<String, dynamic>;
      DateTime? lastLoginDate = userData['lastLoginDate'] != null
          ? (userData['lastLoginDate'] as Timestamp).toDate()
          : null;
      
      int currentStreak = userData['currentStreak'] ?? 0;
      int maxStreak = userData['maxStreak'] ?? 0;
      DateTime today = DateTime.now();
      DateTime todayOnly = DateTime(today.year, today.month, today.day);

      bool isNewRecord = false;

      if (lastLoginDate == null) {
        // First time
        currentStreak = 1;
        maxStreak = 1;
      } else {
        DateTime lastDateOnly = DateTime(lastLoginDate.year, lastLoginDate.month, lastLoginDate.day);
        int daysDifference = todayOnly.difference(lastDateOnly).inDays;

        if (daysDifference == 0) {
          // Same day - no change
          return {'currentStreak': currentStreak, 'maxStreak': maxStreak, 'isNewRecord': false};
        } else if (daysDifference == 1) {
          // Next day - streak continues!
          currentStreak++;
          if (currentStreak > maxStreak) {
            maxStreak = currentStreak;
            isNewRecord = true;
          }
        } else {
          // Streak broken
          currentStreak = 1;
        }
      }

      // Update Firestore
      await _firestore.collection('users').doc(userId).update({
        'lastLoginDate': FieldValue.serverTimestamp(),
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
      });

      print('[Streak] 🔥 Current: $currentStreak | Max: $maxStreak | New Record: $isNewRecord');

      return {
        'currentStreak': currentStreak,
        'maxStreak': maxStreak,
        'isNewRecord': isNewRecord,
      };
    } catch (e) {
      print('[Streak] Error: $e');
      return {'currentStreak': 0, 'maxStreak': 0, 'isNewRecord': false};
    }
  }

  // ✅ GET REWARDS BASED ON STREAK
  Map<String, dynamic> getStreakReward(int streak) {
    if (streak >= 365) {
      return {
        'title': '🏆 HUYỀN THOẠI!',
        'badge': '👑',
        'message': 'Ghi chép 365 ngày liên tiếp! Bạn là bậc thầy quản lý tài chính!',
        'reward': 'Badge: HUYỀN THOẠI + Premium 1 năm miễn phí',
        'color': 0xFFFFD700, // Gold
      };
    } else if (streak >= 180) {
      return {
        'title': '💎 CHUYÊN GIA!',
        'badge': '💎',
        'message': 'Streak 180 ngày! Bạn là chuyên gia quản lý chi tiêu!',
        'reward': 'Badge: CHUYÊN GIA + Premium 6 tháng miễn phí',
        'color': 0xFF00D4FF, // Diamond blue
      };
    } else if (streak >= 100) {
      return {
        'title': '🔥 SIÊU SAO!',
        'badge': '⭐',
        'message': 'Streak 100 ngày! Kỷ luật tài chính tuyệt vời!',
        'reward': 'Badge: SIÊU SAO + Premium 3 tháng miễn phí',
        'color': 0xFFFF6B00, // Orange
      };
    } else if (streak >= 50) {
      return {
        'title': '🎯 CAO THỦ!',
        'badge': '🎖️',
        'message': 'Streak 50 ngày! Bạn đang làm rất tốt!',
        'reward': 'Badge: CAO THỦ + Premium 1 tháng miễn phí',
        'color': 0xFFAB47BC, // Purple
      };
    } else if (streak >= 30) {
      return {
        'title': '🚀 KỶ LUẬT!',
        'badge': '🥈',
        'message': 'Streak 30 ngày! Thói quen tốt đã hình thành!',
        'reward': 'Badge: KỶ LUẬT + Unlock tính năng nâng cao',
        'color': 0xFFC0C0C0, // Silver
      };
    } else if (streak >= 14) {
      return {
        'title': '💪 KIÊN TRÌ!',
        'badge': '🥉',
        'message': 'Streak 2 tuần! Tiếp tục phát huy nhé!',
        'reward': 'Badge: KIÊN TRÌ + Unlock themes',
        'color': 0xFFCD7F32, // Bronze
      };
    } else if (streak >= 7) {
      return {
        'title': '✨ TUẦN ĐẦU!',
        'badge': '🌟',
        'message': 'Streak 7 ngày! Bạn đang trên đà tốt!',
        'reward': 'Badge: TUẦN ĐẦU',
        'color': 0xFF4CAF50, // Green
      };
    } else if (streak >= 3) {
      return {
        'title': '🔰 KHỞI ĐẦU!',
        'badge': '🎯',
        'message': 'Streak 3 ngày! Hãy duy trì nhé!',
        'reward': 'Badge: KHỞI ĐẦU',
        'color': 0xFF00D09E, // Teal
      };
    }
    
    return {
      'title': 'Bắt đầu streak!',
      'badge': '📝',
      'message': 'Hãy ghi chép mỗi ngày để xây dựng streak!',
      'reward': '',
      'color': 0xFF9E9E9E, // Gray
    };
  }

  // ✅ GET CURRENT STREAK
  Future<int> getCurrentStreak() async {
    try {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
      if (!userDoc.exists) return 0;
      var userData = userDoc.data() as Map<String, dynamic>;
      return userData['currentStreak'] ?? 0;
    } catch (e) {
      return 0;
    }
  }
}