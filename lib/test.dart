// import 'dart:io';
// import 'dart:isolate';
// // import 'dart:ui';
// import 'package:dukkan/util/adapters.dart';
// import 'package:dukkan/util/Product.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

// import 'package:flutter/foundation.dart';

Future<void> gg() async {
  var te = await getApplicationDocumentsDirectory();
  // print(te.path);
  // 'storage/emulated/0/dukkan/v2'
  Hive.init(te.path);

  // Hive.deleteBoxFromDisk('productBackup');
  // Hive.deleteBoxFromDisk('ownersBackup');
  // Hive.deleteBoxFromDisk('LogBackup');

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(LogAdapter());
  Hive.registerAdapter(OwnerAdapter());
  Box inv = await Hive.openBox('inventory');
  // Hive.registerAdapter(LogAdapter());
  Box back = await Hive.openBox('productBackup');

  Box logs = await Hive.openBox('logs');
  // Hive.registerAdapter(LogAdapter());
  Box loBack = await Hive.openBox('LogBackup');

  Box owners = await Hive.openBox('owners');
  // Hive.registerAdapter(LogAdapter());
  Box ownersBack = await Hive.openBox('ownersBackup');

  print(inv.values.length);
  for (Log element in logs.values) {
    loBack.add(element.toMap());
  }
  print(logs.values.length);
  for (Product element in inv.values) {
    back.put(element.name, element.toJson());
  }
  for (Owner element in owners.values) {
    ownersBack.put(element.ownerName, element.toJson());
  }
}

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
    priceHistory = map['priceHistory'];
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
      'priceHistory': {},
      'endDate': endDate,
    };
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

class Owner {
  late String ownerName;
  late DateTime lastPaymentDate;
  late double lastPayment;
  late double totalPayed;
  late double dueMoney;
  Owner({
    required this.ownerName,
    required this.lastPaymentDate,
    required this.lastPayment,
    required this.totalPayed,
    required this.dueMoney,
  });
  Map<String, Object?> toJson() {
    return {
      'ownerName': ownerName,
      'lastPaymentDate': lastPaymentDate,
      'lastPayment': lastPayment,
      'totalPayed': totalPayed,
      'dueMoney': dueMoney,
    };
  }

  Owner.fromJson({required Map<String, Object?> map}) {
    ownerName = map['ownerName'] as String;
    lastPaymentDate = map['lastPaymentDate'] as DateTime;
    lastPayment = map['lastPayment'] as double;
    totalPayed = map['totalPayed'] as double;
    dueMoney = map['dueMoney'] as double;
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

// class responder {
//   responder({
//     required this.Brs,
//     required this.iso,
//     required this.sp,
//   });
//   var recievePort;
//   Stream Brs;
//   SendPort sp;
//   Isolate iso;
//   static Future<responder> init() async {
//     var recievePort = ReceivePort();
//     var _iso = await Isolate.spawn(heavy, recievePort.sendPort);
//     var _Brs = recievePort.asBroadcastStream();
//     var _sp = await _Brs.first;
//     return responder(Brs: _Brs, iso: _iso, sp: _sp);
//   }
// }

// void heavy(SendPort sp) {
//   ReceivePort rp = ReceivePort();
//   sp.send(rp.sendPort);
//   rp.forEach((element) {
//     if (element == 'here') {
//       sp.send(99.99);
//     } else if (element == 'now') {
//       sp.send(77);
//     } else {
//       sp.send('bye..');
//       exit(0);
//     }
//   });
//   // return 99;
// }
