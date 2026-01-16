// lib/service/ai_service.dart
// SIMPLIFIED VERSION - Không crash khi không có API key

import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // TODO: Thay bằng API key của bạn từ https://makersuite.google.com/app/apikey
  static const String GEMINI_API_KEY = 'YOUR_API_KEY_HERE';
  
  // Analyze with AI (OPTIONAL - không bắt buộc)
  static Future<Map<String, dynamic>?> analyzeVoice(String voiceText) async {
    // Nếu chưa có API key, return null ngay (không log gì cả)
    if (GEMINI_API_KEY == 'YOUR_API_KEY_HERE' || GEMINI_API_KEY.isEmpty) {
      // Im lặng, không in gì để tránh spam console
      return null;
    }
    
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GEMINI_API_KEY'
      );
      
      final prompt = '''
Phân tích câu: "$voiceText"

Trả về JSON (không thêm markdown):
{
  "type": "expense" hoặc "income",
  "amount": số tiền VNĐ (số nguyên),
  "category": danh mục phù hợp,
  "note": ghi chú ngắn
}

Lưu ý:
- "10 tỷ" = 10000000000
- "5 triệu" = 5000000
- "35 nghìn" = 35000
''';
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 200,
          }
        }),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        
        if (text != null) {
          // Clean response
          final cleaned = text
              .replaceAll('```json', '')
              .replaceAll('```', '')
              .trim();
          
          final result = jsonDecode(cleaned);
          print('🤖 AI Analysis: $result');
          return result;
        }
      }
    } catch (e) {
      // Silent fail - không log để tránh spam
      // print('AI error: $e');
    }
    
    return null;
  }
}
