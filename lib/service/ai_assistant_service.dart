import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import 'financial_context_service.dart';

class AIAssistantService {
  final FinancialContextService _financialContext = FinancialContextService();
  
  static const String BACKEND_URL = "https://buddy-budget-system-backend.onrender.com";
  
  static const String PROVIDER_AUTO = 'auto';
  static const String PROVIDER_GEMINI = 'gemini';
  static const String PROVIDER_GROQ = 'groq';
  
  static String _currentProvider = PROVIDER_AUTO;
  
  final String systemPrompt = '''
BẠN LÀ AI:
- Tên: BuddyAI - Trợ lý tài chính thông minh
- Vai trò: Cố vấn tài chính cá nhân trong ứng dụng "Budget Buddy"
- Tính cách: Thân thiện, nhiệt tình, chuyên nghiệp

NHIỆM VỤ CHÍNH:
1. Phân tích chi tiêu và đưa ra nhận xét cụ thể
2. Tư vấn ngân sách và quản lý tiền bạc
3. Động viên người dùng tiết kiệm và đạt mục tiêu tài chính
4. Cảnh báo khi chi tiêu vượt mức
5. Gợi ý cách tiết kiệm thông minh

QUY TẮC TRẢ LỜI (QUAN TRỌNG):
✅ LUÔN LUÔN trả lời bằng TIẾNG VIỆT (trừ khi user hỏi bằng tiếng Anh)
✅ Ngắn gọn, súc tích (2-4 câu)
✅ Dùng emoji phù hợp: 💰 💡 ✅ ⚠️ 📊 🎯 👍 ❌
✅ Dựa vào DỮ LIỆU THỰC TẾ của user (đừng bịa số liệu)
✅ Đưa ra con số cụ thể khi phân tích
✅ Giọng điệu thân thiện như bạn bè, KHÔNG máy móc
✅ Kết thúc bằng câu hỏi hoặc gợi ý hành động (nếu phù hợp)

❌ TUYỆT ĐỐI KHÔNG:
- Trả lời dài dòng, lan man
- Sử dụng từ ngữ học thuật khó hiểu
- Bịa đặt số liệu tài chính
- Trả lời bằng tiếng Anh khi user hỏi tiếng Việt
- Nói chung chung, không cụ thể

MẪU TRẢ LỜI TốT:
User: "Chi tiêu tháng này thế nào?"
AI: "Tháng này bạn đã chi 5,2 triệu đồng, vượt ngân sách 700k đấy! 😅 Phần lớn là ăn uống (2,8tr) và mua sắm (1,5tr). Bạn có muốn mình gợi ý cách cắt giảm không?"

VÍ DỤ CỤ THỂ VỀ PHONG CÁCH:
- TỐT: "Tháng này bạn tiết kiệm được 2 triệu rồi đấy! 🎉 Giỏi quá!"
- TỆ: "Theo dữ liệu phân tích, khoản tiết kiệm của bạn trong tháng hiện tại đạt mức 2.000.000 VND."

LUÔN NHỚ: Bạn là BẠN BÈ tài chính, không phải ngân hàng hay kế toán viên!
''';

  // ✅ DEBUG: Print financial context
  Future<String> sendMessage(String userMessage, {List<ChatMessage>? chatHistory}) async {
    try {
      print('[AIAssistant] Sending message (Provider: $_currentProvider)...');
      
      // ✅ GET & PRINT CONTEXT
      String financialContext = await _financialContext.buildFinancialContext();
      
      print('═══════════════════════════════════════');
      print('📊 FINANCIAL CONTEXT SENT TO AI:');
      print('═══════════════════════════════════════');
      print(financialContext);
      print('═══════════════════════════════════════');

      List<Map<String, String>> chatHistoryFormatted = [];
      
      if (chatHistory != null && chatHistory.isNotEmpty) {
        for (var msg in chatHistory.take(10)) {
          if (msg.message.trim().isEmpty) continue;
          
          chatHistoryFormatted.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.message.trim()
          });
        }
      }

      final response = await http.post(
        Uri.parse('$BACKEND_URL/api/chat'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'message': userMessage.trim(),
          'chatHistory': chatHistoryFormatted,
          'financialContext': '$systemPrompt\n\n$financialContext',
          'provider': _currentProvider,
        }),
      ).timeout(
        Duration(seconds: 120),
        onTimeout: () {
          throw TimeoutException('Server đang khởi động');
        },
      );

      print('[AIAssistant] Response status: ${response.statusCode}');

      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        return '❌ Server trả về định dạng không hợp lệ';
      }

      dynamic jsonData;
      try {
        jsonData = jsonDecode(response.body);
      } catch (e) {
        return '❌ Không thể đọc phản hồi từ server';
      }

      if (response.statusCode == 200) {
        if (jsonData['message'] != null && jsonData['message'].toString().trim().isNotEmpty) {
          String aiResponse = jsonData['message'];
          String provider = jsonData['provider'] ?? 'unknown';
          
          print('[AIAssistant] ✅ Response from $provider');
          
          return aiResponse.trim();
        } else {
          return '❌ Server trả về response rỗng';
        }
      } else {
        String errorMsg = jsonData['error']?.toString() ?? 'Xin lỗi, đã xảy ra lỗi';
        
        if (errorMsg.contains('API key')) {
          errorMsg += '\n\n💡 Vào Render Dashboard để set API key:\n'
                     '- Gemini: https://aistudio.google.com/apikey\n'
                     '- Groq: https://console.groq.com/keys (MIỄN PHÍ)';
        }
        
        return '❌ $errorMsg';
      }
    } catch (e) {
      print('[AIAssistant] Exception: $e');
      
      if (e is TimeoutException) {
        return '⏱️ Server đang khởi động (60-120s).\n\n'
               'Mở: https://buddy-budget-system-backend.onrender.com/health';
      } else if (e.toString().contains('SocketException')) {
        return '🔌 Không thể kết nối với server';
      } else {
        return '❌ Lỗi: ${e.toString()}';
      }
    }
  }

  static void setProvider(String provider) {
    if (provider == PROVIDER_AUTO || 
        provider == PROVIDER_GEMINI || 
        provider == PROVIDER_GROQ) {
      _currentProvider = provider;
      print('[AIAssistant] Switched to provider: $provider');
    }
  }

  static String getCurrentProvider() => _currentProvider;

  Future<bool> warmUpServer() async {
    try {
      print('[AIAssistant] 🔥 Warming up server...');
      final response = await http.get(
        Uri.parse('$BACKEND_URL/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 90));
      
      if (response.statusCode == 200) {
        print('[AIAssistant] ✅ Server ready!');
        
        try {
          final data = jsonDecode(response.body);
          print('[AIAssistant] Gemini: ${data['geminiConfigured']}');
          print('[AIAssistant] Groq: ${data['groqConfigured']}');
          print('[AIAssistant] Mode: ${data['mode']}');
        } catch (e) {
          print('[AIAssistant] Could not parse health check');
        }
        
        return true;
      }
      return false;
    } catch (e) {
      print('[AIAssistant] ⚠️ Warmup timeout');
      return false;
    }
  }

  Future<Map<String, dynamic>> testGemini() async {
    try {
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/test-gemini'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OK',
          'testResponse': data['testResponse'] ?? '',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<Map<String, dynamic>> testGroq() async {
    try {
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/test-groq'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'OK',
          'testResponse': data['testResponse'] ?? '',
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          'success': false,
          'error': error['error'] ?? 'Unknown error',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  Future<String> getSpendingAnalysis() => sendMessage('Phân tích chi tiêu của tôi tháng này');
  Future<String> getBudgetAdvice() => sendMessage('Tôi có đang chi tiêu quá ngân sách không?');
  Future<String> getSavingSuggestions() => sendMessage('Làm thế nào để tôi tiết kiệm được nhiều hơn?');
  Future<String> getForecast() => sendMessage('Dự đoán chi tiêu của tôi cuối tháng này');
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}