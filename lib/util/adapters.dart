import 'package:dukkan/util/product.dart';
import 'package:hive/hive.dart';

import 'Log.dart';
import 'Owner.dart';

class ProductAdapter extends TypeAdapter<Product> {
  @override
  Product read(BinaryReader reader) {
    var name = reader.read();
    var barcode = reader.read();
    var ownerName = reader.read();
    var buyprice = reader.read();
    var sellprice = reader.read();
    var count = reader.read();
    var weightable = reader.read();
    var wholeUnit = reader.read();
    var offer = reader.read();
    var offerCount = reader.read();
    var offerPrice = reader.read();
    List<Map<DateTime, double>> priceHistory =
        (reader.read() as List).cast<Map<DateTime, double>>();
    var endDate = reader.read();
    return Product(
        name: name,
        ownerName: ownerName,
        barcode: barcode,
        buyprice: buyprice,
        sellprice: sellprice,
        count: count,
        weightable: weightable,
        wholeUnit: wholeUnit,
        offer: offer,
        offerCount: offerCount,
        offerPrice: offerPrice,
        priceHistory: priceHistory,
        endDate: endDate);
  }

  @override
  int get typeId => 0;

  @override
  void write(BinaryWriter writer, Product obj) {
    writer.write(obj.name);
    writer.write(obj.barcode);
    writer.write(obj.ownerName);
    writer.write(obj.buyprice);
    writer.write(obj.sellprice);
    writer.write(obj.count);
    writer.write(obj.weightable);
    writer.write(obj.wholeUnit);
    writer.write(obj.offer);
    writer.write(obj.offerCount);
    writer.write(obj.offerPrice);
    writer.write(obj.priceHistory);
    writer.write(obj.endDate);
  }
}

class LogAdapter extends TypeAdapter<Log> {
  @override
  Log read(BinaryReader reader) {
    var price = reader.read();
    var profit = reader.read();
    var date = reader.read();
    var products = List<Product>.from(reader.read());
    return Log(price: price, profit: profit, date: date, products: products);
  }

  @override
  int get typeId => 1;

  @override
  void write(BinaryWriter writer, Log obj) {
    writer.write(obj.price);
    writer.write(obj.profit);
    writer.write(obj.date);
    writer.write(obj.products);
  }
}

class OwnerAdapter extends TypeAdapter<Owner> {
  @override
  Owner read(BinaryReader reader) {
    var ownerName = reader.read();
    var lastPaymentDate = reader.read();
    var lastPayment = reader.read();
    var dueMoney = reader.read();
    var totalPayment = reader.read();
    return Owner(
      ownerName: ownerName,
      lastPaymentDate: lastPaymentDate,
      lastPayment: lastPayment,
      totalPayed: totalPayment,
      dueMoney: dueMoney,
    );
  }

  @override
  int get typeId => 2;

  @override
  void write(BinaryWriter writer, Owner obj) {
    writer.write(obj.ownerName);
    writer.write(obj.lastPaymentDate);
    writer.write(obj.lastPayment);
    writer.write(obj.dueMoney);
    writer.write(obj.totalPayed);
  }
}
