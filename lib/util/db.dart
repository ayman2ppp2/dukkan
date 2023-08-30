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
    while (await Permission.storage.isDenied ||
        await Permission.manageExternalStorage.isDenied) {
      await Permission.manageExternalStorage.request();
      await Permission.storage.request();
    }

    inventory = await Hive.openBox('inventory');
    logs = await Hive.openBox('logs');
    owners = await Hive.openBox('owners');

    List<Product> temp = [
      Product(
        name: 'عدس',
        barcode: '',
        buyprice: 1,
        sellprice: 1.5,
        count: 1000,
        ownerName: '',
        weightable: true,
        wholeUnit: 'كيلو',
      ),
      Product(
        name: 'فول',
        barcode: '',
        buyprice: 600,
        sellprice: 700,
        count: 20,
        ownerName: ',',
        weightable: true,
        wholeUnit: 'رطل',
      ),
      Product(
        name: 'صلصة',
        barcode: '',
        buyprice: 500,
        sellprice: 600,
        count: 10,
        ownerName: '',
        weightable: false,
        wholeUnit: 'gg',
      ),
      Product(
        name: 'زيت',
        barcode: '',
        buyprice: 800,
        sellprice: 900,
        count: 15,
        ownerName: '',
        weightable: false,
        wholeUnit: 'hh',
      ),
    ];
    for (var element in temp) {
      inventory.put(element.name, element);
    }
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
    return temp2;
  }

  Future<void> insertProducts({required List<Product> products}) async {
    for (var element in products) {
      await inventory.put(element.name, element);
    }
  }

  void printProducts() {
    for (var element in getAllProducts()) {
      print(element.toMap());
    }
  }

  Future<void> CheckOut(
      {required List<Product> lst, required double total}) async {
    double price = 0;
    double profit = 0;
    for (var element in lst) {
      if (element.ownerName.isNotEmpty) {
        Owner tempOwner = owners.get(element.ownerName);
        tempOwner.dueMoney += element.sellprice * element.count;
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
        ),
      );
      price += element.sellprice * element.count;
      profit += (element.sellprice - element.buyprice) * element.count;
    }
    logs.add(
      Log(
        products: lst,
        price: price,
        profit: profit,
        date: DateTime.now(),
      ),
    );
  }
}
