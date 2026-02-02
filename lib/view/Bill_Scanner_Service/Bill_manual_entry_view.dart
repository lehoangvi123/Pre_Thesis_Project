// lib/view/bill_manual_entry_view.dart
// Màn hình nhập thủ công các món trong bill

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  final List<BillItem> _items = [];
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _storeNameController = TextEditingController();
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _storeNameController.dispose();
    super.dispose();
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.totalPrice);

  void _addItem() {
    if (_nameController.text.isEmpty || _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin')),
      );
      return;
    }

    final price = double.tryParse(_priceController.text.replaceAll(',', ''));
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giá tiền không hợp lệ')),
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

    // Focus về tên món để tiếp tục nhập
    FocusScope.of(context).requestFocus(FocusNode());
  }

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

  void _deleteItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _saveTransactions() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có món nào')),
      );
      return;
    }

    // TODO: Integrate với TransactionProvider
    // final provider = Provider.of<TransactionProvider>(context, listen: false);
    // for (final item in _items) {
    //   await provider.addTransaction(...);
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu ${_items.length} giao dịch'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // Back to scanner
    Navigator.pop(context); // Back to home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhập Thông Tin Bill'),
        backgroundColor: const Color(0xFF00D09E),
        actions: [
          if (_items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveTransactions,
            ),
        ],
      ),
      body: Column(
        children: [
          // Bill image preview
          _buildImagePreview(),
          
          // Store name (optional)
          _buildStoreNameInput(),

          // Add item form
          _buildAddItemForm(),

          // Items list
          Expanded(
            child: _items.isEmpty ? _buildEmptyState() : _buildItemsList(),
          ),

          // Total & Save
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return GestureDetector(
      onTap: () {
        // Show full image
        showDialog(
          context: context,
          builder: (context) => Dialog(
            child: Image.file(widget.billImage, fit: BoxFit.contain),
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
                child: const Text(
                  'Nhấn để phóng to',
                  style: TextStyle(color: Colors.white, fontSize: 12),
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
      padding: const EdgeInsets.all(12),
      child: TextField(
        controller: _storeNameController,
        decoration: InputDecoration(
          labelText: 'Tên cửa hàng (tuỳ chọn)',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          prefixIcon: const Icon(Icons.store),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
    );
  }

  Widget _buildAddItemForm() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.blue[50],
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Tên món',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                isDense: true,
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.white,
                suffixText: 'đ',
                isDense: true,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            child: const Icon(Icons.add, color: Colors.white),
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
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF00D09E).withOpacity(0.1),
              child: Text('${index + 1}', style: const TextStyle(color: Color(0xFF00D09E))),
            ),
            title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text('${_currencyFormat.format(item.price)} đ',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                  onPressed: () => _editItem(index),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  onPressed: () => _deleteItem(index),
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
        children: const [
          Icon(Icons.add_shopping_cart, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text('Chưa có món nào', style: TextStyle(fontSize: 16, color: Colors.grey)),
          SizedBox(height: 8),
          Text('Nhập thông tin món ở trên', style: TextStyle(fontSize: 14, color: Colors.grey)),
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
              const Text('Tổng cộng:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                '${_currencyFormat.format(_totalAmount)} đ',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00D09E)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('${_items.length} món', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _items.isEmpty ? null : _saveTransactions,
              icon: const Icon(Icons.save),
              label: const Text('Lưu Tất Cả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09E),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
        ],
      ),
    );
  }
}