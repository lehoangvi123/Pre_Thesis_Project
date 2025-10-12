import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import './HomeView.dart';
import './AnalysisView.dart';
import './Transaction.dart';
import './CategorizeContent.dart';
import '../notification/NotificationView.dart';
import '../login/LoginView.dart';
import '../FunctionProfileView/Help.dart'; // Add this import for Help

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String userName = 'User';
  String userEmail = 'user@example.com';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Get current Firebase user
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Fetch user data from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            userName = userData['name'] ?? currentUser.displayName ?? 'User';
            userEmail = userData['email'] ?? currentUser.email ?? 'user@example.com';
            isLoading = false;
          });

          // Save to SharedPreferences for offline access
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', userName);
          await prefs.setString('user_email', userEmail);
        } else {
          // If Firestore doc doesn't exist, use Firebase Auth data
          setState(() {
            userName = currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'User';
            userEmail = currentUser.email ?? 'user@example.com';
            isLoading = false;
          });
        }
      } else {
        // No Firebase user, try SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          userName = prefs.getString('user_name') ?? 'User';
          userEmail = prefs.getString('user_email') ?? 'user@example.com';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Fallback to SharedPreferences
      try {
        final prefs = await SharedPreferences.getInstance();
        setState(() {
          userName = prefs.getString('user_name') ?? 'User';
          userEmail = prefs.getString('user_email') ?? 'user@example.com';
          isLoading = false;
        });
      } catch (e) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFFE8F5E9),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
              _buildAppBar(),
              
              // Scrollable Content
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFF00CED1),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              const SizedBox(height: 20),
                              
                              // Profile Picture and Info
                              _buildProfileHeader(),
                              const SizedBox(height: 32),
                              
                              // Menu Items
                              _buildMenuItem(
                                icon: Icons.person_outline,
                                iconColor: Colors.blue[400]!,
                                iconBackground: Colors.blue[50]!,
                                title: 'Edit Profile',
                                onTap: () {
                                  _showEditProfileDialog();
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildMenuItem(
                                icon: Icons.security,
                                iconColor: Colors.blue[400]!,
                                iconBackground: Colors.blue[50]!,
                                title: 'Security',
                                onTap: () {
                                  // Navigate to Security
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Security page coming soon')),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildMenuItem(
                                icon: Icons.attach_money,
                                iconColor: Colors.blue[400]!,
                                iconBackground: Colors.blue[50]!,
                                title: 'Converting Currency',
                                onTap: () {
                                  // Navigate to Currency Converter
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Currency converter coming soon')),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildMenuItem(
                                icon: Icons.settings,
                                iconColor: Colors.blue[400]!,
                                iconBackground: Colors.blue[50]!,
                                title: 'Setting',
                                onTap: () {
                                  // Navigate to Settings
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Settings page coming soon')),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildMenuItem(
                                icon: Icons.help_outline,
                                iconColor: Colors.blue[400]!,
                                iconBackground: Colors.blue[50]!,
                                title: 'Help',
                                onTap: () {
                                  // Navigate to Help - UPDATED HERE
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const HelpView(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildMenuItem(
                                icon: Icons.logout,
                                iconColor: Colors.red[400]!,
                                iconBackground: Colors.red[50]!,
                                title: 'Logout',
                                onTap: () {
                                  _showLogoutDialog();
                                },
                              ),
                              
                              // Extra space for bottom navigation
                              const SizedBox(height: 80),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.arrow_back, color: Colors.grey[700]),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationView(),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.notifications_outlined, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        // Profile Picture with Edit Button
        Stack(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey[300],
                border: Border.all(color: Colors.white, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.grey[600],
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change profile picture coming soon')),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CED1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Name (from Firebase)
        Text(
          userName,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        
        // Email (from Firebase)
        Text(
          userEmail,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final TextEditingController nameController = TextEditingController(text: userName);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: 'Name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                String newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != userName) {
                  await _updateUserProfile(newName);
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Save',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateUserProfile(String newName) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      
      if (currentUser != null) {
        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .update({
          'name': newName,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Update Firebase Auth display name
        await currentUser.updateDisplayName(newName);

        // Update SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', newName);

        // Refresh UI
        setState(() {
          userName = newName;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Update failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Đăng xuất',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Hủy',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Đăng xuất',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();
      
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Navigate to login
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              _buildNavItem(Icons.home, false, Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeView()),
                );
              }),
              _buildNavItem(Icons.search, false, Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AnalysisView()),
                );
              }),
              _buildNavItem(Icons.swap_horiz, false, Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const TransactionView()),
                );
              }),
              _buildNavItem(Icons.layers, false, Colors.grey[400]!, onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CategoriesView()),
                );
              }),
              _buildNavItem(Icons.person_outline, true, const Color(0xFF00CED1), onTap: () {
                // Already on Profile page
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}