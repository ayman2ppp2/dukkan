class Product {
  late String name;
  late String ownerName;
  late double buyprice;
  late double sellprice;
  late String barcode;
  late int count;
  late bool weightable;
  late String wholeUnit;

  Product({
    required this.name,
    required this.ownerName,
    required this.barcode,
    required this.buyprice,
    required this.sellprice,
    required this.count,
    required this.weightable,
    required this.wholeUnit,
  });

  Product.fromMap({required Map<String, Object?> map}) {
    name = map['name'] as String;

    buyprice = double.parse(map['buyprice'].toString());

    sellprice = double.parse(map['sellprice'].toString());

    count = int.parse(map['count'].toString());
  }

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'buyprice': buyprice,
      'sellprice': sellprice,
      'count': count
    };
  }
}
