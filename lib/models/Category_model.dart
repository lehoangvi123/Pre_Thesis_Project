class CategoryModel {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String iconName;
  final String colorHex;

  CategoryModel({
    required this.id,
    required this.name,
    required this.type,
    required this.iconName,
    required this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      iconName: map['iconName'],
      colorHex: map['colorHex'],
    );
  }
}
