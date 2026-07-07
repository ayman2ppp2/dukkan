import 'package:dukkan/util/models/Emap.dart';
import 'package:dukkan/util/models/Product.dart';

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

  static Map<String, dynamic> _productToMap(Product p) => {
        'id': p.id,
        'name': p.name,
        'ownerName': p.ownerName,
        'barcode': p.barcode,
        'weightable': p.weightable,
        'wholeUnit': p.wholeUnit,
        'buyprice': p.buyprice,
        'sellPrice': p.sellPrice,
        'count': p.count,
        'offer': p.offer,
        'offerCount': p.offerCount,
        'offerPrice': p.offerPrice,
        'priceHistory': p.priceHistory.map((e) => e.toMap()).toList(),
        'endDate': p.endDate?.toIso8601String(),
        'hot': p.hot,
      };

  static Product _productFromMap(Map<String, dynamic> map) {
    final p = Product();
    p.id = (map['id'] as num).toInt();
    p.name = map['name'] as String?;
    p.ownerName = map['ownerName'] as String?;
    p.barcode = map['barcode'] as String?;
    p.weightable = map['weightable'] as bool?;
    p.wholeUnit = map['wholeUnit'] as String?;
    p.buyprice = (map['buyprice'] as num?)?.toDouble();
    p.sellPrice = (map['sellPrice'] as num?)?.toDouble();
    p.count = (map['count'] as num?)?.toInt();
    p.offer = map['offer'] as bool?;
    p.offerCount = (map['offerCount'] as num?)?.toDouble();
    p.offerPrice = (map['offerPrice'] as num?)?.toDouble();
    final history = (map['priceHistory'] as List?);
    if (history != null) {
      p.priceHistory = history.map((e) {
        final em = e as Map<String, dynamic>;
        return Emap()
          ..date = em['date']
          ..buyPrice = em['buyPrice']
          ..sellPrice = em['sellPrice'];
      }).toList();
    }
    final endDate = map['endDate'];
    p.endDate = endDate != null ? DateTime.parse(endDate as String) : null;
    p.hot = map['hot'] as bool?;
    return p;
  }
}
