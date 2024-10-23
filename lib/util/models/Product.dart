import 'package:dukkan/util/models/Emap.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'BC_product.dart';
part '../adapters/Product.g.dart';
part 'Product.g.dart';

@Collection(inheritance: false)
class Product {
  Id id = Isar.autoIncrement;
  // @HiveField(0, defaultValue: '')
  @Index(
      unique: true, caseSensitive: false, type: IndexType.value, replace: true)
  String? name;

  // @HiveField(1, defaultValue: '')
  String? ownerName;
  // @HiveField(2, defaultValue: 0)
  double? buyprice;
  // @HiveField(3, defaultValue: 0)
  double? sellPrice;
  // @HiveField(4, defaultValue: '')
  String? barcode;
  // @HiveField(5, defaultValue: 0)
  int? count;
  // @HiveField(6, defaultValue: false)
  bool? weightable;
  // @HiveField(7, defaultValue: '')
  String? wholeUnit;
  // @HiveField(8, defaultValue: false)
  bool? offer;
  // @HiveField(9, defaultValue: 0)
  double? offerCount;
  // @HiveField(10, defaultValue: 0)
  double? offerPrice;
  // @HiveField(11, defaultValue: <DateTime, double>{})
  late List<Emap> priceHistory = List.empty(growable: true);

  // @HiveField(12)
  DateTime? endDate;
  // @HiveField(13, defaultValue: false)
  bool? hot;
  Product();
  Product.named({
    required this.name,
    required this.ownerName,
    required this.barcode,
    required this.buyprice,
    required this.sellPrice,
    required this.count,
    required this.weightable,
    required this.wholeUnit,
    required this.offer,
    required this.offerCount,
    required this.offerPrice,
    required this.priceHistory,
    required this.endDate,
    required this.hot,
  });
  Product.named2(
      {required this.name,
      required this.ownerName,
      required this.barcode,
      required this.buyprice,
      required this.sellPrice,
      required this.count,
      required this.weightable,
      required this.wholeUnit,
      required this.offer,
      required this.offerCount,
      required this.offerPrice,
      required this.priceHistory,
      required this.endDate,
      required this.hot,
      required this.id});

  // Product.fromBcProduct(BcProduct product) {
  //   name = product.name;
  //   ownerName = product.ownerName;
  //   buyprice = product.buyprice;
  //   sellPrice = product.sellPrice;
  //   barcode = product.barcode;
  //   count = product.count;
  //   weightable = product.weightable;
  //   wholeUnit = product.wholeUnit;
  //   offer = product.offer;
  //   offerCount = product.offerCount;
  //   offerPrice = product.offerPrice;
  //   // priceHistory = [];
  //   endDate = product.endDate;
  //   hot = product.hot;
  // }
  Product.fromJson({required map}) {
    name = map['name'] as String;
    ownerName = map['ownerName'] as String;
    barcode = map['barcode'] as String;
    weightable = map['weightable'] as bool;
    wholeUnit = map['wholeUnit'] as String;
    buyprice = double.parse(map['buyprice'].toString());
    sellPrice = double.parse(map['sellPrice'].toString());
    count = int.parse(map['count'].toString());
    offer = map['offer'] as bool;
    offerCount = double.parse(map['offerCount'].toString());
    offerPrice = double.parse(map['offerPrice'].toString());
    priceHistory = (map['priceHistory'] as List<Map<String, dynamic>>)
        .map((e) => Emap()
          ..date = e['date']
          ..buyPrice = e['buyPrice']
          ..sellPrice = e['sellPrice'])
        .toList();
    endDate = map['endDate'] as DateTime;
    hot = map['hot'];
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'name': name,
      'ownerName': ownerName,
      'barcode': barcode,
      'weightable': weightable,
      'wholeUnit': wholeUnit,
      'buyprice': buyprice,
      'sellPrice': sellPrice,
      'count': count,
      'offer': offer,
      'offerCount': offerCount,
      'offerPrice': offerPrice,
      'priceHistory': List.generate(priceHistory.length,
          (index) => priceHistory.elementAt(index).toMap()),
      'endDate': endDate,
      'hot': hot,
    };
  }

  EmbeddedProduct toEmbedded() {
    return EmbeddedProduct()
      ..buyPrice = buyprice!
      ..count = count
      ..productId = id
      ..name = name
      ..sellPrice =
          (offer! && count! % offerCount! == 0) ? offerPrice! : sellPrice!
      ..hot = hot;
    // ..offer = offer;
  }
}

@embedded
class EmbeddedProduct {
  // Id id = Isar.autoIncrement;
  String? name;
  int? productId;
  double? buyPrice;
  double? sellPrice;
  int? count;
  bool? hot;
  // bool? offer;
  // double? offerCount;
  // double? offerPrice;
  DateTime? endDate;

  EmbeddedProduct();
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'productId': productId,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'count': count,
      'hot': hot,
      'endDate': endDate?.toIso8601String(),
    };
  }

  /// Create an EmbeddedProduct object from a Map<String, dynamic>
  static EmbeddedProduct fromMap(Map<String, dynamic> map) {
    return EmbeddedProduct()
      ..name = map['name'] as String?
      ..productId = map['productId'] as int?
      ..buyPrice = map['buyPrice'] as double?
      ..sellPrice = map['sellPrice'] as double?
      ..count = map['count'] as int?
      ..hot = map['hot'] as bool?
      ..endDate = map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null;
  }

  EmbeddedProduct.fromJson({required map}) {
    // return EmbeddedProduct()
    name = map['name'];
    productId = map['productId'];
    buyPrice = map['buyPrice'];
    sellPrice = map['sellPrice'];
    count = map['count'];
    hot = map['hot'];
    // offer = map['offer'];
    // offerCount = map['offerCount'];
    // offerPrice = map['offerPrice'];
    endDate = map['endDate'];
  }
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'productId': productId,
      'buyPrice': buyPrice,
      'sellPrice': sellPrice,
      'count': count,
      'hot': hot,
      // 'offer': offer,
      // 'offerCount': offerCount,
      // 'offerPrice': offerPrice,
      'endDate': endDate,
    };
  }
}
