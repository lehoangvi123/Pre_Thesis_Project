import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:project1/view/login/WelcomeView.dart';
import 'package:project1/view/login/OnboardingView.dart';
import 'package:project1/view/Function/HomeView.dart';
import './view/ThemeProvider/ThemeProviderDark.dart';
import './view/Function/Language/MultiLanguage.dart';

void main() async { 
  // Đảm bảo Flutter engine đã khởi tạo
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Load language (nếu cần)
  await AppLocalizations.loadLanguage();
  
  // Chạy app
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Smart Expense Tracker',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const WelcomeView(),
          routes: {
            '/welcome': (context) => const WelcomeView(),
            '/onboarding': (context) => const OnboardingView(),
            '/home': (context) => const HomeView(),
          },
        );
      },
    );
  }
}