// lib/view/Function/FunctionProfile/help/help_data.dart

import 'package:flutter/material.dart';

class HelpCategory {
  final String title;
  final IconData icon;
  final Color color;
  final List<HelpFAQ> faqs;

  HelpCategory({
    required this.title,
    required this.icon,
    required this.color,
    required this.faqs,
  });
}

class HelpFAQ {
  final String question;
  final String answer;
  final List<String>? steps;

  HelpFAQ({
    required this.question,
    required this.answer,
    this.steps,
  });
}

class HelpData {
  static List<HelpCategory> getAllCategories() {
    return [
      // Getting Started Category
      HelpCategory(
        title: 'Getting Started',
        icon: Icons.rocket_launch_outlined,
        color: const Color(0xFF00D2D3),
        faqs: [
          HelpFAQ(
            question: 'How do I create an account?',
            answer:
                'To create an account, tap the "Sign Up" button on the login screen. Enter your email address, create a strong password, and fill in your personal information. You\'ll receive a verification email to confirm your account. Click the link in the email to activate your account and start using the app.',
          ),
          HelpFAQ(
            question: 'How do I add my first transaction?',
            answer:
                'Adding a transaction is simple! Tap the "+" button on the home screen, select whether it\'s an Income or Expense, enter the amount, choose a category (like Food, Transport, etc.), add an optional note, and tap Save. Your transaction will appear immediately in your transaction history.',
          ),
          HelpFAQ(
            question: 'How do I set up my monthly budget?',
            answer:
                'Go to Settings → Budget Management. Here you can set monthly spending limits for each category like Food, Transport, Rent, etc. The app will track your spending against these limits and notify you when you\'re approaching or exceeding your budget.',
          ),
          HelpFAQ(
            question: 'What information do I need to provide during setup?',
            answer:
                'During initial setup, you\'ll need to provide your email, create a password, and optionally add your monthly income. You can also set up categories and budgets, but these can be configured later. The more information you provide, the better the AI can help you manage your finances.',
          ),
        ],
      ),

      // Account & Security Category
      HelpCategory(
        title: 'Account & Security',
        icon: Icons.security_outlined,
        color: const Color(0xFF4CAF50),
        faqs: [
          HelpFAQ(
            question: 'Is my financial data secure?',
            answer:
                'Absolutely! We take your security seriously. All your data is encrypted using bank-level AES-256 encryption both in transit and at rest. We never share your personal information or financial data with third parties. Your data is stored on secure servers with multiple layers of protection including firewalls, intrusion detection, and regular security audits.',
          ),
          HelpFAQ(
            question: 'How do I change my password?',
            answer:
                'To change your password, go to Profile → Security → Change Password. You\'ll need to enter your current password first, then create a new strong password. We recommend using a password that\'s at least 8 characters long with a mix of uppercase, lowercase, numbers, and special characters.',
          ),
          HelpFAQ(
            question: 'Can I enable two-factor authentication?',
            answer:
                'Yes! Two-factor authentication (2FA) adds an extra layer of security. Go to Profile → Security → Two-Factor Authentication. You can choose to receive verification codes via SMS or use an authenticator app like Google Authenticator. We highly recommend enabling 2FA for maximum account security.',
          ),
          HelpFAQ(
            question: 'What should I do if I forget my password?',
            answer:
                'On the login screen, tap "Forgot Password". Enter your registered email address, and we\'ll send you a password reset link. Click the link in the email and follow the instructions to create a new password. The reset link is valid for 24 hours for security reasons.',
          ),
          HelpFAQ(
            question: 'How do I delete my account?',
            answer:
                'If you wish to delete your account, go to Profile → Settings → Account Management → Delete Account. Please note that this action is permanent and irreversible. All your data, including transactions, budgets, and insights will be permanently deleted. You\'ll receive a confirmation email before final deletion.',
          ),
        ],
      ),

      // Features & Usage Category
      HelpCategory(
        title: 'Features & Usage',
        icon: Icons.star_outline,
        color: const Color(0xFFFF9800),
        faqs: [
          HelpFAQ(
            question: 'How does the AI prediction work?',
            answer:
                'Our AI analyzes your spending patterns over time using machine learning algorithms. It looks at factors like spending frequency, amounts, categories, and time periods. After collecting 2-3 months of data, the AI can predict your future expenses with 85-90% accuracy, helping you plan better. The more you use the app, the smarter the predictions become.',
          ),
          HelpFAQ(
            question: 'How do I view my spending analysis?',
            answer:
                'Tap the Analysis tab at the bottom of the screen. Here you\'ll see detailed charts showing your income vs expenses, category breakdowns, spending trends, and AI-generated insights. You can switch between Daily, Weekly, Monthly, and Yearly views to see different time periods.',
          ),
          HelpFAQ(
            question: 'Can I export my transaction data?',
            answer:
                'Yes! Go to Settings → Data Management → Export Data. You can export your data in multiple formats: CSV (for Excel), PDF (for printing or sharing), or Excel format. Choose your desired date range and categories, then tap Export. The file will be saved to your device and you can share it via email or cloud storage.',
          ),
          HelpFAQ(
            question: 'How do I categorize my expenses?',
            answer:
                'The app comes with pre-defined categories like Food, Transport, Rent, Entertainment, etc. When adding a transaction, simply select the appropriate category. You can also create custom categories by going to Categories → More → Add Custom Category. Proper categorization helps the AI provide better insights.',
          ),
          HelpFAQ(
            question: 'Can I edit or delete past transactions?',
            answer:
                'Yes! Go to the Transaction tab and find the transaction you want to modify. Tap on it to open the details, then you can either Edit to change the amount, category, or date, or Delete to remove it completely. All changes are reflected immediately in your analysis and budget tracking.',
          ),
        ],
      ),

      // AI Features Category
      HelpCategory(
        title: 'AI-Based Features',
        icon: Icons.psychology_outlined,
        color: const Color(0xFF9C27B0),
        faqs: [
          HelpFAQ(
            question: 'What AI insights can I expect?',
            answer:
                'The AI provides several types of insights: spending pattern analysis, budget optimization suggestions, expense predictions, anomaly detection (unusual charges), savings recommendations, and personalized financial tips. These insights are updated weekly and become more accurate as you use the app.',
          ),
          HelpFAQ(
            question: 'How accurate are the spending predictions?',
            answer:
                'Prediction accuracy depends on the amount of data available. In the first month, accuracy is around 60-70%. After 2-3 months of consistent data entry, accuracy typically reaches 85-90%. The AI continuously learns from your spending patterns and adapts to changes in your financial behavior.',
          ),
          HelpFAQ(
            question: 'What is anomaly detection?',
            answer:
                'Anomaly detection is an AI feature that identifies unusual spending patterns. If you suddenly spend much more than normal in a category, or if there\'s a suspicious transaction that doesn\'t match your habits, the app will alert you. This helps catch fraudulent charges or identify areas where you\'re overspending.',
          ),
          HelpFAQ(
            question: 'How does the app suggest savings?',
            answer:
                'The AI analyzes your income, expenses, and spending patterns to identify opportunities to save. It compares your spending to similar users (anonymously) and suggests areas where you might be overspending. It also recommends optimal savings amounts based on your financial goals and available income.',
          ),
        ],
      ),

      // Offline & Sync Category
      HelpCategory(
        title: 'Offline & Synchronization',
        icon: Icons.sync_outlined,
        color: const Color(0xFF2196F3),
        faqs: [
          HelpFAQ(
            question: 'Can I use the app without internet?',
            answer:
                'Yes! The app works fully offline. You can add, edit, and delete transactions without an internet connection. All your changes are stored locally on your device. When you reconnect to the internet, the app will automatically sync all your offline changes to the cloud.',
          ),
          HelpFAQ(
            question: 'How does data synchronization work?',
            answer:
                'The app automatically syncs your data with the cloud whenever you have an internet connection. This ensures your data is backed up and accessible from multiple devices. If you use the app on multiple devices, changes made on one device will appear on others within a few seconds of syncing.',
          ),
          HelpFAQ(
            question: 'What happens if sync fails?',
            answer:
                'If sync fails due to poor internet connection, the app will retry automatically. Your data remains safe on your device. You\'ll see a sync icon indicating pending changes. Once connection is restored, sync will complete automatically. You can also manually trigger sync by pulling down on the home screen.',
          ),
        ],
      ),

      // Troubleshooting Category
      HelpCategory(
        title: 'Troubleshooting',
        icon: Icons.build_outlined,
        color: const Color(0xFFF44336),
        faqs: [
          HelpFAQ(
            question: 'The app is not syncing, what should I do?',
            answer:
                'First, check your internet connection. If connected, try these steps: 1) Pull down on the home screen to manually refresh, 2) Force close the app and reopen it, 3) Log out and log back in, 4) Clear app cache in Settings → Storage. If the problem persists, contact our support team.',
            steps: [
              'Check your internet connection',
              'Pull down to refresh manually',
              'Force close and reopen the app',
              'Log out and log back in',
              'Clear app cache in Settings',
              'Contact support if issue persists',
            ],
          ),
          HelpFAQ(
            question: 'My transactions are not showing up, why?',
            answer:
                'Check these common causes: 1) Date filter - you might be viewing a different time period, 2) Category filter - ensure "All Categories" is selected, 3) Sync issue - pull down to refresh, 4) Transaction not saved - verify by checking Recently Deleted in Settings. If none of these help, contact support.',
            steps: [
              'Check date filter settings',
              'Verify category filter is set to "All"',
              'Pull down to refresh and sync',
              'Check Recently Deleted section',
              'Restart the app',
            ],
          ),
          HelpFAQ(
            question: 'Why are AI insights not appearing?',
            answer:
                'AI insights require sufficient data to generate meaningful predictions. Ensure you have: 1) At least 10 transactions entered, 2) Data spanning at least 2 weeks, 3) Data sync enabled, 4) Latest app version installed. Wait 24-48 hours after reaching these minimums for AI to process your data.',
            steps: [
              'Add at least 10 transactions',
              'Use the app for 2+ weeks',
              'Enable data synchronization',
              'Update to latest app version',
              'Wait 24-48 hours for processing',
            ],
          ),
          HelpFAQ(
            question: 'The app crashes or freezes, how do I fix it?',
            answer:
                'Try these solutions in order: 1) Force close the app completely, 2) Clear app cache in device settings, 3) Ensure you have the latest app version from the store, 4) Restart your device, 5) If on Android, clear app data (note: this will require re-login), 6) Uninstall and reinstall the app. Your data is safe in the cloud.',
            steps: [
              'Force close the app',
              'Clear app cache',
              'Update to latest version',
              'Restart your device',
              'Clear app data (if needed)',
              'Reinstall the app as last resort',
            ],
          ),
          HelpFAQ(
            question: 'I can\'t log in, what should I do?',
            answer:
                'First, verify your email and password are correct. If you\'ve forgotten your password, use "Forgot Password" on the login screen. Check your email spam folder for the reset link. If you\'re sure your credentials are correct but still can\'t log in, there might be a temporary server issue - wait a few minutes and try again, or contact support.',
          ),
        ],
      ),

      // Settings & Customization Category
      HelpCategory(
        title: 'Settings & Customization',
        icon: Icons.settings_outlined,
        color: const Color(0xFF607D8B),
        faqs: [
          HelpFAQ(
            question: 'How do I change the app currency?',
            answer:
                'Go to Profile → Converting Currency → Select Currency. Choose your preferred currency from the list. If you need to convert existing transactions, the app will ask if you want to apply the new currency to all past transactions or only new ones. Exchange rates are updated daily.',
          ),
          HelpFAQ(
            question: 'Can I customize expense categories?',
            answer:
                'Yes! Go to Categories tab, tap "More" → "Manage Categories". Here you can add custom categories, edit existing ones, change category icons and colors, or delete categories you don\'t use. Custom categories work exactly like default ones and are included in all analysis and predictions.',
          ),
          HelpFAQ(
            question: 'How do I manage notifications?',
            answer:
                'Go to Settings → Notifications. You can customize alerts for: budget warnings, bill reminders, weekly summaries, AI insights, low balance alerts, and unusual activity. Turn notifications on/off individually and set quiet hours for when you don\'t want to be disturbed.',
          ),
        ],
      ),
    ];
  }

  static List<HelpFAQ> getAllFAQs() {
    List<HelpFAQ> allFaqs = [];
    for (var category in getAllCategories()) {
      allFaqs.addAll(category.faqs);
    }
    return allFaqs;
  }

  static List<HelpFAQ> searchFAQs(String query) {
    if (query.isEmpty) return [];
    
    final lowercaseQuery = query.toLowerCase();
    return getAllFAQs().where((faq) {
      return faq.question.toLowerCase().contains(lowercaseQuery) ||
          faq.answer.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }
}