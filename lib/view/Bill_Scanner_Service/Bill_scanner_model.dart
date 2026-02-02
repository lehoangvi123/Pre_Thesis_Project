// lib/models/bill_scanner_model.dart

class BillItem {
  final String name;
  final double price;
  final int quantity;

  BillItem({
    required this.name,
    required this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'price': price,
        'quantity': quantity,
      };

  factory BillItem.fromJson(Map<String, dynamic> json) => BillItem(
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] as int? ?? 1,
      );

  double get totalPrice => price * quantity;
}

class ScannedBill {
  final List<BillItem> items;
  final DateTime scannedAt;
  final String? storeName;
  final String? imageUrl;

  ScannedBill({
    required this.items,
    required this.scannedAt,
    this.storeName,
    this.imageUrl,
  });

  double get totalAmount => items.fold(0, (sum, item) => sum + item.totalPrice);

  int get itemCount => items.length;

  Map<String, dynamic> toJson() => {
        'items': items.map((item) => item.toJson()).toList(),
        'scannedAt': scannedAt.toIso8601String(),
        'storeName': storeName,
        'imageUrl': imageUrl,
        'totalAmount': totalAmount,
      };

  factory ScannedBill.fromJson(Map<String, dynamic> json) => ScannedBill(
        items: (json['items'] as List)
            .map((item) => BillItem.fromJson(item as Map<String, dynamic>))
            .toList(),
        scannedAt: DateTime.parse(json['scannedAt'] as String),
        storeName: json['storeName'] as String?,
        imageUrl: json['imageUrl'] as String?,
      );
}