import 'package:dukkan/util/models/Emap.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:isar_community/isar.dart';

Product productFixture({
  int id = Isar.autoIncrement,
  String name = 'Sugar',
  String ownerName = 'Golden',
  String barcode = '123456',
  double buyPrice = 6,
  double sellPrice = 10,
  int count = 10,
  bool offer = false,
  double offerCount = 0,
  double offerPrice = 0,
  DateTime? priceDate,
}) {
  return Product.named2(
    id: id,
    name: name,
    ownerName: ownerName,
    barcode: barcode,
    buyprice: buyPrice,
    sellPrice: sellPrice,
    count: count,
    weightable: false,
    wholeUnit: '',
    offer: offer,
    offerCount: offerCount,
    offerPrice: offerPrice,
    priceHistory: [
      Emap()
        ..buyPrice = buyPrice
        ..sellPrice = sellPrice
        ..date = priceDate ?? DateTime.now(),
    ],
    endDate: DateTime.now().add(const Duration(days: 30)),
    hot: false,
  );
}

Owner ownerFixture({String name = 'Golden', double dueMoney = 0}) {
  return Owner(
    ownerName: name,
    lastPaymentDate: DateTime.now(),
    lastPayment: 0,
    totalPayed: 0,
    dueMoney: dueMoney,
  );
}

Loaner loanerFixture({
  String name = 'Customer',
  double amount = 0,
  DateTime? paymentDate,
}) {
  return Loaner(
    name: name,
    phoneNumber: '0910000000',
    location: 'Market',
    lastPayment: [
      EmbeddedMap()
        ..key = (paymentDate ?? DateTime.now()).toIso8601String()
        ..value = '0'
        ..remaining = amount,
    ],
    loanedAmount: amount,
  )..zeroingDate = DateTime(1900);
}

Expense expenseFixture({String name = 'Delivery', double amount = 0}) {
  return Expense.named(
    name: name,
    amount: amount,
    period: 0,
    payDate: null,
    lastCalculationDate: DateTime.now(),
    fixed: false,
  );
}

Log logFixture({
  required Product product,
  int count = 1,
  int? loanerId,
  DateTime? date,
}) {
  final sold = productFixture(
    id: product.id,
    name: product.name ?? 'Sugar',
    ownerName: product.ownerName ?? 'Golden',
    barcode: product.barcode ?? '123456',
    buyPrice: product.buyprice ?? 6,
    sellPrice: product.sellPrice ?? 10,
    count: count,
    offer: product.offer ?? false,
    offerCount: product.offerCount ?? 0,
    offerPrice: product.offerPrice ?? 0,
  );
  return Log.named2(
    price: (product.sellPrice ?? 0) * count,
    profit: ((product.sellPrice ?? 0) - (product.buyprice ?? 0)) * count,
    date: date ?? DateTime.now(),
    products: [sold.toEmbedded()],
    discount: 0,
    loaned: loanerId != null,
    loanerID: loanerId,
    expense: false,
    expenseId: null,
  );
}
