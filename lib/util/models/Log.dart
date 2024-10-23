import 'package:dukkan/util/models/Product.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
// import 'package:uuid/uuid.dart';

// import 'BcLog.dart';
part '../adapters/Log.g.dart';
part 'Log.g.dart';

@collection
class Log {
  Id id = Isar.autoIncrement;
  late List<EmbeddedProduct> products;

  late double price;

  late double profit;

  @Index(type: IndexType.value, unique: true, replace: true)
  late DateTime date;

  late double discount;
  @Index()
  late bool loaned;

  late int? loanerID;
  @Index()
  late bool expense;
  @Index()
  late int? expenseId;

  Log({
    required this.price,
    required this.profit,
    required this.date,
    // this.products,
    required this.discount,
    required this.loaned,
    required this.loanerID,
  });
  Log.named1({
    required this.price,
    required this.profit,
    required this.date,
    required this.products,
    required this.discount,
    required this.loaned,
    required this.loanerID,
  });
  Log.named2({
    required this.price,
    required this.profit,
    required this.date,
    required this.products,
    required this.discount,
    required this.loaned,
    required this.loanerID,
    required this.expense,
    required this.expenseId,
  });
  // Log.fromBcLog(BcLog log) {
  //   products = log.products.map((e) => Product.fromBcProduct(e)).toList();
  //   price = log.price;
  //   profit = log.profit;
  //   date = log.date;
  //   discount = log.discount;
  //   loaned = log.loaned;
  //   loanerID = log.loanerID;
  // }
  Log.fromjson({required Map map}) {
    price = map['price'] as double;
    profit = map['profit'] as double;
    date = DateTime.fromMillisecondsSinceEpoch(map['date']);
    products = List<EmbeddedProduct>.generate(map['products'].length,
        (index) => EmbeddedProduct.fromJson(map: map['products'][index]));
    discount = map['discount'];
    loaned = map['loaned'];
    loanerID = convertId(map['loanerID']).toInt();
    expense = false;
    expenseId = null;
  }
  Map<String, Object?> toJson() {
    return {
      'price': price,
      'profit': profit,
      'date': date.millisecondsSinceEpoch,
      'discount': discount,
      'loaned': loaned,
      'loanerID': loanerID,
      'products': List.generate(
          products.length, (index) => products.elementAt(index).toMap())
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'products': products
          .map((e) => e.toMap())
          .toList(), // assuming EmbeddedProduct has a toMap method
      'price': price,
      'profit': profit,
      'date': date.toIso8601String(),
      'discount': discount,
      'loaned': loaned,
      'loanerID': loanerID,
      'expense': expense,
      'expenseId': expenseId,
    };
  }

  static Log fromMap(Map<String, dynamic> map) {
    return Log.named2(
      price: map['price'] as double,
      profit: map['profit'] as double,
      date: DateTime.parse(map['date'] as String),
      products: (map['products'] as List)
          .map((item) => EmbeddedProduct.fromMap(item as Map<String, dynamic>))
          .toList(), // assuming EmbeddedProduct has a fromMap method
      discount: map['discount'] as double,
      loaned: map['loaned'] as bool,
      loanerID: map['loanerID'] as int?,
      expense: map['expense'] as bool,
      expenseId: map['expenseId'] as int?,
    );
  }

  int convertId(id) {
    if (id == -3750763034362895579) {
      return 0;
    } else {
      int largeNumber = id;

      // Convert to a 4-digit number using modulo
      int fourDigitNumber = (largeNumber % 10000).toInt();
      return fourDigitNumber;
      // print('4-digit number: $fourDigitNumber');
    }
  }
}
