// lib/view/AIInsights/ai_insights_view.dart
// AI INSIGHTS VIEW - Hiển thị phân tích thông minh

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './AI_financial_advisor_service.dart';

class AIInsightsView extends StatefulWidget {
  const AIInsightsView({Key? key}) : super(key: key);

  @override
  State<AIInsightsView> createState() => _AIInsightsViewState();
}

class _AIInsightsViewState extends State<AIInsightsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = true;
  FinancialInsight? _insight;
  
  @override
  void initState() {
    super.initState();
    _loadInsights();
  }
  
  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);
    
    try {
      String? userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      // Get user financial data
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};
      
      double income = (userData['totalIncome'] ?? 0).toDouble();
      double expense = (userData['totalExpense'] ?? 0).toDouble();
      
      // Get expense breakdown by category
      final transactionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .where('type', isEqualTo: 'expense')
          .get();
      
      Map<String, double> expenseByCategory = {};
      for (var doc in transactionsSnapshot.docs) {
        String category = doc.data()['categoryName'] ?? 'Other';
        double amount = (doc.data()['amount'] as num).abs().toDouble();
        expenseByCategory[category] = (expenseByCategory[category] ?? 0) + amount;
      }
      
      // Generate AI insights
      final insight = await AIFinancialAdvisorService.analyzeFinancialHealth(
        income: income,
        expense: expense,
        expenseByCategory: expenseByCategory,
      );
      
      setState(() {
        _insight = insight;
        _isLoading = false;
      });
      
    } catch (e) {
      print('Error loading insights: $e');
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'AI Phân tích thông minh',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF00CED1),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _insight == null
              ? _buildEmptyState()
              : _buildInsightsContent(isDark),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.psychology, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu để phân tích',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInsightsContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHealthScoreCard(isDark),
          const SizedBox(height: 20),
          _buildQuickStatsCard(isDark),
          const SizedBox(height: 20),
          _buildRecommendationsCard(isDark),
          const SizedBox(height: 20),
          _buildLifestyleSuggestionsCard(isDark),
          const SizedBox(height: 20),
          _buildInvestmentAdviceCard(isDark),
          const SizedBox(height: 20),
          _buildSpendingAllocationCard(isDark),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
  
  Widget _buildHealthScoreCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _insight!.healthColor,
            _insight!.healthColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _insight!.healthColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sức khỏe tài chính',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _insight!.healthLevel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${_insight!.healthScore.toInt()}',
                    style: TextStyle(
                      color: _insight!.healthColor,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _insight!.healthScore / 100,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Hạng: ${_insight!.tierName}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickStatsCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Tỷ lệ tiết kiệm',
              '${_insight!.savingRate.toStringAsFixed(1)}%',
              Icons.savings,
              const Color(0xFF00CED1),
              isDark,
            ),
          ),
          Container(
            width: 1,
            height: 40,
            color: isDark ? Colors.grey[700] : Colors.grey[300],
          ),
          Expanded(
            child: _buildStatItem(
              'Chi tiêu',
              '${_insight!.expenseRatio.toStringAsFixed(1)}%',
              Icons.shopping_cart,
              Colors.red,
              isDark,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildRecommendationsCard(bool isDark) {
    return _buildCard(
      title: '💡 Khuyến nghị',
      isDark: isDark,
      child: Column(
        children: _insight!.recommendations.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00CED1).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${entry.key + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00CED1),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    entry.value,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildLifestyleSuggestionsCard(bool isDark) {
    return _buildCard(
      title: '🎯 Gợi ý lối sống',
      isDark: isDark,
      child: Column(
        children: _insight!.lifestyleSuggestions.map((suggestion) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.grey[800]
                  : const Color(0xFF00CED1).withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      suggestion.category,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF00CED1),
                      ),
                    ),
                    Text(
                      _formatCurrency(suggestion.budget),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  suggestion.suggestion,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildInvestmentAdviceCard(bool isDark) {
    return _buildCard(
      title: '📊 Tư vấn đầu tư',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet,
                    color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Khả năng đầu tư',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(_insight!.investmentAdvice.availableAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _insight!.investmentAdvice.strategy,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 16),
          ..._insight!.investmentAdvice.options.map((option) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          option.name,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00CED1).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${option.allocation.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00CED1),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.trending_up,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        option.expectedReturn,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.shield, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Rủi ro: ${option.risk}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildSpendingAllocationCard(bool isDark) {
    return _buildCard(
      title: '💰 Phân bổ chi tiêu đề xuất',
      isDark: isDark,
      child: Column(
        children: _insight!.spendingAllocation.percentages.entries.map((entry) {
          double amount = _insight!.spendingAllocation.monthlyAmounts[entry.key]!;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    Text(
                      '${entry.value.toStringAsFixed(0)}% • ${_formatCurrency(amount)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: entry.value / 100,
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[200],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00CED1),
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildCard({
    required String title,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
  
  String _formatCurrency(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}B₫';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M₫';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K₫';
    }
    return '${amount.toStringAsFixed(0)}₫';
  }
}