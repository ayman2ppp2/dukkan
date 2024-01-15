// import 'dart:io';

// import 'package:device_info_plus/device_info_plus.dart';
import 'package:dukkan/test.dart' as te;
import 'package:dukkan/util/models/BC_product.dart';
import 'package:dukkan/util/models/BcLog.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:permission_handler/permission_handler.dart';

import 'models/Loaner.dart';
import 'models/Owner.dart';
// import 'package:uuid/uuid.dart';

class DB {
  late Box inventory;
  late Box logs;
  late Box owners;
  late Box loaners;
  late Box invBack;
  late Box logBack;
  late Box ownersBack;
  DB() {
    init();
  }
  void init() async {
    // while (await Permission.storage.isDenied) {
    //   await Permission.storage.request();
    //   await Permission.manageExternalStorage.request();
    // }
    inventory = await Hive.openBox('inventoryv2.2.0');
    logs = await Hive.openBox('logsv2.2.0');
    owners = await Hive.openBox('ownersv2.2.0');
    loaners = await Hive.openBox('loanersv2.2.0');

    invBack = await Hive.openBox('productbackup');
    logBack = await Hive.openBox('logbackup');
    ownersBack = await Hive.openBox("ownersBackup");
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

  Future<void> useBackup() async {
    await te.gg().then((value) {
      for (var element in invBack.values) {
        Product temp = Product.fromJson(map: element);
        inventory.put(temp.name, temp);
      }
      print('finished inventory');
      for (var element in logBack.values) {
        Log temp = Log.fromMap(map: element);
        logs.put(
            '${temp.date.year}-${temp.date.month}-${temp.date.day}-${temp.date.hour}-${temp.date.minute}-${temp.date.second}',
            temp);
      }
      print('finished logs');
      for (var element in ownersBack.values) {
        Owner temp = Owner.fromJson(map: element);
        owners.put(temp.ownerName, temp);
      }
      print('finished owners');
    });
  }

  void insertLoaner(Loaner loaner) {
    loaners.put(loaner.ID, loaner);
  }

  List<Loaner> getLoaners() {
    return List<Loaner>.from(loaners.values);
  }

  List<Owner> getOwnersList() {
    return List<Owner>.from(owners.values);
  }

  void insertOwner(Owner owner) {
    owners.put(owner.ownerName, owner);
  }

  List<BcProduct> getAllProductsPev() {
    List<BcProduct> temp2 =
        inventory.values.map((e) => BcProduct.fromProduct(e)).toList();
    return temp2;
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

  List<BcLog> getAllLogsPev() {
    Iterable temp = logs.values;
    List<Log> temp2 = [];
    List<BcLog> temp3 = [];
    for (var element in temp) {
      temp2.add(element);
    }
    temp2.sort((a, b) => a.date.compareTo(b.date));
    temp2 = List<Log>.from(temp2.reversed);
    temp3 = temp2.map((e) => BcLog.fromLog(e)).toList();
    return temp3;
  }

  Future<void> insertProducts({required List<Product> products}) async {
    // products.elementAt(0).priceHistory.add({
    //   DateTime.now(): products.elementAt(0).buyprice,
    // });
    for (var element in products) {
      await inventory.put(element.name, element);
    }
  }

  // void printProducts() {
  //   for (var element in getAllProducts()) {
  //     print(element.toJson());
  //   }
  // }

  Future<void> checkOut({
    required List<Product> lst,
    required double total,
    required double discount,
    required String LoID,
    required bool loaned,
    required bool edit,
    required String logID,
  }) async {
    double price = 0;
    double profit = 0;
    for (var element in lst) {
      if (element.ownerName.isNotEmpty) {
        Owner tempOwner = owners.get(element.ownerName);
        tempOwner.dueMoney += element.buyprice * element.count;
        owners.put(element.ownerName, tempOwner);
      }

      if (!element.hot) {
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
            hot: false,
          ),
        );
        profit += ((((element.offer && element.count % element.offerCount == 0)
                            ? (element.offerPrice)
                            : (element.sellprice)) -
                        element.buyprice) *
                    element.count)
                .round() -
            discount;
        price += (((element.offer && element.count % element.offerCount == 0)
                    ? element.offerPrice
                    : element.sellprice) *
                element.count)
            .round();
      }
    }

    if (loaned) {
      loaners.put(
          LoID,
          Loaner(
            name: loaners.get(LoID).name,
            ID: loaners.get(LoID).ID,
            phoneNumber: loaners.get(LoID).phoneNumber,
            location: loaners.get(LoID).location,
            lastPayment: loaners.get(LoID).lastPayment,
            lastPaymentDate: loaners.get(LoID).lastPaymentDate,
            loanedAmount:
                loaners.get(LoID).loanedAmount + total.round() - discount,
          ));
    }

    logs.put(
      '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}-${DateTime.now().hour}-${DateTime.now().minute}-${DateTime.now().second}',
      Log(
        products: lst,
        price: price - discount,
        profit: profit,
        date: DateTime.now(),
        discount: discount,
        loaned: loaned,
        loanerID: LoID,
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