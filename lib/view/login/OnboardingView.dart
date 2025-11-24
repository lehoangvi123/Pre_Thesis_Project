import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:project1/view/login/LoginView.dart';
import '../sign-up/SignUpView.dart'; // ← Thêm dòng này


class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
  }

  @override
  Widget build(BuildContext context) {
    var media = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Image.asset(
           "assets/images/Intro_screen-login/Onboardingg.png",
            width: media.width,
            height: media.height,
            fit: BoxFit.cover,
          ),
          
          // Nút Get Started - Positioned chính xác
          Positioned(
            bottom: 60, // Khoảng cách từ đáy màn hình
            left: 30,    // Khoảng cách từ bên trái
            right: 30,   // Khoảng cách từ bên phải
            child: ElevatedButton(
              onPressed: () {
                // TODO: Navigate to Sign Up screen
                print("Get Started pressed");
                 Navigator.push(
                   context,
                   MaterialPageRoute(builder: (context) => const SignUpView()),
                 );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4DD0E1),
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 5,
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          
          // Text "Already Have Account? Log in" - Clickable
          Positioned(
            bottom: 20, // Khoảng cách từ đáy
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already Have Account? ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // TODO: Navigate to Login page
                    print("Login link clicked!");
                     Navigator.push(
                       context,
                       MaterialPageRoute(builder: (context) => const LoginView()),
                     );
                  },
                  child: const Text(
                    'Log in',
                    style: TextStyle(
                      fontSize: 14, 
                      color: Color(0xFF4DD0E1),
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
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