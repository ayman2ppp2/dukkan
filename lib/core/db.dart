// import 'dart:io';

// import 'package:device info_plus/device_info_plus.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dukkan/core/IsolatePool.dart';
import 'package:dukkan/core/postgres_connection.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/models/prodStats.dart';
import 'package:dukkan/util/models/searchQuery.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:path_provider/path_provider.dart';

import '../util/models/Loaner.dart';
import '../util/models/Owner.dart';

RootIsolateToken? _getRootIsolateToken() {
  return RootIsolateToken.instance;
}

class DB {
  Isar? isar;
  static DB? _instance;
  static bool _isInitializing = false;
  static final _initCompleter = Completer<DB>();

  DB._internal();

  static Future<DB> getInstance() async {
    if (_instance != null) return _instance!;
    if (_isInitializing) {
      return await _initCompleter.future;
    }
    _isInitializing = true;
    _instance = DB._internal();
    await _instance!._init();
    _initCompleter.complete(_instance);
    _isInitializing = false;
    return _instance!;
  }

  static Future<void> initialize() async {
    if (_instance != null) return;
    await getInstance();
  }

  static Future<Isar> _openIsar(String directoryPath) async {
    final existing = await Isar.getInstance("isarInstance");
    if (existing != null) return existing;
    return await Isar.open(
      [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
      directory: directoryPath,
      name: 'isarInstance',
    );
  }

  static Future<Isar> openIsarSafely(String directoryPath) async {
    try {
      return await _openIsar(directoryPath);
    } catch (e) {
      debugPrint('Failed to open Isar: $e');
      final fallback = await Isar.getInstance("isarInstance");
      if (fallback != null) {
        debugPrint('Using fallback Isar instance');
        return fallback;
      }
      throw StateError('No Isar instance available: $e');
    }
  }

  Future<void> _init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final existingIsar = await Isar.getInstance("isarInstance");
      if (existingIsar != null) {
        isar = existingIsar;
        return;
      }
      isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: 'isarInstance',
      );
    } catch (e) {
      debugPrint('Isar initialization failed: $e');
      final fallback = await Isar.getInstance("isarInstance");
      if (fallback != null) {
        isar = fallback;
      } else {
        debugPrint('Isar getInstance also failed - database unavailable');
      }
    }
  }

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

  // Future<void> useBackup() async {
  //   // DEPRECATED: Removed due to migration to isar_community
  //   // This function depended on old Hive backup code (gg class)
  // }

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

  Future<List<Map<String, dynamic>>> getLowStockProductsWithPercent(
      {double thresholdPercent = 0.25}) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final logs =
        await isar!.logs.filter().dateBetween(thirtyDaysAgo, now).findAll();

    final allProducts = await isar!.products.where().findAll();

    final Map<int, int> soldById = {};
    final Map<String, int> soldByName = {};

    for (final log in logs) {
      for (final ep in log.products) {
        final soldCount = ep.count ?? 0;
        if (ep.productId != null && ep.productId! > 0) {
          soldById.update(ep.productId!, (v) => v + soldCount,
              ifAbsent: () => soldCount);
        } else if (ep.name != null) {
          soldByName.update(ep.name!, (v) => v + soldCount,
              ifAbsent: () => soldCount);
        }
      }
    }

    final List<Map<String, dynamic>> results = [];
    for (final p in allProducts) {
      final currentStock = p.count ?? 0;
      final soldThisMonth = soldById[p.id] ?? soldByName[p.name ?? ''] ?? 0;
      final totalAvailable = currentStock + soldThisMonth;

      bool isLow;
      if (totalAvailable <= 0) {
        isLow = currentStock <= 0;
      } else {
        final percentRemaining = currentStock / totalAvailable;
        isLow = percentRemaining < thresholdPercent;
      }

      if (isLow) {
        results.add({
          'product': p,
          'percentRemaining':
              totalAvailable > 0 ? currentStock / totalAvailable : 0.0,
          'currentStock': currentStock,
          'soldLast30Days': soldThisMonth,
        });
      }
    }
    results.sort((a, b) {
      final lastDate = (Product p) => p.priceHistory.isEmpty
          ? DateTime(2000)
          : p.priceHistory
              .map((e) => e.date ?? DateTime(2000))
              .reduce((max, d) => d.isAfter(max) ? d : max);

      final dateA = lastDate(a['product'] as Product);
      final dateB = lastDate(b['product'] as Product);
      return dateB.compareTo(dateA);
    });
    return results;
  }

  Future<void> deleteLog(Log log) {
    return isar!.writeTxn(() async => isar!.logs.delete(log.id));
  }

  Future<void> insertProducts({required List<Product> products}) async {
    await isar!.writeTxn(() => isar!.products.putAll(products));
  }

  Future<bool> checkOut({
    required List<Product> products,
    required double total,
    double discount = 0,
    int? loanerId,
    bool loaned = false,
    bool expense = false,
    int? expenseId,
  }) async {
    try {
      var productsIds = products.map((e) => e.id);

      productsIds = productsIds.toSet();
      final productCounts = <int, int>{};
      for (final product in products) {
        final id = product.id;
        final count = product.count ?? 0;
        productCounts.update(
          id,
          (existing) => existing + count,
          ifAbsent: () => count,
        );
      }
      List<Product> clearedProducts = [];
      productsIds.forEach((id) {
        var product = products.firstWhere((e) => e.id == id);
        clearedProducts.add(Product.named2(
            id: product.id,
            name: product.name,
            ownerName: product.ownerName,
            barcode: product.barcode,
            buyprice: product.buyprice,
            sellPrice: product.sellPrice,
            count: productCounts[id],
            weightable: product.weightable,
            wholeUnit: product.wholeUnit,
            offer: product.offer,
            offerCount: product.offerCount,
            offerPrice: product.offerPrice,
            priceHistory: product.priceHistory,
            endDate: product.endDate,
            hot: product.hot));
      });

      debugPrint(clearedProducts.map((p) => p.toJson()).toString());
      double totalPrice = 0;
      double totalProfit = 0;

      // Collect updated entities for batch writing
      final updatedOwners = <Owner>[];
      final updatedProducts = <Product>[];
      Owner? tempOwner;

      for (final product in clearedProducts) {
        // 🔹 Update owner's due money
        if ((product.ownerName ?? '').isNotEmpty) {
          tempOwner = await isar!.owners
              .where()
              .filter()
              .ownerNameEqualTo(product.ownerName!)
              .findFirst();

          if (tempOwner != null) {
            tempOwner.dueMoney = (tempOwner.dueMoney) +
                (product.buyprice ?? 0) * (product.count ?? 0);
            updatedOwners.add(tempOwner);
          }
        }

        // 🔹 Update product count (skip if 'hot')
        if (!(product.hot!)) {
          final existing = await isar!.products.get(product.id);
          if (existing == null) continue;

          final updatedCount = (existing.count ?? 0) - (product.count ?? 0);
          updatedProducts.add(
            existing..count = updatedCount,
          );

          // 🔹 Calculate profit and price
          if ((product.offer == true) &&
              (product.offerCount ?? 0) > 0 &&
              (product.count ?? 0) >= (product.offerCount ?? 0)) {
            final offerCount = product.offerCount!;
            final count = product.count!;
            final bundleCount = count ~/ offerCount;
            final remaining = count % offerCount;

            final buy = product.buyprice ?? 0;
            final offerP = product.offerPrice ?? 0;
            final sell = product.sellPrice ?? 0;

            // If offerPrice is per item, multiply by offerCount
            totalProfit += (offerP - buy) * bundleCount * offerCount;
            totalProfit += (sell - buy) * remaining;

            totalPrice += offerP * bundleCount * offerCount;
            totalPrice += sell * remaining;
          } else {
            final buy = product.buyprice ?? 0;
            final sell = product.sellPrice ?? 0;
            final count = product.count ?? 0;

            totalProfit += (sell - buy) * count;
            totalPrice += sell * count;
          }

          // final sellPrice =
          //     offerActive && product.count! % product.offerCount! == 0
          //         ? (product.offerPrice ?? 0)
          //         : (product.sellPrice ?? 0);

          // final unitProfit = sellPrice - (product.buyprice ?? 0);

          // totalProfit += unitProfit * (product.count ?? 0);
          // totalPrice += sellPrice * (product.count ?? 0);
        }
      }

      // debugPrint(updatedProducts.map((e) => e.toString()).toString());

      // 🔹 Apply discount
      if (discount > 0) {
        totalPrice -= discount;
        totalProfit -= discount;
      }

      // 🔹 Prepare loaner and expense updates
      Loaner? updatedLoaner;
      if (loanerId != null) {
        updatedLoaner = await isar!.loaners.get(loanerId);
        if (updatedLoaner != null) {
          updatedLoaner.loanedAmount =
              (updatedLoaner.loanedAmount ?? 0) + total.round() - discount;
        }
      }

      Expense? updatedExpense;
      if (expenseId != null) {
        updatedExpense = await isar!.expenses.get(expenseId);
        if (updatedExpense != null) {
          updatedExpense.amount = (updatedExpense.amount ?? 0) + totalPrice;
        }
      }

      // 🔹 Create log
      final log = Log.named2(
        price: totalPrice,
        profit: totalProfit,
        products: products.map((p) => p.toEmbedded()).toList(),
        date: DateTime.now(),
        discount: discount,
        loaned: loaned,
        loanerID: loanerId,
        expenseId: expenseId,
        expense: expense,
      );

      // 🔹 Validate stock and entities before transaction
      for (final product in clearedProducts) {
        if (product.hot == true) continue;
        final existing = await isar!.products.get(product.id);
        if (existing == null) {
          throw Exception('Product "${product.name}" not found in database');
        }
        final remaining = (existing.count ?? 0) - (product.count ?? 0);
        if (remaining < 0) {
          throw Exception('Insufficient stock for "${product.name}": '
              'have ${existing.count}, need ${product.count}');
        }
      }

      if (loanerId != null) {
        final existingLoaner = await isar!.loaners.get(loanerId);
        if (existingLoaner == null) {
          throw Exception('Selected loaner not found (ID $loanerId)');
        }
      }
      if (expenseId != null) {
        final existingExpense = await isar!.expenses.get(expenseId);
        if (existingExpense == null) {
          throw Exception('Selected expense not found (ID $expenseId)');
        }
      }
      const maxRetries = 3;
      var success = false;
      for (var attempt = 0; attempt < maxRetries && !success; attempt++) {
        try {
          success = await isar!.writeTxn(() async {
            if (updatedOwners.isNotEmpty) {
              await isar!.owners.putAll(updatedOwners);
            }
            if (updatedProducts.isNotEmpty) {
              await isar!.products.putAll(updatedProducts);
            }
            if (updatedLoaner != null) {
              await isar!.loaners.put(updatedLoaner);
            }
            if (updatedExpense != null) {
              await isar!.expenses.put(updatedExpense);
            }
            await isar!.logs.put(log);
            return true;
          });
        } catch (e) {
          debugPrint(
              '❌ checkOut transaction failed (attempt ${attempt + 1}/$maxRetries): $e');
          if (attempt == maxRetries - 1) {
            debugPrint('❌ checkOut failed after $maxRetries attempts');
            rethrow;
          }
          await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
        }
      }
      return success;
    } catch (e, st) {
      debugPrint('❌ Error in checkOut: $e\n$st');
      rethrow;
    }
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
        .optional(searchQuery.userId != null, (q) {
          return q.loanerIDEqualTo(int.tryParse(searchQuery.userId!) ?? 0);
        })
        .dateBetween(searchQuery.startDate, searchQuery.endDate)
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

    // Read data outside transaction
    final logs = await isar!.logs.where().findAll();
    jsonData['logs'] = logs.map((e) => e.toMap()).toList();

    // Convert to JSON string
    final jsonString = jsonEncode(jsonData);

    // Save jsonString to a file
    var te = await getApplicationDocumentsDirectory();
    var file = File('${te.path}/backup.txt');
    await file.writeAsString(jsonString);
  }

  Future<void> importData() async {
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
    final token = _getRootIsolateToken();
    if (token == null) {
      debugPrint('RootIsolateToken not available');
      return;
    }
    List<Future> futures = [];
    for (var i = 0; i < pool.numberOfIsolates; i++) {
      futures.add(pool.scheduleJob(StopIsar(map: {'1': token})));
    }
    await Future.wait(futures);
  }

  Future<IsolatePool> reOpenPool() async {
    return Pool.reInit();
  }

  Future<void> useLocalBacup() async {
    final dir = await getApplicationDocumentsDirectory();
    await _replaceLiveIsarWithFile('${dir.path}/backup.isar');
  }

  void insertInPostgres(
      {required String name,
      required String ownerName,
      required double buyPrice,
      required double sellPrice,
      required String barcode,
      required int count,
      required bool weightable,
      required String wholeUnit,
      required bool offer,
      required double offerCount,
      required double offerPrice,
      required DateTime? endDate,
      required bool hot}) {
    var postgresConnection = PostgresConnection();
    postgresConnection.connect();
    postgresConnection.insertProduct(
      name: name,
      ownerName: ownerName,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      barcode: barcode,
      count: count,
      weightable: weightable,
      wholeUnit: wholeUnit,
      offer: offer,
      offerCount: offerCount,
      offerPrice: offerPrice,
      endDate: endDate,
      hot: hot,
    );
  }

  Future<void> windows() async {
    final dir = await getApplicationDocumentsDirectory();
    await _replaceLiveIsarWithFile('${dir.path}/backup.isar.received');
  }

  Future<void> _replaceLiveIsarWithFile(String sourcePath) async {
    final dir = await getApplicationDocumentsDirectory();
    final livePath = '${dir.path}/isarInstance.isar';
    final sourceFile = File(sourcePath);
    final liveFile = File(livePath);
    final bakFile = File('$livePath.bak');

    await _verifyIsarFile(sourcePath);
    await closeAllIsarInstances();
    await isar!.close();

    if (await bakFile.exists()) {
      await bakFile.delete();
    }
    if (await liveFile.exists()) {
      await liveFile.rename(bakFile.path);
    }

    try {
      await sourceFile.copy(livePath);
      isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: 'isarInstance',
      );
      if (await bakFile.exists()) {
        await bakFile.delete();
      }
    } catch (e) {
      if (await liveFile.exists()) {
        await liveFile.delete();
      }
      if (await bakFile.exists()) {
        await bakFile.rename(livePath);
        isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: 'isarInstance',
        );
      }
      rethrow;
    }
  }

  Future<void> _verifyIsarFile(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Backup file not found at $sourcePath');
    }

    final tempDir = await getTemporaryDirectory();
    final verifyName = 'isar_verify_${DateTime.now().microsecondsSinceEpoch}';
    final verifyPath = '${tempDir.path}/$verifyName.isar';
    Isar? verifyIsar;

    try {
      await sourceFile.copy(verifyPath);
      verifyIsar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: tempDir.path,
        name: verifyName,
      );
      await verifyIsar.close();
      verifyIsar = null;
    } catch (e) {
      throw Exception('Backup file is corrupted or invalid: $e');
    } finally {
      if (verifyIsar != null) {
        try {
          await verifyIsar.close();
        } catch (_) {}
      }
      final verifyFile = File(verifyPath);
      if (await verifyFile.exists()) {
        await verifyFile.delete();
      }
    }
  }

  inboundReceipt({required List<Product> lst, required double total}) async {
    await isar!.writeTxn(() async {
      for (var element in lst) {
        var num = await isar!.products.get(element.id);
        if (num == null) continue;
        await isar!.products.put(
          Product.named2(
            id: element.id,
            name: element.name,
            barcode: element.barcode,
            buyprice: element.buyprice,
            sellPrice: element.sellPrice,
            count: (num.count!) + element.count!,
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
      }
    });
  }

  Future<void> cancelReceiptAtomically({
    required Log log,
    required double hotSum,
    required bool wasLoaned,
    required List<EmbeddedProduct> productsToRestore,
  }) async {
    await isar!.writeTxn(() async {
      if (wasLoaned && log.loanerID != null) {
        Loaner? temp = await isar!.loaners.get(log.loanerID!);
        if (temp != null) {
          DateTime calculateDate() {
            if (temp.loanedAmount! == 0) {
              return DateTime.parse(temp.lastPayment!.last.key!);
            }
            if (temp.loanedAmount! - (log.price + hotSum) == 0) {
              return DateTime.now();
            } else {
              try {
                return DateTime.parse(temp.lastPayment!.last.key!);
              } catch (e) {
                return DateTime(1900);
              }
            }
          }

          temp
            ..loanedAmount = (temp.loanedAmount ?? 0) > 0
                ? temp.loanedAmount! - (log.price + hotSum)
                : 0
            ..zeroingDate = calculateDate();
          await isar!.loaners.put(temp);
        }
      }
      for (final ep in productsToRestore) {
        final existing = await isar!.products.get(ep.productId!);
        if (existing != null) {
          existing.count = (existing.count ?? 0) + (ep.count ?? 0);
          await isar!.products.put(existing);
        }
      }
      await isar!.logs.delete(log.id);
    });
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
      final fallbackDir = await getApplicationDocumentsDirectory();
      isar = await DB.openIsarSafely(fallbackDir.path);
    }
    return isar.close();
  }
}

class CgetLowStockItemsPerMonth extends PooledJob<List<Product>> {
  Map map;
  CgetLowStockItemsPerMonth({required this.map});
  @override
  Future<List<Product>> job() async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);

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
      final fallbackDir = await getApplicationDocumentsDirectory();
      isar = await DB.openIsarSafely(fallbackDir.path);
    }
    // List<Log> temp = await isar.logs
    //     .where()
    //     .dateBetween(
    //         DateTime.now(), DateTime.now().add(const Duration(days: 30)))
    //     .findAll();
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Get all logs for the current month
      final monthlyLogs = await isar.logs
          .filter()
          .dateBetween(startOfMonth, endOfMonth)
          .findAll();

      // Get all products
      final products = await isar.products.where().anyId().findAll();

      // Accumulate sold counts per product id and per name (fallback)
      final Map<int, int> soldById = {};
      final Map<String, int> soldByName = {};

      for (final log in monthlyLogs) {
        for (final ep in log.products) {
          final soldCount = ep.count ?? 0;
          if (ep.productId != null && ep.productId! > 0) {
            soldById.update(ep.productId!, (v) => v + soldCount,
                ifAbsent: () => soldCount);
          } else if (ep.name != null) {
            soldByName.update(ep.name!, (v) => v + soldCount,
                ifAbsent: () => soldCount);
          }
        }
      }

      // Determine low stock products
      final List<Product> lowStock = [];
      for (final p in products) {
        final currentStock = p.count ?? 0;
        final soldThisMonth = soldById[p.id] ?? soldByName[p.name ?? ''] ?? 0;
        final totalAvailable = currentStock + soldThisMonth;

        if (totalAvailable <= 0) continue; // avoid division by zero

        final percentRemaining = currentStock / totalAvailable;

        // If remaining stock is less than 15% of total available this month
        if (percentRemaining < 0.25) {
          lowStock.add(p);
        }
      }

      return lowStock;
    } catch (e) {
      debugPrint('Error in CgetLowStockItemsPerMonth.job: $e');
      return <Product>[];
    }
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
      final fallbackDir = await getApplicationDocumentsDirectory();
      isar = await DB.openIsarSafely(fallbackDir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
        final existing = await Isar.getInstance("isarInstance");
        if (existing == null) {
          debugPrint('No Isar instance available: $e');
          return [];
        }
        isar = existing;
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
      final existing = await Isar.getInstance('isarInstance');
      if (existing != null) return existing;
      rethrow;
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
        isar = await DB.openIsarSafely(dir.path);
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
