// lib/service/ai_deep_analysis_service.dart
// AI DEEP ANALYSIS - Phân tích sâu dựa trên lịch sử chi tiêu thực tế

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AIDeepAnalysisService {
  
  /// Phân tích chi tiết spending patterns
  static Future<DeepAnalysisResult> analyzeSpendingPatterns({
    required String userId,
    required double income,
    required double expense,
  }) async {
    final firestore = FirebaseFirestore.instance;
    
    // 1. Get transaction history (last 3 months)
    final now = DateTime.now();
    final threeMonthsAgo = now.subtract(const Duration(days: 90));
    
    final transactionsSnapshot = await firestore
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .where('date', isGreaterThan: Timestamp.fromDate(threeMonthsAgo))
        .get();
    
    // 2. Analyze spending by category
    Map<String, CategorySpending> categoryAnalysis = {};
    Map<String, List<double>> categoryHistory = {};
    
    for (var doc in transactionsSnapshot.docs) {
      var data = doc.data();
      String category = data['categoryName'] ?? data['category'] ?? 'Khác';
      double amount = (data['amount'] as num).abs().toDouble();
      String type = (data['type'] ?? 'expense').toString();
      
      if (type == 'expense') {
        if (!categoryAnalysis.containsKey(category)) {
          categoryAnalysis[category] = CategorySpending(
            category: category,
            totalAmount: 0,
            transactionCount: 0,
            averageAmount: 0,
          );
          categoryHistory[category] = [];
        }
        
        categoryAnalysis[category]!.totalAmount += amount;
        categoryAnalysis[category]!.transactionCount += 1;
        categoryHistory[category]!.add(amount);
      }
    }
    
    // Calculate averages
    categoryAnalysis.forEach((key, value) {
      value.averageAmount = value.totalAmount / value.transactionCount;
    });
    
    // 3. Identify spending trends
    List<SpendingTrend> trends = _identifyTrends(categoryAnalysis, income);
    
    // 4. Generate insights
    List<AIInsight> insights = _generateInsights(
      income: income,
      expense: expense,
      categoryAnalysis: categoryAnalysis,
      trends: trends,
    );
    
    // 5. Provide actionable recommendations
    List<ActionableRecommendation> recommendations = 
        _generateRecommendations(
      income: income,
      expense: expense,
      categoryAnalysis: categoryAnalysis,
      trends: trends,
    );
    
    // 6. Calculate risk assessment
    RiskAssessment riskAssessment = _assessRisks(
      income: income,
      expense: expense,
      categoryAnalysis: categoryAnalysis,
    );
    
    // 7. Suggest optimizations
    List<OptimizationSuggestion> optimizations = 
        _suggestOptimizations(categoryAnalysis, income);
    
    return DeepAnalysisResult(
      categoryAnalysis: categoryAnalysis,
      trends: trends,
      insights: insights,
      recommendations: recommendations,
      riskAssessment: riskAssessment,
      optimizations: optimizations,
    );
  }
  
  /// Identify spending trends
  static List<SpendingTrend> _identifyTrends(
    Map<String, CategorySpending> categoryAnalysis,
    double income,
  ) {
    List<SpendingTrend> trends = [];
    
    // Sort categories by total amount
    var sorted = categoryAnalysis.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    
    // Top 3 spending categories
    if (sorted.isNotEmpty) {
      trends.add(SpendingTrend(
        title: 'Chi tiêu nhiều nhất',
        description: 'Bạn chi nhiều nhất cho ${sorted[0].category}',
        category: sorted[0].category,
        amount: sorted[0].totalAmount,
        percentage: (sorted[0].totalAmount / income * 100),
        trendType: TrendType.high,
      ));
    }
    
    // Identify unusual patterns
    for (var category in categoryAnalysis.values) {
      double percentOfIncome = category.totalAmount / income * 100;
      
      // Flag if category > 20% of income
      if (percentOfIncome > 20) {
        trends.add(SpendingTrend(
          title: 'Cảnh báo chi tiêu cao',
          description: '${category.category} chiếm ${percentOfIncome.toStringAsFixed(1)}% thu nhập',
          category: category.category,
          amount: category.totalAmount,
          percentage: percentOfIncome,
          trendType: TrendType.warning,
        ));
      }
      
      // Flag frequent small transactions
      if (category.transactionCount > 30 && category.averageAmount < income * 0.01) {
        trends.add(SpendingTrend(
          title: 'Chi tiêu nhỏ lẻ thường xuyên',
          description: '${category.transactionCount} giao dịch ${category.category} nhỏ lẻ',
          category: category.category,
          amount: category.totalAmount,
          percentage: (category.totalAmount / income * 100),
          trendType: TrendType.frequent,
        ));
      }
    }
    
    return trends;
  }
  
  /// Generate AI insights
  static List<AIInsight> _generateInsights({
    required double income,
    required double expense,
    required Map<String, CategorySpending> categoryAnalysis,
    required List<SpendingTrend> trends,
  }) {
    List<AIInsight> insights = [];
    
    double savingRate = ((income - expense) / income * 100);
    
    // Saving rate insight
    if (savingRate >= 50) {
      insights.add(AIInsight(
        icon: '🌟',
        title: 'Tỷ lệ tiết kiệm xuất sắc',
        description: 'Bạn đang tiết kiệm ${savingRate.toStringAsFixed(1)}% thu nhập. Đây là một con số rất tốt!',
        type: InsightType.positive,
        priority: InsightPriority.high,
      ));
    } else if (savingRate < 10) {
      insights.add(AIInsight(
        icon: '⚠️',
        title: 'Tỷ lệ tiết kiệm thấp',
        description: 'Bạn chỉ tiết kiệm được ${savingRate.toStringAsFixed(1)}%. Cần cải thiện ngay!',
        type: InsightType.warning,
        priority: InsightPriority.critical,
      ));
    }
    
    // Income bracket insight
    if (income >= 100000000000) {
      insights.add(AIInsight(
        icon: '👑',
        title: 'Mức thu nhập cao',
        description: 'Thu nhập của bạn ở top 0.1%. Nên có chiến lược đầu tư và quản lý tài sản chuyên nghiệp.',
        type: InsightType.opportunity,
        priority: InsightPriority.high,
      ));
    } else if (income >= 10000000000) {
      insights.add(AIInsight(
        icon: '💎',
        title: 'Thu nhập rất cao',
        description: 'Với thu nhập này, hãy xem xét đa dạng hóa đầu tư và mua bất động sản cao cấp.',
        type: InsightType.opportunity,
        priority: InsightPriority.medium,
      ));
    }
    
    // Category-specific insights
    if (categoryAnalysis.containsKey('Food') || categoryAnalysis.containsKey('Đồ ăn')) {
      var foodSpending = categoryAnalysis['Food'] ?? categoryAnalysis['Đồ ăn'];
      if (foodSpending != null) {
        double foodPercent = foodSpending.totalAmount / income * 100;
        if (foodPercent > 30) {
          insights.add(AIInsight(
            icon: '🍽️',
            title: 'Chi tiêu ăn uống cao',
            description: 'Bạn chi ${foodPercent.toStringAsFixed(1)}% thu nhập cho ăn uống. Nên giảm xuống 15-20%.',
            type: InsightType.warning,
            priority: InsightPriority.medium,
          ));
        }
      }
    }
    
    // Spending consistency insight
    int totalTransactions = categoryAnalysis.values
        .fold(0, (sum, cat) => sum + cat.transactionCount);
    
    if (totalTransactions > 100) {
      insights.add(AIInsight(
        icon: '📊',
        title: 'Giao dịch thường xuyên',
        description: 'Bạn có ${totalTransactions} giao dịch trong 3 tháng. Hãy xem xét consolidate spending.',
        type: InsightType.neutral,
        priority: InsightPriority.low,
      ));
    }
    
    return insights;
  }
  
  /// Generate actionable recommendations
  static List<ActionableRecommendation> _generateRecommendations({
    required double income,
    required double expense,
    required Map<String, CategorySpending> categoryAnalysis,
    required List<SpendingTrend> trends,
  }) {
    List<ActionableRecommendation> recommendations = [];
    
    double savingRate = ((income - expense) / income * 100);
    double monthlySavings = income - expense;
    
    // Saving recommendations
    if (savingRate < 20) {
      recommendations.add(ActionableRecommendation(
        title: 'Tăng tỷ lệ tiết kiệm',
        description: 'Mục tiêu: tiết kiệm 20% thu nhập',
        currentValue: savingRate,
        targetValue: 20.0,
        potentialSavings: income * 0.20 - monthlySavings,
        actions: [
          'Cắt giảm chi tiêu không cần thiết',
          'Đặt mục tiêu tiết kiệm tự động',
          'Review và loại bỏ subscriptions không dùng',
        ],
        priority: RecommendationPriority.high,
      ));
    }
    
    // Category-specific recommendations
    categoryAnalysis.forEach((category, spending) {
      double percent = spending.totalAmount / income * 100;
      
      if (percent > 25) {
        double targetPercent = 15.0;
        double potentialSaving = spending.totalAmount - (income * targetPercent / 100);
        
        recommendations.add(ActionableRecommendation(
          title: 'Giảm chi ${category}',
          description: 'Giảm từ ${percent.toStringAsFixed(1)}% xuống ${targetPercent.toStringAsFixed(0)}%',
          currentValue: percent,
          targetValue: targetPercent,
          potentialSavings: potentialSaving,
          actions: [
            'Lập kế hoạch chi tiêu cho ${category}',
            'Tìm các lựa chọn tiết kiệm hơn',
            'Set limit hàng tuần',
          ],
          priority: RecommendationPriority.medium,
        ));
      }
    });
    
    // Investment recommendations based on income
    if (income >= 100000000000 && monthlySavings > 0) {
      recommendations.add(ActionableRecommendation(
        title: 'Đầu tư chuyên nghiệp',
        description: 'Với thu nhập này, nên có portfolio manager',
        currentValue: 0,
        targetValue: monthlySavings * 0.6,
        potentialSavings: 0,
        actions: [
          'Thuê financial advisor',
          'Đa dạng hóa quốc tế',
          'Đầu tư vào private equity',
          'Xem xét real estate cao cấp',
        ],
        priority: RecommendationPriority.high,
      ));
    } else if (income >= 1000000000 && monthlySavings > 0) {
      recommendations.add(ActionableRecommendation(
        title: 'Bắt đầu đầu tư',
        description: 'Đưa ${(monthlySavings * 0.5 / 1000000).toStringAsFixed(0)}M vào đầu tư',
        currentValue: 0,
        targetValue: monthlySavings * 0.5,
        potentialSavings: 0,
        actions: [
          'Mở tài khoản chứng khoán',
          'Học về ETF và mutual funds',
          'Cân nhắc mua bất động sản',
        ],
        priority: RecommendationPriority.medium,
      ));
    }
    
    return recommendations;
  }
  
  /// Assess financial risks
  static RiskAssessment _assessRisks({
    required double income,
    required double expense,
    required Map<String, CategorySpending> categoryAnalysis,
  }) {
    List<RiskFactor> risks = [];
    
    double savingRate = ((income - expense) / income * 100);
    
    // Low savings risk
    if (savingRate < 10) {
      risks.add(RiskFactor(
        title: 'Không có quỹ dự phòng',
        description: 'Tỷ lệ tiết kiệm thấp, khó ứng phó khẩn cấp',
        severity: RiskSeverity.high,
        mitigation: 'Xây dựng quỹ khẩn cấp 6 tháng chi phí',
      ));
    }
    
    // High expense ratio
    if (expense / income > 0.9) {
      risks.add(RiskFactor(
        title: 'Chi tiêu quá cao',
        description: 'Chi tiêu gần bằng thu nhập, rất rủi ro',
        severity: RiskSeverity.critical,
        mitigation: 'Cắt giảm chi tiêu ngay lập tức ít nhất 20%',
      ));
    }
    
    // Concentrated spending risk
    var sorted = categoryAnalysis.values.toList()
      ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    
    if (sorted.isNotEmpty && sorted[0].totalAmount / income > 0.5) {
      risks.add(RiskFactor(
        title: 'Chi tiêu tập trung',
        description: 'Quá 50% chi tiêu vào 1 danh mục',
        severity: RiskSeverity.medium,
        mitigation: 'Đa dạng hóa chi tiêu, tránh phụ thuộc',
      ));
    }
    
    // Calculate overall risk score
    int riskScore = 0;
    for (var risk in risks) {
      switch (risk.severity) {
        case RiskSeverity.critical:
          riskScore += 40;
          break;
        case RiskSeverity.high:
          riskScore += 25;
          break;
        case RiskSeverity.medium:
          riskScore += 15;
          break;
        case RiskSeverity.low:
          riskScore += 5;
          break;
      }
    }
    
    return RiskAssessment(
      overallScore: riskScore.clamp(0, 100),
      risks: risks,
      riskLevel: _determineRiskLevel(riskScore),
    );
  }
  
  static RiskLevel _determineRiskLevel(int score) {
    if (score >= 60) return RiskLevel.critical;
    if (score >= 40) return RiskLevel.high;
    if (score >= 20) return RiskLevel.medium;
    return RiskLevel.low;
  }
  
  /// Suggest optimizations
  static List<OptimizationSuggestion> _suggestOptimizations(
    Map<String, CategorySpending> categoryAnalysis,
    double income,
  ) {
    List<OptimizationSuggestion> optimizations = [];
    
    // Identify consolidation opportunities
    List<String> smallCategories = [];
    categoryAnalysis.forEach((category, spending) {
      if (spending.transactionCount > 20 && 
          spending.averageAmount < income * 0.005) {
        smallCategories.add(category);
      }
    });
    
    if (smallCategories.isNotEmpty) {
      optimizations.add(OptimizationSuggestion(
        title: 'Consolidate giao dịch nhỏ',
        description: 'Gộp các giao dịch ${smallCategories.join(", ")} để tiết kiệm thời gian',
        estimatedSavings: 0,
        difficulty: OptimizationDifficulty.easy,
      ));
    }
    
    // Identify subscription optimization
    if (categoryAnalysis.containsKey('Subscription') || 
        categoryAnalysis.containsKey('Entertainment')) {
      optimizations.add(OptimizationSuggestion(
        title: 'Review subscriptions',
        description: 'Kiểm tra và hủy subscriptions không dùng',
        estimatedSavings: income * 0.02,
        difficulty: OptimizationDifficulty.easy,
      ));
    }
    
    // Bulk buying opportunities
    var sorted = categoryAnalysis.values.toList()
      ..sort((a, b) => b.transactionCount.compareTo(a.transactionCount));
    
    if (sorted.isNotEmpty && sorted[0].transactionCount > 30) {
      optimizations.add(OptimizationSuggestion(
        title: 'Mua hàng loạt cho ${sorted[0].category}',
        description: 'Mua số lượng lớn để được giảm giá',
        estimatedSavings: sorted[0].totalAmount * 0.15,
        difficulty: OptimizationDifficulty.medium,
      ));
    }
    
    return optimizations;
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

class CategorySpending {
  final String category;
  double totalAmount;
  int transactionCount;
  double averageAmount;
  
  CategorySpending({
    required this.category,
    required this.totalAmount,
    required this.transactionCount,
    required this.averageAmount,
  });
}

class SpendingTrend {
  final String title;
  final String description;
  final String category;
  final double amount;
  final double percentage;
  final TrendType trendType;
  
  SpendingTrend({
    required this.title,
    required this.description,
    required this.category,
    required this.amount,
    required this.percentage,
    required this.trendType,
  });
}

enum TrendType { high, warning, frequent, normal }

class AIInsight {
  final String icon;
  final String title;
  final String description;
  final InsightType type;
  final InsightPriority priority;
  
  AIInsight({
    required this.icon,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
  });
}

enum InsightType { positive, warning, neutral, opportunity }
enum InsightPriority { critical, high, medium, low }

class ActionableRecommendation {
  final String title;
  final String description;
  final double currentValue;
  final double targetValue;
  final double potentialSavings;
  final List<String> actions;
  final RecommendationPriority priority;
  
  ActionableRecommendation({
    required this.title,
    required this.description,
    required this.currentValue,
    required this.targetValue,
    required this.potentialSavings,
    required this.actions,
    required this.priority,
  });
}

enum RecommendationPriority { critical, high, medium, low }

class RiskAssessment {
  final int overallScore; // 0-100
  final List<RiskFactor> risks;
  final RiskLevel riskLevel;
  
  RiskAssessment({
    required this.overallScore,
    required this.risks,
    required this.riskLevel,
  });
}

class RiskFactor {
  final String title;
  final String description;
  final RiskSeverity severity;
  final String mitigation;
  
  RiskFactor({
    required this.title,
    required this.description,
    required this.severity,
    required this.mitigation,
  });
}

enum RiskSeverity { critical, high, medium, low }
enum RiskLevel { critical, high, medium, low }

class OptimizationSuggestion {
  final String title;
  final String description;
  final double estimatedSavings;
  final OptimizationDifficulty difficulty;
  
  OptimizationSuggestion({
    required this.title,
    required this.description,
    required this.estimatedSavings,
    required this.difficulty,
  });
}

enum OptimizationDifficulty { easy, medium, hard }

class DeepAnalysisResult {
  final Map<String, CategorySpending> categoryAnalysis;
  final List<SpendingTrend> trends;
  final List<AIInsight> insights;
  final List<ActionableRecommendation> recommendations;
  final RiskAssessment riskAssessment;
  final List<OptimizationSuggestion> optimizations;
  
  DeepAnalysisResult({
    required this.categoryAnalysis,
    required this.trends,
    required this.insights,
    required this.recommendations,
    required this.riskAssessment,
    required this.optimizations,
  });
}