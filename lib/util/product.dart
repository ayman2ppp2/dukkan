class Product {
  late String name;
  late String ownerName;
  late double buyprice;
  late double sellprice;
  late String barcode;
  late int count;
  late bool weightable;
  late String wholeUnit;
  late bool offer;
  late double offerCount;
  late double offerPrice;

  Product({
    required this.name,
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
  });

  Product.fromMap({required Map<String, Object?> map}) {
    name = map['name'] as String;
    ownerName = map['ownerName'] as String;
    barcode = map['barcode'] as String;
    weightable = map['weightable'] as bool;
    wholeUnit = map['wholeUnit'] as String;
    buyprice = double.parse(map['buyprice'].toString());
    sellprice = double.parse(map['sellprice'].toString());
    count = int.parse(map['count'].toString());
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'ownerName': ownerName,
      'barcode': barcode,
      'weightable': weightable,
      'wholeUnit': wholeUnit,
      'buyprice': buyprice,
      'sellprice': sellprice,
      'count': count
    };
  }
}
