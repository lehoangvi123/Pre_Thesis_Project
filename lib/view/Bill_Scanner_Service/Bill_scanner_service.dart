// lib/service/bill_scanner_service_simple.dart
// GIẢI PHÁP ĐƠN GIẢN - KHÔNG CẦN ML KIT
// Chỉ cần image_picker để chụp ảnh, sau đó user nhập tay

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import './Bill_scanner_model.dart';

class BillScannerServiceSimple {
  final ImagePicker _picker = ImagePicker();

  /// Chụp ảnh từ camera
  Future<File?> captureImage() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error capturing image: $e');
      return null;
    }
  }

  /// Chọn ảnh từ thư viện
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  /// Tạo bill rỗng để user tự nhập
  ScannedBill createEmptyBill(File imageFile) {
    return ScannedBill(
      items: [], // User sẽ tự thêm items
      scannedAt: DateTime.now(),
      imageUrl: imageFile.path,
    );
  }
}