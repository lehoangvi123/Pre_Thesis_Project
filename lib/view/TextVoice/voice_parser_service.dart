// lib/service/voice_parser_service.dart
// IMPROVED VERSION - Hỗ trợ "tỷ" và số lớn

class VoiceParserService {
  // Parse voice text → transaction data
  static Map<String, dynamic>? parseVoiceInput(String voiceText) {
    try {
      String text = voiceText.toLowerCase().trim();
      
      print('📝 Parsing: "$text"');
      
      // 1. Detect type (thu/chi)
      String type = _detectType(text);
      print('📌 Type: $type');
      
      // 2. Extract amount (số tiền)
      double? amount = _extractAmount(text);
      print('💰 Amount: $amount');
      
      if (amount == null) {
        print('❌ Cannot extract amount');
        return null;
      }
      
      // 3. Extract note
      String note = _extractNote(text);
      print('📝 Note: $note');
      
      // 4. Suggest category
      String category = _suggestCategory(text, type);
      print('📂 Category: $category');
      
      return {
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
        'confidence': 0.85,
      };
    } catch (e) {
      print('❌ Parse error: $e');
      return null;
    }
  }
  
  // Detect income/expense
  static String _detectType(String text) {
    // Income keywords
    if (text.contains('nhận') || 
        text.contains('lương') || 
        text.contains('thu') ||
        text.contains('được trả') ||
        text.contains('kiếm được')) {
      return 'income';
    }
    return 'expense'; // Default
  }
  
  // Extract amount - IMPROVED với hỗ trợ "tỷ"
  static double? _extractAmount(String text) {
    try {
      // Normalize text
      text = text
          .replaceAll('nghìn', 'k')
          .replaceAll('ngàn', 'k')
          .replaceAll('triệu', 'm')
          .replaceAll('tỷ', 'b')     // TỶ = billion
          .replaceAll('đồng', '')
          .replaceAll('vnd', '')
          .replaceAll('đ', '');
      
      print('🔍 Normalized text: "$text"');
      
      // Pattern 1: "10 tỷ" → 10b
      RegExp bPattern = RegExp(r'(\d+(?:\.\d+)?)\s*b');
      var bMatch = bPattern.firstMatch(text);
      if (bMatch != null) {
        double value = double.parse(bMatch.group(1)!);
        double result = value * 1000000000; // 1 tỷ = 1 billion
        print('✅ Found "tỷ": ${bMatch.group(1)} → $result');
        return result;
      }
      
      // Pattern 2: "35k" → 35,000
      RegExp kPattern = RegExp(r'(\d+(?:\.\d+)?)\s*k');
      var kMatch = kPattern.firstMatch(text);
      if (kMatch != null) {
        double value = double.parse(kMatch.group(1)!);
        double result = value * 1000;
        print('✅ Found "k": ${kMatch.group(1)} → $result');
        return result;
      }
      
      // Pattern 3: "5m" → 5,000,000
      RegExp mPattern = RegExp(r'(\d+(?:\.\d+)?)\s*m');
      var mMatch = mPattern.firstMatch(text);
      if (mMatch != null) {
        double value = double.parse(mMatch.group(1)!);
        double result = value * 1000000;
        print('✅ Found "m": ${mMatch.group(1)} → $result');
        return result;
      }
      
      // Pattern 4: "50.000" (dấu chấm ngăn cách)
      RegExp dotPattern = RegExp(r'(\d{1,3}(?:\.\d{3})+)');
      var dotMatch = dotPattern.firstMatch(text);
      if (dotMatch != null) {
        String numStr = dotMatch.group(1)!.replaceAll('.', '');
        double result = double.parse(numStr);
        print('✅ Found dotted number: ${dotMatch.group(1)} → $result');
        return result;
      }
      
      // Pattern 5: "50000" (số thuần ≥4 chữ số)
      RegExp plainPattern = RegExp(r'(\d{4,})');
      var plainMatch = plainPattern.firstMatch(text);
      if (plainMatch != null) {
        double result = double.parse(plainMatch.group(1)!);
        print('✅ Found plain number: ${plainMatch.group(1)} → $result');
        return result;
      }
      
      // Pattern 6: "50" (số ngắn <1000)
      RegExp shortPattern = RegExp(r'\b(\d{2,3})\b');
      var shortMatch = shortPattern.firstMatch(text);
      if (shortMatch != null) {
        double value = double.parse(shortMatch.group(1)!);
        // Nếu < 1000 thì nhân 1000
        double result = value < 1000 ? value * 1000 : value;
        print('✅ Found short number: ${shortMatch.group(1)} → $result');
        return result;
      }
      
      print('❌ No amount pattern matched');
      return null;
    } catch (e) {
      print('❌ Error extracting amount: $e');
      return null;
    }
  }
  
  // Extract note
  static String _extractNote(String text) {
    // Remove số tiền khỏi text
    String note = text
        .replaceAll(RegExp(r'\d+(?:\.\d+)?\s*[kmb]'), '')
        .replaceAll(RegExp(r'\d{1,3}(?:\.\d{3})+'), '')
        .replaceAll(RegExp(r'\d{4,}'), '')
        .replaceAll(RegExp(r'đồng|vnd|đ|nghìn|ngàn|triệu|tỷ|k|m|b'), '');
    
    // Remove keywords thừa
    note = note
        .replaceAll(RegExp(r'\b(chi|mua|trả|nhận|thu|tiêu)\b'), '')
        .replaceAll(RegExp(r'\b(tiền|phí)\b'), '')
        .trim();
    
    // Capitalize first letter
    if (note.isNotEmpty) {
      note = note[0].toUpperCase() + note.substring(1);
    }
    
    return note.isEmpty ? 'Voice transaction' : note;
  }
  
  // Suggest category
  static String _suggestCategory(String text, String type) {
    if (type == 'income') {
      if (text.contains('lương')) return 'Salary';
      if (text.contains('thưởng')) return 'Bonus';
      if (text.contains('freelance')) return 'Freelance';
      return 'Other Income';
    }
    
    // Expense categories
    if (text.contains('ăn') || 
        text.contains('cà phê') ||
        text.contains('coffee') ||
        text.contains('cơm') ||
        text.contains('quán')) {
      return 'Food & Dining';
    }
    
    if (text.contains('grab') || 
        text.contains('xe') ||
        text.contains('taxi') ||
        text.contains('xăng') ||
        text.contains('gửi xe')) {
      return 'Transportation';
    }
    
    if (text.contains('điện') || 
        text.contains('nước') ||
        text.contains('phòng') ||
        text.contains('trọ') ||
        text.contains('gas')) {
      return 'Housing';
    }
    
    if (text.contains('mua') || 
        text.contains('shopping') ||
        text.contains('quần áo') ||
        text.contains('giày')) {
      return 'Shopping';
    }
    
    if (text.contains('gym') || 
        text.contains('thể thao') ||
        text.contains('bóng')) {
      return 'Gym & Sports';
    }
    
    if (text.contains('học') || 
        text.contains('sách') ||
        text.contains('khóa')) {
      return 'Education';
    }
    
    if (text.contains('phim') || 
        text.contains('game') ||
        text.contains('vui chơi')) {
      return 'Entertainment';
    }
    
    if (text.contains('thuốc') || 
        text.contains('khám') ||
        text.contains('bệnh viện')) {
      return 'Healthcare';
    }
    
    return 'Other Expenses';
  }
}