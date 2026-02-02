// lib/view/bill_result_view.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import './Bill_scanner_model.dart';

class BillResultView extends StatefulWidget {
  final ScannedBill scannedBill;

  const BillResultView({
    Key? key,
    required this.scannedBill,
  }) : super(key: key);

  @override
  State<BillResultView> createState() => _BillResultViewState();
}

class _BillResultViewState extends State<BillResultView> {
  late List<BillItem> _items;
  late String? _storeName;
  final NumberFormat _currencyFormat = NumberFormat('#,###', 'vi_VN');

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.scannedBill.items);
    _storeName = widget.scannedBill.storeName;
  }

  double get _totalAmount =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);

  void _editItem(int index) {
    final item = _items[index];
    final nameController = TextEditingController(text: item.name);
    final priceController =
        TextEditingController(text: item.price.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Tên món',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items[index] = BillItem(
                  name: nameController.text,
                  price: double.tryParse(priceController.text) ?? item.price,
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _deleteItem(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Xóa "${_items[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _items.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _saveTransactions() {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có giao dịch nào để lưu')),
      );
      return;
    }

    // TODO: Integrate với TransactionProvider để lưu vào Firestore
    // Ví dụ:
    // final provider = Provider.of<TransactionProvider>(context, listen: false);
    // for (final item in _items) {
    //   await provider.addTransaction(
    //     amount: item.price,
    //     category: 'Food', // hoặc cho user chọn
    //     type: 'expense',
    //     note: '${_storeName ?? 'Bill'} - ${item.name}',
    //   );
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã lưu ${_items.length} giao dịch'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context); // Quay lại màn hình trước
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kết Quả Quét'),
        backgroundColor: const Color(0xFF00D09E),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _saveTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header với ảnh bill
          if (widget.scannedBill.imageUrl != null) _buildImageHeader(),

          // Store name
          if (_storeName != null) _buildStoreNameSection(),

          // Items list
          Expanded(
            child: _items.isEmpty ? _buildEmptyState() : _buildItemsList(),
          ),

          // Total và action buttons
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildImageHeader() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.grey[200],
      child: Image.file(
        File(widget.scannedBill.imageUrl!),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildStoreNameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue[50],
      child: Row(
        children: [
          const Icon(Icons.store, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cửa hàng',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  _storeName!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final item = _items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
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
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () => _editItem(index),
                  color: Colors.blue,
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _deleteItem(index),
                  color: Colors.red,
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
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Không có món nào',
            style: TextStyle(fontSize: 16, color: Colors.grey),
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
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
          Text(
            '${_items.length} món',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // Save button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _saveTransactions,
              icon: const Icon(Icons.save),
              label: const Text(
                'Lưu Tất Cả Giao Dịch',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00D09E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}