// lib/view/achievements_view.dart
// Màn hình hiển thị thành tích

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './Achievement_model.dart';
import './Achievement_service.dart';

class AchievementsView extends StatefulWidget {
  const AchievementsView({Key? key}) : super(key: key);

  @override
  State<AchievementsView> createState() => _AchievementsViewState();
}

class _AchievementsViewState extends State<AchievementsView> {
  final AchievementService _achievementService = AchievementService();
  final user = FirebaseAuth.instance.currentUser;

  List<UserAchievement> _userAchievements = [];
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _progress = {};
  bool _isLoading = true;

  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final achievements = await _achievementService.getUserAchievements(user!.uid);
      final stats = await _achievementService.getAchievementStats(user!.uid);
      final progress = await _achievementService.calculateProgress(user!.uid);

      setState(() {
        _userAchievements = achievements;
        _stats = stats;
        _progress = progress;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error loading achievements: $e');
    }
  }

  bool _isAchievementUnlocked(String achievementId) {
    return _userAchievements.any(
      (ua) => ua.achievementId == achievementId && ua.isUnlocked,
    );
  }

  int _getAchievementProgress(Achievement achievement) {
    switch (achievement.category) {
      case 'transactions':
        return _progress['transactionCount'] ?? 0;
      case 'savings':
        return (_progress['savingsAmount'] ?? 0).toInt();
      case 'streak':
        return _progress['streakDays'] ?? 0;
      case 'bills':
        return _progress['billCount'] ?? 0;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(         
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('🏆 Thành Tích'),
        backgroundColor: const Color(0xFF00D09E),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00D09E)))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildStatsHeader(isDark),
                    _buildCategoryFilter(isDark),
                    _buildAchievementsList(isDark),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsHeader(bool isDark) {
    final unlockedCount = _stats['unlocked'] ?? 0;
    final totalCount = _stats['total'] ?? 0;
    final percentage = _stats['percentage'] ?? '0';
    final totalPoints = _stats['totalPoints'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00D09E), Color(0xFF00A8AA)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00D09E).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Points
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 32),
              const SizedBox(width: 8),
              Text(
                '$totalPoints điểm',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Đã đạt', '$unlockedCount', Icons.check_circle),
              _buildStatItem('Tổng số', '$totalCount', Icons.emoji_events),
              _buildStatItem('Hoàn thành', '$percentage%', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 16),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (unlockedCount / totalCount).clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    final categories = [
      {'id': 'all', 'label': 'Tất cả', 'icon': '🏆'},
      {'id': 'transactions', 'label': 'Giao dịch', 'icon': '💼'},
      {'id': 'savings', 'label': 'Tiết kiệm', 'icon': '💰'},
      {'id': 'streak', 'label': 'Chuỗi', 'icon': '🔥'},
      {'id': 'bills', 'label': 'Bills', 'icon': '📸'},
      {'id': 'special', 'label': 'Đặc biệt', 'icon': '⭐'},
    ];

    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = _selectedCategory == category['id'];

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category['id'] as String;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00D09E)
                    : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00D09E)
                      : Colors.grey.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    category['icon'] as String,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : Colors.black),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAchievementsList(bool isDark) {
    var achievements = AchievementsData.allAchievements;

    if (_selectedCategory != 'all') {
      achievements = achievements
          .where((a) => a.category == _selectedCategory)
          .toList();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        final achievement = achievements[index];
        final isUnlocked = _isAchievementUnlocked(achievement.id);
        final progress = _getAchievementProgress(achievement);

        return _buildAchievementCard(achievement, isUnlocked, progress, isDark);
      },
    );
  }

  Widget _buildAchievementCard(
    Achievement achievement,
    bool isUnlocked,
    int progress,
    bool isDark,
  ) {
    final progressPercentage = (progress / achievement.requiredValue).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFF00D09E)
              : Colors.grey.withOpacity(0.2),
          width: isUnlocked ? 2 : 1,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: const Color(0xFF00D09E).withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Locked overlay
          if (!isUnlocked)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFF00D09E).withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      achievement.icon,
                      style: TextStyle(
                        fontSize: 32,
                        color: isUnlocked ? null : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              achievement.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isUnlocked
                                    ? (isDark ? Colors.white : Colors.black)
                                    : Colors.grey,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00D09E),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.stars, color: Colors.white, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    '+${achievement.points}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        achievement.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Progress bar
                      if (!isUnlocked) ...[
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressPercentage,
                                  backgroundColor: Colors.grey.withOpacity(0.2),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    Color(0xFF00D09E),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$progress/${achievement.requiredValue}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Unlocked badge
                      if (isUnlocked) ...[
                        Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: const Color(0xFF00D09E),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Đã đạt được',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF00D09E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}