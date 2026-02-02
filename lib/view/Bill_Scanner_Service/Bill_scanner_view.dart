// lib/view/bill_scanner_view_simple.dart
// VERSION ĐÃ ĐƠN GIẢN - CHỈ CẦN image_picker

import 'dart:io';
import 'package:flutter/material.dart';
import './Bill_scanner_service.dart';
import './Bill_scanner_model.dart';
import './Bill_manual_entry_view.dart';

class BillScannerViewSimple extends StatefulWidget {
  const BillScannerViewSimple({Key? key}) : super(key: key);

  @override
  State<BillScannerViewSimple> createState() => _BillScannerViewSimpleState();
}

class _BillScannerViewSimpleState extends State<BillScannerViewSimple> {
  final BillScannerServiceSimple _scannerService = BillScannerServiceSimple();
  bool _isLoading = false;

  Future<void> _captureAndAddItems() async {
    setState(() => _isLoading = true);

    try {
      // Chụp ảnh
      final imageFile = await _scannerService.captureImage();
      
      if (imageFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _isLoading = false);

      // Navigate đến màn hình nhập thủ công với ảnh
      _navigateToManualEntry(imageFile);
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi: $e');
    }
  }

  Future<void> _pickImageAndAddItems() async {
    setState(() => _isLoading = true);

    try {
      final imageFile = await _scannerService.pickImageFromGallery();
      
      if (imageFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      setState(() => _isLoading = false);
      _navigateToManualEntry(imageFile);
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi: $e');
    }
  }

  void _navigateToManualEntry(File imageFile) {
    final emptyBill = _scannerService.createEmptyBill(imageFile);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillManualEntryView(
          billImage: imageFile,
          scannedBill: emptyBill,
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thông báo'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Bill'),
        backgroundColor: const Color(0xFF00D09E),
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainView(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00D09E)),
          SizedBox(height: 24),
          Text('Đang xử lý...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          const SizedBox(height: 32),
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF00D09E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 60,
              color: Color(0xFF00D09E),
            ),
          ),
          const SizedBox(height: 32),
          // Title
          const Text(
            'Thêm Hóa Đơn',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Description
          const Text(
            'Chụp hoặc chọn ảnh hóa đơn,\nsau đó nhập thông tin các món',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 48),
          // Buttons
          _buildActionButton(
            icon: Icons.camera_alt,
            label: 'Chụp Ảnh Bill',
            onPressed: _captureAndAddItems,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Chọn Từ Thư Viện',
            onPressed: _pickImageAndAddItems,
            isPrimary: false,
          ),
          const Spacer(),
          // Info
          _buildInfoBox(),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF00D09E) : Colors.grey[200],
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: isPrimary ? 2 : 0,
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text('Lưu ý:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            ],
          ),
          SizedBox(height: 8),
          Text('✓ Ảnh bill giúp bạn nhớ chi tiêu', style: TextStyle(fontSize: 13)),
          Text('✓ Bạn sẽ nhập thông tin các món sau', style: TextStyle(fontSize: 13)),
          Text('✓ Có thể chỉnh sửa trước khi lưu', style: TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}