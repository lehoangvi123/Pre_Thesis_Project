// lib/service/ai_service.dart
// COPY FILE NÀY VÀO: lib/service/ai_service.dart
// OPTIONAL: Chỉ cần nếu muốn dùng AI

import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  // TODO: Thay bằng API key của bạn từ https://makersuite.google.com/app/apikey
  static const String GEMINI_API_KEY = 'YOUR_API_KEY_HERE';
  
  // Analyze with AI (OPTIONAL)
  static Future<Map<String, dynamic>?> analyzeVoice(String voiceText) async {
    // Nếu chưa có API key, return null
    if (GEMINI_API_KEY == 'YOUR_API_KEY_HERE') {
      print('⚠️ No API key - skipping AI analysis');
      return null;
    }
    
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$GEMINI_API_KEY'
      );
      
      final prompt = '''
Phân tích câu: "$voiceText"
Trả về JSON:
{
  "type": "expense" hoặc "income",
  "amount": số tiền VNĐ,
  "category": danh mục phù hợp,
  "note": ghi chú ngắn
}
Chỉ trả về JSON, không thêm gì khác.
''';
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}],
          'generationConfig': {'temperature': 0.2}
        }),
      ).timeout(Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];
        final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
        return jsonDecode(cleaned);
      }
    } catch (e) {
      print('AI error: $e');
    }
    
    return null;
  }
}