import 'package:flutter/material.dart';

class PrivacyPolicyView extends StatelessWidget {
  const PrivacyPolicyView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    size: 60,
                    color: Color(0xFF00CED1),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Privacy Policy',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Last Updated: January 2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Introduction
              _buildContentCard(
                isDark,
                'At Smart Personal Expense Tracker, we take your privacy seriously. This Privacy Policy explains how we collect, use, store, '
                'and protect your personal information when you use our application. By using our app, you agree to the collection and use of '
                'information in accordance with this policy.',
              ),
              const SizedBox(height: 24),

              // 1. Data Collection and Usage
              _buildSectionTitle('1. Data Collection and Usage', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'Information We Collect:\n\n'
                'Personal Information:\n'
                '• Name and email address (if provided)\n'
                '• Device information (model, operating system, unique identifiers)\n'
                '• App usage data and preferences\n\n'
                'Financial Information:\n'
                '• Transaction details (amount, date, category, description)\n'
                '• Budget settings and spending limits\n'
                '• Income and expense records\n'
                '• Account balance information\n\n'
                'Automatically Collected Information:\n'
                '• Log data and device information\n'
                '• App performance and crash data\n'
                '• Location data (only if you grant permission)\n\n'
                'How We Use Your Information:\n\n'
                '• To provide and maintain our expense tracking services\n'
                '• To generate AI-powered financial insights and recommendations\n'
                '• To categorize and analyze your spending patterns\n'
                '• To send you notifications about budget alerts and reminders\n'
                '• To improve and optimize app performance\n'
                '• To detect, prevent, and address technical issues\n'
                '• To provide customer support and respond to inquiries\n'
                '• To ensure the security and integrity of our services\n\n'
                'All financial data is stored locally on your device by default. We process your data locally whenever possible to minimize data transmission and enhance privacy.',
              ),
              const SizedBox(height: 20),

              // 2. Data Security and Privacy Rights
              _buildSectionTitle('2. Data Security and Privacy Rights', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'Security Measures:\n\n'
                '• End-to-end encryption for all data transmission\n'
                '• AES-256 encryption for local data storage\n'
                '• Secure servers with regular security audits\n'
                '• Multi-factor authentication options\n'
                '• Biometric authentication (fingerprint/face ID) support\n'
                '• Regular security updates and patches\n'
                '• Secure backup and recovery procedures\n\n'
                'Data Storage:\n\n'
                '• Primary data storage is local on your device\n'
                '• Optional cloud storage on secure, encrypted servers\n'
                '• Data redundancy and backup systems\n'
                '• We do not sell your personal information to third parties\n'
                '• We never share your financial data for advertising or marketing purposes\n\n'
                'Your Privacy Rights:\n\n'
                '• Access and export your personal data at any time\n'
                '• Correct inaccurate or incomplete information\n'
                '• Request deletion of your account and all associated data\n'
                '• Delete specific transactions or data records\n'
                '• Opt-out of data collection for certain features\n'
                '• Disable cloud synchronization\n'
                '• Control notification preferences\n'
                '• Restrict data processing for specific purposes\n\n'
                'Despite our security measures, no method of transmission over the internet is 100% secure. While we strive to protect your data, we cannot guarantee absolute security.',
              ),
              const SizedBox(height: 20),

              // 3. Legal Compliance and Policy Updates
              _buildSectionTitle('3. Legal Compliance and Policy Updates', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'Data Sharing and Legal Requirements:\n\n'
                'We may share your information only in the following circumstances:\n\n'
                '• When required by law, court order, or legal process\n'
                '• To protect our rights, property, or safety\n'
                '• To prevent fraud or illegal activities\n'
                '• With trusted service providers who assist in operating our app (bound by confidentiality agreements)\n'
                '• In the event of a merger, acquisition, or sale of assets (users will be notified)\n'
                '• When you explicitly authorize us to share your information\n\n'
                'Third-Party Services:\n\n'
                'Our app may contain links to third-party websites or services. We are not responsible for their privacy practices. '
                'We encourage you to review the privacy policies of any third-party services you access through our app.\n\n'
                'Children\'s Privacy:\n\n'
                'Our app is not intended for children under 18. We do not knowingly collect personal information from children. '
                'Minors between 13-17 may use the app only with parental consent and supervision.\n\n'
                'Policy Updates:\n\n'
                'We may update this Privacy Policy from time to time. When we make changes:\n\n'
                '• We will update the "Last Updated" date at the top\n'
                '• We will notify you through the app or via email\n'
                '• Your continued use constitutes acceptance of the updated policy\n\n'
                'We encourage you to review this Privacy Policy periodically to stay informed about how we protect your information.',
              ),
              const SizedBox(height: 24),

              // Contact Section
              _buildSectionTitle('Contact Us', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'If you have any questions, concerns, or requests regarding this Privacy Policy or our data practices, please contact us:\n\n'
                'Email: lehoangvi.work@gmail.com\n\n'
                'We are committed to resolving any privacy concerns you may have and will respond to all inquiries within 48 hours during business days.\n\n'
                'To exercise your privacy rights, please contact us at the email above. We will respond to your request within 30 days.',
              ),
              const SizedBox(height: 24),

              // Commitment Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00CED1).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00CED1).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 48,
                      color: Color(0xFF00CED1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Our Commitment to Your Privacy',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We are committed to protecting your privacy and handling your financial data with the utmost care and security. Your trust is our most valuable asset.',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Footer
              Center(
                child: Column(
                  children: [
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      '© 2025 Smart Personal Expense Tracker',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your privacy, our priority',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildContentCard(bool isDark, String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        content,
        style: TextStyle(
          fontSize: 14,
          height: 1.6,
          color: isDark ? Colors.grey[300] : Colors.grey[800],
        ),
        textAlign: TextAlign.justify,
      ),
    );
  }
} 