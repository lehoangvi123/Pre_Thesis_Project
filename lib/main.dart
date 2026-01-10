import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:project1/view/login/WelcomeView.dart';
import 'package:project1/view/login/OnboardingView.dart';
import 'package:project1/view/Function/HomeView.dart';
import './view/ThemeProvider/ThemeProviderDark.dart';
import './view/Function/Language/MultiLanguage.dart'; 
import './provider/TransactionProvider.dart';

// ⭐ IMPORT TEST VOICE SCREEN
import 'package:project1/view/TextVoice/test_voice.dart'; // Tạo file này ở bước sau

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await AppLocalizations.loadLanguage();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()..listenAll()),
      ],
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
          
          // ⭐ GIỮ NGUYÊN AuthWrapper
          home: const AuthWrapper(),
          
          routes: {
            '/welcome': (context) => const WelcomeView(),
            '/onboarding': (context) => const OnboardingView(),
            '/home': (context) => const HomeView(),
            '/test-voice': (context) =>  TestVoiceScreen(), // ⭐ THÊM ROUTE TEST
          },
        );
      },
    );
  }
}

// ⭐ AuthWrapper - GIỮ NGUYÊN
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print('🔍 ConnectionState: ${snapshot.connectionState}');
        print('🔍 HasData: ${snapshot.hasData}');
        print('🔍 User: ${snapshot.data?.email}');
        print('🔍 User UID: ${snapshot.data?.uid}');
        
        // 1️⃣ Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: const Color(0xFF00BCD4),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 60,
                      color: Color(0xFF00BCD4),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Expense Tracker',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // 2️⃣ Error State
        if (snapshot.hasError) {
          print('❌ Auth Error: ${snapshot.error}');
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Something went wrong',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const MyApp()),
                      );
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // 3️⃣ User Logged In → HomeView với nút Test Voice
        if (snapshot.hasData && snapshot.data != null) {
          print('✅ User logged in: ${snapshot.data!.email}');
          print('✅ Navigating to HomeView with Voice Test option');
          
          // ⭐ Wrap HomeView để thêm nút Test
          return HomeViewWrapper();
        }
        
        // 4️⃣ No User → WelcomeView
        print('❌ No user found, showing WelcomeView');
        return const WelcomeView();
      },
    );
  }
}

// ⭐ WRAPPER để thêm nút Test Voice vào HomeView
class HomeViewWrapper extends StatelessWidget {
  const HomeViewWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Màn hình Home bình thường
        const HomeView(),
        
        // ⭐ Floating button để vào Test Voice (CHỈ DÙNG KHI ĐANG DEV)
        Positioned(
          bottom: 80, // Đặt cao hơn bottom navigation
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              Navigator.pushNamed(context, '/test-voice');
            },
            icon: Icon(Icons.mic),
            label: Text('Test Voice'),
            backgroundColor: Colors.deepPurple,
            heroTag: 'testVoiceBtn', // Tránh conflict với FAB khác
          ),
        ),
      ],
    );
  }
}