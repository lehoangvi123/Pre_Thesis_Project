import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import 'financial_context_service.dart';

class AIAssistantService {
  final FinancialContextService _financialContext = FinancialContextService();
  
  // ✅ URL BACKEND - Đổi sang backend của bạn
  static const String BACKEND_URL = "https://buddy-budget-system-backend.onrender.com";
  
  // ✅ MODELS ChatGPT - Từ rẻ đến đắt 
  static const List<String> MODELS = [  
    'gpt-4o-mini',        // Rẻ nhất, nhanh nhất (khuyến nghị cho chatbot)
    'gpt-4o',             // Cân bằng giá/chất lượng
    'gpt-4-turbo',        // Mạnh hơn
    'gpt-3.5-turbo',      // Legacy, rẻ
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
      print('[AIAssistant] Sending message to backend...');
      
      // Get user's financial context
      String financialContext = await _financialContext.buildFinancialContext();

      // Build chat history
      List<Map<String, String>> chatHistoryFormatted = [];
      
      if (chatHistory != null && chatHistory.isNotEmpty) {
        for (var msg in chatHistory.take(10)) {
          // Validate message has content
          if (msg.message.trim().isNotEmpty) {
            chatHistoryFormatted.add({
              'role': msg.isUser ? 'user' : 'assistant',
              'content': msg.message
            });
          }
        }
      }

      // ✅ GỌI BACKEND THAY VÌ GỌI TRỰC TIẾP OPENAI
      final response = await http.post(
        Uri.parse('$BACKEND_URL/api/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': userMessage,
          'chatHistory': chatHistoryFormatted,
          'financialContext': '$systemPrompt\n\n$financialContext',
          'model': 'gpt-3.5-turbo',  // Chỉ định model cho backend
        }),
      ).timeout(
        Duration(seconds: 120),  // Tăng timeout lên 120s cho cold start
        onTimeout: () {
          throw Exception('timeout');
        },
      );

      print('[AIAssistant] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['message'];
        return aiResponse.trim();
      } else {
        print('[AIAssistant] Error: ${response.statusCode} - ${response.body}');
        final error = jsonDecode(response.body);
        return 'Xin lỗi, tôi đang gặp sự cố: ${error['error'] ?? 'Unknown error'} 😅';
      }
    } catch (e) {
      print('[AIAssistant] Exception: $e');
      
      // Phân biệt lỗi để thông báo rõ hơn
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection refused')) {
        return '🔌 Không thể kết nối với server. Vui lòng kiểm tra kết nối mạng!';
      } else if (e.toString().contains('timeout')) {
        return '⏱️ Server đang khởi động (lần đầu mất 60-120s).\n\n💡 Mẹo: Mở browser vào:\nhttps://buddy-budget-system-backend.onrender.com/health\n\nĐợi thấy {"status":"OK"} rồi quay lại chat!';
      } else {
        return 'Đã xảy ra lỗi: ${e.toString()}';
      }
    }
  }

  // Warm up server để tránh cold start
  Future<bool> warmUpServer() async {
    try {
      print('[AIAssistant] 🔥 Warming up server...');
      final response = await http.get(
        Uri.parse('$BACKEND_URL/health'),
      ).timeout(Duration(seconds: 90));
      
      if (response.statusCode == 200) {
        print('[AIAssistant] ✅ Server ready!');
        return true;
      }
      return false;
    } catch (e) {
      print('[AIAssistant] Warmup timeout');
      return false;
    }
  }

  // Switch model (optional - để user chọn model nếu cần)
  static void switchModel(int index) {
    if (index >= 0 && index < MODELS.length) {
      _currentModelIndex = index;
    }
  }

  // Quick actions for AI
  Future<String> getSpendingAnalysis() async {
    return await sendMessage('Phân tích chi tiêu của tôi tháng này');
  }

  Future<String> getBudgetAdvice() async {
    return await sendMessage('Tôi có đang chi tiêu quá ngân sách không?');
  }

  Future<String> getSavingSuggestions() async {
    return await sendMessage('Làm thế nào để tôi tiết kiệm được nhiều hơn?');
  }

  Future<String> getForecast() async {
    return await sendMessage('Dự đoán chi tiêu của tôi cuối tháng này');
  }
}