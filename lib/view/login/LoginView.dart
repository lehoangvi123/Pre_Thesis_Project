import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart'; 
import 'package:shared_preferences/shared_preferences.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import '../sign-up/SignUpView.dart'; 
import './ForgotPasswordView.dart'; 
import '../Function/HomeView.dart';  
import '../FunctionProfileView/SecurityPart/ManageDevicesView.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // ✅ REGISTER DEVICE AFTER SUCCESSFUL LOGIN
      await DeviceService.registerDevice();

      if (mounted) {
        _showSuccessSnackBar('Đăng nhập thành công!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = '';
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Email không tồn tại. Vui lòng đăng ký trước.';
          break;
        case 'wrong-password':
          errorMessage = 'Sai mật khẩu. Vui lòng thử lại.';
          break;
        case 'invalid-email':
          errorMessage = 'Email không hợp lệ.';
          break;
        case 'user-disabled':
          errorMessage = 'Tài khoản này đã bị vô hiệu hóa.';
          break;
        case 'invalid-credential':
          errorMessage = 'Email hoặc mật khẩu không đúng. Vui lòng thử lại.';
          break;
        default:
          errorMessage = 'Đã xảy ra lỗi: ${e.message}';
      }
      
      _showErrorDialog(errorMessage);
      
    } catch (e) {
      _showErrorDialog('Đã xảy ra lỗi không xác định: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // ✅ REGISTER DEVICE AFTER SUCCESSFUL GOOGLE LOGIN
      if (userCredential.user != null) {
        await DeviceService.registerDevice();
        
        if (mounted) {
          _showSuccessSnackBar('Đăng nhập Google thành công!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeView()),
          );
        }
      }

    } catch (e) {
      _showErrorDialog('Lỗi đăng nhập Google: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final OAuthCredential credential = 
            FacebookAuthProvider.credential(result.accessToken!.token);

        final userCredential = await _auth.signInWithCredential(credential);

        // ✅ REGISTER DEVICE AFTER SUCCESSFUL FACEBOOK LOGIN
        if (userCredential.user != null) {
          await DeviceService.registerDevice();
          
          if (mounted) {
            _showSuccessSnackBar('Đăng nhập Facebook thành công!');
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeView()),
            );
          }
        }
      } else if (result.status == LoginStatus.cancelled) {
        _showErrorDialog('Đăng nhập Facebook đã bị hủy');
      } else {
        _showErrorDialog('Tính năng đăng nhập Facebook đang được cập nhật. Vui lòng sử dụng Email hoặc Google để tiếp tục!');
      }

    } catch (e) {
      _showErrorDialog('Tính năng đăng nhập Facebook đang được cập nhật. Vui lòng sử dụng Email hoặc Google để tiếp tục!');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Thông báo',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          message,
          style: TextStyle(
            color: isDark ? Colors.grey[300] : Colors.black,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Đóng',
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  } 

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Login to your account',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 40),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: isDark ? Colors.grey[500] : null,
                    ),
                    labelText: 'Email',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.blue,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Email không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.lock_outline,
                      color: isDark ? Colors.grey[500] : null,
                    ),
                    labelText: 'Password',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : null,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey[600]! : Colors.blue,
                      ),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: isDark ? Colors.grey[500] : null,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mật khẩu';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                
                // Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (context) => const ForgotPasswordView()),
                      ); 
                    }, 
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),  
                
                // Login Button   
                SizedBox(  
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Log In',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Divider với text "Or continue with"
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                        thickness: 1,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'Or continue with',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.grey[700] : Colors.grey[400],
                        thickness: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Social Login Buttons
                Row(
                  children: [
                    // Google Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithGoogle,
                        icon: Image.asset(
                          'assets/images/google_icon.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.g_mobiledata,
                              color: Color(0xFFDB4437),
                              size: 28,
                            );
                          },
                        ),
                        label: Text(
                          'Google',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Facebook Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _signInWithFacebook,
                        icon: const Icon(
                          Icons.facebook,
                          color: Color(0xFF1877F2),
                          size: 24,
                        ),
                        label: Text(
                          'Facebook',
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Sign Up Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Don\'t have an account? ',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context, 
                          MaterialPageRoute(builder: (context) => const SignUpView()),
                        );
                      },
                      child: const Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLoginWithFirebase(String email, String password) async {
    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      
      // ✅ REGISTER DEVICE AFTER SUCCESSFUL LOGIN
      await DeviceService.registerDevice();
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setString('user_name', userDoc['name'] ?? email.split('@')[0]);
      await prefs.setString('user_email', email);
      await prefs.setString('user_id', userCredential.user!.uid);
      await prefs.setBool('is_logged_in', true);
      
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomeView()),
        (Route<dynamic> route) => false,
      );
      
    } catch (e) {
      print('Login error: $e');
    }
  }
}