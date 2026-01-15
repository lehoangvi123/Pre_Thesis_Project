// lib/service/voice_parser_service.dart
// COPY FILE NÀY VÀO: lib/service/voice_parser_service.dart

class VoiceParserService {
  // Parse voice text → transaction data
  static Map<String, dynamic>? parseVoiceInput(String voiceText) {
    try {
      String text = voiceText.toLowerCase().trim();
      
      // 1. Detect type (thu/chi)
      String type = _detectType(text);
      
      // 2. Extract amount (số tiền)
      double? amount = _extractAmount(text);
      if (amount == null) return null;
      
      // 3. Extract note
      String note = _extractNote(text);
      
      // 4. Suggest category
      String category = _suggestCategory(text, type);
      
      return {
        'type': type,
        'amount': amount,
        'category': category,
        'note': note,
        'confidence': 0.85,
      };
    } catch (e) {
      print('Parse error: $e');
      return null;
    }
  }
  
  // Detect income/expense
  static String _detectType(String text) {
    // Income keywords
    if (text.contains('nhận') || 
        text.contains('lương') || 
        text.contains('thu')) {
      return 'income';
    }
    return 'expense'; // Default
  }
  
  // Extract amount
  static double? _extractAmount(String text) {
    // Replace Vietnamese
    text = text
        .replaceAll('nghìn', 'k')
        .replaceAll('ngàn', 'k')
        .replaceAll('triệu', 'm');
    
    // Pattern 1: "35k"
    RegExp kPattern = RegExp(r'(\d+(?:\.\d+)?)\s*k');
    var kMatch = kPattern.firstMatch(text);
    if (kMatch != null) {
      return double.parse(kMatch.group(1)!) * 1000;
    }
    
    // Pattern 2: "5m"
    RegExp mPattern = RegExp(r'(\d+(?:\.\d+)?)\s*m');
    var mMatch = mPattern.firstMatch(text);
    if (mMatch != null) {
      return double.parse(mMatch.group(1)!) * 1000000;
    }
    
    // Pattern 3: "50000"
    RegExp numPattern = RegExp(r'(\d{4,})');
    var numMatch = numPattern.firstMatch(text);
    if (numMatch != null) {
      return double.parse(numMatch.group(1)!);
    }
    
    return null;
  }
  
  // Extract note
  static String _extractNote(String text) {
    String note = text
        .replaceAll(RegExp(r'\d+(?:\.\d+)?\s*[km]'), '')
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'chi|mua|trả|nhận'), '')
        .trim();
    
    if (note.isEmpty) return 'Voice transaction';
    return note[0].toUpperCase() + note.substring(1);
  }
  
  // Suggest category
  static String _suggestCategory(String text, String type) {
    if (type == 'income') {
      if (text.contains('lương')) return 'Salary';
      return 'Other Income';
    }
    
    // Expense categories
    if (text.contains('ăn') || text.contains('cà phê')) {
      return 'Food & Dining';
    }
    if (text.contains('grab') || text.contains('xe')) {
      return 'Transportation';
    }
    if (text.contains('điện') || text.contains('nước')) {
      return 'Housing';
    }
    if (text.contains('mua')) {
      return 'Shopping';
    }
    
    return 'Other Expenses';
  }
}