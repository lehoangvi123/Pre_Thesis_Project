import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import 'financial_context_service.dart';

class AIAssistantService {
  final FinancialContextService _financialContext = FinancialContextService();
  
  // IMPORTANT: Replace with your actual API key
  static const String GEMINI_API_KEY = 'YOUR_GEMINI_API_KEY';
  static const String GEMINI_API_URL = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

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
      // Get user's financial context
      String financialContext = await _financialContext.buildFinancialContext();

      // Build conversation history
      String conversationHistory = _buildConversationHistory(chatHistory);

      // Construct prompt
      String fullPrompt = '''
$systemPrompt

$financialContext

Previous conversation:
$conversationHistory

User: $userMessage

BuddyAI:
''';

      // Call Gemini API
      final response = await http.post(
        Uri.parse('$GEMINI_API_URL?key=$GEMINI_API_KEY'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['candidates'][0]['content']['parts'][0]['text'];
        return aiResponse.trim();
      } else {
        print('API Error: ${response.statusCode}');
        return 'Xin lỗi, tôi đang gặp sự cố kỹ thuật. Vui lòng thử lại sau! 😅';
      }
    } catch (e) {
      print('Error in sendMessage: $e');
      return 'Đã xảy ra lỗi khi kết nối với AI. Vui lòng kiểm tra kết nối mạng! 🔌';
    }
  }

  // Build conversation history string
  String _buildConversationHistory(List<ChatMessage>? messages) {
    if (messages == null || messages.isEmpty) return 'No previous conversation.';
    
    return messages
        .take(10) // Only last 10 messages to avoid token limit
        .map((msg) => '${msg.isUser ? "User" : "BuddyAI"}: ${msg.message}')
        .join('\n');
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