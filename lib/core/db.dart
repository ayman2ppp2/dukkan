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
import 'package:dukkan/util/models/searchQuery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:path_provider/path_provider.dart';

import '../util/models/Loaner.dart';
import '../util/models/Owner.dart';
// import 'package:uuid/uuid.dart';

class DB {
  Isar? isar;
  // static IsolatePool? _pool;
  static DB? _instance;

  // Private constructor
  DB._internal();

  // Factory constructor for singleton with automatic initialization
  factory DB() {
    _instance ??= DB._internal();
    _instance!._init();
    return _instance!;
  }
  void _init() async {
    // _pool = await Pool.init();
    // if (isar == null) {
    //   final dir = await getApplicationDocumentsDirectory();
    //   try {
    //     isar = await Isar.open(
    //       [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
    //       directory: dir.path,
    //       name: 'isarInstance',
    //     );
    //     // print('try worked');
    //   } catch (e) {
    //     isar = await Isar.getInstance('isarInstance')!;
    //   }

    try {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: 'isarInstance',
      );
    } catch (e) {
      // debugPrint(e.toString());
      isar = await Isar.getInstance("isarInstance")!;
    }
  }

  // void closeAll() {
  //   inventory.close();
  //   logs.close();
  //   owners.close();
  //   loaners.close();
  //   invBack.close();
  //   logBack.close();
  //   ownersBack.close();
  // }

  Future<bool> deleteLoaner(int id) {
    return isar!.writeTxn(() => isar!.loaners.delete(id));
  }

  Future<List<int>> updateProducts(List<EmbeddedProduct> products) async {
    var ids = products.map((e) => e.hot! ? 0 : (e.productId ?? 0)).toList();
    var realProducts = embeddedToProduct(ids);
    var updatedRealProducts = List<Product>.empty(growable: true);
    for (var product in realProducts.nonNulls.toList()) {
      // var num = await isar!.products.get(product.id);
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
    return isar!
        .writeTxn(() async => isar!.products.putAll(updatedRealProducts));
  }

  Future<void> useBackup() async {
    gg g = gg();
    await g.init();
    List<Product> temp = List.empty(growable: true);
    for (Map<String, dynamic> element in g.getProducts()) {
      temp.add(Product.fromJson(map: element));
    }
    await isar!.writeTxn(
      () async => isar!.products.putAll(temp),
    );
    print('finished inventory');
    List<Log> temp1 = List.empty(growable: true);
    var logs = await g.getLogs();
    for (Map<String, dynamic> map in logs) {
      Log log = Log.fromMap(map);
      temp1.add(log);
    }
    await isar!.writeTxn(() async {
      return isar!.logs.putAll(temp1);
    });

    print('finished logs');
    List<Owner> temp2 = List.empty(growable: true);

    for (Map<String, dynamic> map in g.getOwners()) {
      temp2.add(Owner.fromJson(map: map));
    }
    await isar!.writeTxn(
      () async => isar!.owners.putAll(temp2),
    );
    print('finished owners');
    List<Loaner> temp3 = List.empty(growable: true);

    for (Map<String, dynamic> map in g.getLoaner()) {
      temp3.add(Loaner.fromMap(map: map));
    }
    await isar!.writeTxn(
      () async => isar!.loaners.putAll(temp3),
    );
    print('finished loaners');
  }

  Future<int> insertLoaner(Loaner loaner) {
    return isar!.writeTxn(() => isar!.loaners.put(loaner));
    // loaners.put(loaner.ID, loaner);
  }

  Future<List<Loaner>> getLoaners() {
    return isar!.loaners.where().anyID().sortByLoanedAmountDesc().findAll();
    // return List<Loaner>.from(loaners.values);
  }

  Future<int> updateLoaner(Log log, double sum) async {
    Loaner temp =
        (await isar!.loaners.where().iDEqualTo(log.loanerID!).findFirst())!;
    DateTime CalculateDate() {
      if (temp.loanedAmount! == 0) {
        return DateTime.parse(temp.lastPayment!.last.key!);
      }
      if (temp.loanedAmount! - (log.price + sum) == 0) {
        return DateTime.now();
      } else {
        try {
          return DateTime.parse(temp.lastPayment!.last.key!);
        } catch (e) {
          return DateTime(1900);
        }
      }
    }

    return isar!.writeTxn(() async => isar!.loaners.put(Loaner(
          name: temp.name,
          phoneNumber: temp.phoneNumber,
          location: temp.location,
          lastPayment: temp.lastPayment,
          loanedAmount: (temp.loanedAmount ?? 0) > 0
              ? temp.loanedAmount! - (log.price + sum)
              : 0,
        )
          ..ID = temp.ID
          ..zeroingDate = CalculateDate()));
  }

  Future<List<Owner>> getOwnersList() {
    return isar!.owners.where().anyId().findAll();
  }

  Future<Id> insertOwner(Owner owner) {
    return isar!.writeTxn(() async => isar!.owners.put(owner));
  }

  Future<List<Product>> getAllProducts() async {
    List<Product> temp2 =
        await isar!.products.where(sort: Sort.asc).anyId().findAll();
    return temp2;
  }

  Future<void> deleteLog(Log log) {
    return isar!.writeTxn(() async => isar!.logs.delete(log.id));
  }

  Future<void> insertProducts({required List<Product> products}) async {
    isar!.writeTxn(() => isar!.products.putAll(products));
  }

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
        Owner? tempOwner = await (isar!.owners
            .where()
            .filter()
            .ownerNameEqualTo(element.ownerName!)
            .findFirst());
        tempOwner!.dueMoney += element.buyprice! * element.count!;
        await isar!.writeTxn(
          () async => await isar!.owners.put(tempOwner..id = tempOwner.id),
        );
      }

      if (!element.hot!) {
        var num = await isar!.products.get(element.id);
        await isar!.writeTxn(() async => await isar!.products.put(
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
      var tempLoner = await isar!.loaners.get(LoID!);
      await isar!.writeTxn(
        () async => await isar!.loaners.put(
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
      var tempExpense = await isar!.expenses.get(expenseId!);
      await isar!.writeTxn(
        () async => await isar!.expenses.put(
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
    await isar!.writeTxn(
      () async {
        // log.products.save();
        return isar!.logs.put(log);
      },
    );
  }

  Stream<List<Expense>> getExpenses({required bool fixed}) {
    var temp;
    if (fixed) {
      temp = isar!.expenses.where().watch(fireImmediately: true);
    } else {
      temp = isar!.expenses
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
    return isar!.writeTxn(() async => await isar!.expenses.put(temp));
  }

  Future<Loaner?> getLoanerName({required int id}) async {
    return isar!.loaners.get(id);
  }

  List<Product?> embeddedToProduct(List<int> ids) {
    return isar!.products.getAllSync(ids);
  }

  Stream<Expense?> watchExpense({required int id}) {
    return isar!.expenses.watchObject(
      id,
      fireImmediately: true,
    );
  }

  Future<bool> deleteExpense({required int id}) {
    return isar!.writeTxn(() async => await isar!.expenses.delete(id));
  }

  Stream<Loaner?> watchLoaner(int id) {
    return isar!.loaners.watchObject(id, fireImmediately: true);
  }

  Stream<Product?> watchProduct(int id) {
    return isar!.products.watchObject(id, fireImmediately: true);
  }

  Future<bool> deleteProduct(int id) {
    return isar!.writeTxn(() async => await isar!.products.delete(id));
  }

  Stream<List<Product>> getTotalBuyPrice() {
    return isar!.products.where().watch(fireImmediately: true);
  }

  Stream<List<Loaner>> getLoanersStream() {
    return isar!.loaners
        .where()
        .sortByLoanedAmountDesc()
        .watch(fireImmediately: true);
  }

  Stream<List<Log>> getLogsStream(int chunkSize, SearchQuery searchQuery) {
    return isar!.logs
        .filter()
        .optional(searchQuery.queryText.isNotEmpty, (q) {
          // Check if queryText is numeric to search by receipt ID
          if (int.tryParse(searchQuery.queryText) != null) {
            return q.idEqualTo(int.parse(searchQuery.queryText));
          } else {
            // Otherwise, search within receipt products
            return q
                .productsElement((p) => p.nameContains(searchQuery.queryText));
          }
        })
        .optional(searchQuery.startDate != null && searchQuery.endDate != null,
            (q) {
          return q.dateBetween(searchQuery.startDate, searchQuery.endDate);
        })
        .optional(searchQuery.userId != null, (q) {
          return q.loanerIDEqualTo(int.tryParse(searchQuery.userId!) ?? 0);
        })
        .sortByDateDesc()
        .limit(chunkSize)
        .watch(fireImmediately: true);
  }

  Stream<List<Log>> getPersonsLogs(int? id) {
    return isar!.logs
        .filter()
        .loanerIDEqualTo(id!)
        .sortByDateDesc()
        .watch(fireImmediately: true);
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

    await isar!.writeTxn(() async {
      // Export data from each collection
      final myCollectionData = await isar!.logs.where().findAll();
      jsonData['logs'] = myCollectionData.map((e) => e.toMap()).toList();

      // Add more collections if needed
      // final anotherCollectionData = await isar!.anotherCollection.where().findAll();
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
    await isar!.writeTxn(() async => await isar!.logs.clear());
    var jsonFilePath = await getApplicationDocumentsDirectory();
    final jsonString =
        await File('${jsonFilePath.path}/backup.txt').readAsString();
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

    await isar!.writeTxn(() async {
      // Reimport data into the collection
      final myCollectionData = (jsonData['logs'] as List)
          .map((e) => Log.fromMap(e as Map<String, dynamic>))
          .toList();
      await isar!.logs.putAll(myCollectionData);
    });
  }

  getLogsChunk(int chunkSize, int currentLog) {
    return isar!.logs
        .where()
        .sortByDateDesc()
        .offset(currentLog)
        .limit(chunkSize)
        .findAll();
  }

  Future<Map<String, dynamic>> getAccountStatementData(int loanerId) async {
    final loaner = await isar!.loaners.get(loanerId);
    if (loaner == null) throw Exception('Loaner with ID $loanerId not found');
    var date = DateTime.now();
    final loanReceipts = await isar!.logs
        .filter()
        .loanerIDEqualTo(loanerId)
        .dateBetween(DateTime(date.year, date.month, 0), DateTime.now())
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
      var monthPayments = loaner.lastPayment!.where(
        (payment) => DateTime.parse(payment.key!).isAfter(
          DateTime(date.year, date.month, 1, 0),
        ),
      );
      for (var payment in monthPayments) {
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
      'zeroingDateDisplay': loaner.lastPayment!.last.key ?? 'not yet'
    };
  }

  String hasna({required int id}) {
    final logs =
        isar!.logs.filter().loanerIDEqualTo(id).sortByDate().findAllSync();

    // Group logs by year and month
    Map<String, double> monthlySums = {};

    for (var log in logs) {
      String monthKey =
          "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}";

      monthlySums[monthKey] = (monthlySums[monthKey] ?? 0) + log.price;
    }

    return monthlySums.toString();
  }

  Future<void> createLocalBackup() async {
    final backupFilePath =
        '${(await getApplicationDocumentsDirectory()).path}/backup.isar';
    final backupFile = File(backupFilePath);

    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    await isar!.copyToFile(backupFilePath);
    print('Backup created successfully.');
  }

  Future<void> closeAllIsarInstances() async {
    IsolatePool pool = await Pool.init();
    List<Future> futures = [];
    for (var i = 0; i < pool.numberOfIsolates; i++) {
      futures.add(
          pool.scheduleJob(StopIsar(map: {'1': RootIsolateToken.instance!})));
    }
    await Future.wait(futures);
  }

  Future<IsolatePool> reOpenPool() async {
    return Pool.reInit();
  }

  useLocalBacup() async {
    final backupFilePath =
        '${(await getApplicationDocumentsDirectory()).path}/backup.isar';
    final dir = await getApplicationDocumentsDirectory();

    // Close the current Isar instance
    await closeAllIsarInstances();
    await isar!.close();

    // Delete the current Isar database files
    await File('${dir.path}/isarInstance.isar').delete();

    // Copy the backup file to the Isar directory
    final backupFile = File(backupFilePath);
    final newIsarFile = File('${dir.path}/isarInstance.isar');
    await backupFile.copy(newIsarFile.path);

    // Reopen the Isar instance
    isar = await Isar.open(
      [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
      directory: dir.path,
      name: 'isarInstance',
    );
    // await reOpenPool();

    print('Backup restored successfully.');
  }

  void windows() async {
    final receivedFilePath =
        '${(await getApplicationDocumentsDirectory()).path}/isarInstance.isar+1';
    final dir = await getApplicationDocumentsDirectory();
    await closeAllIsarInstances();
    await isar!.close();

    // Delete the current Isar database files

    await File('${dir.path}/isarInstance.isar').delete();

    // Copy the backup file to the Isar directory
    final backupFile = File(receivedFilePath);
    final newIsarFile = File('${dir.path}/isarInstance.isar');
    await backupFile.copy(newIsarFile.path);

    // Reopen the Isar instance
    isar = await Isar.open(
      [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
      directory: dir.path,
      name: 'isarInstance',
    );
  }

  inboundReceipt({required List<Product> lst, required double total}) async {
    for (var element in lst) {
      var num = await isar!.products.get(element.id);
      await isar!.writeTxn(() async => await isar!.products.put(
            // element.name,
            Product.named2(
              id: element.id,
              name: element.name,
              barcode: element.barcode,
              buyprice: element.buyprice,
              sellPrice: element.sellPrice,
              count: (num!.count!) + element.count!,
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
    }
  }
}

class StopIsar extends PooledJob<bool> {
  Map map;
  StopIsar({required this.map});
  @override
  Future<bool> job() async {
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
    return isar.close();
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
      var time = map['2'];
      List<Log> temp = await isar.logs
          .filter()
          .dateBetween(DateTime(time.year, time.month, time.day),
              DateTime(time.year, time.month, time.day, 23, 59, 59))
          .findAll();
      double sales = 0;

      for (var log in temp) {
        sales += log.price;
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
  final Map map;
  final int chunkSize;

  CgetSalesPerProduct({required this.map, required this.chunkSize});

  // Static cache for storing computed results
  static List<ProdStats>? _cachedStats;

  @override
  Future<List<ProdStats>> job() async {
    try {
      // Initialize the isolate's binary messenger
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);

      // If cached results are available, return the required chunk
      if (_cachedStats != null) {
        return _cachedStats!.take(chunkSize).toList();
      }

      // Get the application directory
      final dir = await getApplicationDocumentsDirectory();

      // Open or get an existing Isar instance
      final isar = await _initializeIsar(dir.path);

      // Fetch all logs and products concurrently
      final logsFuture = isar.logs.where().anyId().findAll();
      final productsFuture = isar.products.where().anyId().findAll();
      final logs = await logsFuture;
      final products = await productsFuture;

      // Generate product statistics
      _cachedStats = products.map((product) {
        final salesCount = _getNumberOfSalesForProduct(logs, product.name!);
        return ProdStats(
          date: DateTime.now(),
          name: product.name!,
          count:
              salesCount > 1000 ? salesCount.toDouble() : salesCount.toDouble(),
        );
      }).toList();

      // Return the required chunk
      return _cachedStats!.take(chunkSize).toList();
    } catch (e) {
      debugPrint('Error in job: $e');
      return [];
    }
  }

  Future<Isar> _initializeIsar(String directoryPath) async {
    try {
      return await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: directoryPath,
        name: 'isarInstance',
      );
    } catch (e) {
      return Isar.getInstance('isarInstance')!;
    }
  }

  int _getNumberOfSalesForProduct(List<Log> logs, String productName) {
    return logs.fold<int>(
      0,
      (count, log) =>
          count +
          log.products.where((p) => p.name == productName).fold<int>(
                0,
                (productCount, product) => productCount + (product.count ?? 0),
              ),
    );
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
