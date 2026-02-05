// lib/notification/NotificationView.dart
// FIXED VERSION - Const-compatible

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key}); // ✅ FIXED: super.key

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.grey[800],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notification',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey[800],
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(
              Icons.done_all,
              color: Color(0xFF00CED1),
            ),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: _auth.currentUser == null
          ? _buildEmptyState('Please login to see notifications', isDark)
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(_auth.currentUser!.uid)
                  .collection('notifications')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF00CED1),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildEmptyState('Error loading notifications', isDark);
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState('No notifications yet', isDark);
                }

                final notifications = snapshot.data!.docs;

                // Group notifications by date
                final groupedNotifications = _groupNotificationsByDate(notifications);

                return Scrollbar(
                  thumbVisibility: true,
                  thickness: 6,
                  radius: const Radius.circular(10),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    physics: const BouncingScrollPhysics(),
                    itemCount: groupedNotifications.length,
                    itemBuilder: (context, index) {
                      final groupKey = groupedNotifications.keys.elementAt(index);
                      final groupItems = groupedNotifications[groupKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Padding(
                            padding: const EdgeInsets.only(
                              left: 4,
                              bottom: 12,
                              top: 8,
                            ),
                            child: Text(
                              groupKey,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                              ),
                            ),
                          ),
                          // Notification Items
                          ...groupItems.map((doc) =>
                              _buildNotificationCard(doc, isDark)),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
      bottomNavigationBar: _buildBottomNavBar(isDark),
    );
  }

  // ✅ GROUP NOTIFICATIONS BY DATE
  Map<String, List<QueryDocumentSnapshot>> _groupNotificationsByDate(
      List<QueryDocumentSnapshot> notifications) {
    final Map<String, List<QueryDocumentSnapshot>> grouped = {};

    for (var doc in notifications) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['createdAt'] as Timestamp?;

      if (timestamp == null) continue;

      final date = timestamp.toDate();
      final groupKey = _getGroupKey(date);

      if (!grouped.containsKey(groupKey)) {
        grouped[groupKey] = [];
      }
      grouped[groupKey]!.add(doc);
    }

    return grouped;
  }

  // ✅ GET GROUP KEY (Today, Yesterday, etc.)
  String _getGroupKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final notificationDate = DateTime(date.year, date.month, date.day);

    if (notificationDate == today) {
      return 'Today';
    } else if (notificationDate == yesterday) {
      return 'Yesterday';
    } else if (now.difference(date).inDays < 7) {
      return 'This Week';
    } else {
      return 'Earlier';
    }
  }

  // ✅ BUILD NOTIFICATION CARD
  Widget _buildNotificationCard(QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Notification';
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'general';
    final isRead = data['isRead'] ?? false;
    final timestamp = data['createdAt'] as Timestamp?;

    final icon = _getIconForType(type);
    final color = _getColorForType(type);

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Delete notification?',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            content: Text(
              'This notification will be permanently deleted.',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => _deleteNotification(doc.id),
      child: GestureDetector(
        onTap: () => _markAsRead(doc.id, isRead),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isRead
                ? (isDark
                    ? const Color(0xFF2C2C2C)
                    : color.withOpacity(0.05))
                : color.withOpacity(isDark ? 0.15 : 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isRead
                  ? Colors.transparent
                  : color.withOpacity(0.3),
              width: isRead ? 0 : 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        // Unread indicator
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00CED1),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(timestamp.toDate()),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ GET ICON FOR TYPE
  IconData _getIconForType(String type) {
    switch (type) {
      case 'transaction':
        return Icons.swap_horiz;
      case 'achievement':
        return Icons.emoji_events;
      case 'budget_alert':
        return Icons.warning;
      case 'savings':
        return Icons.savings;
      case 'reminder':
        return Icons.notifications_active;
      case 'update':
        return Icons.update;
      case 'expense':
        return Icons.receipt_long;
      default:
        return Icons.notifications;
    }
  }

  // ✅ GET COLOR FOR TYPE
  Color _getColorForType(String type) {
    switch (type) {
      case 'transaction':
        return const Color(0xFF00CED1);
      case 'achievement':
        return Colors.amber;
      case 'budget_alert':
        return Colors.red;
      case 'savings':
        return Colors.green;
      case 'reminder':
        return const Color(0xFF00CED1);
      case 'update':
        return Colors.blue;
      case 'expense':
        return Colors.orange;
      default:
        return const Color(0xFF00CED1);
    }
  }

  // ✅ FORMAT TIME
  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return DateFormat('HH:mm - MMM dd').format(date);
    }
  }

  // ✅ MARK AS READ
  Future<void> _markAsRead(String notificationId, bool currentReadStatus) async {
    if (currentReadStatus) return; // Already read

    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  // ✅ MARK ALL AS READ
  Future<void> _markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All notifications marked as read'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  // ✅ DELETE NOTIFICATION
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('notifications')
          .doc(notificationId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Notification deleted'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // ✅ EMPTY STATE
  Widget _buildEmptyState(String message, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off,
            size: 80,
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Notifications will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ BOTTOM NAV BAR
  Widget _buildBottomNavBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.home,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[400]!,
              ),
              _buildNavItem(
                Icons.search,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[400]!,
              ),
              _buildNavItem(
                Icons.swap_horiz,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[400]!,
              ),
              _buildNavItem(
                Icons.layers,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[400]!,
              ),
              _buildNavItem(
                Icons.person_outline,
                false,
                isDark ? Colors.grey[400]! : Colors.grey[400]!,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
} 



