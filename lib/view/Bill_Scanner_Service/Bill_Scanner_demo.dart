// lib/test/bill_scanner_demo.dart
// File này để test nhanh tính năng bill scanner

import 'package:flutter/material.dart';

/// Demo text giả lập kết quả OCR từ một bill thật
class BillScannerDemo {
  
  /// Ví dụ 1: Bill Highlands Coffee
  static const String highlantsCoffeeBill = '''
HIGHLANDS COFFEE
Số 123 Nguyễn Huệ, Q1
----------------------------
Cappuccino          45,000đ
Bánh mì            25,000đ
Nước ép cam        35,000đ
----------------------------
TỔNG CỘNG:        105,000đ
Cảm ơn quý khách!
  ''';

  /// Ví dụ 2: Bill Cơm Tấm
  static const String comTamBill = '''
CƠM TẤM SÀI GÒN
12/1 Lê Văn Việt, Q9
=============================
1. Cơm tấm sườn bì      45.000
2. Trà đá                5.000
3. Nước mía            10.000
-----------------------------
Tổng:                  60.000đ
  ''';

  /// Ví dụ3: Bill Siêu Thị
  static const String groceryBill = '''
VINMART
456 Trần Hưng Đạo
================================
Gạo ST25 5kg           180,000
Thịt heo 1kg            85,000
Rau xanh                25,000
Trứng gà 10 quả         35,000
Nước mắm                22,000
Dầu ăn                  45,000
--------------------------------
TỔNG THANH TOÁN:       392,000đ
  ''';

  /// Ví dụ 4: Bill Nhà Hàng
  static const String restaurantBill = '''
NHÀ HÀNG QUÁN NGON
234 Pasteur, Quận 1
================================
Table: 05        22/01/2026 19:30
--------------------------------
Gỏi cuốn (4 cuốn)       40,000
Phở bò đặc biệt         65,000  
Bún chả Hà Nội          55,000
Nước ngọt (2 lon)       20,000
Bia Sài Gòn (2 chai)    30,000
--------------------------------
Tạm tính:              210,000
VAT 10%:                21,000
TỔNG CỘNG:             231,000đ
  ''';

  /// Test parser với text mẫu
  static List<Map<String, dynamic>> parseTestBill(String billText) {
    final List<Map<String, dynamic>> items = [];
    final lines = billText.split('\n');
    
    // Simple price pattern
    final pricePattern = RegExp(
      r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?)',
      caseSensitive: false,
    );

    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      
      final match = pricePattern.firstMatch(line);
      if (match != null) {
        String priceStr = match.group(1)!;
        priceStr = priceStr.replaceAll('.', '').replaceAll(',', '');
        
        final price = double.tryParse(priceStr);
        if (price == null || price < 5000) continue;
        
        String name = line.replaceFirst(match.group(0)!, '').trim();
        name = name.replaceAll(RegExp(r'^[-*•\d\s.]+'), '').trim();
        
        if (name.isNotEmpty && name.length > 2) {
          items.add({
            'name': name,
            'price': price,
          });
        }
      }
    }

    return items;
  }
}

/// Widget để demo kết quả parsing
class BillScannerDemoWidget extends StatefulWidget {
  const BillScannerDemoWidget({Key? key}) : super(key: key);

  @override
  State<BillScannerDemoWidget> createState() => _BillScannerDemoWidgetState();
}

class _BillScannerDemoWidgetState extends State<BillScannerDemoWidget> {
  String selectedBill = BillScannerDemo.highlantsCoffeeBill;
  List<Map<String, dynamic>> parsedItems = [];

  @override
  void initState() {
    super.initState();
    _parseBill();
  }

  void _parseBill() {
    setState(() {
      parsedItems = BillScannerDemo.parseTestBill(selectedBill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Scanner Demo'),
        backgroundColor: const Color(0xFF00D09E),
      ),
      body: Column(
        children: [
          // Bill selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn bill mẫu:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildBillButton('Highlands', BillScannerDemo.highlantsCoffeeBill),
                    _buildBillButton('Cơm Tấm', BillScannerDemo.comTamBill),
                    _buildBillButton('Siêu Thị', BillScannerDemo.groceryBill),
                    _buildBillButton('Nhà Hàng', BillScannerDemo.restaurantBill),
                  ],
                ),
              ],
            ),
          ),

          // Results
          Expanded(
            child: Row(
              children: [
                // Original text
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Text gốc:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SingleChildScrollView(
                              child: Text(
                                selectedBill,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Parsed items
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Kết quả parse:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${parsedItems.length} món',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: parsedItems.length,
                            itemBuilder: (context, index) {
                              final item = parsedItems[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Text(item['name']),
                                  trailing: Text(
                                    '${item['price'].toStringAsFixed(0)} đ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF00D09E),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TỔNG CỘNG:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_calculateTotal()} đ',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
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

  Widget _buildBillButton(String label, String billText) {
    final isSelected = selectedBill == billText;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            selectedBill = billText;
            _parseBill();
          });
        }
      },
      selectedColor: const Color(0xFF00D09E),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  String _calculateTotal() {
    final total = parsedItems.fold<double>(
      0,
      (sum, item) => sum + (item['price'] as double),
    );
    return total.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}