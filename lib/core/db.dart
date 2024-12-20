// import 'dart:io';

// import 'package:device info_plus/device_info_plus.dart';

import 'dart:convert';
import 'dart:io';

import 'package:dukkan/core/IsolatePool.dart';
import 'package:dukkan/test.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/models/prodStats.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:isar/isar.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:path_provider/path_provider.dart';

import '../util/models/Loaner.dart';
import '../util/models/Owner.dart';
// import 'package:uuid/uuid.dart';

class DB {
  late Box inventory;
  late Box logs;
  late Box owners;
  late Box loaners;
  late Box invBack;
  late Box logBack;
  late Box ownersBack;
  late Isar isar;
  late IsolatePool pool;
  gg g = gg();
  DB() {
    init();
  }
  void init() async {
    pool = await Pool.init();
    final dir = await getApplicationDocumentsDirectory();
    try {
      isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: 'isarInstance',
      );
      // print('try worked');
    } catch (e) {
      isar = await Isar.getInstance('isarInstance')!;
      // print('catch worked');
    }
    // var dir = await getApplicationDocumentsDirectory();
    // if (!isar.isOpen) {
    //   isar = await Isar.open(
    //       inspector: true,
    //       [ProductSchema, LogSchema, LoanerSchema, OwnerSchema],
    //       directory: dir.path,
    //       name: 'isarInstance');
    // }

    // await isar.writeTxn(() => isar.products.clear());
    // isar.writeTxn(() {
    //   return isar.products.put(
    //     Product.named(
    //       name: 'gg',
    //       ownerName: "",
    //       barcode: 'barcode',
    //       buyprice: 10,
    //       sellprice: 20,
    //       count: 20,
    //       weightable: false,
    //       wholeUnit: 'wholeUnit',
    //       offer: false,
    //       offerCount: 0,
    //       offerPrice: 0,
    //       endDate: DateTime.now(),
    //       hot: false,
    //     ),
    //   );
    // });
    // isar.writeTxn(() {
    //   return isar.logs.put(Log(
    //       price: 200,
    //       profit: 20,
    //       date: DateTime.now(),
    //       discount: 0,
    //       loaned: false,
    //       loanerID: 0));
    // });
    // Log temp = await isar.logs.where().findFirst() ??
    //     Log(
    //         price: 200,
    //         profit: 20,
    //         date: DateTime.now(),
    //         discount: 0,
    //         loaned: false,
    //         loanerID: 0);
    // temp.products.add((await isar.products.where().findFirst())!);
    // isar.writeTxn(
    //   () {
    //     return temp.products.save();
    //   },
    // );
    // print(await isar.logs.where().anyId().count());
    // isar.products
    //     .where()
    //     .anyId()
    //     .findFirst()
    //     .then((value) => print(value!.toJson()));
    // while (await Permission.storage.isDenied) {
    //   await Permission.storage.request();
    //   await Permission.manageExternalStorage.request();
    // }
    // inventory = await Hive.openBox('inventoryv2.2.0');
    // logs = await Hive.openBox('logsv2.2.0');
    // owners = await Hive.openBox('ownersv2.2.0');
    // loaners = await Hive.openBox('loanersv2.2.0');
    // invBack = await Hive.openBox('productbackup');
    // logBack = await Hive.openBox('logbackup');
    // ownersBack = await Hive.openBox("ownersBackup");
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

  // @override
  // void didChangeAppLifecycleState(AppLifecycleState state) {
  //   if (state == AppLifecycleState.paused ||
  //       state == AppLifecycleState.inactive) {
  //     // App is no longer in the foreground, may be terminated
  //     pool.stop();
  //     isar.close(); // Anticipate termination
  //   } else if (state == AppLifecycleState.detached) {
  //     // App is about to terminate
  //     pool.stop();
  //     isar.close();
  //   }
  // }

  void closeAll() {
    inventory.close();
    logs.close();
    owners.close();
    loaners.close();
    invBack.close();
    logBack.close();
    ownersBack.close();
  }

  Future<bool> deleteLoaner(int id) {
    return isar.writeTxn(() => isar.loaners.delete(id));
  }

  Future<List<int>> updateProducts(List<EmbeddedProduct> products) async {
    var ids = products.map((e) => e.hot! ? 0 : e.productId!).toList();
    var realProducts = embeddedToProduct(ids);
    var updatedRealProducts = List<Product>.empty(growable: true);
    for (var product in realProducts.nonNulls.toList()) {
      // var num = await isar.products.get(product.id);
      var emCount = products
          .firstWhere((element) => element.productId == product.id)
          .count;
      updatedRealProducts.add(Product.named2(
          name: product.name,
          ownerName: product.ownerName,
          barcode: product.barcode,
          buyprice: product.buyprice,
          sellPrice: product.sellPrice,
          count: product.count! + emCount!,
          weightable: product.weightable,
          wholeUnit: product.wholeUnit,
          offer: product.offer,
          offerCount: product.offerCount,
          offerPrice: product.offerPrice,
          priceHistory: product.priceHistory,
          endDate: product.endDate,
          hot: product.hot,
          id: product.id));
    }
    return isar.writeTxn(() async => isar.products.putAll(updatedRealProducts));
  }

  Future<void> useBackup() async {
    gg g = gg();
    await g.init();
    List<Product> temp = List.empty(growable: true);
    for (Map<String, dynamic> element in g.getProducts()) {
      temp.add(Product.fromJson(map: element));
    }
    await isar.writeTxn(
      () async => isar.products.putAll(temp),
    );
    print('finished inventory');
    List<Log> temp1 = List.empty(growable: true);
    var logs = await g.getLogs();
    for (Map<String, dynamic> map in logs) {
      Log log = Log.fromMap(map);
      temp1.add(log);
    }
    await isar.writeTxn(() async {
      return isar.logs.putAll(temp1);
    });

    // for (var element in await isar.logs.where().anyId().findAll()) {
    //   isar.writeTxn(() {
    //     element.products.addAll(element.oldProducts);
    //     return element.products.save();
    //   });
    // }
    print('finished logs');
    List<Owner> temp2 = List.empty(growable: true);

    for (Map<String, dynamic> map in g.getOwners()) {
      temp2.add(Owner.fromJson(map: map));
    }
    await isar.writeTxn(
      () async => isar.owners.putAll(temp2),
    );
    print('finished owners');
    List<Loaner> temp3 = List.empty(growable: true);

    for (Map<String, dynamic> map in g.getLoaner()) {
      temp3.add(Loaner.fromMap(map: map));
    }
    await isar.writeTxn(
      () async => isar.loaners.putAll(temp3),
    );
    print('finished loaners');
  }

  Future<int> insertLoaner(Loaner loaner) {
    return isar.writeTxn(() => isar.loaners.put(loaner));
    // loaners.put(loaner.ID, loaner);
  }

  Future<List<Loaner>> getLoaners() {
    return isar.loaners.where().anyID().sortByLoanedAmountDesc().findAll();
    // return List<Loaner>.from(loaners.values);
  }

  Future<int> updateLoaner(Log log, double sum) async {
    Loaner temp =
        (await isar.loaners.where().iDEqualTo(log.loanerID!).findFirst())!;

    return isar.writeTxn(() async => isar.loaners.put(
          // log.loanerID,
          Loaner(
            name: temp.name,
            // ID: temp.ID,
            phoneNumber: temp.phoneNumber,
            location: temp.location,
            lastPayment: temp.lastPayment,
            // lastPaymentDate: temp.lastPaymentDate,
            loanedAmount: temp.loanedAmount! - (log.price + sum),
          )..ID = temp.ID,
        ));
  }

  Future<List<Owner>> getOwnersList() {
    return isar.owners.where().anyId().findAll();
    // return List<Owner>.from(owners.values);
  }

  Future<Id> insertOwner(Owner owner) {
    return isar.writeTxn(() async => isar.owners.put(owner));
    // owners.put(owner.ownerName, owner);
  }

  // List<BcProduct> getAllProductsPev() {
  //   List<BcProduct> temp2 =
  //       inventory.values.map((e) => BcProduct.fromProduct(e)).toList();
  //   return temp2;
  // }

  Future<List<Product>> getAllProducts() async {
    List<Product> temp2 =
        await isar.products.where(sort: Sort.asc).anyId().findAll();
    return temp2;
  }

  // Future<List<Log>> getAllLogs() {
  //   // Iterable temp = logs.values;
  //   // List<Log> temp2 = [];
  //   // for (var element in temp) {
  //   //   temp2.add(element);
  //   // }
  //   // temp2.sort((a, b) => a.date.compareTo(b.date));
  //   // temp2 = List<Log>.from(temp2.reversed);
  //   // return temp2;
  //   try {
  //     return isar.logs.where().sortByDateDesc().findAll();
  //   } on Exception catch (e, s) {
  //     // TODO0
  //     print(e);
  //     print(s);
  //     return Future.value([]);
  //   }
  // }

  Future<void> deleteLog(Log log) {
    return isar.writeTxn(() async => isar.logs.delete(log.id));
  }

  Future<void> insertProducts({required List<Product> products}) async {
    // products.elementAt(0).priceHistory.add({
    //   DateTime.now(): products.elementAt(0).buyprice,
    // });
    // for (var element in products) {
    //   await inventory.put(element.name, element);
    // }
    isar.writeTxn(() => isar.products.putAll(products));
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
    required int? LoID,
    required bool loaned,
    required bool edit,
    required DateTime logID,
    required bool expense,
    required int? expenseId,
  }) async {
    double price = 0;
    double profit = 0;
    for (var element in lst) {
      if (element.ownerName!.isNotEmpty) {
        Owner? tempOwner = await (isar.owners
            .where()
            .filter()
            .ownerNameEqualTo(element.ownerName!)
            .findFirst());
        tempOwner!.dueMoney += element.buyprice! * element.count!;
        await isar.writeTxn(
          () async => await isar.owners.put(tempOwner..id = tempOwner.id),
        );
      }

      if (!element.hot!) {
        var num = await isar.products.get(element.id);
        await isar.writeTxn(() async => await isar.products.put(
              // element.name,
              Product.named2(
                id: element.id,
                name: element.name,
                barcode: element.barcode,
                buyprice: element.buyprice,
                sellPrice: element.sellPrice,
                count: (num!.count!) - element.count!,
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
            ));
        profit +=
            ((((element.offer! && element.count! % element.offerCount! == 0)
                            ? (element.offerPrice!)
                            : (element.sellPrice!)) -
                        element.buyprice!) *
                    element.count!)
                .round();

        price += (((element.offer! && element.count! % element.offerCount! == 0)
                    ? element.offerPrice!
                    : element.sellPrice!) *
                element.count!)
            .round();
      }
    }

    if (loaned) {
      var tempLoner = await isar.loaners.get(LoID!);
      await isar.writeTxn(
        () async => await isar.loaners.put(
          Loaner(
            name: tempLoner!.name,
            phoneNumber: tempLoner.phoneNumber,
            location: tempLoner.location,
            lastPayment: tempLoner.lastPayment,
            // lastPaymentDate: tempLoner.lastPaymentDate,
            loanedAmount: tempLoner.loanedAmount! + total.round() - discount,
          )..ID = LoID,
        ),
      );
    }
    if (expense) {
      var tempExpense = await isar.expenses.get(expenseId!);
      await isar.writeTxn(
        () async => await isar.expenses.put(
          Expense.named(
              name: tempExpense!.name,
              amount: tempExpense.amount! + price - discount - profit,
              period: tempExpense.period,
              payDate: tempExpense.payDate,
              lastCalculationDate: tempExpense.lastCalculationDate,
              fixed: tempExpense.fixed)
            ..ID = tempExpense.ID,
        ),
      );
    }
    var embeddedProducts = lst.map((e) => e.toEmbedded()).toList();

    var log = Log.named2(
      products: embeddedProducts,
      price: price - discount,
      profit: profit - discount,
      date: edit ? logID : DateTime.now(),
      discount: discount,
      loaned: loaned,
      loanerID: LoID,
      expense: expense,
      expenseId: expenseId,
    );
    // log.products.addAll(lst);
    await isar.writeTxn(
      () async {
        // log.products.save();
        return isar.logs.put(log);
      },
    );
  }

  Stream<List<Expense>> getExpenses({required bool fixed}) {
    var temp;
    if (fixed) {
      temp = isar.expenses.where().watch(fireImmediately: true);
    } else {
      temp = isar.expenses
          .where()
          .fixedEqualTo(false)
          .watch(fireImmediately: true);
    }
    return temp;
  }

  Future<int> addExpense(
      {required String name,
      required double amount,
      required int period,
      int? payDate,
      required bool fixed}) {
    var temp = Expense.named(
      amount: amount,
      name: name,
      period: period,
      payDate: payDate,
      lastCalculationDate: DateTime.now(),
      fixed: fixed,
    );
    // throw "error";
    return isar.writeTxn(() async => await isar.expenses.put(temp));
  }

  Future<Loaner?> getLoanerName({required int id}) async {
    return isar.loaners.get(id);
  }

  List<Product?> embeddedToProduct(List<int> ids) {
    return isar.products.getAllSync(ids);
  }

  Stream<Expense?> watchExpense({required int id}) {
    return isar.expenses.watchObject(
      id,
      fireImmediately: true,
    );
  }

  Future<bool> deleteExpense({required int id}) {
    return isar.writeTxn(() async => await isar.expenses.delete(id));
  }

  Stream<Loaner?> watchLoaner(int id) {
    return isar.loaners.watchObject(id, fireImmediately: true);
  }

  Stream<Product?> watchProduct(int id) {
    return isar.products.watchObject(id, fireImmediately: true);
  }

  Future<bool> deleteProduct(int id) {
    return isar.writeTxn(() async => await isar.products.delete(id));
  }

  Stream<List<Product>> getTotalBuyPrice() {
    return isar.products.where().watch(fireImmediately: true);
  }

  Stream<List<Loaner>> getLoanersStream() {
    return isar.loaners
        .where()
        .sortByLoanedAmountDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<Log>> getLogsStream(int chunkSize) {
    return isar.logs
        .where()
        .sortByDateDesc()
        .limit(chunkSize)
        .watch(fireImmediately: true);
  }

  Future<List<Log>> getPersonsLogs(int? id) {
    return isar.logs.filter().loanerIDEqualTo(id!).sortByDateDesc().findAll();
  }

  // Future<double> getRealProfit() {
  //   return
  // }

  // Future<double> getProfitOfTheMonth() {
  //   Map map = Map();
  //   map['1'] = RootIsolateToken.instance!;
  //   return pool.scheduleJob(CgetProfitOfTheMonth(map: map));
  // }

  Future<void> exportData() async {
    final jsonData = <String, dynamic>{};

    await isar.writeTxn(() async {
      // Export data from each collection
      final myCollectionData = await isar.logs.where().findAll();
      jsonData['logs'] = myCollectionData.map((e) => e.toMap()).toList();

      // Add more collections if needed
      // final anotherCollectionData = await isar.anotherCollection.where().findAll();
      // jsonData['anotherCollection'] = anotherCollectionData.map((e) => e.toMap()).toList();
    });

    // Convert to JSON string
    final jsonString = jsonEncode(jsonData);

    // Save jsonString to a file
    var te = await getApplicationDocumentsDirectory();
    var file = File('${te.path}/backup.txt');
    await file.writeAsString(jsonString);
    // print(jsonString); // You can write this to a file instead of printing
  }

  Future<void> importData() async {
    await isar.writeTxn(() async => await isar.logs.clear());
    var jsonFilePath = await getApplicationDocumentsDirectory();
    final jsonString =
        await File('${jsonFilePath.path}/backup.txt').readAsString();
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    await isar.writeTxn(() async {
      // Reimport data into the collection
      final myCollectionData = (jsonData['logs'] as List)
          .map((e) => Log.fromMap(e as Map<String, dynamic>))
          .toList();
      await isar.logs.putAll(myCollectionData);
    });
  }

  getLogsChunk(int chunkSize, int currentLog) {
    return isar.logs
        .where()
        .sortByDateDesc()
        .offset(currentLog)
        .limit(chunkSize)
        .findAll();
  }

  Future<Map<String, dynamic>> getAccountStatementData(int loanerId) async {
    final loaner = await isar.loaners.get(loanerId);
    if (loaner == null) throw Exception('Loaner with ID $loanerId not found');

    final loanReceipts = await isar.logs
        .filter()
        .loanerIDEqualTo(loanerId)
        .and()
        .loanedEqualTo(true)
        .findAll();

    List<Map<String, dynamic>> transactions = [];
    double totalLoaned = 0.0;
    double totalPaid = 0.0;

    // Add loan receipts
    for (var receipt in loanReceipts) {
      double amount = receipt.products
          .fold(0.0, (sum, p) => sum + (p.sellPrice ?? 0) * (p.count ?? 0));
      totalLoaned += amount;
      transactions.add({
        'date': receipt.date,
        'amount': amount,
        'type': 'loan',
        'description': '${receipt.products.length} items'
      });
    }

    // Add payments
    if (loaner.lastPayment != null) {
      for (var payment in loaner.lastPayment!) {
        double amount = double.tryParse(payment.value ?? '0') ?? 0;
        totalPaid += amount;
        transactions.add({
          'date': DateTime.parse(payment.key!),
          'amount': amount,
          'type': 'payment',
          'description': 'Payment'
        });
      }
    }

    // Sort by date
    transactions.sort(
        (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    return {
      'customerName': loaner.name ?? 'Unknown',
      'phoneNumber': loaner.phoneNumber ?? 'Unknown',
      'location': loaner.location ?? 'Unknown',
      'totalLoaned': totalLoaned,
      'totalPaidAmount': totalPaid,
      'currentBalance': totalLoaned - totalPaid,
      'transactionHistory': transactions,
    };
  }
}

class CgetSalesOfTheMonth extends PooledJob<double> {
  Map map;
  CgetSalesOfTheMonth({required this.map});
  @override
  Future<double> job() async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
    // 'C:/Users/hadow/Documents'

    Isar isar;
    try {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: 'isarInstance',
      );
      print(isar.name);
    } catch (e) {
      // print(e);
      isar = await Isar.getInstance('isarInstance')!;
    }
    List<Log> temp = await isar.logs.where().anyId().findAll();
    temp = temp
        .where((value) =>
            value.date.month == DateTime.now().month &&
            value.date.year == DateTime.now().year)
        .toList();
    double sales = 0;
    for (var log in temp) {
      sales += log.price;
    }
    return sales;

    // print('here1');
    // var te = await getApplicationDocumentsDirectory();
    // // print('storage/emulated/0/dukkan/V2');
    // // 'storage/emulated/0/dukkan/v2'
    // Hive.init(te.path);
    // print('here');
    // Hive.registerAdapter(ProductAdapter());
    // Hive.registerAdapter(LogAdapter());
    // Hive.registerAdapter(OwnerAdapter());
    // Hive.registerAdapter(LoanerAdapter());

    // DB db = DB();
    // print(db.getAllLogsPev());
  }
}

class CgetProfitOfTheMonth extends PooledJob<double> {
  Map map;
  CgetProfitOfTheMonth({required this.map});
  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        // print(e);
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> temp = await isar.logs.where().anyId().findAll();
      temp = temp
          .where((value) =>
              value.date.month == DateTime.now().month &&
              value.date.year == DateTime.now().year)
          .toList();
      double profit = 0;
      for (var log in temp) {
        profit += log.profit;
      }

      return profit;
    } on Exception catch (e) {
      print(e);
      return -1;
    }
  }
}

class CgetDailyProfit extends PooledJob<double> {
  Map map;
  CgetDailyProfit({required this.map});
  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        // print(e);
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> temp = await isar.logs.where().anyId().findAll();
      double profit = 0;
      var time = map['2'];
      for (var log in temp) {
        if (log.date.day == time.day &&
            log.date.month == time.month &&
            log.date.year == time.year) {
          profit += log.profit;
        }
      }

      return profit;
    } catch (e) {
      print(e);
      return -1;
    }
  }
}

class CgetDailySales extends PooledJob<double> {
  Map map;
  CgetDailySales({required this.map});
  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> temp = await isar.logs.where().anyId().findAll();
      double sales = 0;
      var time = map['2'];
      for (var log in temp) {
        if (log.date.day == time.day &&
            log.date.month == time.month &&
            log.date.year == time.year) {
          sales += log.price;
        }
      }

      return sales;
    } catch (e) {
      print(e);
      return -1;
    }
  }
}

class CgetAllSales extends PooledJob<double> {
  CgetAllSales({required this.map});
  Map map;
  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        // debugPrint(e.toString());
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> temp = await isar.logs.where().anyId().findAll();
      double sales = 0;
      for (var log in temp) {
        sales += log.price;
      }

      return sales;
    } catch (e) {
      debugPrint(e.toString());
      return -1;
    }
  }
}

class CgetSaledProductsByDate extends PooledJob<List<Product>> {
  Map map;
  CgetSaledProductsByDate({required this.map});
  @override
  Future<List<Product>> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        // debugPrint(e.toString());
        isar = await Isar.getInstance("isarInstance")!;
      }
      Iterable<Log> temp = await isar.logs.where().anyId().findAll();
      DateTime time = map['2'];
      print(time);
      temp = temp.where((element) =>
          element.date.day == time.day &&
          element.date.month == time.month &&
          element.date.year == time.year);
      debugPrint(temp.length.toString());
      List<EmbeddedProduct> products = [];
      List<Product> result = [];
      for (var log in temp) {
        products.addAll(log.products);
      }
      Map<String, int> yy = {};
      for (var product in products) {
        if (yy.containsKey(product.name)) {
          yy.update(product.name!, (value) => product.count! + value);
        } else {
          yy.addAll({product.name!: product.count!});
        }
      }
      for (var element in yy.entries) {
        result.add(
          Product.named(
            name: element.key,
            buyprice: 0,
            barcode: '',
            sellPrice: 0,
            count: element.value,
            weightable: true,
            ownerName: '',
            wholeUnit: '',
            offer: false,
            offerCount: 0,
            offerPrice: 0,
            endDate: DateTime(2024),
            hot: false,
            priceHistory: [],
          ),
        );
      }
      return result;
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}

class CgetTotalProfit extends PooledJob<double> {
  Map map;
  CgetTotalProfit({required this.map});
  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> temp = await isar.logs.where().anyId().findAll();
      double profit = 0;
      for (var log in temp) {
        profit += log.profit;
      }

      return profit;
    } catch (e) {
      debugPrint(e.toString());
      return -1;
    }
  }
}

class CgetNumberOfSalesForAproduct extends PooledJob<int> {
  Map map;
  CgetNumberOfSalesForAproduct({required this.map});
  var count = 0;

  @override
  Future<int> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> logs = await isar.logs.where().anyId().findAll();
      String key = map['2'];
      for (var log in logs) {
        List<EmbeddedProduct> products = log.products.toList();
        for (var product in products) {
          if (product.name == key) {
            count += product.count!;
          }
        }
      }

      return count;
    } catch (e) {
      debugPrint(e.toString());
      return -1;
    }
  }
}

class CgetSalesPerProduct extends PooledJob<List<ProdStats>> {
  Map map;
  int chunkSize;
  CgetSalesPerProduct({required this.map, required this.chunkSize});
  @override
  Future<List<ProdStats>> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> logs = await isar.logs.where().anyId().findAll();
      List<Product> products = await isar.products.where().anyId().findAll();
      int getNumberOfSalesForAproduct({required String key}) {
        int count = 0;
        // List<Log> logs = db.getAllLogs();
        for (var log in logs) {
          List<EmbeddedProduct> products = log.products.toList();
          for (var product in products) {
            if (product.name == key) {
              count += product.count!;
            }
          }
        }
        return count;
      }

      List<ProdStats> temp = [];

      // List<Product> products = db.getAllProducts();

      for (var product in products) {
        int gg = getNumberOfSalesForAproduct(key: product.name!);
        temp.add(
          ProdStats(
            date: DateTime.now(),
            name: product.name!,
            count: gg > 1000 ? (gg).toDouble() : gg.toDouble(),
          ),
        );
      }

      return temp.getRange(0, chunkSize - 1).toList();
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}

class CgetDailyProfitOfTheMont extends PooledJob<List<SalesStats>> {
  Map map;
  CgetDailyProfitOfTheMont({required this.map});

  @override
  Future<List<SalesStats>> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
        // print(e);
      }
      DateTime month = map['2'];
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      List<Log> logs = await isar.logs
          .filter()
          .dateBetween(startOfMonth, endOfMonth)
          .sortByDateDesc()
          .findAll();
      print(month);

      List<SalesStats> result = [];
      // // List<BcLog> temp = map['1'];
      // // temp.sort(
      // //   (a, b) => a.date.compareTo(b.date),
      // // );
      // // temp = temp.reversed.toList();
      // for (var log in temp) {
      //   if (tt.day != log.date.day) {
      //     result.add(SalesStats(
      //       date: log.date,
      //       sales: getDailySales(log.date),
      //     ));
      //     tt = log.date;
      //   }
      // }
      // Set<SalesStats> temp = {};
      Map<String, double> dailySales = {};

      for (var receipt in logs) {
        String date =
            "${receipt.date.year}-${receipt.date.month.toString().padLeft(2, '0')}-${receipt.date.day.toString().padLeft(2, '0')}";

        if (dailySales.containsKey(date)) {
          double temp1 = dailySales[date]!;
          temp1 += receipt.profit;
          dailySales[date] = temp1;
        } else {
          dailySales[date] = receipt.profit;
        }
      }
      result = dailySales.entries
          .map((e) => SalesStats(date: DateTime.parse(e.key), sales: e.value))
          .toList();
      return result;
    } catch (e) {
      // debugPrint(e.toString() + 'here');
      return [];
    }
  }
}

class CgetDailySalesOfTheMonth extends PooledJob<List<SalesStats>> {
  Map map;
  CgetDailySalesOfTheMonth({required this.map});
  @override
  Future<List<SalesStats>> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      DateTime tt = map['2'];
      final startOfMonth = DateTime(tt.year, tt.month, 1);
      final endOfMonth = DateTime(tt.year, tt.month + 1, 0);
      List<Log> logs = await isar.logs
          .filter()
          .dateBetween(startOfMonth, endOfMonth)
          .sortByDateDesc()
          .findAll();

      List<SalesStats> result = [];

      Map<String, double> dailySales = {};

      for (var receipt in logs) {
        String date =
            "${receipt.date.year}-${receipt.date.month.toString().padLeft(2, '0')}-${receipt.date.day.toString().padLeft(2, '0')}";

        if (dailySales.containsKey(date)) {
          double temp1 = dailySales[date]!;
          temp1 += receipt.price;
          dailySales[date] = temp1;
        } else {
          dailySales[date] = receipt.price;
        }
      }
      result = dailySales.entries
          .map((e) => SalesStats(date: DateTime.parse(e.key), sales: e.value))
          .toList();
      return result;
    } catch (e) {
      debugPrint(e.toString() + 'heree2');
      return [];
    }
  }
}

class CgetMonthlySalesOfTheyear extends PooledJob<List<SalesStats>> {
  Map map;
  CgetMonthlySalesOfTheyear({required this.map});
  @override
  Future<List<SalesStats>> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      DateTime tt = map['2'];
      final startOfYear = DateTime(tt.year, 1);
      final endOfYear = DateTime(tt.year, 12, 31, 23, 59, 59);
      List<Log> logs = await isar.logs
          .filter()
          .dateBetween(startOfYear, endOfYear)
          .sortByDateDesc()
          .findAll();

      List<SalesStats> result = [];
      // // List<BcLog> temp = map['1'];
      // // temp.sort(
      // //   (a, b) => a.date.compareTo(b.date),
      // // );
      // // temp = temp.reversed.toList();
      // for (var log in temp) {
      //   if (tt.day != log.date.day) {
      //     result.add(SalesStats(
      //       date: log.date,
      //       sales: getDailySales(log.date),
      //     ));
      //     tt = log.date;
      //   }
      // }
      // Set<SalesStats> temp = {};
      Map<String, double> monthlySales = {};

      for (var receipt in logs) {
        String date =
            "${receipt.date.year}-${receipt.date.month.toString().padLeft(2, '0')}-${2.toString().padLeft(2, '0')}";

        if (monthlySales.containsKey(date)) {
          double temp1 = monthlySales[date]!;
          temp1 += receipt.price;
          monthlySales[date] = temp1;
        } else {
          monthlySales[date] = receipt.price;
        }
      }
      result = monthlySales.entries
          .map((e) => SalesStats(date: DateTime.parse(e.key), sales: e.value))
          .toList();
      result.sort(
        (a, b) => a.date.compareTo(b.date),
      );
      result = result.reversed.toList();
      return result;

      // print(result);
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}

class CgetMonthlyProfitsOfTheyear extends PooledJob<List<SalesStats>> {
  Map map;
  CgetMonthlyProfitsOfTheyear({required this.map});
  @override
  Future<List<SalesStats>> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      List<Log> temp = await isar.logs.where().anyId().findAll();
      double getMonthlyProfits(DateTime time) {
        // List<BcLog> temp = map['2'];
        double sales = 0;
        for (var log in temp) {
          if (log.date.month == time.month && log.date.year == time.year) {
            sales += log.profit;
          }
        }

        return sales;
      }

      DateTime tt = map['2'];
      List<SalesStats> result = [];
      // List<BcLog> temp = map['2'];
      for (var log in temp) {
        if (log.date.year == map['2'].year) {
          if (tt.month == log.date.month) {
            continue;
          } else {
            result.add(
              SalesStats(
                date: log.date,
                sales: getMonthlyProfits(log.date),
              ),
            );
            if (log.date.compareTo(tt) != 0) {
              tt = log.date;
            }
          }
        }
      }
      // print(result);
      result.sort(
        (a, b) => a.date.compareTo(b.date),
      );
      result = result.reversed.toList();
      return result;
    } catch (e) {
      debugPrint(e.toString());
      return [];
    }
  }
}

class CgetMonthlyloans extends PooledJob<double> {
  Map map;
  CgetMonthlyloans({required this.map});

  Future<double> _calculateTotalPayments(Isar isar, int year, int month) async {
    try {
      List<Loaner> loaners = await isar.loaners.where().findAll();

      return loaners.fold<double>(0.0, (total, loaner) {
        if (loaner.lastPayment == null) return total;

        return total +
            (loaner.lastPayment ?? []).where((value) {
              if (value.key == null) return false;
              try {
                final paymentDate = DateTime.parse(value.key!);
                return paymentDate.year == year && paymentDate.month == month;
              } catch (e) {
                debugPrint('Error parsing payment date: $e');
                return false;
              }
            }).fold(
                0.0,
                (previousValue, element) =>
                    double.parse(element.value ?? '0') + previousValue);
      });
    } catch (e) {
      debugPrint('Error calculating total payments: $e');
      return 0.0;
    }
  }

  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();

      final isar = await Isar.getInstance('isarInstance') ??
          await Isar.open(
            [
              LogSchema,
              ProductSchema,
              LoanerSchema,
              OwnerSchema,
              ExpenseSchema
            ],
            directory: dir.path,
            name: 'isarInstance',
          );

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1)
          .subtract(Duration(milliseconds: 1));

      final receipts = await isar.logs
          .filter()
          .loanedEqualTo(true)
          .dateBetween(startOfMonth, endOfMonth)
          .findAll();

      final totalUnpaidLoans = receipts.fold<double>(0.0, (total, receipt) {
        final receiptTotal = receipt.products.fold<double>(
            0.0,
            (subtotal, product) =>
                subtotal + ((product.count ?? 0) * (product.sellPrice ?? 0)));
        return total + receiptTotal - (receipt.discount);
      });

      final totalPayments =
          await _calculateTotalPayments(isar, now.year, now.month);

      return totalUnpaidLoans - totalPayments;
    } catch (e) {
      debugPrint('Error in CgetMonthlyloans.job: $e');
      return -1;
    }
  }
}

class getTotalExpenseNow extends PooledJob<double> {
  Map map;
  getTotalExpenseNow({required this.map});
  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      Isar isar;
      try {
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      } catch (e) {
        isar = await Isar.getInstance('isarInstance')!;
      }
      var expenses = await isar.expenses.where().anyID().findAll();
      double total = 0.0;
      for (var expense in expenses) {
        if (!(expense.fixed!)) {
          var logs = await isar.logs
              .where()
              .expenseIdEqualTo(expense.ID)
              .filter()
              .dateGreaterThan(
                  DateTime(DateTime.now().year, DateTime.now().month, 1))
              // .add(Duration(days: expense.period!)))
              .findAll();
          total += logs.fold(
            0.0,
            (previousValue, element) =>
                previousValue + element.price - element.discount,
          );
        } else {
          total += expense.amount!;
        }
      }
      return total;
    } catch (e) {
      debugPrint(e.toString());
      return -1;
    }
  }
}

class CgetDailyloans extends PooledJob<double> {
  Map map;
  CgetDailyloans({required this.map});

  @override
  Future<double> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final dir = await getApplicationDocumentsDirectory();
      final isar = await Isar.getInstance('isarInstance') ??
          await Isar.open(
            [
              LogSchema,
              ProductSchema,
              LoanerSchema,
              OwnerSchema,
              ExpenseSchema
            ],
            directory: dir.path,
            name: 'isarInstance',
          );

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay =
          startOfDay.add(Duration(days: 1)).subtract(Duration(milliseconds: 1));

      final receipts = await isar.logs
          .filter()
          .loanedEqualTo(true)
          .dateBetween(startOfDay, endOfDay)
          .findAll();

      final totalUnpaidLoans = receipts.fold<double>(
        0.0,
        (total, receipt) =>
            total +
            receipt.products.fold<double>(
              0.0,
              (subtotal, product) =>
                  subtotal + (product.count ?? 0) * (product.sellPrice ?? 0),
            ) -
            (receipt.discount),
      );

      return totalUnpaidLoans;
    } catch (e) {
      debugPrint('Error in CgetDailyloans.job: $e');
      return -1;
    }
  }
}
