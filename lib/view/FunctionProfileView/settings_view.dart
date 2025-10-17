import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({Key? key}) : super(key: key);

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool pushNotifications = true;
  bool emailNotifications = false;
  bool budgetAlerts = true;
  bool expenseReminders = true;
  bool darkMode = false;
  String selectedCurrency = 'VND';
  String selectedLanguage = 'English';
  bool biometricLogin = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      pushNotifications = prefs.getBool('push_notifications') ?? true;
      emailNotifications = prefs.getBool('email_notifications') ?? false;
      budgetAlerts = prefs.getBool('budget_alerts') ?? true;
      expenseReminders = prefs.getBool('expense_reminders') ?? true;
      darkMode = prefs.getBool('dark_mode') ?? false;
      selectedCurrency = prefs.getString('selected_currency') ?? 'VND';
      selectedLanguage = prefs.getString('selected_language') ?? 'English';
      biometricLogin = prefs.getBool('biometric_login') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 16),

              // Notifications Section
              _buildSectionTitle('Notifications'),
              const SizedBox(height: 12),
              _buildToggleItem(
                title: 'Push Notifications',
                subtitle: 'Receive app notifications',
                value: pushNotifications,
                onChanged: (value) {
                  setState(() => pushNotifications = value);
                  _saveSetting('push_notifications', value);
                },
              ),
              const SizedBox(height: 12),
              _buildToggleItem(
                title: 'Email Notifications',
                subtitle: 'Receive email updates',
                value: emailNotifications,
                onChanged: (value) {
                  setState(() => emailNotifications = value);
                  _saveSetting('email_notifications', value);
                },
              ),
              const SizedBox(height: 12),
              _buildToggleItem(
                title: 'Budget Alerts',
                subtitle: 'Get notified when budget limit is reached',
                value: budgetAlerts,
                onChanged: (value) {
                  setState(() => budgetAlerts = value);
                  _saveSetting('budget_alerts', value);
                },
              ),
              const SizedBox(height: 12),
              _buildToggleItem(
                title: 'Expense Reminders',
                subtitle: 'Daily reminders to log expenses',
                value: expenseReminders,
                onChanged: (value) {
                  setState(() => expenseReminders = value);
                  _saveSetting('expense_reminders', value);
                },
              ),
              const SizedBox(height: 24),

              // Display Section
              _buildSectionTitle('Display'),
              const SizedBox(height: 12),
              _buildToggleItem(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: darkMode,
                onChanged: (value) {
                  setState(() => darkMode = value);
                  _saveSetting('dark_mode', value);
                },
              ),
              const SizedBox(height: 12),
              _buildSelectItem(
                title: 'Currency',
                subtitle: 'Default currency for display',
                value: selectedCurrency,
                options: ['VND', 'USD', 'EUR', 'GBP', 'JPY', 'CNY'],
                onChanged: (value) {
                  setState(() => selectedCurrency = value);
                  _saveSetting('selected_currency', value);
                },
              ),
              const SizedBox(height: 12),
              _buildSelectItem(
                title: 'Language',
                subtitle: 'Choose your preferred language',
                value: selectedLanguage,
                options: ['English', 'Vietnamese', 'Spanish', 'French', 'Chinese'],
                onChanged: (value) {
                  setState(() => selectedLanguage = value);
                  _saveSetting('selected_language', value);
                },
              ),
              const SizedBox(height: 24),

              // Security Section
              _buildSectionTitle('Security'),
              const SizedBox(height: 12),
              _buildToggleItem(
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or face recognition',
                value: biometricLogin,
                onChanged: (value) {
                  setState(() => biometricLogin = value);
                  _saveSetting('biometric_login', value);
                },
              ),
              const SizedBox(height: 24),

              // Data Section
              _buildSectionTitle('Data'),
              const SizedBox(height: 12),
              _buildActionItem(
                icon: Icons.download,
                title: 'Export Data',
                subtitle: 'Download your data as CSV',
                onTap: () => _showExportDialog(),
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                icon: Icons.delete_outline,
                title: 'Clear Cache',
                subtitle: 'Remove temporary files',
                onTap: () => _showClearCacheDialog(),
              ),
              const SizedBox(height: 24),

              // About Section
              _buildSectionTitle('About'),
              const SizedBox(height: 12),
              _buildInfoItem(
                title: 'App Version',
                subtitle: '1.0.0',
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                icon: Icons.info_outline,
                title: 'About Us',
                subtitle: 'Learn more about the app',
                onTap: () => _showAboutDialog(),
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                icon: Icons.description_outlined,
                title: 'Terms & Conditions',
                subtitle: 'Read our terms of service',
                onTap: () => _showTermsDialog(),
              ),
              const SizedBox(height: 12),
              _buildActionItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'View privacy policy',
                onTap: () => _showPrivacyDialog(),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildToggleItem({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.teal.shade500,
           
          ),
        ],
      ),
    );
  }

  Widget _buildSelectItem({
    required String title,
    required String subtitle,
    required String value,
    required List<String> options,
    required Function(String) onChanged,
  }) {
    return GestureDetector(
      onTap: () => _showSelectDialog(title, options, value, onChanged),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.teal.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.blue.shade400, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSelectDialog(String title, List<String> options, String currentValue,
      Function(String) onChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options
                  .map(
                    (option) => RadioListTile(
                      title: Text(option),
                      value: option,
                      groupValue: currentValue,
                      onChanged: (value) {
                        onChanged(value as String);
                        Navigator.pop(context);
                      },
                      activeColor: Colors.teal,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Export Data'),
          content: const Text(
            'Your expense data will be exported as CSV file. This includes all transactions and categories.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data exported successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
              ),
              child: const Text(
                'Export',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Clear Cache'),
          content: const Text(
            'This will remove temporary files and may improve app performance. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cache cleared successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('About Us'),
          content: const Text(
            'Smart Personal Expense Tracker with AI-Based Financial Insights\n\n'
            'Version 1.0.0\n\n'
            'This app helps you track expenses, analyze spending patterns, and get AI-powered financial recommendations.\n\n'
            'Contact: support@expensetracker.com',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
              ),
              child: const Text(
                'Close',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Terms & Conditions'),
          content: SingleChildScrollView(
            child: Text(
              'Terms and Conditions\n\n'
              '1. User Agreement\n'
              'By using this app, you agree to these terms.\n\n'
              '2. Data Protection\n'
              'Your data is protected and encrypted.\n\n'
              '3. User Responsibilities\n'
              'You are responsible for maintaining account security.\n\n'
              '4. Limitation of Liability\n'
              'We are not liable for any indirect damages.\n\n'
              '5. Changes to Terms\n'
              'We may update these terms at any time.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Privacy Policy'),
          content: SingleChildScrollView(
            child: Text(
              'Privacy Policy\n\n'
              '1. Data Collection\n'
              'We collect only necessary data for app functionality.\n\n'
              '2. Data Usage\n'
              'Your data is used only for improving your experience.\n\n'
              '3. Third-Party Services\n'
              'We do not share your data with third parties.\n\n'
              '4. Data Security\n'
              'We use industry-standard encryption.\n\n'
              '5. Your Rights\n'
              'You can request data deletion at any time.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00CED1),
              ),
              child: const Text(
                'Accept',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}