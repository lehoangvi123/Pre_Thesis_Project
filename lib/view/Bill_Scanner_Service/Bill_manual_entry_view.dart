// lib/view/Bill_Scanner_Service/bill_manual_entry_view.dart
// Màn hình nhập thủ công các món trong bill - VERSION CÓ OCR TỰ ĐỘNG

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './Bill_scanner_model.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

class BillManualEntryView extends StatefulWidget {
  final File billImage;
  final ScannedBill scannedBill;

  const BillManualEntryView({
    Key? key,
    required this.billImage,
    required this.scannedBill,
  }) : super(key: key);

  @override
  State<BillManualEntryView> createState() => _BillManualEntryViewState();
}

class _BillManualEntryViewState extends State<BillManualEntryView> {
  List<BillItem> _items = [];
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _storeNameController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  // ✅ OCR State
  bool _isScanning = false;
  bool _hasScanned = false;

  // ✅ Quick Add Suggestions (món ăn phổ biến Việt Nam)
  final List<Map<String, dynamic>> _quickSuggestions = [
    {'name': 'Cà phê', 'price': 45000, 'icon': '☕'},
    {'name': 'Trà sữa', 'price': 35000, 'icon': '🧋'},
    {'name': 'Bánh mì', 'price': 25000, 'icon': '🥖'},
    {'name': 'Cơm tấm', 'price': 40000, 'icon': '🍚'},
    {'name': 'Phở', 'price': 50000, 'icon': '🍜'},
    {'name': 'Bún bò', 'price': 45000, 'icon': '🍲'},
    {'name': 'Nước ép', 'price': 30000, 'icon': '🥤'},
    {'name': 'Bánh ngọt', 'price': 35000, 'icon': '🍰'},
  ];

  @override
  void initState() {
    super.initState();
    // ✅ TỰ ĐỘNG QUÉT KHI VÀO MÀN HÌNH
    _autoScanBill();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);

  // ==================== OCR METHODS ====================

  // ✅ TỰ ĐỘNG QUÉT BILL
  Future<void> _autoScanBill() async {
    if (_hasScanned) return;
    
    setState(() => _isScanning = true);

    try {
      // Quét text từ ảnh
      String text = await FlutterTesseractOcr.extractText(
        widget.billImage.path,
        language: 'eng+vie', // Hỗ trợ tiếng Anh và tiếng Việt
        args: {
          "preserve_interword_spaces": "1",
        },
      );

      print('🔍 OCR Result: $text'); // Debug

      // Parse text thành items
      final extractedItems = _parseTextToItems(text);

      if (extractedItems.isNotEmpty) {
        setState(() {
          _items = extractedItems;
          _hasScanned = true;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('✅ Quét thành công ${_items.length} món!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else {
        setState(() => _hasScanned = true);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Không tìm thấy món nào. Vui lòng nhập thủ công.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ OCR Error: $e');
      setState(() => _hasScanned = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Không thể quét. Vui lòng nhập thủ công.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  // ✅ PARSE TEXT THÀNH ITEMS
  List<BillItem> _parseTextToItems(String text) {
    final List<BillItem> items = [];
    final lines = text.split('\n');

    // Regex tìm giá tiền (VD: 45,000 hoặc 45.000 hoặc 45000)
    final pricePattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (line.trim().isEmpty) continue;

      final priceMatch = pricePattern.firstMatch(line);
      
      if (priceMatch != null) {
        try {
          // Lấy giá
          String priceStr = priceMatch.group(1)!;
          priceStr = priceStr.replaceAll('.', '').replaceAll(',', '');
          
          final price = double.tryParse(priceStr);
          
          // Chỉ lấy nếu giá >= 1000
          if (price != null && price >= 1000) {
            // Lấy tên món (phần còn lại của dòng)
            String itemName = line
                .replaceFirst(priceMatch.group(0)!, '')
                .trim();
            
            // Làm sạch tên
            itemName = itemName.replaceAll(RegExp(r'^[-*•\d\s.]+'), '');
            itemName = itemName.replaceAll(RegExp(r'[xX]\s*\d+$'), '');
            itemName = itemName.trim();

            if (itemName.isNotEmpty && itemName.length > 2) {
              // Viết hoa chữ đầu
              if (itemName.isNotEmpty) {
                itemName = itemName[0].toUpperCase() + 
                          itemName.substring(1).toLowerCase();
              }

              items.add(BillItem(name: itemName, price: price));
              print('✅ Found: $itemName - $price'); // Debug
            }
          }
        } catch (e) {
          print('⚠️ Parse error for line: $line - $e');
          continue;
        }
      }
    }

    return items;
  }

  // ==================== ITEM MANAGEMENT METHODS ====================

  // ✅ Thêm món thủ công
  void _addItem() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ thông tin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', ''));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Giá tiền không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _items.add(BillItem(
        name: _nameController.text,
        price: price,
      ));
      _nameController.clear();
      _priceController.clear();
    });

    FocusScope.of(context).requestFocus(FocusNode());
  }

  // ✅ Quick Add
  void _quickAddItem(String name, double price) {
    setState(() {
      _items.add(BillItem(name: name, price: price));
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã thêm $name'),
        duration: const Duration(milliseconds: 800),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ✅ Edit món
  void _editItem(int index) {
    final item = _items[index];
    _nameController.text = item.name;
    _priceController.text = item.price.toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa món'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên món',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Giá tiền',
                border: OutlineInputBorder(),
                suffixText: 'đ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _priceController.clear();
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final newPrice = double.tryParse(_priceController.text.replaceAll(',', ''));
              if (newPrice != null && _nameController.text.isNotEmpty) {
                setState(() {
                  _items[index] = BillItem(
                    name: _nameController.text,
                    price: newPrice,
                  );
                });
                _nameController.clear();
                _priceController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  // ✅ Delete món
  void _deleteItem(int index) {
    final itemName = _items[index].name;
    
    setState(() {
      _items.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🗑️ Đã xóa $itemName'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  // ✅ Clear tất cả
  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa tất cả?'),
        content: Text('Bạn có chắc muốn xóa ${_items.length} món?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items.clear();
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã xóa tất cả')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  // ✅ Save transactions
  void _saveTransactions() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có món nào để lưu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Integrate với TransactionProvider
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Đã lưu ${_items.length} giao dịch'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // Back to scanner
    Navigator.pop(context); // Back to transaction
  }

  // ==================== UI BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Thông Tin Bill'),
        backgroundColor: const Color(0xFF00D09E),
        actions: [
          // ✅ NÚT QUÉT LẠI
          if (_hasScanned)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() {
                  _hasScanned = false;
                  _items.clear();
                });
                _autoScanBill();
              },
              tooltip: 'Quét lại',
            ),
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: 'Xóa tất cả',
            ),
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTransactions,
              tooltip: 'Lưu',
            ),
        ],
      ),
      body: _isScanning ? _buildScanningView() : _buildMainView(),
    );
  }

  // ✅ LOADING VIEW KHI ĐANG QUÉT
  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              color: Color(0xFF00D09E),
              strokeWidth: 6,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            '🤖 AI đang quét bill...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Vui lòng đợi 2-5 giây',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: const Column(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 24),
                SizedBox(height: 8),
                Text(
                  'Đang phân tích ảnh bill\nvà trích xuất thông tin...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        _buildImagePreview(),
        
        // ✅ KẾT QUẢ QUÉT
        if (_hasScanned && _items.isNotEmpty)
          _buildScanResultBanner(),
        
        _buildStoreNameInput(),
        if (_items.length < 5) _buildQuickAddSection(),
        _buildAddItemForm(),
        Expanded(
          child: _items.isEmpty ? _buildEmptyState() : _buildItemsList(),
        ),
        _buildBottomSection(),
      ],
    );
  }

  // ✅ BANNER THÔNG BÁO KẾT QUẢ QUÉT
  Widget _buildScanResultBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[50]!, Colors.green[100]!],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green[300]!, width: 2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '✨ AI đã quét xong!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tìm thấy ${_items.length} món. Kiểm tra và chỉnh sửa nếu cần.',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== OTHER UI COMPONENTS ====================
  // (Giữ nguyên tất cả các widget builders khác từ file gốc)

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Stack(
              children: [
                Image.file(widget.billImage, fit: BoxFit.contain),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: Container(
        height: 150,
        width: double.infinity,
        color: Colors.grey[200],
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(widget.billImage, fit: BoxFit.cover),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.zoom_in, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'Nhấn để phóng to',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreNameInput() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TextField(
        controller: _storeNameController,
        decoration: InputDecoration(
          labelText: 'Tên cửa hàng (tuỳ chọn)',
          hintText: 'VD: Highlands Coffee',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: const Icon(Icons.store, color: Color(0xFF00D09E)),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildQuickAddSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(Icons.flash_on, color: Colors.orange, size: 20),
                SizedBox(width: 4),
                Text(
                  'Thêm nhanh:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 45,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _quickSuggestions.length,
              itemBuilder: (context, index) {
                final item = _quickSuggestions[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: Text(
                      item['icon'],
                      style: const TextStyle(fontSize: 16),
                    ),
                    label: Text(
                      '${item['name']} ${_currencyFormat.format(item['price'])}đ',
                      style: const TextStyle(fontSize: 12),
                    ),
                    onPressed: () => _quickAddItem(
                      item['name'],
                      item['price'].toDouble(),
                    ),
                    backgroundColor: Colors.orange[50],
                    side: BorderSide(color: Colors.orange[200]!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddItemForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên món',
                hintText: 'VD: Cà phê',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onSubmitted: (_) => _addItem(),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Giá',
                hintText: '45000',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                suffixText: 'đ',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              onSubmitted: (_) => _addItem(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _addItem,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D09E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.all(14),
              minimumSize: const Size(45, 45),
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF00D09E).withOpacity(0.1),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Color(0xFF00D09E),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${_currencyFormat.format(item.price)} đ',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _editItem(index),
                  color: Colors.blue,
                  tooltip: 'Sửa',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _deleteItem(index),
                  color: Colors.red,
                  tooltip: 'Xóa',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_shopping_cart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'Chưa có món nào',
            style: TextStyle(fontSize: 18, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhập thông tin món ở trên\nhoặc dùng "Thêm nhanh"',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '${_currencyFormat.format(_totalAmount)} đ',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00D09E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_items.length} món',
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),
              if (_items.isNotEmpty)
                Text(
                  'Trung bình: ${_currencyFormat.format(_totalAmount / _items.length)} đ/món',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _items.isEmpty ? null : _saveTransactions,
              icon: const Icon(Icons.save),
              label: const Text(
                'Lưu Tất Cả',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}