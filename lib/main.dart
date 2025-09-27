import 'package:flutter/material.dart';
import 'package:project1/view/login/welcome.dart';

void main() {
  runApp(const MyApp());
}          

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Inter",
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: false,
      ),
      home: const WelcomeScreen(), // Sử dụng WelcomeScreen từ file welcome.dart
    );
  }
}

// Class TColor để fix lỗi màu sắc (dựa trên code bạn đã có trước đó)
class TColor {
  static const Color primary = Color(0xFF2E7D32);
  static const Color gray80 = Color(0xFFF5F5F5);
  static const Color gray60 = Color(0xFF757575);
  static const Color secondary = Color(0xFF60AD5E);
}