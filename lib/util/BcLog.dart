import 'models/BC_product.dart';
import 'models/Log.dart';
import 'models/Product.dart';

class BcLog {
  late List<BcProduct> products = [];
  late double price;
  late double profit;
  late DateTime date;
  late double discount;
  late bool loaned;
  late String loanerID;

  BcLog.fromLog(Log log) {
    products = log.products.map((e) => BcProduct.fromProduct(e)).toList();
    price = log.price;
    profit = log.profit;
    date = log.date;
    discount = log.discount;
    loaned = log.loaned;
    loanerID = log.loanerID;
  }
}
