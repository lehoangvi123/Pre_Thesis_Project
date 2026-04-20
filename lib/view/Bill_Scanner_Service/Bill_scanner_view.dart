// lib/view/Bill_Scanner_Service/Bill_scanner_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './ocr_service.dart';
import './Bill_scanner_service.dart';
import './Bill_scanner_model.dart';
import './Bill_manual_entry_view.dart';

enum ScanMode { manual, autoOCR }

class BillScannerViewSimple extends StatefulWidget {
  const BillScannerViewSimple({Key? key}) : super(key: key);
  @override
  State<BillScannerViewSimple> createState() => _BillScannerViewSimpleState();
}

class _BillScannerViewSimpleState extends State<BillScannerViewSimple> {
  final BillScannerServiceSimple _scannerService = BillScannerServiceSimple();
  final OCRService _ocrService = OCRService();

  bool _isLoading = false;
  ScanMode _scanMode = ScanMode.autoOCR;

  static const List<Map<String, String>> _categories = [
    {'key': 'Ăn uống',           'icon': '🍜'},
    {'key': 'Giải trí & xã hội', 'icon': '🎬'},
    {'key': 'Mua sắm cá nhân',   'icon': '🛍️'},
    {'key': 'Di chuyển',         'icon': '🚗'},
    {'key': 'Sức khoẻ',          'icon': '💊'},
    {'key': 'Hóa đơn tiện ích',  'icon': '💡'},
    {'key': 'Giáo dục',          'icon': '📚'},
    {'key': 'Tiết kiệm',         'icon': '💰'},
    {'key': 'Chi phí gia đình',  'icon': '👨‍👩‍👧'},
    {'key': 'Khác',              'icon': '📌'},
  ];

  @override
  void dispose() {
    _ocrService.dispose();
    super.dispose();
  }

  // ── OCR workflow ──────────────────────────────────────────
  Future<void> _scanWithOCR({bool fromCamera = true}) async {
    setState(() => _isLoading = true);
    try {
      final result = await _ocrService.scanReceipt(fromCamera: fromCamera);
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

  // ── Manual workflow ───────────────────────────────────────
  Future<void> _captureForManualEntry() async {
    setState(() => _isLoading = true);
    try {
      final imageFile = await _scannerService.captureImage();
      setState(() => _isLoading = false);
      if (imageFile != null) _navigateToManualEntry(imageFile);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi: $e');
    }
  }

  Future<void> _pickImageForManualEntry() async {
    setState(() => _isLoading = true);
    try {
      final imageFile = await _scannerService.pickImageFromGallery();
      setState(() => _isLoading = false);
      if (imageFile != null) _navigateToManualEntry(imageFile);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Lỗi: $e');
    }
  }

  void _navigateToManualEntry(File imageFile) {
    final emptyBill = _scannerService.createEmptyBill(imageFile);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => BillManualEntryView(billImage: imageFile, scannedBill: emptyBill)));
  }

  // ── OCR Result Dialog ─────────────────────────────────────
  void _showOCRResultDialog(Map<String, dynamic> result) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedCategory = result['category'] ?? 'Khác';

    final items    = (result['items'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    final subtotal = result['subtotal'] as double?;
    final svc      = result['service_charge'] as double?;
    final total    = result['total_amount'] as double?;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header ──────────────────────────────────
                Row(children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.15),
                        shape: BoxShape.circle),
                    child: const Icon(Icons.check_circle,
                        color: Colors.green, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Đã quét hóa đơn',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      if (result['store_name'] != null)
                        Text(result['store_name'],
                            style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                    ],
                  )),
                ]),

                const SizedBox(height: 14),
                Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
                const SizedBox(height: 10),

                // ── Bill detail list ─────────────────────────
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.38,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Items
                        if (items.isNotEmpty) ...[
                          ...items.map((item) => _buildBillRow(
                            name:   item['name'] as String? ?? '',
                            amount: (item['amount'] as num?)?.toDouble(),
                            isDark: isDark,
                          )),
                          const SizedBox(height: 8),
                          Divider(height: 1,
                              color: isDark ? Colors.grey[700] : Colors.grey[200]),
                          const SizedBox(height: 6),
                        ],

                        // Subtotal
                        if (subtotal != null)
                          _buildBillRow(
                              name: 'Subtotal', amount: subtotal,
                              isDark: isDark, isSubRow: true),

                        // Service charge
                        if (svc != null)
                          _buildBillRow(
                              name: 'Service charge', amount: svc,
                              isDark: isDark, isSubRow: true),

                        // Total
                        if (total != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.3)),
                            ),
                            child: Row(children: [
                              const Text('💰 Total',
                                  style: TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.bold)),
                              const Spacer(),
                              Text(_ocrService.formatMoney(total),
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green[700])),
                            ]),
                          ),
                        ],

                        if (items.isEmpty && total == null)
                          Center(child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text('Không đọc được chi tiết',
                                style: TextStyle(color: Colors.grey[500])),
                          )),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? Colors.grey[700] : Colors.grey[200]),
                const SizedBox(height: 12),

                // ── Category picker ──────────────────────────
                GestureDetector(
                  onTap: () => _showCategoryPicker(
                    context: context,
                    isDark: isDark,
                    current: selectedCategory,
                    onSelected: (cat) =>
                        setDialogState(() => selectedCategory = cat),
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF00D09E).withOpacity(0.4),
                          width: 1.5),
                    ),
                    child: Row(children: [
                      const Icon(Icons.category_rounded,
                          size: 18, color: Color(0xFF00D09E)),
                      const SizedBox(width: 8),
                      Text('Danh mục: ',
                          style: TextStyle(fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600])),
                      Expanded(child: Text(
                        '${_getCategoryIcon(selectedCategory)}  $selectedCategory',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87),
                      )),
                      Icon(Icons.edit_rounded, size: 15, color: Colors.grey[400]),
                    ]),
                  ),
                ),

                // Hint + confidence
                const SizedBox(height: 6),
                Row(children: [
                  Icon(Icons.touch_app_rounded, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('Nhấn để đổi danh mục',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  const Spacer(),
                  if (result['confidence'] != null) ...[
                    Icon(Icons.info_outline, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      'Độ tin cậy: ${(result['confidence'] * 100).toInt()}%',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ]),

                const SizedBox(height: 16),

                // ── Actions ──────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Hủy',
                        style: TextStyle(color: Colors.grey[600])),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      final updated = Map<String, dynamic>.from(result);
                      updated['category'] = selectedCategory;
                      _saveTransactionFromOCR(updated);
                    },
                    icon: const Icon(Icons.save, size: 16),
                    label: const Text('Lưu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D09E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Bill row widget ───────────────────────────────────────
  Widget _buildBillRow({
    required String name,
    required double? amount,
    required bool isDark,
    bool isSubRow = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        if (!isSubRow)
          Container(
            width: 6, height: 6,
            margin: const EdgeInsets.only(right: 10, top: 1),
            decoration: BoxDecoration(
                color: const Color(0xFF00D09E), shape: BoxShape.circle),
          )
        else
          const SizedBox(width: 16),
        Expanded(child: Text(name,
          style: TextStyle(
            fontSize: isSubRow ? 12 : 14,
            fontWeight: isSubRow ? FontWeight.normal : FontWeight.w500,
            color: isSubRow
                ? (isDark ? Colors.grey[400] : Colors.grey[600])
                : (isDark ? Colors.white : Colors.black87),
          ),
        )),
        Text(
          amount != null ? _ocrService.formatMoney(amount) : '—',
          style: TextStyle(
            fontSize: isSubRow ? 12 : 14,
            fontWeight: isSubRow ? FontWeight.normal : FontWeight.w600,
            color: isSubRow
                ? (isDark ? Colors.grey[400] : Colors.grey[600])
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ]),
    );
  }

  // ── Category picker bottom sheet ──────────────────────────
  void _showCategoryPicker({
    required BuildContext context,
    required bool isDark,
    required String current,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2))),
          Text('Chọn danh mục',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2, shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 3.2,
            children: _categories.map((cat) {
              final isSel = cat['key'] == current;
              return GestureDetector(
                onTap: () {
                  onSelected(cat['key']!);
                  Navigator.pop(sheetCtx);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF00D09E).withOpacity(0.15)
                        : (isDark ? Colors.grey[800] : Colors.grey[100]),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF00D09E)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(children: [
                    Text(cat['icon']!,
                        style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(cat['key']!,
                      style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500,
                        color: isSel
                            ? const Color(0xFF00D09E)
                            : (isDark ? Colors.grey[300] : Colors.grey[800]),
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                    if (isSel)
                      const Icon(Icons.check_rounded,
                          size: 14, color: Color(0xFF00D09E)),
                  ]),
                ),
              );
            }).toList(),
          ),
        ]),
      ),
    );
  }

  String _getCategoryIcon(String category) {
    final cat = _categories.firstWhere(
        (c) => c['key'] == category,
        orElse: () => {'key': '', 'icon': '📌'});
    return cat['icon']!;
  }

  // ── Save transaction ──────────────────────────────────────
  Future<void> _saveTransactionFromOCR(Map<String, dynamic> result) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users').doc(userId).get();
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};

      final currentBalance = (userData['balance']      ?? 0).toDouble();
      final currentExpense = (userData['totalExpense'] ?? 0).toDouble();
      final currentIncome  = (userData['totalIncome']  ?? 0).toDouble();
      final amount = (result['total_amount'] ?? 0).toDouble();

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final txId = FirebaseFirestore.instance
            .collection('users').doc(userId)
            .collection('transactions').doc().id;

        tx.set(
          FirebaseFirestore.instance
              .collection('users').doc(userId)
              .collection('transactions').doc(txId),
          {
            'id':           txId,
            'userId':       userId,
            'categoryId':   '',
            'categoryName': result['category'] ?? 'Khác',
            'category':     result['category'] ?? 'Khác',
            'title':        result['store_name'] ?? 'Hóa đơn',
            'amount':       amount,
            'type':         'expense',
            'isIncome':     false,
            'date':         Timestamp.now(),
            'createdAt':    FieldValue.serverTimestamp(),
            'message':      'Quét từ hóa đơn - OCR',
            'items':        result['items'] ?? [],
            'rawText':      result['raw_text'] ?? '',
          },
        );

        tx.update(
          FirebaseFirestore.instance.collection('users').doc(userId),
          {
            'balance':      currentBalance - amount,
            'totalExpense': currentExpense + amount,
            'totalIncome':  currentIncome,
            'updatedAt':    FieldValue.serverTimestamp(),
          },
        );
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text('✅ Đã lưu ${_ocrService.formatMoney(amount)}'),
          ]),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        await Future.delayed(const Duration(seconds: 1));
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('❌ Lỗi: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 8),
          Text('Lỗi'),
        ]),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(_scanMode == ScanMode.autoOCR
          ? '🤖 Chế độ: Tự động OCR'
          : '✍️ Chế độ: Nhập tay'),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── Build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm Bill'),
        backgroundColor: const Color(0xFF00D09E),
        actions: [
          IconButton(
            icon: Icon(_scanMode == ScanMode.autoOCR
                ? Icons.auto_awesome
                : Icons.edit),
            tooltip: _scanMode == ScanMode.autoOCR ? 'OCR tự động' : 'Nhập tay',
            onPressed: _toggleScanMode,
          ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: Color(0xFF00D09E)),
        const SizedBox(height: 24),
        Text(
          _scanMode == ScanMode.autoOCR
              ? 'Đang quét và phân tích...'
              : 'Đang xử lý...',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    ));
  }

  Widget _buildMainView() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 32),
        Stack(children: [
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF00D09E).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long, size: 60,
                color: Color(0xFF00D09E)),
          ),
          Positioned(
            right: 0, bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _scanMode == ScanMode.autoOCR
                    ? Colors.blue
                    : Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _scanMode == ScanMode.autoOCR
                    ? Icons.auto_awesome
                    : Icons.edit,
                color: Colors.white, size: 20,
              ),
            ),
          ),
        ]),
        const SizedBox(height: 32),
        Text(
          _scanMode == ScanMode.autoOCR
              ? 'Quét Hóa Đơn Tự Động'
              : 'Thêm Hóa Đơn',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text(
          _scanMode == ScanMode.autoOCR
              ? 'AI sẽ tự động trích xuất\nthông tin từ hóa đơn'
              : 'Chụp ảnh hóa đơn,\nsau đó nhập thông tin các món',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
        ),
        const SizedBox(height: 48),
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
        _buildInfoBox(),
      ]),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = true,
  }) {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFF00D09E)
              : Colors.grey[200],
          foregroundColor: isPrimary ? Colors.white : Colors.black87,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          elevation: isPrimary ? 2 : 0,
        ),
      ),
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _scanMode == ScanMode.autoOCR
            ? Colors.blue[50]
            : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _scanMode == ScanMode.autoOCR
              ? Colors.blue[100]!
              : Colors.orange[100]!,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.info_outline,
              color: _scanMode == ScanMode.autoOCR
                  ? Colors.blue
                  : Colors.orange,
              size: 20),
          const SizedBox(width: 8),
          Text(
            _scanMode == ScanMode.autoOCR
                ? 'Chế độ OCR:'
                : 'Chế độ thủ công:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: _scanMode == ScanMode.autoOCR
                  ? Colors.blue
                  : Colors.orange,
            ),
          ),
        ]),
        const SizedBox(height: 8),
        if (_scanMode == ScanMode.autoOCR) ...[
          const Text('✓ AI tự động đọc số tiền',
              style: TextStyle(fontSize: 13)),
          const Text('✓ Liệt kê chi tiết từng món',
              style: TextStyle(fontSize: 13)),
          const Text('✓ Nhận diện cửa hàng & danh mục',
              style: TextStyle(fontSize: 13)),
          const Text('✓ Lưu nhanh chỉ 1 click',
              style: TextStyle(fontSize: 13)),
        ] else ...[
          const Text('✓ Ảnh bill giúp bạn nhớ chi tiêu',
              style: TextStyle(fontSize: 13)),
          const Text('✓ Bạn sẽ nhập thông tin các món sau',
              style: TextStyle(fontSize: 13)),
          const Text('✓ Có thể chỉnh sửa trước khi lưu',
              style: TextStyle(fontSize: 13)),
        ],
      ]),
    );
  }
}