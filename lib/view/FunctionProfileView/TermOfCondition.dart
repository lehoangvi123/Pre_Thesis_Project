import 'package:flutter/material.dart';

class TermsConditionsView extends StatelessWidget {
  const TermsConditionsView({Key? key}) : super(key: key);

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
          'Terms & Conditions',
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
                    Icons.description_outlined,
                    size: 60,
                    color: Color(0xFF00CED1),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Terms & Conditions',
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
                'Welcome to Smart Personal Expense Tracker. These Terms and Conditions govern your use of our application '
                'and services. By downloading, installing, or using this app, you agree to be bound by these terms. '
                'Please read them carefully before using our services.',
              ),
              const SizedBox(height: 24),

              // 1. Acceptance of Terms
              _buildSectionTitle('1. Acceptance of Terms', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'By accessing and using the Smart Personal Expense Tracker application ("the App"), you accept and agree to be bound by the terms and provisions of this agreement. '
                'If you do not agree to these Terms and Conditions, please do not use the App.\n\n'
                'We reserve the right to modify these terms at any time. Your continued use of the App following the posting of changes constitutes your acceptance of such changes. '
                'We recommend checking this page periodically for any updates.',
              ),
              const SizedBox(height: 20),

              // 2. User Eligibility and Responsibilities
              _buildSectionTitle('2. User Eligibility and Responsibilities', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'You must be at least 18 years old or have parental/guardian consent to use this App. By using the App, you agree to:\n\n'
                '• Provide accurate and truthful financial information\n'
                '• Maintain the security and confidentiality of your account\n'
                '• Use the App only for lawful purposes\n'
                '• Not attempt to gain unauthorized access to the App or its systems\n'
                '• Not reverse engineer, decompile, or disassemble the App\n'
                '• Not interfere with other users\' use and enjoyment of the App\n'
                '• Comply with all applicable local, state, national, and international laws\n\n'
                'You are responsible for maintaining the confidentiality of your account information and for all activities that occur under your account.',
              ),
              const SizedBox(height: 20),

              // 3. Service Description
              _buildSectionTitle('3. Service Description', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'The Smart Personal Expense Tracker provides:\n\n'
                '• Personal finance tracking and management tools\n'
                '• AI-powered financial insights and recommendations\n'
                '• Expense categorization and analysis\n'
                '• Budget planning and monitoring features\n'
                '• Data visualization and reporting capabilities\n'
                '• Secure data storage and synchronization\n\n'
                'We strive to maintain the App\'s availability and accuracy but do not guarantee uninterrupted or error-free service. '
                'Features and functionality may be modified, suspended, or discontinued at any time without prior notice.',
              ),
              const SizedBox(height: 20),

              // 4. Privacy and Data Protection
              _buildSectionTitle('4. Privacy and Data Protection', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'Your privacy is important to us. Our data protection practices include:\n\n'
                '• Collection of only necessary data for app functionality\n'
                '• Encryption of sensitive financial information using industry-standard protocols\n'
                '• Secure storage with AES-256 encryption\n'
                '• No selling or sharing of personal data with third parties for marketing purposes\n'
                '• Transparent data usage policies\n'
                '• User control over data export and deletion\n\n'
                'For detailed information about how we collect, use, and protect your data, please refer to our Privacy Policy. '
                'By using the App, you consent to the collection and use of information in accordance with our Privacy Policy.',
              ),
              const SizedBox(height: 20),

              // 5. Intellectual Property Rights
              _buildSectionTitle('5. Intellectual Property Rights', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'All intellectual property rights in the App, including software code, algorithms, design, user interface, graphics, logos, AI models, and trademarks, '
                'are owned by or licensed to Smart Personal Expense Tracker.\n\n'
                'You are granted a limited, non-exclusive, non-transferable license to use the App for personal, non-commercial purposes only. You may not:\n\n'
                '• Copy, modify, or create derivative works of the App\n'
                '• Distribute, sell, lease, or sublicense the App\n'
                '• Remove or alter any proprietary notices\n'
                '• Use the App\'s intellectual property for commercial purposes without written permission',
              ),
              const SizedBox(height: 20),

              // 6. Financial Advice Disclaimer
              _buildSectionTitle('6. Financial Advice Disclaimer', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'IMPORTANT: The Smart Personal Expense Tracker and its AI-powered insights are tools for personal financial management only. '
                'They do NOT constitute professional financial advice, investment recommendations, or tax guidance.\n\n'
                'You acknowledge that:\n\n'
                '• The App provides general information and suggestions based on your input data\n'
                '• AI-generated insights are not guaranteed to be accurate or suitable for your specific situation\n'
                '• You should consult qualified financial advisors, accountants, or tax professionals for personalized advice\n'
                '• You are solely responsible for all financial decisions made using the App\n'
                '• Past performance and predictions do not guarantee future results\n'
                '• We are not liable for any financial losses resulting from your use of the App\n\n'
                'Always verify important financial information with professional advisors before making significant financial decisions.',
              ),
              const SizedBox(height: 20),

              // 7. Limitation of Liability
              _buildSectionTitle('7. Limitation of Liability', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'To the maximum extent permitted by law, Smart Personal Expense Tracker and its developers, employees, and affiliates shall not be liable for:\n\n'
                '• Any indirect, incidental, special, consequential, or punitive damages\n'
                '• Loss of profits, revenue, data, or business opportunities\n'
                '• Financial losses resulting from investment or spending decisions\n'
                '• Damages resulting from unauthorized access to your account\n'
                '• Errors, bugs, or inaccuracies in the App\n'
                '• Service interruptions or data loss\n'
                '• Third-party actions or content\n\n'
                'THE APP IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND. '
                'Our total liability to you for all claims arising from your use of the App shall not exceed the amount you paid for the App (if any) '
                'in the twelve months preceding the claim.',
              ),
              const SizedBox(height: 20),

              // 8. Account Termination
              _buildSectionTitle('8. Account Termination', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'We reserve the right to suspend or terminate your account at any time for any reason, including:\n\n'
                '• Violation of these Terms and Conditions\n'
                '• Fraudulent, abusive, or illegal activity\n'
                '• Extended periods of inactivity\n'
                '• Requests from law enforcement or government agencies\n'
                '• Technical or security reasons\n\n'
                'You may also terminate your account at any time by deleting the App from your device or requesting account deletion through the settings. '
                'Upon termination, your right to use the App will immediately cease. We may retain certain data as required by law or for legitimate business purposes.',
              ),
              const SizedBox(height: 20),

              // 9. Governing Law and Dispute Resolution
              _buildSectionTitle('9. Governing Law and Dispute Resolution', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'These Terms and Conditions shall be governed by and construed in accordance with applicable laws. '
                'Any disputes arising from these terms or your use of the App shall be subject to the jurisdiction of competent courts.\n\n'
                'In the event of any dispute, we encourage you to:\n\n'
                '• Contact us first to seek an informal resolution\n'
                '• Attempt good faith negotiation before pursuing formal legal action\n'
                '• Consider mediation or arbitration as alternatives to litigation\n\n'
                'Many disputes can be resolved quickly through direct communication.',
              ),
              const SizedBox(height: 20),

              // 10. Changes to Terms and Contact Information
              _buildSectionTitle('10. Changes to Terms and Contact Information', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'We reserve the right to modify these Terms and Conditions at any time. When we make changes:\n\n'
                '• We will update the "Last Updated" date at the top of this document\n'
                '• We may notify you through the App or via email\n'
                '• Your continued use after changes constitutes acceptance of the revised terms\n\n'
                'We recommend reviewing these Terms and Conditions periodically to stay informed of any updates.\n\n'
                'Contact Information:\n'
                'If you have any questions or concerns regarding these Terms and Conditions, please contact us at:\n\n'
                'Email: lehoangvi.work@gmail.com\n'
                'Website: www.smartexpensetracker.com\n\n'
                'We aim to respond to all inquiries within 48 hours during business days.',
              ),
              const SizedBox(height: 24),

              // Acceptance Section
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
                      Icons.check_circle_outline,
                      size: 48,
                      color: Color(0xFF00CED1),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Agreement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'By using the Smart Personal Expense Tracker, you acknowledge that you have read, understood, and agree to be bound by these Terms and Conditions.',
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
                      'All rights reserved',
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