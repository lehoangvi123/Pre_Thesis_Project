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

              // 2. User Agreement
              _buildSectionTitle('2. User Agreement and Eligibility', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'You must be at least 18 years old or have parental/guardian consent to use this App. By using the App, you represent and warrant that:\n\n'
                '• You have the legal capacity to enter into a binding agreement\n'
                '• You will use the App in compliance with all applicable laws and regulations\n'
                '• All information you provide is accurate, current, and complete\n'
                '• You will maintain the security of your account credentials\n'
                '• You will not use the App for any illegal or unauthorized purpose\n\n'
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

              // 4. User Responsibilities
              _buildSectionTitle('4. User Responsibilities', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'As a user of the App, you agree to:\n\n'
                '• Provide accurate and truthful financial information\n'
                '• Maintain the security and confidentiality of your account\n'
                '• Use the App only for lawful purposes\n'
                '• Not attempt to gain unauthorized access to the App or its systems\n'
                '• Not reverse engineer, decompile, or disassemble the App\n'
                '• Not use the App to transmit harmful code, viruses, or malware\n'
                '• Not interfere with other users\' use and enjoyment of the App\n'
                '• Report any security vulnerabilities or bugs you discover\n'
                '• Comply with all applicable local, state, national, and international laws\n\n'
                'Failure to comply with these responsibilities may result in termination of your access to the App.',
              ),
              const SizedBox(height: 20),

              // 5. Data Protection and Privacy
              _buildSectionTitle('5. Data Protection and Privacy', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'Your privacy is important to us. Our data protection practices include:\n\n'
                '• Collection of only necessary data for app functionality\n'
                '• Encryption of sensitive financial information\n'
                '• Secure storage using industry-standard protocols\n'
                '• No selling or sharing of personal data with third parties for marketing\n'
                '• Transparent data usage policies\n'
                '• User control over data export and deletion\n\n'
                'For detailed information about how we collect, use, and protect your data, please refer to our Privacy Policy. '
                'By using the App, you consent to the collection and use of information in accordance with our Privacy Policy.',
              ),
              const SizedBox(height: 20),

              // 6. Intellectual Property Rights
              _buildSectionTitle('6. Intellectual Property Rights', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'All intellectual property rights in the App, including but not limited to:\n\n'
                '• Software code and algorithms\n'
                '• Design, layout, and user interface\n'
                '• Text, graphics, logos, and images\n'
                '• AI models and machine learning technologies\n'
                '• Trademarks and brand elements\n\n'
                'are owned by or licensed to Smart Personal Expense Tracker. You are granted a limited, non-exclusive, '
                'non-transferable license to use the App for personal, non-commercial purposes only.\n\n'
                'You may not:\n'
                '• Copy, modify, or create derivative works of the App\n'
                '• Distribute, sell, lease, or sublicense the App\n'
                '• Remove or alter any proprietary notices\n'
                '• Use the App\'s intellectual property for commercial purposes without written permission',
              ),
              const SizedBox(height: 20),

              // 7. Financial Advice Disclaimer
              _buildSectionTitle('7. Financial Advice Disclaimer', isDark),
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

              // 8. Limitation of Liability
              _buildSectionTitle('8. Limitation of Liability', isDark),
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
                'Our total liability to you for all claims arising from your use of the App shall not exceed the amount you paid for the App (if any) '
                'in the twelve months preceding the claim.\n\n'
                'Some jurisdictions do not allow the exclusion or limitation of certain warranties or liabilities. In such jurisdictions, '
                'our liability will be limited to the maximum extent permitted by law.',
              ),
              const SizedBox(height: 20),

              // 9. Warranty Disclaimer
              _buildSectionTitle('9. Warranty Disclaimer', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'THE APP IS PROVIDED ON AN "AS IS" AND "AS AVAILABLE" BASIS WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED.\n\n'
                'We disclaim all warranties, including but not limited to:\n\n'
                '• Merchantability and fitness for a particular purpose\n'
                '• Non-infringement of third-party rights\n'
                '• Accuracy, completeness, or reliability of content\n'
                '• Uninterrupted, secure, or error-free operation\n'
                '• Correction of defects or bugs\n'
                '• Freedom from viruses or harmful components\n\n'
                'You acknowledge that your use of the App is at your sole risk. We do not warrant that the App will meet your requirements '
                'or that it will be compatible with all devices or operating systems.',
              ),
              const SizedBox(height: 20),

              // 10. Indemnification
              _buildSectionTitle('10. Indemnification', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'You agree to indemnify, defend, and hold harmless Smart Personal Expense Tracker, its developers, officers, employees, and affiliates from any claims, damages, losses, liabilities, and expenses (including legal fees) arising from:\n\n'
                '• Your use or misuse of the App\n'
                '• Your violation of these Terms and Conditions\n'
                '• Your violation of any rights of another party\n'
                '• Your violation of any applicable laws or regulations\n'
                '• Any content you submit through the App\n'
                '• Any financial decisions or actions you take based on App insights\n\n'
                'This indemnification obligation will survive the termination of your use of the App.',
              ),
              const SizedBox(height: 20),

              // 11. Third-Party Services
              _buildSectionTitle('11. Third-Party Services and Links', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'The App may contain links to third-party websites, services, or resources that are not owned or controlled by us. '
                'We do not endorse or assume responsibility for:\n\n'
                '• The content, accuracy, or opinions expressed on third-party sites\n'
                '• Privacy practices of external services\n'
                '• Any damages or losses caused by third-party services\n\n'
                'Your interactions with third-party services are solely between you and the third party. We encourage you to review '
                'the terms and privacy policies of any third-party services you access through the App.',
              ),
              const SizedBox(height: 20),

              // 12. Account Termination
              _buildSectionTitle('12. Account Termination', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'We reserve the right to:\n\n'
                '• Suspend or terminate your account at any time for any reason\n'
                '• Remove or refuse to post any content\n'
                '• Limit or disable your access to certain features\n\n'
                'Grounds for termination include, but are not limited to:\n\n'
                '• Violation of these Terms and Conditions\n'
                '• Fraudulent, abusive, or illegal activity\n'
                '• Extended periods of inactivity\n'
                '• Requests from law enforcement or government agencies\n'
                '• Technical or security reasons\n\n'
                'You may also terminate your account at any time by:\n'
                '• Deleting the App from your device\n'
                '• Requesting account deletion through the settings\n'
                '• Contacting our support team\n\n'
                'Upon termination, your right to use the App will immediately cease. We may retain certain data as required by law or for legitimate business purposes.',
              ),
              const SizedBox(height: 20),

              // 13. Updates and Modifications
              _buildSectionTitle('13. App Updates and Modifications', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'We continually work to improve the App and may:\n\n'
                '• Release updates, patches, and new versions\n'
                '• Modify, suspend, or discontinue features\n'
                '• Change the App\'s functionality or appearance\n\n'
                'Updates may be automatic or require manual installation. Some updates may be necessary for security or legal compliance. '
                'Failure to install required updates may limit your access to certain features or the entire App.\n\n'
                'We are not obligated to provide any specific updates or maintain backward compatibility with older versions.',
              ),
              const SizedBox(height: 20),

              // 14. Data Backup
              _buildSectionTitle('14. Data Backup and Recovery', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'While we implement measures to protect your data, you acknowledge that:\n\n'
                '• You are responsible for maintaining your own backup copies of important data\n'
                '• We cannot guarantee the recovery of lost or corrupted data\n'
                '• Data loss may occur due to technical failures, device issues, or other circumstances\n'
                '• We are not liable for any data loss regardless of the cause\n\n'
                'We recommend regularly exporting and backing up your financial data to prevent loss.',
              ),
              const SizedBox(height: 20),

              // 15. Governing Law
              _buildSectionTitle('15. Governing Law and Jurisdiction', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'These Terms and Conditions shall be governed by and construed in accordance with the laws of [Your Jurisdiction], '
                'without regard to its conflict of law provisions.\n\n'
                'Any disputes arising from these terms or your use of the App shall be subject to the exclusive jurisdiction of the courts located in [Your Jurisdiction]. '
                'However, we retain the right to seek injunctive relief in any jurisdiction.',
              ),
              const SizedBox(height: 20),

              // 16. Dispute Resolution
              _buildSectionTitle('16. Dispute Resolution', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'In the event of any dispute, controversy, or claim arising from these Terms and Conditions:\n\n'
                '• We encourage you to contact us first to seek an informal resolution\n'
                '• Many disputes can be resolved quickly through direct communication\n'
                '• Formal legal proceedings should be a last resort\n\n'
                'If informal resolution is unsuccessful, disputes may be resolved through:\n\n'
                '• Mediation by a mutually agreed-upon mediator\n'
                '• Arbitration in accordance with applicable arbitration rules\n'
                '• Court proceedings as specified in the Governing Law section\n\n'
                'You agree to attempt good faith negotiation before pursuing formal legal action.',
              ),
              const SizedBox(height: 20),

              // 17. Severability
              _buildSectionTitle('17. Severability', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'If any provision of these Terms and Conditions is found to be invalid, illegal, or unenforceable by a court of competent jurisdiction:\n\n'
                '• That provision shall be modified to the minimum extent necessary to make it valid and enforceable\n'
                '• If modification is not possible, the provision shall be severed from these terms\n'
                '• All other provisions shall remain in full force and effect\n'
                '• The invalidity of one provision shall not affect the validity of the remaining provisions',
              ),
              const SizedBox(height: 20),

              // 18. Entire Agreement
              _buildSectionTitle('18. Entire Agreement', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'These Terms and Conditions, together with our Privacy Policy and any other legal notices published by us in the App, '
                'constitute the entire agreement between you and Smart Personal Expense Tracker concerning your use of the App.\n\n'
                'These terms supersede all prior agreements, understandings, and arrangements between us, whether written or oral, '
                'regarding the subject matter.',
              ),
              const SizedBox(height: 20),

              // 19. Contact Information
              _buildSectionTitle('19. Contact Information', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'If you have any questions, concerns, or feedback regarding these Terms and Conditions, please contact us at:\n\n'
                'Email: lehoangvi.work@gmail.com\n'
                'Website: www.smartexpensetracker.com\n\n'
                'We aim to respond to all inquiries within 48 hours during business days.',
              ),
              const SizedBox(height: 20),

              // 20. Changes to Terms
              _buildSectionTitle('20. Changes to These Terms', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'We reserve the right to modify these Terms and Conditions at any time. When we make changes:\n\n'
                '• We will update the "Last Updated" date at the top of this document\n'
                '• We may notify you through the App or via email\n'
                '• Significant changes will be prominently announced\n\n'
                'Your continued use of the App after changes are posted constitutes your acceptance of the revised terms. '
                'If you do not agree to the new terms, you must stop using the App.\n\n'
                'We recommend reviewing these Terms and Conditions periodically to stay informed of any updates.',
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