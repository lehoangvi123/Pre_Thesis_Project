// lib/service/ai_financial_advisor_service.dart
// AI FINANCIAL ADVISOR - Phân tích thông minh và đưa ra lời khuyên

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart'; // ← Add this import

class AIFinancialAdvisorService {
  
  /// Phân tích tổng thể và đưa ra insights
  static Future<FinancialInsight> analyzeFinancialHealth({
    required double income,
    required double expense,
    required Map<String, double> expenseByCategory,
  }) async {
    
    // 1. Calculate ratios
    double savingRate = income > 0 ? ((income - expense) / income * 100) : 0;
    double expenseRatio = income > 0 ? (expense / income * 100) : 0;
    
    // 2. Determine income tier
    IncomeTier tier = _determineIncomeTier(income);
    
    // 3. Generate recommendations
    List<String> recommendations = _generateRecommendations(
      income: income,
      expense: expense,
      savingRate: savingRate,
      tier: tier,
      categoryBreakdown: expenseByCategory,
    );
    
    // 4. Lifestyle suggestions
    List<LifestyleSuggestion> lifestyleSuggestions = 
        _generateLifestyleSuggestions(tier, income, expense);
    
    // 5. Investment advice
    InvestmentAdvice investmentAdvice = 
        _generateInvestmentAdvice(tier, income, expense);
    
    // 6. Spending allocation
    SpendingAllocation allocation = 
        _generateSpendingAllocation(income, tier);
    
    // 7. Financial health score
    double healthScore = _calculateHealthScore(
      savingRate: savingRate,
      expenseRatio: expenseRatio,
      tier: tier,
    );
    
    return FinancialInsight(
      tier: tier,
      savingRate: savingRate,
      expenseRatio: expenseRatio,
      healthScore: healthScore,
      recommendations: recommendations,
      lifestyleSuggestions: lifestyleSuggestions,
      investmentAdvice: investmentAdvice,
      spendingAllocation: allocation,
    );
  }
  
  /// Xác định mức thu nhập
  static IncomeTier _determineIncomeTier(double monthlyIncome) {
    if (monthlyIncome >= 100000000000) {
      return IncomeTier.ultraHigh; // 100B+
    } else if (monthlyIncome >= 10000000000) {
      return IncomeTier.veryHigh; // 10B-100B
    } else if (monthlyIncome >= 1000000000) {
      return IncomeTier.high; // 1B-10B
    } else if (monthlyIncome >= 500000000) {
      return IncomeTier.upperMiddle; // 500M-1B
    } else if (monthlyIncome >= 100000000) {
      return IncomeTier.middle; // 100M-500M
    } else if (monthlyIncome >= 30000000) {
      return IncomeTier.lowerMiddle; // 30M-100M
    } else {
      return IncomeTier.entry; // <30M
    }
  }
  
  /// Generate smart recommendations
  static List<String> _generateRecommendations({
    required double income,
    required double expense,
    required double savingRate,
    required IncomeTier tier,
    required Map<String, double> categoryBreakdown,
  }) {
    List<String> recommendations = [];
    
    // Saving rate recommendations
    if (savingRate < 10) {
      recommendations.add('⚠️ Tỷ lệ tiết kiệm thấp (${savingRate.toStringAsFixed(1)}%). Nên tiết kiệm ít nhất 20% thu nhập.');
    } else if (savingRate < 20) {
      recommendations.add('💡 Tỷ lệ tiết kiệm khá (${savingRate.toStringAsFixed(1)}%). Cố gắng tăng lên 30%.');
    } else if (savingRate < 50) {
      recommendations.add('✅ Tỷ lệ tiết kiệm tốt (${savingRate.toStringAsFixed(1)}%). Bạn đang làm rất tốt!');
    } else {
      recommendations.add('🌟 Tỷ lệ tiết kiệm xuất sắc (${savingRate.toStringAsFixed(1)}%). Hãy xem xét đầu tư!');
    }
    
    // Tier-specific recommendations
    switch (tier) {
      case IncomeTier.ultraHigh:
        recommendations.add('🏰 Thu nhập cao cấp: Nên có cố vấn tài chính riêng, đầu tư bất động sản cao cấp.');
        recommendations.add('💼 Xem xét thành lập công ty quản lý tài sản cá nhân.');
        break;
        
      case IncomeTier.veryHigh:
        recommendations.add('🏢 Thu nhập rất cao: Đa dạng hóa danh mục đầu tư, bất động sản, cổ phiếu.');
        recommendations.add('📊 Nên có quỹ đầu tư ít nhất 2-3 tỷ.');
        break;
        
      case IncomeTier.high:
        recommendations.add('💎 Thu nhập cao: Bắt đầu xây dựng danh mục đầu tư, mua bất động sản.');
        recommendations.add('🏠 Xem xét mua nhà hoặc căn hộ đầu tư.');
        break;
        
      case IncomeTier.upperMiddle:
        recommendations.add('🎯 Thu nhập khá: Tiết kiệm để mua nhà, đầu tư vàng hoặc quỹ.');
        recommendations.add('📈 Bắt đầu học về đầu tư chứng khoán.');
        break;
        
      case IncomeTier.middle:
        recommendations.add('💪 Thu nhập trung bình: Tập trung tiết kiệm, tránh nợ tiêu dùng.');
        recommendations.add('🎓 Đầu tư vào kỹ năng để tăng thu nhập.');
        break;
        
      case IncomeTier.lowerMiddle:
        recommendations.add('🌱 Đang phát triển: Ưu tiên quỹ khẩn cấp, chi tiêu thông minh.');
        recommendations.add('💡 Tìm kiếm cơ hội tăng thu nhập thêm.');
        break;
        
      case IncomeTier.entry:
        recommendations.add('🚀 Bắt đầu: Tập trung phát triển sự nghiệp, hạn chế chi tiêu không cần thiết.');
        recommendations.add('📚 Đầu tư vào học tập và kỹ năng.');
        break;
    }
    
    // Category-specific advice
    if (categoryBreakdown.isNotEmpty) {
      double foodExpense = categoryBreakdown['Food & Dining'] ?? 0;
      double transportExpense = categoryBreakdown['Transport'] ?? 0;
      double entertainmentExpense = categoryBreakdown['Entertainment'] ?? 0;
      
      if (foodExpense > income * 0.3) {
        recommendations.add('🍽️ Chi tiêu ăn uống cao (${(foodExpense/income*100).toStringAsFixed(0)}%). Nên giảm xuống 20-25%.');
      }
      
      if (transportExpense > income * 0.2) {
        recommendations.add('🚗 Chi phí di chuyển cao. Xem xét phương tiện tiết kiệm hơn.');
      }
      
      if (entertainmentExpense > income * 0.1) {
        recommendations.add('🎮 Giải trí chiếm nhiều chi phí. Cân nhắc giảm xuống 5-10%.');
      }
    }
    
    return recommendations;
  }
  
  /// Generate lifestyle suggestions based on income
  static List<LifestyleSuggestion> _generateLifestyleSuggestions(
    IncomeTier tier,
    double income,
    double expense,
  ) {
    List<LifestyleSuggestion> suggestions = [];
    
    switch (tier) {
      case IncomeTier.ultraHigh:
        suggestions.addAll([
          LifestyleSuggestion(
            category: 'Ăn uống',
            suggestion: 'Nhà hàng cao cấp 2-3 lần/tuần, có đầu bếp riêng',
            budget: income * 0.05,
          ),
          LifestyleSuggestion(
            category: 'Gặp gỡ',
            suggestion: 'CLB riêng tư, golf, du thuyền, tiệc sang trọng',
            budget: income * 0.08,
          ),
          LifestyleSuggestion(
            category: 'Đầu tư',
            suggestion: 'Bất động sản cao cấp, cổ phiếu quốc tế, nghệ thuật',
            budget: income * 0.40,
          ),
          LifestyleSuggestion(
            category: 'Du lịch',
            suggestion: 'Du lịch hạng sang mỗi quý, thuê jet riêng',
            budget: income * 0.10,
          ),
        ]);
        break;
        
      case IncomeTier.veryHigh:
        suggestions.addAll([
          LifestyleSuggestion(
            category: 'Ăn uống',
            suggestion: 'Nhà hàng cao cấp 1-2 lần/tuần',
            budget: income * 0.08,
          ),
          LifestyleSuggestion(
            category: 'Gặp gỡ',
            suggestion: 'CLB golf, bar rooftop, tiệc cao cấp',
            budget: income * 0.10,
          ),
          LifestyleSuggestion(
            category: 'Đầu tư',
            suggestion: 'Mua căn hộ thứ 2, cổ phiếu, quỹ',
            budget: income * 0.35,
          ),
          LifestyleSuggestion(
            category: 'Du lịch',
            suggestion: 'Du lịch quốc tế 2-3 lần/năm, hạng thương gia',
            budget: income * 0.08,
          ),
        ]);
        break;
        
      case IncomeTier.high:
        suggestions.addAll([
          LifestyleSuggestion(
            category: 'Ăn uống',
            suggestion: 'Nhà hàng tốt cuối tuần, meal prep ngày thường',
            budget: income * 0.12,
          ),
          LifestyleSuggestion(
            category: 'Gặp gỡ',
            suggestion: 'Café specialty, bar trendy, BBQ với bạn bè',
            budget: income * 0.08,
          ),
          LifestyleSuggestion(
            category: 'Đầu tư',
            suggestion: 'Bắt đầu mua nhà, cổ phiếu, tiết kiệm',
            budget: income * 0.30,
          ),
          LifestyleSuggestion(
            category: 'Du lịch',
            suggestion: 'Du lịch trong nước + 1 chuyến quốc tế/năm',
            budget: income * 0.10,
          ),
        ]);
        break;
        
      case IncomeTier.upperMiddle:
      case IncomeTier.middle:
        suggestions.addAll([
          LifestyleSuggestion(
            category: 'Ăn uống',
            suggestion: 'Nấu ăn tại nhà, đi ăn ngoài 2-3 lần/tháng',
            budget: income * 0.15,
          ),
          LifestyleSuggestion(
            category: 'Gặp gỡ',
            suggestion: 'Café, picnic, ăn uống bình dân với bạn bè',
            budget: income * 0.05,
          ),
          LifestyleSuggestion(
            category: 'Tiết kiệm',
            suggestion: 'Quỹ khẩn cấp 6 tháng, tiết kiệm định kỳ',
            budget: income * 0.25,
          ),
          LifestyleSuggestion(
            category: 'Du lịch',
            suggestion: 'Du lịch trong nước 2-3 lần/năm',
            budget: income * 0.08,
          ),
        ]);
        break;
        
      default:
        suggestions.addAll([
          LifestyleSuggestion(
            category: 'Ăn uống',
            suggestion: 'Nấu ăn tại nhà, meal prep tiết kiệm',
            budget: income * 0.20,
          ),
          LifestyleSuggestion(
            category: 'Gặp gỡ',
            suggestion: 'Hoạt động miễn phí: công viên, thư viện',
            budget: income * 0.03,
          ),
          LifestyleSuggestion(
            category: 'Tiết kiệm',
            suggestion: 'Quỹ khẩn cấp 3-6 tháng chi phí',
            budget: income * 0.20,
          ),
          LifestyleSuggestion(
            category: 'Phát triển',
            suggestion: 'Học online miễn phí, tìm thu nhập thêm',
            budget: income * 0.05,
          ),
        ]);
    }
    
    return suggestions;
  }
  
  /// Generate investment advice
  static InvestmentAdvice _generateInvestmentAdvice(
    IncomeTier tier,
    double income,
    double expense,
  ) {
    double availableForInvestment = income - expense;
    
    List<InvestmentOption> options = [];
    String strategy = '';
    
    switch (tier) {
      case IncomeTier.ultraHigh:
      case IncomeTier.veryHigh:
        strategy = 'Đa dạng hóa tối đa với tỷ trọng lớn vào bất động sản cao cấp và cổ phiếu quốc tế';
        options.addAll([
          InvestmentOption(
            name: 'Bất động sản cao cấp',
            allocation: 40,
            expectedReturn: '15-25%/năm',
            risk: 'Trung bình',
          ),
          InvestmentOption(
            name: 'Cổ phiếu quốc tế',
            allocation: 30,
            expectedReturn: '10-20%/năm',
            risk: 'Trung bình-Cao',
          ),
          InvestmentOption(
            name: 'Trái phiếu doanh nghiệp',
            allocation: 20,
            expectedReturn: '7-12%/năm',
            risk: 'Thấp-Trung bình',
          ),
          InvestmentOption(
            name: 'Nghệ thuật & Sưu tầm',
            allocation: 10,
            expectedReturn: 'Biến động',
            risk: 'Cao',
          ),
        ]);
        break;
        
      case IncomeTier.high:
        strategy = 'Tập trung vào bất động sản và cổ phiếu, bắt đầu xây dựng danh mục đầu tư';
        options.addAll([
          InvestmentOption(
            name: 'Mua nhà/căn hộ đầu tư',
            allocation: 50,
            expectedReturn: '10-20%/năm',
            risk: 'Trung bình',
          ),
          InvestmentOption(
            name: 'Cổ phiếu VN30',
            allocation: 25,
            expectedReturn: '8-15%/năm',
            risk: 'Trung bình',
          ),
          InvestmentOption(
            name: 'Quỹ mở',
            allocation: 15,
            expectedReturn: '6-10%/năm',
            risk: 'Thấp-Trung bình',
          ),
          InvestmentOption(
            name: 'Tiết kiệm có kỳ hạn',
            allocation: 10,
            expectedReturn: '5-7%/năm',
            risk: 'Rất thấp',
          ),
        ]);
        break;
        
      case IncomeTier.upperMiddle:
      case IncomeTier.middle:
        strategy = 'Bắt đầu với quỹ và tiết kiệm, chuẩn bị mua nhà trong 3-5 năm';
        options.addAll([
          InvestmentOption(
            name: 'Quỹ mở cân bằng',
            allocation: 40,
            expectedReturn: '6-10%/năm',
            risk: 'Thấp-Trung bình',
          ),
          InvestmentOption(
            name: 'Tiết kiệm kỳ hạn',
            allocation: 30,
            expectedReturn: '5-7%/năm',
            risk: 'Rất thấp',
          ),
          InvestmentOption(
            name: 'Vàng SJC',
            allocation: 20,
            expectedReturn: '5-8%/năm',
            risk: 'Thấp',
          ),
          InvestmentOption(
            name: 'Học cổ phiếu cơ bản',
            allocation: 10,
            expectedReturn: 'Biến động',
            risk: 'Cao (học tập)',
          ),
        ]);
        break;
        
      default:
        strategy = 'Ưu tiên xây dựng quỹ khẩn cấp trước khi đầu tư';
        options.addAll([
          InvestmentOption(
            name: 'Quỹ khẩn cấp',
            allocation: 60,
            expectedReturn: '4-6%/năm',
            risk: 'Rất thấp',
          ),
          InvestmentOption(
            name: 'Tiết kiệm ngắn hạn',
            allocation: 30,
            expectedReturn: '4-5%/năm',
            risk: 'Rất thấp',
          ),
          InvestmentOption(
            name: 'Học về tài chính',
            allocation: 10,
            expectedReturn: 'Vô giá',
            risk: 'Không',
          ),
        ]);
    }
    
    return InvestmentAdvice(
      availableAmount: availableForInvestment,
      strategy: strategy,
      options: options,
    );
  }
  
  /// Generate spending allocation (50/30/20 rule adapted)
  static SpendingAllocation _generateSpendingAllocation(
    double income,
    IncomeTier tier,
  ) {
    Map<String, double> allocation = {};
    
    switch (tier) {
      case IncomeTier.ultraHigh:
      case IncomeTier.veryHigh:
        allocation = {
          'Cần thiết': 20, // Housing, food, utilities
          'Đầu tư': 50,    // Investments
          'Lối sống': 20,  // Lifestyle, entertainment
          'Từ thiện': 10,  // Charity, giving back
        };
        break;
        
      case IncomeTier.high:
        allocation = {
          'Cần thiết': 30,
          'Đầu tư': 40,
          'Lối sống': 20,
          'Dự phòng': 10,
        };
        break;
        
      case IncomeTier.upperMiddle:
      case IncomeTier.middle:
        allocation = {
          'Cần thiết': 50,
          'Tiết kiệm': 30,
          'Lối sống': 15,
          'Dự phòng': 5,
        };
        break;
        
      default:
        allocation = {
          'Cần thiết': 60,
          'Tiết kiệm': 25,
          'Lối sống': 10,
          'Dự phòng': 5,
        };
    }
    
    return SpendingAllocation(
      percentages: allocation,
      monthlyAmounts: allocation.map(
        (key, value) => MapEntry(key, income * value / 100),
      ),
    );
  }
  
  /// Calculate financial health score (0-100)
  static double _calculateHealthScore({
    required double savingRate,
    required double expenseRatio,
    required IncomeTier tier,
  }) {
    double score = 0;
    
    // Saving rate contribution (40 points max)
    if (savingRate >= 50) {
      score += 40;
    } else if (savingRate >= 30) {
      score += 35;
    } else if (savingRate >= 20) {
      score += 25;
    } else if (savingRate >= 10) {
      score += 15;
    } else {
      score += savingRate; // 0-10 points
    }
    
    // Expense ratio contribution (30 points max)
    if (expenseRatio <= 50) {
      score += 30;
    } else if (expenseRatio <= 70) {
      score += 20;
    } else if (expenseRatio <= 90) {
      score += 10;
    }
    
    // Income tier bonus (30 points max)
    switch (tier) {
      case IncomeTier.ultraHigh:
      case IncomeTier.veryHigh:
        score += 30;
        break;
      case IncomeTier.high:
        score += 25;
        break;
      case IncomeTier.upperMiddle:
        score += 20;
        break;
      case IncomeTier.middle:
        score += 15;
        break;
      case IncomeTier.lowerMiddle:
        score += 10;
        break;
      default:
        score += 5;
    }
    
    return score.clamp(0, 100);
  }
}

// ============================================================================
// DATA MODELS
// ============================================================================

enum IncomeTier {
  entry,        // <30M
  lowerMiddle,  // 30-100M
  middle,       // 100-500M
  upperMiddle,  // 500M-1B
  high,         // 1-10B
  veryHigh,     // 10-100B
  ultraHigh,    // 100B+
}

class FinancialInsight {
  final IncomeTier tier;
  final double savingRate;
  final double expenseRatio;
  final double healthScore;
  final List<String> recommendations;
  final List<LifestyleSuggestion> lifestyleSuggestions;
  final InvestmentAdvice investmentAdvice;
  final SpendingAllocation spendingAllocation;
  
  FinancialInsight({
    required this.tier,
    required this.savingRate,
    required this.expenseRatio,
    required this.healthScore,
    required this.recommendations,
    required this.lifestyleSuggestions,
    required this.investmentAdvice,
    required this.spendingAllocation,
  });
  
  String get tierName {
    switch (tier) {
      case IncomeTier.ultraHigh: return 'Siêu giàu';
      case IncomeTier.veryHigh: return 'Rất giàu';
      case IncomeTier.high: return 'Giàu';
      case IncomeTier.upperMiddle: return 'Khá giả';
      case IncomeTier.middle: return 'Trung lưu';
      case IncomeTier.lowerMiddle: return 'Trung lưu thấp';
      case IncomeTier.entry: return 'Mới bắt đầu';
    }
  }
  
  String get healthLevel {
    if (healthScore >= 80) return 'Xuất sắc';
    if (healthScore >= 60) return 'Tốt';
    if (healthScore >= 40) return 'Trung bình';
    return 'Cần cải thiện';
  }
  
  Color get healthColor {
    if (healthScore >= 80) return const Color(0xFF00C853);
    if (healthScore >= 60) return const Color(0xFF64DD17);
    if (healthScore >= 40) return const Color(0xFFFFAB00);
    return const Color(0xFFFF5252);
  }
}

class LifestyleSuggestion {
  final String category;
  final String suggestion;
  final double budget;
  
  LifestyleSuggestion({
    required this.category,
    required this.suggestion,
    required this.budget,
  });
}

class InvestmentAdvice {
  final double availableAmount;
  final String strategy;
  final List<InvestmentOption> options;
  
  InvestmentAdvice({
    required this.availableAmount,
    required this.strategy,
    required this.options,
  });
}

class InvestmentOption {
  final String name;
  final double allocation; // Percentage
  final String expectedReturn;
  final String risk;
  
  InvestmentOption({
    required this.name,
    required this.allocation,
    required this.expectedReturn,
    required this.risk,
  });
}

class SpendingAllocation {
  final Map<String, double> percentages;
  final Map<String, double> monthlyAmounts;
  
  SpendingAllocation({
    required this.percentages,
    required this.monthlyAmounts,
  });
}