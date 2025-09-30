import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  } 




  @override
  Widget build(BuildContext context) { 
    // MediaQuery must be called inside build method
    var media = MediaQuery.sizeOf(context);
    
    return Scaffold(
      body: Stack(
        children: [
          Image.asset(
            "assets/images/Intro screen-login/Splash Screen.png", 
            width: media.width, 
            height: media.height, 
            fit: BoxFit.cover, // Fixed: BoxFit not Boxfix
          ),
        ],
      ),
    );
  }
}