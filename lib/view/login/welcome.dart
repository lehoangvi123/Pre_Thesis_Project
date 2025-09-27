import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [    
              // Welcome Image Container
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40.0),
                  child: Image.asset(
                    'assets/images/freepik__android-mobile-app-welcome-screen-for-a-finance-ap__13441.png',        
                    fit: BoxFit.contain,       
                    errorBuilder: (context, error, stackTrace) {  
                      // Fallback if image not found
                      return Container(    
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.account_balance_wallet,
                                size: 80,
                                color: Color(0xFF2E7D32),
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Welcome Image\nPlaceholder',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Welcome Text Section
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Welcome to',
                        style: TextStyle(
                          fontSize: 24,
                          color: Color(0xFF757575),
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Smart Expense Tracker',
                        style: TextStyle(
                          fontSize: 28,
                          color: Color(0xFF2E7D32),
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Track your expenses with AI-powered insights',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w400,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom spacing
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}