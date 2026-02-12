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
import '../FunctionProfileView/Help.dart';
import '../FunctionProfileView/converting_currency_view.dart';
import '../FunctionProfileView//security_view.dart';
import '../FunctionProfileView/settings_view.dart';
import './FixDataScript.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  String userName = 'User';
  String userEmail = 'user@example.com';
  String phoneNumber = '';
  String bio = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;

          if (!mounted) return;
          setState(() {
            userName = userData['name'] ?? currentUser.displayName ?? 'User';
            userEmail =
                userData['email'] ?? currentUser.email ?? 'user@example.com';
            phoneNumber = userData['phoneNumber'] ?? '';
            bio = userData['bio'] ?? '';
            isLoading = false;
          });

          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', userName);
          await prefs.setString('user_email', userEmail);
        } else {
          if (!mounted) return;
          setState(() {
            userName =
                currentUser.displayName ??
                currentUser.email?.split('@')[0] ??
                'User';
            userEmail = currentUser.email ?? 'user@example.com';
            isLoading = false;
          });
        }
      } else {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        setState(() {
          userName = prefs.getString('user_name') ?? 'User';
          userEmail = prefs.getString('user_email') ?? 'user@example.com';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted) return;
        setState(() {
          userName = prefs.getString('user_name') ?? 'User';
          userEmail = prefs.getString('user_email') ?? 'user@example.com';
          isLoading = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF1A1A1A), const Color(0xFF0F0F0F)]
                : [const Color(0xFFE8F5E9), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
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
                              _buildProfileHeader(),
                              const SizedBox(height: 32),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SecurityView(),
                                    ),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ConvertingCurrencyView(),
                                    ),
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
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsView(),
                                    ),
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
                                icon: Icons.build_circle,
                                iconColor: Colors.orange[400]!,
                                iconBackground: Colors.orange[50]!,
                                title: '🔧 Fix Data (Income âm)',
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FixDataScreen(),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
               Navigator.pushReplacement(
                 context,
                 MaterialPageRoute(builder: (context) => const HomeView()),
               );
             },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
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
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.notifications_outlined,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  
  return Column(
    children: [
      Stack(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
              border: Border.all(
                color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                width: 4,
              ),
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
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Change profile picture coming soon'),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CED1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                    width: 2,
                  ),
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
      
      // Name
      Text(
        userName,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      const SizedBox(height: 4),
      
      // Email
      Text(
        userEmail,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
      
      // ✅ BIO - NEW
      if (bio.isNotEmpty) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: isDark 
                ? const Color(0xFF2C2C2C).withOpacity(0.5)
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            bio,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
                color: isDark
                    ? iconBackground.withOpacity(0.2)
                    : iconBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW BEAUTIFUL EDIT PROFILE DIALOG
  void _showEditProfileDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final nameController = TextEditingController(text: userName);
    final emailController = TextEditingController(text: userEmail);
    final phoneController = TextEditingController(text: phoneNumber);
    final bioController = TextEditingController(text: bio);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: const Color(0xFF00CED1),
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Avatar Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            border: Border.all(
                              color: const Color(0xFF00CED1),
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.person,
                            size: 50,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('📸 Change avatar (Coming soon)'),
                                  backgroundColor: Color(0xFF00CED1),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00CED1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  // Name Field
                  _buildTextField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 16),

                  // Email Field
                  _buildTextField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                    enabled: false,
                  ),
                  
                  const SizedBox(height: 16),

                  // Phone Field
                  _buildTextField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    isDark: isDark,
                    keyboardType: TextInputType.phone,
                    hint: 'Enter your phone number',
                  ),
                  
                  const SizedBox(height: 16),

                  // Bio Field
                  _buildTextField(
                    controller: bioController,
                    label: 'Bio',
                    icon: Icons.info_outline,
                    isDark: isDark,
                    maxLines: 3,
                    hint: 'Tell us about yourself...',
                  ),

                  const SizedBox(height: 24),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () async {
                          await _updateProfile(
                            name: nameController.text,
                            phone: phoneController.text,
                            bio: bioController.text,
                          );
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00CED1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper: Build Text Field
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
    bool enabled = true,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
            prefixIcon: Icon(
              icon,
              color: const Color(0xFF00CED1),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF00CED1),
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Update Profile Function
  Future<void> _updateProfile({
    required String name,
    required String phone,
    required String bio,
  }) async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({
        'name': name,
        'phoneNumber': phone,
        'bio': bio,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update Auth
      await currentUser.updateDisplayName(name);

      // Update SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);

      // Update local state
      if (!mounted) return;
      setState(() {
        userName = name;
        phoneNumber = phone;
        this.bio = bio;
      });

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showLogoutDialog() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Đăng xuất',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: Text(
            'Bạn có chắc chắn muốn đăng xuất không?',
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.black,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Hủy',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
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
      await FirebaseAuth.instance.signOut();

      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildBottomNavBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
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
              _buildNavItem(
                Icons.home,
                false,
                Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeView()),
                  );
                },
              ),
              _buildNavItem(
                Icons.search,
                false,
                Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalysisView(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                Icons.swap_horiz,
                false,
                Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionView(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                Icons.layers,
                false,
                Colors.grey[400]!,
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoriesView(),
                    ),
                  );
                },
              ),
              _buildNavItem(
                Icons.person_outline,
                true,
                const Color(0xFF00CED1),
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    bool isActive,
    Color color, {
    VoidCallback? onTap,
  }) {
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