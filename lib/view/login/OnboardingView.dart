import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
            "assets/images/Intro screen-login/Onboarding.png",
            width: media.width,
            height: media.height,
            fit: BoxFit.cover,
          ),
          
          // Content overlay (nếu cần thêm nội dung)
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Nút Get Started (nếu cần)
                Padding(
                  padding: const EdgeInsets.all(40.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Navigate to next screen (Sign up/Login)
                      print("Get Started pressed");
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DD0E1),
                      minimumSize: Size(media.width * 0.8, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}