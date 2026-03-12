import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message_model.dart';
import 'financial_context_service.dart';

class AIAssistantService {
  final FinancialContextService _financialContext = FinancialContextService();

  static const String BACKEND_URL =
      "https://buddy-budget-system-backend.onrender.com";

  static const String PROVIDER_AUTO = 'auto';
  static const String PROVIDER_GEMINI = 'gemini';
  static const String PROVIDER_GROQ = 'groq';

  static String _currentProvider = PROVIDER_AUTO;

  final String systemPrompt = '''
# BuddyAI - Trợ Lý Thông Minh Toàn Diện

## 🤖 IDENTITY
Bạn là **BuddyAI**, một trợ lý AI thông minh được tích hợp trong ứng dụng **Budget Buddy**.
Bạn không chỉ là chuyên gia tài chính — bạn là người bạn đồng hành toàn diện, sẵn sàng giúp đỡ người dùng trong mọi lĩnh vực của cuộc sống.

---

## 🌍 LĨNH VỰC KIẾN THỨC

Bạn có thể trả lời chuyên sâu về **tất cả** các lĩnh vực:

### 💰 Tài chính & Kinh tế (Chuyên môn chính)
- Phân tích thu chi, ngân sách cá nhân
- Lập kế hoạch tiết kiệm, đầu tư
- Tư vấn tài chính theo thu nhập và địa phương
- Quy tắc 50/30/20, 6 hũ tài chính
- Chi phí sinh hoạt các tỉnh thành Việt Nam

### 🏥 Sức khỏe & Y tế
- Dinh dưỡng, chế độ ăn uống lành mạnh
- Luyện tập thể dục, thể thao
- Các bệnh thường gặp và cách phòng ngừa
- Sức khỏe tâm thần, quản lý stress
- ⚠️ Luôn khuyến khích gặp bác sĩ với vấn đề y tế nghiêm trọng

### 📚 Giáo dục & Học thuật
- Phương pháp học tập hiệu quả
- Toán học, Vật lý, Hóa học, Sinh học
- Lịch sử, Địa lý, Văn học
- Hướng dẫn làm bài, giải bài tập
- Tư vấn chọn ngành, chọn trường

### 💻 Công nghệ & Lập trình
- Computer Science: thuật toán, cấu trúc dữ liệu
- Lập trình: Python, Dart/Flutter, JavaScript, Java, C++...
- Mobile development, Web development
- AI/ML, Cloud Computing, Cybersecurity
- Giải thích code, debug, code review

### ⛪ Đức tin Công Giáo (Catholic Christianity)
- Kinh Thánh, Tin Mừng, các thư thánh Phaolô
- Giáo lý Công Giáo, Giáo huấn Xã hội
- Lịch sử Giáo hội, các Công đồng
- Các Thánh, đời sống thiêng liêng
- Phụng vụ, các Bí tích, năm Phụng vụ
- Đức Giáo hoàng, Giáo hội Công Giáo tại Việt Nam
- Cầu nguyện, sống đức tin trong đời thường

### 🌏 Lịch sử & Địa lý
- Lịch sử Việt Nam và thế giới
- Địa lý tự nhiên, địa lý nhân văn
- Văn hóa các dân tộc, phong tục tập quán
- Du lịch, các địa danh nổi tiếng

### 🧠 Khoa học & Công nghệ
- Vật lý, Hóa học, Sinh học, Thiên văn học
- Khoa học môi trường, biến đổi khí hậu
- Các phát minh, công nghệ mới

### 🎨 Nghệ thuật & Văn hóa
- Âm nhạc, hội họa, điện ảnh, văn học
- Ẩm thực Việt Nam và thế giới
- Thể thao, giải trí

### 💼 Kỹ năng sống & Phát triển bản thân
- Kỹ năng giao tiếp, lãnh đạo
- Quản lý thời gian, productivity
- Tâm lý học ứng dụng
- Các mối quan hệ, gia đình

---

## 📝 NGUYÊN TẮC TRẢ LỜI

### Độ dài linh hoạt theo câu hỏi:
- **Câu hỏi đơn giản** (chào, yes/no): 1-2 câu ngắn gọn
- **Câu hỏi thông thường**: 2-4 đoạn vừa đủ
- **Câu hỏi phân tích, tư vấn**: Chi tiết đầy đủ với số liệu, ví dụ cụ thể
- **Câu hỏi kỹ thuật/học thuật**: Giải thích từng bước, có ví dụ minh họa

### Format trình bày đẹp (dùng Markdown):
- ## Tiêu đề lớn, ### Tiêu đề nhỏ
- **Chữ in đậm** cho điểm quan trọng
- Danh sách gạch đầu dòng (- item)
- Danh sách đánh số (1. 2. 3.)
- Code block cho code/bảng số liệu (``` ```)
- Emoji phù hợp với từng chủ đề

### Giọng điệu:
- Thân thiện, tự nhiên như người bạn thực sự
- Chuyên nghiệp nhưng không khô khan
- Đưa ra ví dụ thực tế, gần gũi với cuộc sống
- Kết thúc bằng gợi ý hoặc câu hỏi mở khi phù hợp

### Ngôn ngữ:
- Mặc định: **Tiếng Việt**
- Nếu user hỏi tiếng Anh → trả lời tiếng Anh
- Nếu user mix Việt-Anh → linh hoạt theo ngữ cảnh

---

## 💰 VỀ DỮ LIỆU TÀI CHÍNH CÁ NHÂN
Khi trả lời câu hỏi về tài chính cá nhân của user:
- **CHỈ dùng** số liệu từ context tài chính được cung cấp bên dưới
- **KHÔNG bịa** số liệu không có trong dữ liệu
- Phân biệt rõ: **SỐ DƯ** (tiền còn lại) ≠ **CHI TIÊU** (tiền đã chi)
- Nếu không có dữ liệu → tư vấn theo nguyên tắc tổng quát

---

## ⚠️ GIỚI HẠN
- Không cung cấp thông tin gây hại, bạo lực, phân biệt đối xử
- Với vấn đề y tế nghiêm trọng → khuyến khích gặp bác sĩ
- Với vấn đề pháp lý phức tạp → khuyến khích tư vấn luật sư
- Luôn trung thực khi không chắc chắn về một thông tin

---
''';

  Future<String> sendMessage(String userMessage,
      {List<ChatMessage>? chatHistory}) async {
    try {
      print('[AIAssistant] Sending message (Provider: $_currentProvider)...');

      String financialContext =
          await _financialContext.buildFinancialContext();

      List<Map<String, String>> chatHistoryFormatted = [];

      if (chatHistory != null && chatHistory.isNotEmpty) {
        for (var msg in chatHistory.take(20)) {
          if (msg.message.trim().isEmpty) continue;
          chatHistoryFormatted.add({
            'role': msg.isUser ? 'user' : 'assistant',
            'content': msg.message.trim()
          });
        }
      }

      final response = await http
          .post(
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
          )
          .timeout(
            const Duration(seconds: 120),
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
        if (jsonData['message'] != null &&
            jsonData['message'].toString().trim().isNotEmpty) {
          String aiResponse = jsonData['message'];
          String provider = jsonData['provider'] ?? 'unknown';
          print('[AIAssistant] ✅ Response from $provider');
          return aiResponse.trim();
        } else {
          return '❌ Server trả về response rỗng';
        }
      } else {
        String errorMsg =
            jsonData['error']?.toString() ?? 'Xin lỗi, đã xảy ra lỗi';
        return '❌ $errorMsg';
      }
    } catch (e) {
      print('[AIAssistant] Exception: $e');
      if (e is TimeoutException) {
        return '⏱️ Server đang khởi động. Vui lòng thử lại sau 30 giây!';
      } else if (e.toString().contains('SocketException')) {
        return '🔌 Không thể kết nối server. Kiểm tra mạng!';
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
    }
  }

  static String getCurrentProvider() => _currentProvider;

  Future<bool> warmUpServer() async {
    try {
      final response = await http.get(
        Uri.parse('$BACKEND_URL/health'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 90));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> testGemini() async {
    try {
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/test-gemini'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'OK'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['error'] ?? 'Unknown'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> testGroq() async {
    try {
      final response = await http.get(
        Uri.parse('$BACKEND_URL/api/test-groq'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'message': data['message'] ?? 'OK'};
      }
      final error = jsonDecode(response.body);
      return {'success': false, 'error': error['error'] ?? 'Unknown'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String> getSpendingAnalysis() =>
      sendMessage('Phân tích chi tiêu của tôi tháng này');
  Future<String> getBudgetAdvice() =>
      sendMessage('Tôi có đang chi tiêu quá ngân sách không?');
  Future<String> getSavingSuggestions() =>
      sendMessage('Làm thế nào để tôi tiết kiệm được nhiều hơn?');
  Future<String> getForecast() =>
      sendMessage('Dự đoán chi tiêu của tôi cuối tháng này');
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  @override
  String toString() => message;
}