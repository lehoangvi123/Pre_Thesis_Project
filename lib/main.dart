import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart'; // ✅ THÊM
import 'firebase_options.dart';
import 'package:project1/view/login/WelcomeView.dart';
import 'package:project1/view/login/OnboardingView.dart';
import 'package:project1/view/Function/HomeView.dart';
import './view/ThemeProvider/ThemeProviderDark.dart';
import './view/Function/Language/MultiLanguage.dart';
import './provider/TransactionProvider.dart';
import 'package:project1/view/TextVoice/test_voice.dart';
import './service/backend_keepalive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ THÊM: Init locale tiếng Việt trước khi chạy app
  await initializeDateFormatting('vi', null);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ Start keep-alive
  BackendKeepAliveService.start();

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
          home: const AuthWrapper(),
          routes: {
            '/welcome': (context) => const WelcomeView(),
            '/onboarding': (context) => const OnboardingView(),
            '/home': (context) => const HomeView(),
            '/test-voice': (context) => TestVoiceView(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  Future<void> main() async {
    await dotenv.load(fileName: ".env");
    runApp(MyApp());
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Loading State
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
                    'Budget Buddy',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(color: Colors.white),
                ],
              ),
            ),
          );
        }

        // Error State
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Something went wrong',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const MyApp()),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        // User Logged In
        if (snapshot.hasData && snapshot.data != null) {
          return const HomeView();
        }

        // No User
        return const WelcomeView();
      },
    );
  }
}