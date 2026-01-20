import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import 'financial_context_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIAssistantService {
  final FinancialContextService _financialContext = FinancialContextService();
  
  // ✅ CHATGPT API KEY - Lấy từ file .env
  static String get OPENAI_API_KEY => 
    dotenv.env['OPENAI_API_KEY'] ?? '';
  
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
  
  // ✅ API URL của OpenAI
  static const String API_URL = 'https://api.openai.com/v1/chat/completions';

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
      // Kiểm tra API key
      if (OPENAI_API_KEY.isEmpty) {
        return 'Lỗi: API key chưa được cấu hình. Vui lòng thêm OPENAI_API_KEY vào file .env! 🔑';
      }

      // Get user's financial context
      String financialContext = await _financialContext.buildFinancialContext();

      // Build messages array for ChatGPT
      List<Map<String, String>> messages = [
        {
          'role': 'system',
          'content': '$systemPrompt\n\n$financialContext'
        }
      ];

      // Add conversation history
      if (chatHistory != null && chatHistory.isNotEmpty) {
        for (var msg in chatHistory.take(10)) {
          messages.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.message
          });
        }
      }

      // Add current user message
      messages.add({
        'role': 'user',
        'content': userMessage
      });

      // Call OpenAI API
      final response = await http.post(
        Uri.parse(API_URL),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $OPENAI_API_KEY',
        },
        body: jsonEncode({
          'model': currentModel,
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'];
        return aiResponse.trim();
      } else if (response.statusCode == 401) {
        return 'Lỗi: API key không hợp lệ. Vui lòng kiểm tra lại! 🔑';
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return 'Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau! 😅';
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      return 'Đã xảy ra lỗi khi kết nối với AI. Vui lòng kiểm tra kết nối mạng! 🔌';
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