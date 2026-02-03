// lib/view/Bill_Scanner_Service/bill_manual_entry_view.dart
// Màn hình nhập thủ công các món trong bill - FINAL VERSION

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import './Bill_scanner_model.dart';

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
    {'name': 'Sinh tố', 'price': 30000, 'icon': '🍹'},
    {'name': 'Mì Ý', 'price': 65000, 'icon': '🍝'},
    {'name': 'Pizza', 'price': 120000, 'icon': '🍕'},
    {'name': 'Burger', 'price': 55000, 'icon': '🍔'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);

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

  // ✅ Save transactions to Firebase
  Future<void> _saveTransactions() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chưa có món nào để lưu'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00D09E)),
      ),
    );

    try {
      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Chưa đăng nhập');
      }

      // Get store name
      final storeName = _storeNameController.text.isEmpty 
          ? 'Bill' 
          : _storeNameController.text;

      // Save each item as a transaction
      for (final item in _items) {
        // Create transaction data
        final transactionData = {
          'userId': user.uid,
          'amount': item.price,
          'category': 'Food & Dining',
          'type': 'expense',
          'date': Timestamp.now(),
          'title': item.name,
          'note': storeName,
          'createdAt': Timestamp.now(),
        };

        // Add to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .add(transactionData);

        // Update user balance
        await _updateUserBalance(user.uid, item.price);
      }

      // Close loading
      if (mounted) Navigator.pop(context);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('✅ Đã lưu ${_items.length} giao dịch thành công!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Navigate back
      if (mounted) {
        Navigator.pop(context); // Back to scanner
        Navigator.pop(context); // Back to transaction view
      }
      
    } catch (e) {
      // Close loading
      if (mounted) Navigator.pop(context);
      
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  // ✅ Update user balance
  Future<void> _updateUserBalance(String userId, double amount) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      
      if (userDoc.exists) {
        final data = userDoc.data();
        final currentBalance = (data?['balance'] ?? 0.0).toDouble();
        final currentExpense = (data?['totalExpense'] ?? 0.0).toDouble();
        
        transaction.update(userRef, {
          'balance': currentBalance - amount,
          'totalExpense': currentExpense + amount,
        });
      }
    });
  }

  // ==================== UI BUILD METHODS ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Thông Tin Bill'),
        backgroundColor: const Color(0xFF00D09E),
        actions: [
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
      body: Column(
        children: [
          _buildImagePreview(),
          _buildStoreNameInput(),
          if (_items.length < 8) _buildQuickAddSection(),
          _buildAddItemForm(),
          Expanded(
            child: _items.isEmpty ? _buildEmptyState() : _buildItemsList(),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: Stack(
              children: [
                Center(
                  child: Image.file(widget.billImage, fit: BoxFit.contain),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
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