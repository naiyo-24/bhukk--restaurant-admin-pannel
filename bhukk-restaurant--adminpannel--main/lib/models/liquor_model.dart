// models/liquor_model.dart
class LiquorModel {
  final String id;
  final String name;
  final String type;
  final double price;
  final String age; // '18+' or '21+'
  final String? imageUrl;
  final String description;
  final bool available;
  final int volumeMl; // bottle volume in milliliters
  final int quantity; // units in stock

  LiquorModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.age,
    this.imageUrl,
    this.description = '',
    this.available = true,
    this.volumeMl = 750,
    this.quantity = 0,
  });

  LiquorModel copyWith({
    String? id,
    String? name,
    String? type,
    double? price,
    String? age,
    String? imageUrl,
    String? description,
    bool? available,
    int? volumeMl,
    int? quantity,
  }) {
    return LiquorModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      age: age ?? this.age,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      available: available ?? this.available,
      volumeMl: volumeMl ?? this.volumeMl,
      quantity: quantity ?? this.quantity,
    );
  }

  bool get inStock => quantity > 0;

  @override
  String toString() => 'LiquorModel(id: $id, name: $name, type: $type, price: $price, ml: $volumeMl, qty: $quantity, available: $available)';
}
