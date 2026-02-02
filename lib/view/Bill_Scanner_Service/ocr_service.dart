import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Quét text từ ảnh và trả về danh sách {tên món, giá}
  Future<List<Map<String, dynamic>>> extractBillItems(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = 
          await _textRecognizer.processImage(inputImage);

      return _parseTextToItems(recognizedText.text);
    } catch (e) {
      print('OCR Error: $e');
      return [];
    }
  }

  /// Parse text thành list items
  List<Map<String, dynamic>> _parseTextToItems(String text) {
    final List<Map<String, dynamic>> items = [];
    final lines = text.split('\n');

    // Regex tìm giá tiền (VD: 45,000 hoặc 45.000 hoặc 45000)
    final pricePattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)\s*(?:đ|vnd|₫|d)?',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final priceMatch = pricePattern.firstMatch(line);
      
      if (priceMatch != null) {
        try {
          // Lấy giá tiền
          String priceStr = priceMatch.group(1)!;
          priceStr = priceStr.replaceAll('.', '').replaceAll(',', '');
          
          final price = double.tryParse(priceStr);
          
          // Chỉ lấy nếu giá >= 1000 (bỏ qua số lẻ)
          if (price != null && price >= 1000) {
            // Lấy tên món (phần còn lại của dòng)
            String itemName = line
                .replaceFirst(priceMatch.group(0)!, '')
                .trim();
            
            itemName = _cleanItemName(itemName);

            if (itemName.isNotEmpty && itemName.length > 1) {
              items.add({
                'name': itemName,
                'price': price,
              });
            }
          }
        } catch (e) {
          continue;
        }
      }
    }

    return items;
  }

  /// Làm sạch tên món
  String _cleanItemName(String name) {
    // Xóa ký tự đặc biệt đầu/cuối
    name = name.replaceAll(RegExp(r'^[-*•\d\s.]+'), '');
    name = name.replaceAll(RegExp(r'[xX]\s*\d+$'), ''); // Xóa "x2"
    name = name.trim();

    // Viết hoa chữ cái đầu
    if (name.isNotEmpty) {
      name = name[0].toUpperCase() + name.substring(1).toLowerCase();
    }

    return name;
  }

  /// Dispose
  void dispose() {
    _textRecognizer.close();
  }
}