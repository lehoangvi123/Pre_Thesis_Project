class CategoryModel {
  final String id;
  final String name;
  final String type; // "expense" hoặc "income"
  final String iconName;
  final String colorHex;

  const CategoryModel._({
    required this.id,
    required this.name,
    required this.type,
    this.iconName = "",
    this.colorHex = "",
  });

  // ✅ Factory named constructors
  factory CategoryModel.expense({required String id, String? name, String? iconName, String? colorHex}) =>
      CategoryModel._(
        id: id,
        name: name ?? id,
        type: "expense",
        iconName: iconName ?? "",
        colorHex: colorHex ?? "",
      );

  factory CategoryModel.income({required String id, String? name, String? iconName, String? colorHex}) =>
      CategoryModel._(
        id: id,
        name: name ?? id,
        type: "income",
        iconName: iconName ?? "",
        colorHex: colorHex ?? "",
      );

  // ✅ Convert Firestore → CategoryModel
  factory CategoryModel.fromMap(Map<String, dynamic> map) {
    return CategoryModel._(
      id: map['id'] ?? "",
      name: map['name'] ?? "",
      type: map['type'] ?? "",
      iconName: map['iconName'] ?? "",
      colorHex: map['colorHex'] ?? "",
    );
  }

  // ✅ Convert CategoryModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'iconName': iconName,
      'colorHex': colorHex,
    };
  }
}
