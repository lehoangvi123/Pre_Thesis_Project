// ✅ STREAK TRACKER CARD - OPTION A REFINED
// File: lib/view/Streak_update/StreakTrackerCard.dart
// Thay thế file cũ

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import './Login_streak_service.dart';

class StreakTrackerCard extends StatelessWidget {
  const StreakTrackerCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return const SizedBox();

    return StreamBuilder<Map<String, int>>(
      stream: LoginStreakService().streakStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final data = snapshot.data!;
        final currentStreak = data['currentStreak'] ?? 0;
        final maxStreak = data['maxStreak'] ?? 0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange[400]!,
                Colors.deepOrange[500]!,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '🔥',
                          style: TextStyle(fontSize: 28),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Login Streak',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Login every day!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Current & Max Streak
              Row(
                children: [
                  // Current Streak
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$currentStreak',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentStreak == 1 ? 'day' : 'days',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Current',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Max Streak (Record)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.emoji_events,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$maxStreak',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            maxStreak == 1 ? 'day' : 'days',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Best',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ✅ IMPROVED DYNAMIC MOTIVATIONAL MESSAGES
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _getMessageIcon(currentStreak, maxStreak),
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getMotivationalMessage(currentStreak, maxStreak),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ DYNAMIC MESSAGES BASED ON STREAK
  String _getMotivationalMessage(int current, int max) {
    // First day ever
    if (current == 1 && max == 1) {
      return 'Great start! Come back tomorrow! 🚀';
    }
    
    // Breaking record or at record
    if (current >= max && current > 1) {
      return '🎉 New record! Amazing! Keep going!';
    }
    
    // Lost streak, restarting
    if (current == 1 && max > 1) {
      return 'Back on track! Let\'s beat $max days! 💪';
    }
    
    // Week+ progress
    if (current >= 7 && current < max) {
      final remaining = max - current;
      return 'Awesome! $remaining days to beat your record!';
    }
    
    // Good progress (3-6 days)
    if (current >= 3 && current < 7) {
      return 'You\'re on fire! Keep the momentum! 🔥';
    }
    
    // Day 2
    if (current == 2) {
      return '2 days! Building a habit! 👏';
    }
    
    // Default
    return 'Come back tomorrow to continue! ⭐';
  }

  // ✅ DYNAMIC ICONS BASED ON CONTEXT
  IconData _getMessageIcon(int current, int max) {
    // First day
    if (current == 1 && max == 1) {
      return Icons.rocket_launch;
    }
    // Breaking record
    if (current >= max && current > 1) {
      return Icons.celebration;
    }
    // Week+ streak
    if (current >= 7) {
      return Icons.local_fire_department;
    }
    // Comeback
    if (current == 1 && max > 1) {
      return Icons.refresh;
    }
    // Default
    return Icons.info_outline;
  }
}