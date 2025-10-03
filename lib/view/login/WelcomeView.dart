import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'OnboardingView.dart'; // Import màn hình Onboarding

class WelcomeView extends StatefulWidget { 
  const WelcomeView({super.key}); 

  @override
  State<WelcomeView> createState() => _WelcomeViewState();  
} 

class _WelcomeViewState extends State<WelcomeView> {   

  @override  
  void initState(){ 
    super.initState(); 
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.leanBack);
    
    // Tự động chuyển sang màn hình Onboarding sau 5 giây
    Timer(const Duration(seconds: 5), () {
      // Kiểm tra xem widget còn mounted không trước khi navigate
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const OnboardingView(),
          ),
        );
      }
    });
  } 

  @override
  Widget build(BuildContext context) { 
    var media = MediaQuery.sizeOf(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Splash Screen Image (BuddyBudget)
          Image.asset(
            "assets/images/Intro_screen-login/Splash_Screen.png", 
            width: media.width, 
            height: media.height, 
            fit: BoxFit.cover,
          ),
          
          // Loading indicator (tùy chọn)
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}