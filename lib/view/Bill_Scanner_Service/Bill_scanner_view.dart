// lib/view/Bill_Scanner_Service/Bill_scanner_view.dart
// VERSION MỚI: Kết hợp manual entry + OCR tự động

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../service/ocr_service.dart';
import './Bill_scanner_service.dart';
import './Bill_scanner_model.dart';
import './Bill_manual_entry_view.dart';

enum ScanMode {
  manual,    // Chụp ảnh → Nhập tay
  autoOCR,   // Chụp ảnh → OCR tự động
}

class BillScannerViewSimple extends StatefulWidget {
  const BillScannerViewSimple({Key? key}) : super(key: key);

  @override
  State<BillScannerViewSimple> createState() => _BillScannerViewSimpleState();
}

class _BillScannerViewSimpleState extends State<BillScannerViewSimple> {
  final BillScannerServiceSimple _scannerService = BillScannerServiceSimple();
  final OCRService _ocrService = OCRService();
  
  bool _isLoading = false;
  ScanMode _scanMode = ScanMode.autoOCR; // Mặc định dùng OCR

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  // ✅ WORKFLOW 1: AUTO OCR (Mới)
  Future<void> _scanWithOCR({bool fromCamera = true}) async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> result = await _ocrService.scanReceipt(fromCamera: fromCamera);
      
      setState(() => _isLoading = false);

      if (result['success'] == true) {
        _showOCRResultDialog(result);
      } else {
        _showErrorDialog(result['error'] ?? 'Có lỗi xảy ra');
      }
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi OCR: $e');
    }
  }

  // ✅ WORKFLOW 2: MANUAL ENTRY (Cũ - giữ nguyên)
  Future<void> _captureForManualEntry() async {
    setState(() => _isLoading = true);

    try {
      final imageFile = await _scannerService.captureImage();
      
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

  Future<void> _pickImageForManualEntry() async {
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

  // ✅ DIALOG: Hiển thị kết quả OCR
  void _showOCRResultDialog(Map<String, dynamic> result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 28),
            ),
            SizedBox(width: 12),
            Expanded(child: Text('Đã quét hóa đơn', style: TextStyle(fontSize: 18))),
          ],
        ),
        
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Store name
              if (result['store_name'] != null) ...[
                _buildInfoRow(
                  icon: Icons.store,
                  label: 'Cửa hàng',
                  value: result['store_name'],
                  isDark: isDark,
                ),
                SizedBox(height: 12),
              ],
              
              // Total amount
              if (result['total_amount'] != null) ...[
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '💰 Tổng tiền:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey[300] : Colors.grey[800],
                        ),
                      ),
                      Text(
                        _ocrService.formatMoney(result['total_amount']),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),
              ],
              
              // Category
              if (result['category'] != null) ...[
                _buildInfoRow(
                  icon: Icons.category,
                  label: 'Danh mục',
                  value: _getCategoryName(result['category']),
                  isDark: isDark,
                ),
                SizedBox(height: 12),
              ],
              
              // Items
              if (result['items'] != null && result['items'].isNotEmpty) ...[
                Text(
                  '📝 Chi tiết:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.grey[300] : Colors.grey[800],
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: List.generate(result['items'].length, (index) {
                      var item = result['items'][index];
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '• ${item['name']}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              _ocrService.formatMoney(item['price']),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 12),
              ],
              
              // Confidence
              if (result['confidence'] != null) ...[
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                    SizedBox(width: 4),
                    Text(
                      'Độ tin cậy: ${(result['confidence'] * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(color: Colors.grey[600])),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to manual edit screen nếu cần
            },
            child: Text('Sửa lại'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _saveTransactionFromOCR(result);
            },
            icon: Icon(Icons.save, size: 18),
            label: Text('Lưu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00D09E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Color(0xFF00D09E)),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _getCategoryName(String category) {
    Map<String, String> categoryNames = {
      'Food': 'Ăn uống 🍔',
      'Shopping': 'Mua sắm 🛒',
      'Transport': 'Di chuyển 🚗',
      'Entertainment': 'Giải trí 🎬',
      'Other': 'Khác 📌',
    };
    return categoryNames[category] ?? category;
  }

  Future<void> _saveTransactionFromOCR(Map<String, dynamic> result) async {
    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      var userData = userDoc.data() as Map<String, dynamic>? ?? {};
      double currentBalance = (userData['balance'] ?? 0).toDouble();
      double currentExpense = (userData['totalExpense'] ?? 0).toDouble();
      double currentIncome = (userData['totalIncome'] ?? 0).toDouble();
      
      double amount = (result['total_amount'] ?? 0).toDouble();
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        String transactionId = FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .doc()
            .id;
        
        transaction.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('transactions')
              .doc(transactionId),
          {
            'id': transactionId,
            'userId': userId,
            'categoryId': '',
            'categoryName': result['category'] ?? 'Shopping',
            'title': result['store_name'] ?? 'Mua sắm',
            'amount': amount,
            'type': 'expense',
            'isIncome': false,
            'date': Timestamp.now(),
            'createdAt': FieldValue.serverTimestamp(),
            'message': 'Quét từ hóa đơn - OCR',
            'items': result['items'] ?? [],
            'rawText': result['raw_text'] ?? '',
          },
        );
        
        transaction.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {
            'balance': currentBalance - amount,
            'totalExpense': currentExpense + amount,
            'totalIncome': currentIncome,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('✅ Đã lưu ${_ocrService.formatMoney(amount)}'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        
        await Future.delayed(Duration(seconds: 1));
        Navigator.pop(context, true);
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Lỗi'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _toggleScanMode() {
    setState(() {
      _scanMode = _scanMode == ScanMode.autoOCR 
          ? ScanMode.manual 
          : ScanMode.autoOCR;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _scanMode == ScanMode.autoOCR
              ? '🤖 Chế độ: Tự động OCR'
              : '✍️ Chế độ: Nhập tay',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Bill'),
        backgroundColor: const Color(0xFF00D09E),
        actions: [
          // Toggle scan mode
          IconButton(
            icon: Icon(
              _scanMode == ScanMode.autoOCR
                  ? Icons.auto_awesome
                  : Icons.edit,
            ),
            tooltip: _scanMode == ScanMode.autoOCR ? 'OCR tự động' : 'Nhập tay',
            onPressed: _toggleScanMode,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00D09E)),
          SizedBox(height: 24),
          Text(
            _scanMode == ScanMode.autoOCR 
                ? 'Đang quét và phân tích...'
                : 'Đang xử lý...',
            style: TextStyle(fontSize: 16),
          ),
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
          // Icon với badge mode
          Stack(
            children: [
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
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _scanMode == ScanMode.autoOCR ? Colors.blue : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _scanMode == ScanMode.autoOCR ? Icons.auto_awesome : Icons.edit,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            _scanMode == ScanMode.autoOCR 
                ? 'Quét Hóa Đơn Tự Động'
                : 'Thêm Hóa Đơn',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            _scanMode == ScanMode.autoOCR
                ? 'AI sẽ tự động trích xuất\nthông tin từ hóa đơn'
                : 'Chụp ảnh hóa đơn,\nsau đó nhập thông tin các món',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 48),
          // Buttons
          _buildActionButton(
            icon: Icons.camera_alt,
            label: _scanMode == ScanMode.autoOCR 
                ? 'Chụp & Quét Tự Động'
                : 'Chụp Ảnh Bill',
            onPressed: _scanMode == ScanMode.autoOCR
                ? () => _scanWithOCR(fromCamera: true)
                : _captureForManualEntry,
          ),
          const SizedBox(height: 16),
          _buildActionButton(
            icon: Icons.photo_library,
            label: 'Chọn Từ Thư Viện',
            onPressed: _scanMode == ScanMode.autoOCR
                ? () => _scanWithOCR(fromCamera: false)
                : _pickImageForManualEntry,
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
        color: _scanMode == ScanMode.autoOCR ? Colors.blue[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _scanMode == ScanMode.autoOCR ? Colors.blue[100]! : Colors.orange[100]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: _scanMode == ScanMode.autoOCR ? Colors.blue : Colors.orange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                _scanMode == ScanMode.autoOCR ? 'Chế độ OCR:' : 'Chế độ thủ công:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _scanMode == ScanMode.autoOCR ? Colors.blue : Colors.orange,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          if (_scanMode == ScanMode.autoOCR) ...[
            Text('✓ AI tự động đọc số tiền', style: TextStyle(fontSize: 13)),
            Text('✓ Nhận diện cửa hàng & danh mục', style: TextStyle(fontSize: 13)),
            Text('✓ Lưu nhanh chỉ 1 click', style: TextStyle(fontSize: 13)),
          ] else ...[
            Text('✓ Ảnh bill giúp bạn nhớ chi tiêu', style: TextStyle(fontSize: 13)),
            Text('✓ Bạn sẽ nhập thông tin các món sau', style: TextStyle(fontSize: 13)),
            Text('✓ Có thể chỉnh sửa trước khi lưu', style: TextStyle(fontSize: 13)),
          ],
        ],
      ),
    );
  }
}