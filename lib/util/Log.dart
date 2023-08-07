import 'package:dukkan/util/product.dart';

class Log {
  List<Product> products = [];
  double price;
  double profit;
  DateTime date;
  Log(
      {required this.price,
      required this.profit,
      required this.date,
      required this.products});
}
