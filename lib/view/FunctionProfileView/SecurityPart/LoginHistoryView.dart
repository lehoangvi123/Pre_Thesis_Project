import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

// Login Activity Model
class LoginActivity {
  final String id;
  final String deviceName;
  final String deviceType;
  final String ipAddress;
  final String location;
  final DateTime timestamp;
  final bool isSuccessful;
  final String loginMethod; // email, google, facebook
  final String? failureReason;

  LoginActivity({
    required this.id,
    required this.deviceName,
    required this.deviceType,
    required this.ipAddress,
    required this.location,
    required this.timestamp,
    required this.isSuccessful,
    required this.loginMethod,
    this.failureReason,
  });

  factory LoginActivity.fromJson(Map<String, dynamic> json) {
    return LoginActivity(
      id: json['id'] ?? '',
      deviceName: json['deviceName'] ?? 'Unknown Device',
      deviceType: json['deviceType'] ?? 'Unknown',
      ipAddress: json['ipAddress'] ?? 'Unknown',
      location: json['location'] ?? 'Unknown Location',
      timestamp: json['timestamp'] != null
          ? (json['timestamp'] is Timestamp
              ? (json['timestamp'] as Timestamp).toDate()
              : DateTime.parse(json['timestamp']))
          : DateTime.now(),
      isSuccessful: json['isSuccessful'] ?? true,
      loginMethod: json['loginMethod'] ?? 'email',
      failureReason: json['failureReason'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'ipAddress': ipAddress,
      'location': location,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSuccessful': isSuccessful,
      'loginMethod': loginMethod,
      'failureReason': failureReason,
    };
  }
}

// Login History Service
class LoginHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // Get current device info
  static Future<Map<String, dynamic>> getCurrentDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        String deviceName = '${androidInfo.brand} ${androidInfo.model}';
        if (deviceName.contains('sdk_gphone')) {
          deviceName = 'Android Emulator';
        }
        return {
          'deviceId': androidInfo.id,
          'deviceName': deviceName.trim(),
          'deviceType': 'Android',
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'deviceName': iosInfo.name ?? 'iOS Device',
          'deviceType': 'iOS',
        };
      }
    } catch (e) {
      print('Error getting device info: $e');
    }
    return {
      'deviceId': 'unknown',
      'deviceName': 'Unknown Device',
      'deviceType': Platform.operatingSystem,
    };
  }

  // Log successful login
  static Future<void> logLoginAttempt({
    required bool isSuccessful,
    required String loginMethod,
    String? failureReason,
  }) async {
    try {
      print('📝 Logging login attempt...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null && isSuccessful) {
        print('❌ No user logged in but login marked as successful');
        return;
      }

      final deviceInfo = await getCurrentDeviceInfo();
      final userId = user?.uid ?? 'unknown';
      
      final activityId = DateTime.now().millisecondsSinceEpoch.toString();

      final loginData = {
        'id': activityId,
        'deviceName': deviceInfo['deviceName'],
        'deviceType': deviceInfo['deviceType'],
        'ipAddress': 'Unknown', // You can implement IP detection
        'location': 'Vietnam', // You can implement geolocation
        'timestamp': FieldValue.serverTimestamp(),
        'isSuccessful': isSuccessful,
        'loginMethod': loginMethod,
        'failureReason': failureReason,
      };

      print('💾 Saving login activity to Firestore...');
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('loginHistory')
          .doc(activityId)
          .set(loginData);

      print('✅ Login activity logged successfully!');
    } catch (e) {
      print('❌ Error logging login attempt: $e');
    }
  }

  // Fetch login history
  static Future<List<LoginActivity>> fetchLoginHistory({int limit = 50}) async {
    try {
      print('🔍 Fetching login history...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in!');
        return [];
      }

      print('✅ User ID: ${user.uid}');

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('loginHistory')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      print('📊 Found ${snapshot.docs.length} login activities');

      return snapshot.docs.map((doc) {
        return LoginActivity.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print('❌ Error fetching login history: $e');
      return [];
    }
  }

  // Clear old login history (keep last 100 records)
  static Future<void> clearOldHistory({int keepLast = 100}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('loginHistory')
          .orderBy('timestamp', descending: true)
          .get();

      if (snapshot.docs.length > keepLast) {
        final docsToDelete = snapshot.docs.skip(keepLast);
        for (var doc in docsToDelete) {
          await doc.reference.delete();
        }
        print('🗑️ Cleared ${docsToDelete.length} old login records');
      }
    } catch (e) {
      print('❌ Error clearing old history: $e');
    }
  }
}

// Login History View
class LoginHistoryView extends StatefulWidget {
  const LoginHistoryView({Key? key}) : super(key: key);

  @override
  State<LoginHistoryView> createState() => _LoginHistoryViewState();
}

class _LoginHistoryViewState extends State<LoginHistoryView> {
  List<LoginActivity> loginHistory = [];
  bool isLoading = true;
  String filterType = 'all'; // all, successful, failed

  @override
  void initState() {
    super.initState();
    loadLoginHistory();
  }

  Future<void> loadLoginHistory() async {
    setState(() => isLoading = true);
    try {
      final history = await LoginHistoryService.fetchLoginHistory();
      setState(() {
        loginHistory = history;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showErrorSnackbar('Failed to load login history');
    }
  }

  List<LoginActivity> get filteredHistory {
    if (filterType == 'successful') {
      return loginHistory.where((a) => a.isSuccessful).toList();
    } else if (filterType == 'failed') {
      return loginHistory.where((a) => !a.isSuccessful).toList();
    }
    return loginHistory;
  }

  void showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Login History',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.grey),
            onSelected: (value) {
              setState(() {
                filterType = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Activities')),
              const PopupMenuItem(value: 'successful', child: Text('Successful Only')),
              const PopupMenuItem(value: 'failed', child: Text('Failed Only')),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D2D3)),
            )
          : RefreshIndicator(
              onRefresh: loadLoginHistory,
              color: const Color(0xFF00D2D3),
              child: Column(
                children: [
                  // Info Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F9F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Color(0xFF00D2D3), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'View recent login activities on your account',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Statistics Row
                  if (loginHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Total',
                              loginHistory.length.toString(),
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Successful',
                              loginHistory.where((a) => a.isSuccessful).length.toString(),
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatCard(
                              'Failed',
                              loginHistory.where((a) => !a.isSuccessful).length.toString(),
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Login History List
                  Expanded(
                    child: filteredHistory.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No login history found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: filteredHistory.length,
                            itemBuilder: (context, index) {
                              return LoginActivityCard(
                                activity: filteredHistory[index],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// Login Activity Card Widget
class LoginActivityCard extends StatelessWidget {
  final LoginActivity activity;

  const LoginActivityCard({
    Key? key,
    required this.activity,
  }) : super(key: key);

  IconData getDeviceIcon() {
    if (activity.deviceType.toLowerCase().contains('android')) {
      return Icons.phone_android;
    } else if (activity.deviceType.toLowerCase().contains('ios')) {
      return Icons.phone_iphone;
    } else {
      return Icons.devices;
    }
  }

  IconData getLoginMethodIcon() {
    switch (activity.loginMethod.toLowerCase()) {
      case 'google':
        return Icons.g_mobiledata;
      case 'facebook':
        return Icons.facebook;
      default:
        return Icons.email;
    }
  }

  Color getStatusColor() {
    return activity.isSuccessful ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activity.isSuccessful
              ? Colors.grey.shade200
              : Colors.red.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: getStatusColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  activity.isSuccessful ? Icons.check_circle : Icons.cancel,
                  color: getStatusColor(),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _formatDateTime(activity.timestamp),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          getLoginMethodIcon(),
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatRelativeTime(activity.timestamp),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: activity.isSuccessful
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  activity.isSuccessful ? 'Success' : 'Failed',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(getDeviceIcon(), size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activity.deviceName,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                activity.location,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          if (!activity.isSuccessful && activity.failureReason != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.error_outline, size: 16, color: Colors.red.shade600),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    activity.failureReason!,
                    style: TextStyle(fontSize: 13, color: Colors.red.shade600),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today at ${_formatTime(date)}';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${(difference.inDays / 7).floor()} weeks ago';
    }
  }
}