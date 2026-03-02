// lib/services/DailyGreetingService.dart
// Automatically creates daily greeting notifications based on time of day

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DailyGreetingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // ✅ Call this on app launch or when NotificationView opens
  static Future<void> createDailyGreetingIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final hour = now.hour;

    // Check if we already sent a greeting today
    final existing = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'daily_greeting')
        .where('dateKey', isEqualTo: todayKey)
        .get();

    if (existing.docs.isNotEmpty) return; // Already sent today

    // Determine greeting based on time
    final greeting = _getGreeting(hour);

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add({
      'title': greeting['title'],
      'body': greeting['body'],
      'type': 'daily_greeting',
      'isRead': false,
      'dateKey': todayKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Also call this to create a budget reminder if user has no transactions today
  static Future<void> createBudgetReminderIfNeeded() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayKey = '${now.year}-${now.month}-${now.day}';
    final hour = now.hour;

    // Only show budget reminder in afternoon/evening
    if (hour < 12) return;

    // Check if reminder already sent today
    final existing = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'budget_reminder')
        .where('dateKey', isEqualTo: todayKey)
        .get();

    if (existing.docs.isNotEmpty) return;

    // Check if user has logged any transaction today
    final startOfDay = DateTime(now.year, now.month, now.day);
    final transactions = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .limit(1)
        .get();

    // Only remind if no transactions today
    if (transactions.docs.isNotEmpty) return;

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('notifications')
        .add({
      'title': '💰 Budget Reminder',
      'body': 'You haven\'t logged any transactions today. Please fill in your income and expenses to keep your budget on track!',
      'type': 'budget_reminder',
      'isRead': false,
      'dateKey': todayKey,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Greeting messages based on hour
  static Map<String, String> _getGreeting(int hour) {
    if (hour >= 5 && hour < 12) {
      return {
        'title': '🌅 Good Morning!',
        'body': 'Start your day right! Review your budget and plan your spending for today.',
      };
    } else if (hour >= 12 && hour < 14) {
      return {
        'title': '☀️ Good Afternoon!',
        'body': 'Lunchtime check-in! Don\'t forget to log your morning expenses.',
      };
    } else if (hour >= 14 && hour < 18) {
      return {
        'title': '📝 Afternoon Reminder',
        'body': 'Please fill in your income and budget into the app to stay on track with your financial goals.',
      };
    } else if (hour >= 18 && hour < 21) {
      return {
        'title': '🌆 Evening Check-in',
        'body': 'How was your spending today? Log your expenses now and review your daily summary.',
      };
    } else {
      return {
        'title': '🌙 Good Night!',
        'body': 'Great job today! Review your spending summary and prepare your budget for tomorrow.',
      };
    }
  }
}