import 'package:dukkan/util/product.dart';

class Log {
  late List<Product> products = [];
  late double price;
  late double profit;
  late DateTime date;
  Log(
      {required this.price,
      required this.profit,
      required this.date,
      required this.products});
  Log.fromMap({required Map map}) {
    price = map['price'] as double;
    profit = map['profit'] as double;
    date = DateTime.fromMillisecondsSinceEpoch(map['date']);
    products = List<Product>.generate(map['products'].length,
        (index) => Product.fromJson(map: map['products'][index]));
  }
  Map<String, Object?> toMap() {
    return {
      'price': price,
      'profit': profit,
      'date': date.millisecondsSinceEpoch,
      'products':
          List.generate(products.length, (index) => products[index].toJson())
    };
  }
}
