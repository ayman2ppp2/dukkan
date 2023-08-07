class Product {
  late String name;
  late String ownerName;
  late double buyprice;
  late double sellprice;
  late int count;
  late bool weightable;
  late String wholeUnit;
  

  Product({
    required this.name,
    required this.buyprice,
    required this.sellprice,
    required this.count,
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
