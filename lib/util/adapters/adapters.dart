import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:hive/hive.dart';

import '../models/Log.dart';
import '../models/Owner.dart';

// class ProductAdapter extends TypeAdapter<Product> {
//   @override
//   Product read(BinaryReader reader) {
//     var name = reader.read();
//     var barcode = reader.read();
//     var ownerName = reader.read();
//     var buyprice = reader.read();
//     var sellprice = reader.read();
//     var count = reader.read();
//     var weightable = reader.read();
//     var wholeUnit = reader.read();
//     var offer = reader.read();
//     var offerCount = reader.read();
//     var offerPrice = reader.read();
//     var priceHistory = reader.read();
//     var endDate = reader.read();
//     var hot = reader.read();
//     return Product(
//       name: name,
//       ownerName: ownerName,
//       barcode: barcode,
//       buyprice: buyprice,
//       sellprice: sellprice,
//       count: count,
//       weightable: weightable,
//       wholeUnit: wholeUnit,
//       offer: offer,
//       offerCount: offerCount,
//       offerPrice: offerPrice,
//       priceHistory: priceHistory,
//       endDate: endDate,
//       hot: hot,
//     );
//   }

//   @override
//   int get typeId => 0;

//   @override
//   void write(BinaryWriter writer, Product obj) {
//     writer.write(obj.name);
//     writer.write(obj.barcode);
//     writer.write(obj.ownerName);
//     writer.write(obj.buyprice);
//     writer.write(obj.sellprice);
//     writer.write(obj.count);
//     writer.write(obj.weightable);
//     writer.write(obj.wholeUnit);
//     writer.write(obj.offer);
//     writer.write(obj.offerCount);
//     writer.write(obj.offerPrice);
//     writer.write(obj.priceHistory);
//     writer.write(obj.endDate);
//     writer.write(obj.hot);
//   }
// }

// class LogAdapter extends TypeAdapter<Log> {
//   @override
//   Log read(BinaryReader reader) {
//     var price = reader.read();
//     var profit = reader.read();
//     var date = reader.read();
//     var products = List<Product>.from(reader.read());
//     var discount = reader.read();
//     var loaned = reader.read();
//     var loanerID = reader.read();
//     return Log(
//       price: price,
//       profit: profit,
//       date: date,
//       products: products,
//       discount: discount,
//       loaned: loaned,
//       loanerID: loanerID,
//     );
//   }

//   @override
//   int get typeId => 1;

//   @override
//   void write(BinaryWriter writer, Log obj) {
//     writer.write(obj.price);
//     writer.write(obj.profit);
//     writer.write(obj.date);
//     writer.write(obj.products);
//     writer.write(obj.discount);
//     writer.write(obj.loaned);
//     writer.write(obj.loanerID);
//   }
// }

// class OwnerAdapter extends TypeAdapter<Owner> {
//   @override
//   Owner read(BinaryReader reader) {
//     var ownerName = reader.read();
//     var lastPaymentDate = reader.read();
//     var lastPayment = reader.read();
//     var dueMoney = reader.read();
//     var totalPayment = reader.read();
//     return Owner(
//       ownerName: ownerName,
//       lastPaymentDate: lastPaymentDate,
//       lastPayment: lastPayment,
//       totalPayed: totalPayment,
//       dueMoney: dueMoney,
//     );
//   }

//   @override
//   int get typeId => 2;

//   @override
//   void write(BinaryWriter writer, Owner obj) {
//     writer.write(obj.ownerName);
//     writer.write(obj.lastPaymentDate);
//     writer.write(obj.lastPayment);
//     writer.write(obj.dueMoney);
//     writer.write(obj.totalPayed);
//   }
// }

// class LoanerAdapter extends TypeAdapter<Loaner> {
//   @override
//   Loaner read(BinaryReader reader) {
//     var name = reader.read();
//     var ID = reader.read();
//     var phoneNumber = reader.read();
//     var location = reader.read();
//     var lastPayment = reader.read();
//     var lastPaymentDate = reader.read();
//     var loanedAmount = reader.read();
//     return Loaner(
//       name: name,
//       ID: ID,
//       phoneNumber: phoneNumber,
//       location: location,
//       lastPayment: lastPayment,
//       lastPaymentDate: lastPaymentDate,
//       loanedAmount: loanedAmount,
//     );
//   }

//   @override
//   // TODO: implement typeId
//   int get typeId => 3;

//   @override
//   void write(BinaryWriter writer, Loaner obj) {
//     writer.write(obj.name);
//     writer.write(obj.ID);
//     writer.write(obj.phoneNumber);
//     writer.write(obj.location);
//     writer.write(obj.lastPayment);
//     writer.write(obj.lastPaymentDate);
//     writer.write(obj.loanedAmount);
//   }
// }
