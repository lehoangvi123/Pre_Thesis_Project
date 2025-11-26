class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String iconName;
  final String colorHex;
  final double budgetLimit;
  final bool isDefault;
  final String userId;
  final DateTime createdAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
    this.budgetLimit = 0,
    this.isDefault = false,
    required this.userId,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconName': iconName,
      'colorHex': colorHex,
      'budgetLimit': budgetLimit,
      'isDefault': isDefault,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'expense',
      iconName: map['iconName'] ?? 'category',
      colorHex: map['colorHex'] ?? '#4CAF50',
      budgetLimit: (map['budgetLimit'] ?? 0).toDouble(),
      isDefault: map['isDefault'] ?? false,
      userId: map['userId'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  CategoryModel copyWith({
    String? name,
    String? iconName,
    String? colorHex,
    double? budgetLimit,
  }) {
    return CategoryModel(
      id: this.id,
      name: name ?? this.name,
      type: this.type,
      iconName: iconName ?? this.iconName,
      colorHex: colorHex ?? this.colorHex,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      isDefault: this.isDefault,
      userId: this.userId,
      createdAt: this.createdAt,
    );
  }
}