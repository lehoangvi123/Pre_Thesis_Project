import 'dart:io';
import 'dart:convert';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class OCRService {
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();

  // ✅ 1. Chụp ảnh và OCR
  Future<Map<String, dynamic>> scanReceipt({bool fromCamera = true}) async {
    try {
      // Chụp ảnh
      final XFile? image = await _picker.pickImage(
        source: fromCamera ? ImageSource.camera : ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      
      if (image == null) {
        return {'success': false, 'error': 'Người dùng hủy chụp ảnh'};
      }

      print('[OCR] 📸 Đã chụp ảnh: ${image.path}');

      // OCR text từ ảnh
      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String extractedText = recognizedText.text;
      
      print('[OCR] 📄 Text trích xuất được:');
      print('═══════════════════════════════════');
      print(extractedText);
      print('═══════════════════════════════════');

      if (extractedText.isEmpty) {
        return {
          'success': false,
          'error': 'Không phát hiện được text trên ảnh. Thử chụp lại với ánh sáng tốt hơn.'
        };
      }

      // Parse với AI
      print('[OCR] 🤖 Đang parse với AI...');
      Map<String, dynamic> parsed = await _parseWithGroqAI(extractedText);
      
      if (parsed.isEmpty) {
        // Fallback: Parse đơn giản với regex
        print('[OCR] ⚠️ AI parse thất bại, dùng regex fallback');
        parsed = _parseWithRegex(extractedText);
      }
      
      parsed['success'] = true;
      parsed['raw_text'] = extractedText;
      parsed['image_path'] = image.path;
      
      return parsed;
      
    } catch (e, stackTrace) {
      print('[OCR] ❌ Error: $e');
      print('[OCR] Stack trace: $stackTrace');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ✅ 2. Parse text với GROQ AI
  Future<Map<String, dynamic>> _parseWithGroqAI(String text) async {
    try {
      // TODO: Replace với GROQ API key của bạn
      const String GROQ_API_KEY = 'gsk_YOUR_KEY_HERE';
      
      if (GROQ_API_KEY == 'gsk_YOUR_KEY_HERE') {
        print('[OCR] ⚠️ Chưa có GROQ API key, dùng regex fallback');
        return {};
      }

      String prompt = '''
Bạn là AI chuyên phân tích hóa đơn Việt Nam.

Phân tích text hóa đơn sau và trích xuất thông tin:

$text

Trả về CHÍNH XÁC format JSON này (KHÔNG có markdown, KHÔNG có text khác):
{
  "store_name": "tên cửa hàng hoặc địa điểm (nếu có)",
  "total_amount": số tiền tổng (chỉ số, VD: 50000),
  "items": [
    {"name": "tên món", "price": giá (số)}
  ],
  "category": "Food" hoặc "Shopping" hoặc "Transport" hoặc "Entertainment" hoặc "Other",
  "confidence": 0.0 đến 1.0
}

QUY TẮC:
- Nếu không tìm thấy thông tin, để null
- total_amount là số tiền TỔNG lớn nhất tìm được
- items chỉ list nếu tìm được rõ ràng, nếu không để []
- category dựa vào context (food, shopping, transport...)
- CHỈ trả về JSON, không có text giải thích
''';

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Authorization': 'Bearer $GROQ_API_KEY',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'Bạn là AI phân tích hóa đơn. CHỈ trả về JSON, không có text khác.'
            },
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.1,
          'max_tokens': 500,
        }),
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String aiResponse = data['choices'][0]['message']['content'].trim();
        
        print('[OCR] 🤖 AI Response:');
        print(aiResponse);
        
        // Remove markdown nếu có
        aiResponse = aiResponse.replaceAll('```json', '').replaceAll('```', '').trim();
        
        // Parse JSON
        try {
          Map<String, dynamic> parsed = jsonDecode(aiResponse);
          print('[OCR] ✅ Parse thành công!');
          return parsed;
        } catch (e) {
          print('[OCR] ❌ JSON parse error: $e');
          return {};
        }
      } else {
        print('[OCR] ❌ API Error: ${response.statusCode} - ${response.body}');
        return {};
      }
      
    } catch (e) {
      print('[OCR] ❌ AI Parse Error: $e');
      return {};
    }
  }

  // ✅ 3. Fallback: Parse đơn giản với Regex (nếu AI fail)
  Map<String, dynamic> _parseWithRegex(String text) {
    print('[OCR] 🔧 Parsing với regex...');
    
    Map<String, dynamic> result = {
      'store_name': null,
      'total_amount': null,
      'items': [],
      'category': 'Other',
      'confidence': 0.5,
    };

    // Tìm số tiền (VD: 50.000, 50,000, 50000)
    List<double> amounts = [];
    RegExp amountRegex = RegExp(r'(\d{1,3}[.,]?\d{3}[.,]?\d{0,3})\s*(đ|d|vnd)?', caseSensitive: false);
    
    for (Match match in amountRegex.allMatches(text)) {
      String amountStr = match.group(1)!.replaceAll(RegExp(r'[.,]'), '');
      double? amount = double.tryParse(amountStr);
      if (amount != null && amount > 1000) { // Lọc số quá nhỏ
        amounts.add(amount);
      }
    }

    if (amounts.isNotEmpty) {
      // Lấy số lớn nhất (thường là tổng)
      amounts.sort((a, b) => b.compareTo(a));
      result['total_amount'] = amounts.first;
      print('[OCR] 💰 Tìm thấy số tiền: ${amounts.first}');
    }

    // Tìm tên cửa hàng (dòng đầu tiên thường là tên)
    List<String> lines = text.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isNotEmpty) {
      result['store_name'] = lines.first.trim();
    }

    // Đoán category
    String lowerText = text.toLowerCase();
    if (lowerText.contains('food') || lowerText.contains('ăn') || 
        lowerText.contains('phở') || lowerText.contains('cơm') ||
        lowerText.contains('bún') || lowerText.contains('cafe') ||
        lowerText.contains('coffee') || lowerText.contains('restaurant')) {
      result['category'] = 'Food';
    } else if (lowerText.contains('grab') || lowerText.contains('xăng') || 
               lowerText.contains('petrol') || lowerText.contains('taxi')) {
      result['category'] = 'Transport';
    } else if (lowerText.contains('shop') || lowerText.contains('store') ||
               lowerText.contains('mart') || lowerText.contains('mall')) {
      result['category'] = 'Shopping';
    }

    print('[OCR] 📊 Regex result: $result');
    return result;
  }

  // ✅ 4. Format tiền VND
  String formatMoney(dynamic amount) {
    if (amount == null) return '0đ';
    int value = (amount is double) ? amount.toInt() : amount;
    return '${value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )}đ';
  }

  // ✅ 5. Cleanup
  void dispose() {
    _textRecognizer.close();
  }
}