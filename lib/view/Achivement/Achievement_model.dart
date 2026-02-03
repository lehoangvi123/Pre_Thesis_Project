// lib/models/achievement_model.dart
// Model cho hệ thống thành tích

class Achievement {
  final String id;
  final String title;
  final String description;
  final String icon; // emoji
  final int requiredValue;
  final String category;
  final int points;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredValue,
    required this.category,
    required this.points,
  });
}

class UserAchievement {
  final String achievementId;
  final DateTime unlockedAt;
  final int currentProgress;
  final bool isUnlocked;

  UserAchievement({
    required this.achievementId,
    required this.unlockedAt,
    required this.currentProgress,
    required this.isUnlocked,
  });

  Map<String, dynamic> toJson() {
    return {
      'achievementId': achievementId,
      'unlockedAt': unlockedAt.toIso8601String(),
      'currentProgress': currentProgress,
      'isUnlocked': isUnlocked,
    };
  }

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      achievementId: json['achievementId'],
      unlockedAt: DateTime.parse(json['unlockedAt']),
      currentProgress: json['currentProgress'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
    );
  }
}

// ✅ DANH SÁCH CÁC THÀNH TÍCH
class AchievementsData {
  static final List<Achievement> allAchievements = [
    // 🎯 TRANSACTION ACHIEVEMENTS
    Achievement(
      id: 'first_transaction',
      title: 'Bước Đầu Tiên',
      description: 'Thêm giao dịch đầu tiên',
      icon: '🎯',
      requiredValue: 1,
      category: 'transactions',
      points: 10,
    ),
    Achievement(
      id: 'transactions_10',
      title: 'Người Ghi Chép',
      description: 'Thêm 10 giao dịch',
      icon: '📝',
      requiredValue: 10,
      category: 'transactions',
      points: 50,
    ),
    Achievement(
      id: 'transactions_50',
      title: 'Chuyên Gia Tài Chính',
      description: 'Thêm 50 giao dịch',
      icon: '💼',
      requiredValue: 50,
      category: 'transactions',
      points: 200,
    ),
    Achievement(
      id: 'transactions_100',
      title: 'Bậc Thầy Quản Lý',
      description: 'Thêm 100 giao dịch',
      icon: '🏆',
      requiredValue: 100,
      category: 'transactions',
      points: 500,
    ),

    // 💰 SAVINGS ACHIEVEMENTS
    Achievement(
      id: 'savings_1m',
      title: 'Tiết Kiệm Khởi Đầu',
      description: 'Tiết kiệm được 1 triệu đồng',
      icon: '💰',
      requiredValue: 1000000,
      category: 'savings',
      points: 100,
    ),
    Achievement(
      id: 'savings_5m',
      title: 'Nhà Tiết Kiệm',
      description: 'Tiết kiệm được 5 triệu đồng',
      icon: '💎',
      requiredValue: 5000000,
      category: 'savings',
      points: 300,
    ),
    Achievement(
      id: 'savings_10m',
      title: 'Triệu Phú Nhỏ',
      description: 'Tiết kiệm được 10 triệu đồng',
      icon: '👑',
      requiredValue: 10000000,
      category: 'savings',
      points: 1000,
    ),

    // 🔥 STREAK ACHIEVEMENTS
    Achievement(
      id: 'streak_3',
      title: 'Kiên Trì 3 Ngày',
      description: 'Ghi chi tiêu 3 ngày liên tiếp',
      icon: '🔥',
      requiredValue: 3,
      category: 'streak',
      points: 30,
    ),
    Achievement(
      id: 'streak_7',
      title: 'Tuần Hoàn Hảo',
      description: 'Ghi chi tiêu 7 ngày liên tiếp',
      icon: '⭐',
      requiredValue: 7,
      category: 'streak',
      points: 100,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Tháng Kỷ Luật',
      description: 'Ghi chi tiêu 30 ngày liên tiếp',
      icon: '🌟',
      requiredValue: 30,
      category: 'streak',
      points: 500,
    ),

    // 📊 BUDGET ACHIEVEMENTS
    Achievement(
      id: 'budget_keeper',
      title: 'Người Giữ Ngân Sách',
      description: 'Chi dưới budget 1 tháng',
      icon: '🎯',
      requiredValue: 1,
      category: 'budget',
      points: 150,
    ),
    Achievement(
      id: 'super_saver',
      title: 'Siêu Tiết Kiệm',
      description: 'Chi dưới 50% budget 1 tháng',
      icon: '🦸',
      requiredValue: 1,
      category: 'budget',
      points: 300,
    ),

    // 📸 BILL ACHIEVEMENTS
    Achievement(
      id: 'first_bill',
      title: 'Người Quét Bill',
      description: 'Thêm bill đầu tiên',
      icon: '📸',
      requiredValue: 1,
      category: 'bills',
      points: 20,
    ),
    Achievement(
      id: 'bills_10',
      title: 'Thu Thập Hóa Đơn',
      description: 'Thêm 10 bills',
      icon: '📋',
      requiredValue: 10,
      category: 'bills',
      points: 100,
    ),

    // 🤖 AI ACHIEVEMENTS
    Achievement(
      id: 'ai_chat',
      title: 'Người Dùng AI',
      description: 'Trò chuyện với AI lần đầu',
      icon: '🤖',
      requiredValue: 1,
      category: 'ai',
      points: 50,
    ),

    // 🎨 SPECIAL ACHIEVEMENTS
    Achievement(
      id: 'early_bird',
      title: 'Chim Sớm',
      description: 'Thêm giao dịch trước 8h sáng',
      icon: '🌅',
      requiredValue: 1,
      category: 'special',
      points: 30,
    ),
    Achievement(
      id: 'night_owl',
      title: 'Cú Đêm',
      description: 'Thêm giao dịch sau 11h đêm',
      icon: '🦉',
      requiredValue: 1,
      category: 'special',
      points: 30,
    ),
  ];

  static Achievement? getAchievementById(String id) {
    try {
      return allAchievements.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  static List<Achievement> getAchievementsByCategory(String category) {
    return allAchievements.where((a) => a.category == category).toList();
  }
}