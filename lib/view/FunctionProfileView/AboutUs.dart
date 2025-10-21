import 'package:flutter/material.dart';

class AboutUsView extends StatelessWidget {
  const AboutUsView({Key? key}) : super(key: key);

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
          'About Us',
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
              // App Logo/Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet,
                    size: 50,
                    color: Color(0xFF00CED1),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // App Title
              Center(
                child: Text(
                  'Smart Personal Expense Tracker',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'with AI-Based Financial Insights',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF00CED1),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 1. Overview & Mission
              _buildSectionTitle('Overview & Mission', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'The Smart Personal Expense Tracker is an innovative mobile application designed to revolutionize personal finance management. '
                'By combining traditional expense tracking with cutting-edge artificial intelligence technology, this app empowers users to take control '
                'of their financial lives through intelligent insights, predictive analytics, and personalized recommendations.\n\n'
                'Our mission is to democratize financial intelligence and make sophisticated financial management tools accessible to everyone. '
                'We believe that everyone deserves to have clear, actionable insights into their spending habits without needing to be a financial expert. '
                'Whether you\'re saving for a major purchase, trying to reduce unnecessary spending, or simply want better visibility into your '
                'financial habits, our app is your trusted companion on the journey to financial wellness.',
              ),
              const SizedBox(height: 24),

              // 2. Key Features
              _buildSectionTitle('Key Features', isDark),
              const SizedBox(height: 12),
              _buildFeatureCard(
                isDark,
                Icons.auto_awesome,
                'AI-Powered Insights',
                'Advanced machine learning algorithms analyze your spending patterns to provide personalized financial insights and recommendations.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                isDark,
                Icons.category,
                'Smart Categorization',
                'Automatically categorizes expenses into intuitive groups, learning from your inputs to become more accurate over time.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                isDark,
                Icons.analytics,
                'Comprehensive Analytics',
                'Visualize spending through beautiful charts and graphs, tracking expenses by category, time period, or custom filters.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                isDark,
                Icons.account_balance_wallet,
                'Budget Management',
                'Set personalized budgets and receive intelligent alerts when approaching limits to stay on track with financial goals.',
              ),
              const SizedBox(height: 12),
              _buildFeatureCard(
                isDark,
                Icons.security,
                'Bank-Level Security',
                'Financial data protected with industry-standard encryption and multi-layer security measures for complete privacy.',
              ),
              const SizedBox(height: 24),

              // 3. Technology & Innovation
              _buildSectionTitle('Technology & Innovation', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'This application represents the culmination of advanced software engineering and artificial intelligence research. '
                'Built using Flutter framework, it provides a native-like experience on both iOS and Android platforms.\n\n'
                'The AI engine utilizes:\n\n'
                '• Machine Learning models for expense classification and pattern recognition\n'
                '• Natural Language Processing for intelligent transaction descriptions\n'
                '• Predictive analytics for financial forecasting\n'
                '• Deep learning algorithms for personalized recommendations\n'
                '• Real-time data processing for instant insights\n\n'
                'Our commitment to privacy means all AI processing can be done locally on your device, ensuring your financial data '
                'never needs to leave your phone unless you choose to sync it to the cloud.',
              ),
              const SizedBox(height: 24),

              // 4. Development & Team
              _buildSectionTitle('Development & Team', isDark),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'This application was developed as part of a thesis project titled "Development of Smart Personal Expense Tracker '
                'with AI-Based Financial Insights." The project represents months of dedicated research, development, and testing '
                'to create a solution that truly makes a difference in people\'s financial lives.\n\n'
                'Our interdisciplinary team combines expertise in:\n\n'
                '• Software Engineering and Mobile Development\n'
                '• Artificial Intelligence and Machine Learning\n'
                '• User Experience and Interface Design\n'
                '• Financial Technology and Analytics\n'
                '• Data Security and Privacy Protection\n\n'
                'We are passionate about creating technology that empowers users and improves their quality of life. '
                'We extend our heartfelt gratitude to our academic advisors, beta testers, the open-source community, '
                'and all users who trust us with their financial data.',
              ),
              const SizedBox(height: 24),

              // 5. Contact & Privacy
              _buildSectionTitle('Contact & Privacy', isDark),
              const SizedBox(height: 12),
              _buildContactCard(
                isDark,
                Icons.email,
                'Email',
                'lehoangvi.work@gmail.com',
              ),
              const SizedBox(height: 12),
              _buildContentCard(
                isDark,
                'We understand that financial data is deeply personal and sensitive. Our security measures include:\n\n'
                '• End-to-end encryption for all data transmission\n'
                '• Local data storage with AES-256 encryption\n'
                '• No selling or sharing of personal data with third parties\n'
                '• Optional biometric authentication (fingerprint/face ID)\n'
                '• Transparent data usage policies\n'
                '• User control over data deletion and export\n\n'
                'Your trust is our most valuable asset, and we work tirelessly to maintain it.',
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
                      'Made with ❤️ for better financial wellness',
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
        fontSize: 20,
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

  Widget _buildFeatureCard(
    bool isDark,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF00CED1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00CED1),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  textAlign: TextAlign.justify,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(
    bool isDark,
    IconData icon,
    String title,
    String info,
  ) {
    return Container(
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF00CED1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF00CED1),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  info,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}