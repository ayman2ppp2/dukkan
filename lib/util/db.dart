import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dukkan/util/Log.dart';
import 'package:dukkan/util/product.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import 'Owner.dart';

class DB {
  late Box inventory;
  late Box logs;
  late Box owners;
  DB() {
    init();
  }
  void init() async {
    inventory = await Hive.openBox('inventory');
    logs = await Hive.openBox('logs');
    owners = await Hive.openBox('owners');

    // List<Product> temp = [
    // Product(
    //   name: 'شعرية',
    //   barcode: '',
    //   buyprice: 250,
    //   sellprice: 400,
    //   count: 20,
    //   ownerName: '',
    //   weightable: false,
    //   wholeUnit: 'كيلو',
    //   offer: true,
    //   offerCount: 3,
    //   offerPrice: 333.3333333333,
    //   priceHistory: [],
    //   endDate: DateTime(2024),
    // ),
    //   Product(
    //     name: 'فول',
    //     barcode: '',
    //     buyprice: 600,
    //     sellprice: 700,
    //     count: 20,
    //     ownerName: ',',
    //     weightable: true,
    //     wholeUnit: 'رطل',
    //   ),
    //   Product(
    //     name: 'صلصة',
    //     barcode: '',
    //     buyprice: 500,
    //     sellprice: 600,
    //     count: 10,
    //     ownerName: '',
    //     weightable: false,
    //     wholeUnit: 'gg',
    //   ),
    //   Product(
    //     name: 'زيت',
    //     barcode: '',
    //     buyprice: 800,
    //     sellprice: 900,
    //     count: 15,
    //     ownerName: '',
    //     weightable: false,
    //     wholeUnit: 'hh',
    //   ),
    // ];
    // for (var element in temp) {
    //   inventory.put(element.name, element);
    // }
  }

  List<Owner> getOwnersList() {
    return List<Owner>.from(owners.values);
  }

  void insertOwner(Owner owner) {
    owners.put(owner.ownerName, owner);
  }

  List<Product> getAllProducts() {
    List<Product> temp2 = List.from(inventory.values);
    return temp2;
  }

  List<Log> getAllLogs() {
    Iterable temp = logs.values;
    List<Log> temp2 = [];
    for (var element in temp) {
      temp2.add(element);
    }
    temp2.sort((a, b) => a.date.compareTo(b.date));
    temp2 = List<Log>.from(temp2.reversed);
    return temp2;
  }

  Future<void> insertProducts({required List<Product> products}) async {
    // products.elementAt(0).priceHistory.add({
    //   DateTime.now(): products.elementAt(0).buyprice,
    // });
    for (var element in products) {
      await inventory.put(element.name, element);
    }
  }

  void printProducts() {
    for (var element in getAllProducts()) {
      print(element.toJson());
    }
  }

  Future<void> checkOut(
      {required List<Product> lst, required double total}) async {
    double price = 0;
    double profit = 0;
    for (var element in lst) {
      if (element.ownerName.isNotEmpty) {
        Owner tempOwner = owners.get(element.ownerName);
        tempOwner.dueMoney += element.buyprice * element.count;
        owners.put(element.ownerName, tempOwner);
      }
      inventory.put(
        element.name,
        Product(
          name: element.name,
          barcode: element.barcode,
          buyprice: element.buyprice,
          sellprice: element.sellprice,
          count: (inventory.get(element.name))!.count - element.count,
          ownerName: element.ownerName,
          weightable: element.weightable,
          wholeUnit: element.wholeUnit,
          offer: element.offer,
          offerCount: element.offerCount,
          offerPrice: element.offerPrice,
          priceHistory: element.priceHistory,
          endDate: element.endDate,
        ),
      );
      profit += ((((element.offer && element.count % element.offerCount == 0)
                      ? (element.offerPrice)
                      : (element.sellprice)) -
                  element.buyprice) *
              element.count)
          .round();
    }
    price += total.round();

    logs.put(
      '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}',
      Log(
        products: lst,
        price: price,
        profit: profit,
        date: DateTime.now(),
      ),
    );
  }
}

// ((lst.fold(
//           00.0,
//           (previousValue, element) =>
//               previousValue +
//               ((element.offer && element.count % element.offerCount == 0)
//                   ? (element.offerPrice * element.count)
//                   : (element.sellprice * element.count)))))