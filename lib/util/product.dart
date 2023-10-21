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
  late List<Map<DateTime, double>> priceHistory;
  late DateTime endDate;

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
    required this.priceHistory,
    required this.endDate,
  });

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
    priceHistory = List.generate(map['priceHistory'].length,
            (index) => map['priceHistory'].elementAt(index))
        .cast<Map<DateTime, double>>();
    endDate = map['endDate'] as DateTime;
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
      'priceHistory': List.generate(
          priceHistory.length, (index) => priceHistory.elementAt(index)),
      'endDate': endDate,
    };
  }
}
