import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import 'financial_context_service.dart';

class AIAssistantService {
  final FinancialContextService _financialContext = FinancialContextService();
  
  // ✅ URL BACKEND
  static const String BACKEND_URL = "https://buddy-budget-system-backend.onrender.com";
  
  // ✅ GROQ MODELS - HOÀN TOÀN MIỄN PHÍ! 🎉
  static const List<String> MODELS = [  
    'llama-3.3-70b-versatile',       // Llama 3.3 70B - Mạnh nhất (khuyến nghị) ✅
    'mixtral-8x7b-32768',            // Mixtral 8x7B - Nhanh & tốt ✅
    'llama-3.1-8b-instant',          // Llama 3.1 8B - Cực nhanh ✅
  ];
  
  // Model hiện tại
  static int _currentModelIndex = 0;
  static String get currentModel => MODELS[_currentModelIndex]; 

  // System prompt for AI personality
  final String systemPrompt = '''
You are a friendly and professional Vietnamese financial advisor AI assistant named "BuddyAI" 
integrated into a personal expense tracking app called "Budget Buddy". 

Your role:
- Help users understand their spending habits
- Provide personalized financial advice
- Answer questions about their transactions, budget, and savings
- Give encouragement and motivation for financial goals
- Warn about overspending or risky financial behavior
- Suggest ways to save money

Guidelines:
- Always respond in Vietnamese (unless user asks in English)
- Be conversational and friendly, not robotic
- Use emojis occasionally (💰 💡 ✅ ⚠️ 📊)
- Keep responses concise (2-4 sentences usually)
- When giving advice, provide specific numbers from their actual data
- Ask clarifying questions if needed
- Never make up financial data - only use provided context

Response format:
- Start with a greeting or acknowledgment
- Provide analysis or answer
- End with a question or action suggestion (optional)
''';

  // Send message to AI and get response
  Future<String> sendMessage(String userMessage, {List<ChatMessage>? chatHistory}) async {
    try {
      print('[AIAssistant] Sending message to backend (Groq)...');
      print('[AIAssistant] Message: ${userMessage.substring(0, userMessage.length > 50 ? 50 : userMessage.length)}...');
      
      // Get user's financial context
      String financialContext = await _financialContext.buildFinancialContext();

      // Build chat history for Groq format (OpenAI-compatible)
      List<Map<String, String>> chatHistoryFormatted = [];
      
      if (chatHistory != null && chatHistory.isNotEmpty) {
        for (var msg in chatHistory.take(10)) {
          if (msg.message.trim().isEmpty) {
            continue;
          }
          
          chatHistoryFormatted.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.message.trim()
          });
        }
      }

      print('[AIAssistant] Chat history: ${chatHistoryFormatted.length} messages');

      // ✅ GỌI BACKEND VỚI GROQ API
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
          'model': currentModel,
        }),
      ).timeout(
        Duration(seconds: 120),
        onTimeout: () {
          throw TimeoutException('Server đang khởi động');
        },
      );

      print('[AIAssistant] Response status: ${response.statusCode}');

      // ✅ Kiểm tra content type
      final contentType = response.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        print('[AIAssistant] ❌ Server trả về HTML thay vì JSON!');
        
        if (response.body.contains('error') || response.body.contains('Error')) {
          return '❌ Server gặp lỗi. Vui lòng kiểm tra:\n\n'
                 '1. GROQ_API_KEY đã được set chưa?\n'
                 '2. API key có hợp lệ không?\n'
                 '3. Lấy key miễn phí tại: https://console.groq.com\n'
                 '4. Kiểm tra logs tại Render dashboard';
        }
        
        return '❌ Server trả về định dạng không hợp lệ.\n\n'
               'Vui lòng kiểm tra backend logs!';
      }

      // ✅ Parse JSON response
      dynamic jsonData;
      try {
        jsonData = jsonDecode(response.body);
      } catch (e) {
        print('[AIAssistant] ❌ Lỗi parse JSON: $e');
        return '❌ Không thể đọc phản hồi từ server.';
      }

      // ✅ Xử lý response thành công
      if (response.statusCode == 200) {
        if (jsonData['message'] != null && jsonData['message'].toString().trim().isNotEmpty) {
          String aiResponse = jsonData['message'];
          
          // Log usage
          if (jsonData['usage'] != null) {
            print('[AIAssistant] Token usage: ${jsonData['usage']}');
          }
          
          return aiResponse.trim();
        } else {
          return '❌ Server trả về response rỗng';
        }
      } 
      // ✅ Xử lý error response
      else {
        print('[AIAssistant] Error: ${response.statusCode} - $jsonData');
        
        String errorMsg = 'Xin lỗi, đã xảy ra lỗi';
        
        if (jsonData['error'] != null) {
          errorMsg = jsonData['error'].toString();
          
          // Hướng dẫn fix
          if (errorMsg.contains('API key')) {
            errorMsg += '\n\n💡 Lấy API key MIỄN PHÍ tại:\n'
                       'https://console.groq.com/keys\n\n'
                       'Không cần credit card! 🎉';
          } else if (errorMsg.contains('429')) {
            errorMsg += '\n\n⏳ Đã hết quota miễn phí.\n'
                       'Đợi 1 phút hoặc tạo account mới.';
          }
        }
        
        return '❌ $errorMsg';
      }
    } catch (e) {
      print('[AIAssistant] Exception: $e');
      
      if (e is TimeoutException) {
        return '⏱️ Server đang khởi động (60-120s).\n\n'
               '💡 Mở browser: https://buddy-budget-system-backend.onrender.com/health';
      } else if (e.toString().contains('SocketException')) {
        return '🔌 Không thể kết nối với server.\n\n'
               'Kiểm tra kết nối mạng!';
      } else {
        return '❌ Lỗi: ${e.toString()}';
      }
    }
  }

  // Warm up server
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
          print('[AIAssistant] Groq configured: ${data['groqConfigured']}');
          
          if (data['groqConfigured'] == false) {
            print('[AIAssistant] ⚠️ GROQ_API_KEY chưa được cấu hình!');
          }
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

  // Test connection
  Future<Map<String, dynamic>> testConnection() async {
    try {
      print('[AIAssistant] 🧪 Testing Groq connection...');
      
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/test-groq'),
        headers: {'Accept': 'application/json'},
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('[AIAssistant] ✅ Groq test successful!');
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

  // Switch model
  static void switchModel(int index) {
    if (index >= 0 && index < MODELS.length) {
      _currentModelIndex = index;
      print('[AIAssistant] Switched to model: ${MODELS[index]}');
    }
  }

  static String getCurrentModelName() => MODELS[_currentModelIndex];
  static List<String> getAvailableModels() => MODELS;

  // Quick actions
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