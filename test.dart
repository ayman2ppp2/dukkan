void main(List<String> args) {
  List<Product> tt = [
    Product(
        name: 'test1', buyprice: 0, sellprice: 0, count: 2, countable: true),
    Product(
        name: 'test2', buyprice: 0, sellprice: 0, count: 9, countable: true),
    Product(
        name: 'test1', buyprice: 0, sellprice: 0, count: 3, countable: true),
  ];
  tt = test().gethh(tt);
  for (Product element in tt) {
    print(element.toMap());
  }
}

class test {
  List<Product> gethh(List<Product> tt) {
    List<Product> result = [];
    Map<String, int> yy = {};
    for (var product in tt) {
      if (yy.containsKey(product.name)) {
        yy.update(product.name, (value) => product.count + value);
      } else {
        yy.addAll({product.name: product.count});
      }
    }
    for (var element in yy.entries) {
      result.add(Product(
          name: element.key,
          buyprice: 0,
          sellprice: 0,
          count: element.value,
          countable: true));
    }
    print(yy);
    return result;
  }
}

class Product {
  late String name;
  late double buyprice;
  late double sellprice;
  late int count;
  late bool countable;
  late double? weight;

  Product({
    required this.name,
    required this.buyprice,
    required this.sellprice,
    required this.count,
    required this.countable,
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
