import 'package:dukkan/models/Product.dart';

class PendingCart {
  final String name;
  final List<Product> products;
  final DateTime parkedAt;

  PendingCart({
    required this.name,
    required this.products,
    required this.parkedAt,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'products': products.map(_productToMap).toList(),
        'parkedAt': parkedAt.toIso8601String(),
      };

  static PendingCart fromJson(Map<String, dynamic> json) => PendingCart(
        name: json['name'] as String,
        products: (json['products'] as List)
            .map((e) => _productFromMap(e as Map<String, dynamic>))
            .toList(),
        parkedAt: DateTime.parse(json['parkedAt'] as String),
      );

  static Map<String, dynamic> _productToMap(Product p) => p.toJson();

  static Product _productFromMap(Map<String, dynamic> map) =>
      Product.fromJson(map: map);
}
