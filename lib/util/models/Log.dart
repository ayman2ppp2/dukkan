import 'package:dukkan/util/models/Product.dart';
import 'package:hive/hive.dart';

import '../BcLog.dart';
part '../adapters/Log.g.dart';

@HiveType(typeId: 10)
class Log extends HiveObject {
  @HiveField(0)
  late List<Product> products = [];
  @HiveField(1)
  late double price;
  @HiveField(2)
  late double profit;
  @HiveField(3)
  late DateTime date;
  @HiveField(4, defaultValue: 0)
  late double discount;
  @HiveField(5, defaultValue: false)
  late bool loaned;
  @HiveField(6, defaultValue: '')
  late String loanerID;

  Log({
    required this.price,
    required this.profit,
    required this.date,
    required this.products,
    required this.discount,
    required this.loaned,
    required this.loanerID,
  });
  Log.fromBcLog(BcLog log) {
    products = log.products.map((e) => Product.fromBcProduct(e)).toList();
    price = log.price;
    profit = log.profit;
    date = log.date;
    discount = log.discount;
    loaned = log.loaned;
    loanerID = log.loanerID;
  }
  Log.fromMap({required Map map}) {
    price = map['price'] as double;
    profit = map['profit'] as double;
    date = DateTime.fromMillisecondsSinceEpoch(map['date']);
    products = List<Product>.generate(map['products'].length,
        (index) => Product.fromJson(map: map['products'][index]));
    discount = 0;
    loaned = false;
    loanerID = '';
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
