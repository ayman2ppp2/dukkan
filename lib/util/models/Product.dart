import 'package:hive/hive.dart';

import 'BC_product.dart';
part '../adapters/Product.g.dart';

@HiveType(typeId: 5)
class Product extends HiveObject {
  @HiveField(0, defaultValue: '')
  late String name;

  @HiveField(1, defaultValue: '')
  late String ownerName;
  @HiveField(2, defaultValue: 0)
  late double buyprice;
  @HiveField(3, defaultValue: 0)
  late double sellprice;
  @HiveField(4, defaultValue: '')
  late String barcode;
  @HiveField(5, defaultValue: 0)
  late int count;
  @HiveField(6, defaultValue: false)
  late bool weightable;
  @HiveField(7, defaultValue: '')
  late String wholeUnit;
  @HiveField(8, defaultValue: false)
  late bool offer;
  @HiveField(9, defaultValue: 0)
  late double offerCount;
  @HiveField(10, defaultValue: 0)
  late double offerPrice;
  @HiveField(11, defaultValue: <DateTime, double>{})
  late Map<DateTime, double> priceHistory;
  @HiveField(12)
  late DateTime endDate;
  @HiveField(13, defaultValue: false)
  late bool hot;

  Product(
      {required this.name,
      required this.ownerName,
      required this.barcode,
      required this.buyprice,
      required this.sellprice,
      required this.count,
      required this.weightable,
      required this.wholeUnit,
      required this.offer,
      required this.offerCount,
      required this.offerPrice,
      required this.priceHistory,
      required this.endDate,
      required this.hot});

  Product.fromBcProduct(BcProduct product) {
    name = product.name;
    ownerName = product.ownerName;
    buyprice = product.buyprice;
    sellprice = product.sellprice;
    barcode = product.barcode;
    count = product.count;
    weightable = product.weightable;
    wholeUnit = product.wholeUnit;
    offer = product.offer;
    offerCount = product.offerCount;
    offerPrice = product.offerPrice;
    priceHistory = product.priceHistory;
    endDate = product.endDate;
    hot = product.hot;
  }
  Product.fromJson({required map}) {
    name = map['name'] as String;
    ownerName = map['ownerName'] as String;
    barcode = map['barcode'] as String;
    weightable = map['weightable'] as bool;
    wholeUnit = map['wholeUnit'] as String;
    buyprice = double.parse(map['buyprice'].toString());
    sellprice = double.parse(map['sellprice'].toString());
    count = int.parse(map['count'].toString());
    offer = map['offer'] as bool;
    offerCount = double.parse(map['offerCount'].toString());
    offerPrice = double.parse(map['offerPrice'].toString());
    priceHistory = priceHistory;
    endDate = map['endDate'] as DateTime;
    hot = false;
  }

  Map<String, Object?> toJson() {
    return {
      'name': name,
      'ownerName': ownerName,
      'barcode': barcode,
      'weightable': weightable,
      'wholeUnit': wholeUnit,
      'buyprice': buyprice,
      'sellprice': sellprice,
      'count': count,
      'offer': offer,
      'offerCount': offerCount,
      'offerPrice': offerPrice,
      'priceHistory': priceHistory,
      'endDate': endDate,
    };
  }
}
