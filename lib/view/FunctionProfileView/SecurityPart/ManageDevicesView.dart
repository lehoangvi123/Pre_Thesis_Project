import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';

// Device Model
class DeviceInfo {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final String lastActive;
  final String location;
  final bool isCurrentDevice;
  final DateTime loginTime;

  DeviceInfo({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.lastActive,
    required this.location,
    required this.isCurrentDevice,
    required this.loginTime,
  });

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] ?? '',
      deviceName: json['deviceName'] ?? 'Unknown Device',
      deviceType: json['deviceType'] ?? 'Unknown',
      lastActive: json['lastActive'] ?? '',
      location: json['location'] ?? 'Unknown Location',
      isCurrentDevice: json['isCurrentDevice'] ?? false,
      loginTime: json['loginTime'] != null 
          ? (json['loginTime'] is Timestamp 
              ? (json['loginTime'] as Timestamp).toDate()
              : DateTime.parse(json['loginTime']))
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'lastActive': lastActive,
      'location': location,
      'isCurrentDevice': isCurrentDevice,
      'loginTime': Timestamp.fromDate(loginTime),
    };
  }
}

// Device Service
class DeviceService {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current device information
  static Future<Map<String, dynamic>> getCurrentDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        return {
          'deviceId': androidInfo.id,
          'deviceName': '${androidInfo.brand} ${androidInfo.model}',
          'deviceType': 'Android',
          'osVersion': androidInfo.version.release,
          'model': androidInfo.model,
        };
      } else if (Platform.isIOS) {
        IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        return {
          'deviceId': iosInfo.identifierForVendor ?? 'unknown',
          'deviceName': iosInfo.name ?? 'iOS Device',
          'deviceType': 'iOS',
          'osVersion': iosInfo.systemVersion,
          'model': iosInfo.model ?? 'iPhone',
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

  // Register device on login (call this after successful login)
  static Future<void> registerDevice() async {
    try {
      print('🔷 Starting device registration...');
      
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ No user logged in!');
        return;
      }
      
      print('✅ User ID: ${user.uid}');
      print('📧 User Email: ${user.email}');

      final deviceInfo = await getCurrentDeviceInfo();
      final deviceId = deviceInfo['deviceId'];
      
      print('📱 Device Info:');
      print('   - ID: $deviceId');
      print('   - Name: ${deviceInfo['deviceName']}');
      print('   - Type: ${deviceInfo['deviceType']}');

      print('💾 Saving to Firestore...');
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .set({
        'deviceId': deviceId,
        'deviceName': deviceInfo['deviceName'],
        'deviceType': deviceInfo['deviceType'],
        'loginTime': FieldValue.serverTimestamp(),
        'lastActive': 'Just now',
        'location': 'Vietnam', // You can implement IP-based location
        'isCurrentDevice': true,
      }, SetOptions(merge: true));

      print('✅ Device registered successfully!');

      // Update all other devices to not be current device
      print('🔄 Updating other devices...');
      final devicesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .where('deviceId', isNotEqualTo: deviceId)
          .get();

      print('📋 Found ${devicesSnapshot.docs.length} other devices');
      for (var doc in devicesSnapshot.docs) {
        await doc.reference.update({'isCurrentDevice': false});
      }
      
      print('✅ Device registration completed!');
    } catch (e) {
      print('❌ Error registering device: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  // Fetch all devices for user
  static Future<List<DeviceInfo>> fetchUserDevices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final currentDeviceInfo = await getCurrentDeviceInfo();
      final currentDeviceId = currentDeviceInfo['deviceId'];

      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .orderBy('loginTime', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['isCurrentDevice'] = data['deviceId'] == currentDeviceId;
        return DeviceInfo.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error fetching devices: $e');
      return [];
    }
  }

  // Remove device
  static Future<bool> removeDevice(String deviceId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .doc(deviceId)
          .delete();

      return true;
    } catch (e) {
      print('Error removing device: $e');
      return false;
    }
  }

  // Logout all other devices
  static Future<bool> logoutAllOtherDevices() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final currentDeviceInfo = await getCurrentDeviceInfo();
      final currentDeviceId = currentDeviceInfo['deviceId'];

      final devicesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('devices')
          .where('deviceId', isNotEqualTo: currentDeviceId)
          .get();

      for (var doc in devicesSnapshot.docs) {
        await doc.reference.delete();
      }

      return true;
    } catch (e) {
      print('Error logging out devices: $e');
      return false;
    }
  }
}

// Manage Devices View
class ManageDevicesView extends StatefulWidget {
  const ManageDevicesView({Key? key}) : super(key: key);

  @override
  State<ManageDevicesView> createState() => _ManageDevicesViewState();
}

class _ManageDevicesViewState extends State<ManageDevicesView> {
  List<DeviceInfo> devices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadDevices();
  }

  Future<void> loadDevices() async {
    setState(() => isLoading = true);
    try {
      final fetchedDevices = await DeviceService.fetchUserDevices();
      setState(() {
        devices = fetchedDevices;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      showErrorSnackbar('Failed to load devices');
    }
  }

  Future<void> removeDevice(DeviceInfo device) async {
    final confirm = await showConfirmDialog(
      'Remove Device',
      'Are you sure you want to remove "${device.deviceName}"? This will log you out from that device.',
    );

    if (confirm == true) {
      final success = await DeviceService.removeDevice(device.deviceId);
      if (success) {
        showSuccessSnackbar('Device removed successfully');
        loadDevices();
      } else {
        showErrorSnackbar('Failed to remove device');
      }
    }
  }

  Future<void> logoutAllOtherDevices() async {
    final confirm = await showConfirmDialog(
      'Logout All Devices',
      'Are you sure you want to logout from all other devices? This will end all active sessions except this one.',
    );

    if (confirm == true) {
      final success = await DeviceService.logoutAllOtherDevices();
      if (success) {
        showSuccessSnackbar('Logged out from all other devices');
        loadDevices();
      } else {
        showErrorSnackbar('Failed to logout from devices');
      }
    }
  }

  Future<bool?> showConfirmDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
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
          'Manage Devices',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D2D3)),
            )
          : RefreshIndicator(
              onRefresh: loadDevices,
              color: const Color(0xFF00D2D3),
              child: Column(
                children: [
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
                            'View and manage all devices signed into your account',
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: devices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.devices_other, size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 16),
                                Text(
                                  'No devices found',
                                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: devices.length,
                            itemBuilder: (context, index) {
                              return DeviceCard(
                                device: devices[index],
                                onRemove: () => removeDevice(devices[index]),
                              );
                            },
                          ),
                  ),
                  if (devices.where((d) => !d.isCurrentDevice).isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: logoutAllOtherDevices,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade50,
                            foregroundColor: Colors.red,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Logout All Other Devices',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}

// Device Card Widget
class DeviceCard extends StatelessWidget {
  final DeviceInfo device;
  final VoidCallback onRemove;

  const DeviceCard({
    Key? key,
    required this.device,
    required this.onRemove,
  }) : super(key: key);

  IconData getDeviceIcon() {
    if (device.deviceType.toLowerCase().contains('android')) {
      return Icons.phone_android;
    } else if (device.deviceType.toLowerCase().contains('ios') ||
        device.deviceType.toLowerCase().contains('iphone')) {
      return Icons.phone_iphone;
    } else if (device.deviceType.toLowerCase().contains('ipad') ||
        device.deviceType.toLowerCase().contains('tablet')) {
      return Icons.tablet;
    } else {
      return Icons.devices;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: device.isCurrentDevice ? const Color(0xFFE8F9F9) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: device.isCurrentDevice ? const Color(0xFF00D2D3) : Colors.grey.shade200,
          width: device.isCurrentDevice ? 2 : 1,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: device.isCurrentDevice ? const Color(0xFF00D2D3) : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  getDeviceIcon(),
                  color: device.isCurrentDevice ? Colors.white : Colors.grey.shade700,
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
                        Flexible(
                          child: Text(
                            device.deviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (device.isCurrentDevice) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00D2D3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'This Device',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.deviceType,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              if (!device.isCurrentDevice)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: onRemove,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Last active: ${device.lastActive}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  device.location,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.login, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                'Signed in: ${_formatDate(device.loginTime)}',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}