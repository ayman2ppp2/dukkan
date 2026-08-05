// import 'dart:io';

// import 'package:device info_plus/device_info_plus.dart';

import 'dart:async';
import 'dart:io';

import 'package:dukkan/core/observability.dart';
import 'package:dukkan/data/backup/backup_service.dart';
import 'package:dukkan/models/Expense.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/searchQuery.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/Loaner.dart';
import '../../models/Owner.dart';

class DB {
  static const isarName = 'isarInstance';
  static const liveDatabaseFileName = '$isarName.isar';

  Isar? isar;
  Directory? _documentsDirectoryOverride;
  String _isarName = isarName;
  static DB? _instance;
  static bool _isInitializing = false;
  static Completer<DB> _initCompleter = Completer<DB>();

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

  @visibleForTesting
  static Future<DB> createForTesting({
    required String directoryPath,
    String name = 'isarInstance',
  }) async {
    final db = DB._internal()
      .._documentsDirectoryOverride = Directory(directoryPath)
      .._isarName = name;
    db.isar = await Isar.open(
      [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
      directory: directoryPath,
      name: name,
    );
    return db;
  }

  @visibleForTesting
  static Future<void> resetForTesting() async {
    await _instance?.isar?.close();
    _instance = null;
    _isInitializing = false;
    _initCompleter = Completer<DB>();
  }

  Future<Directory> _documentsDirectory() async {
    return _documentsDirectoryOverride ??
        await getApplicationDocumentsDirectory();
  }

  Future<Directory> getDocumentsDirectory() => _documentsDirectory();

  String get isarInstanceName => _isarName;

  bool get usesOverriddenDocumentsDirectory =>
      _documentsDirectoryOverride != null;

  BackupService? _backup;

  BackupService get backupService => _backup ??= BackupService(this);

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
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'database.open');
      final fallback = await Isar.getInstance("isarInstance");
      if (fallback != null) {
        AppLogger.warning('Using fallback Isar instance',
            data: {'area': 'database.open'});
        return fallback;
      }
      throw StateError('No Isar instance available: $e');
    }
  }

  Future<void> _init() async {
    try {
      final dir = await _documentsDirectory();
      final existingIsar = await Isar.getInstance(_isarName);
      if (existingIsar != null) {
        isar = existingIsar;
        return;
      }
      isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: _isarName,
      );
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'database.initialize');
      final fallback = await Isar.getInstance("isarInstance");
      if (fallback != null) {
        isar = fallback;
      } else {
        AppLogger.warning('Isar fallback unavailable',
            data: {'area': 'database.initialize'});
      }
    }
  }

  Future<bool> deleteLoaner(int id) {
    return isar!.writeTxn(() => isar!.loaners.delete(id));
  }

  Future<int> insertLoaner(Loaner loaner) {
    return isar!.writeTxn(() => isar!.loaners.put(loaner));
    // loaners.put(loaner.ID, loaner);
  }

  Future<List<Loaner>> getLoaners() {
    return isar!.loaners.where().anyID().sortByBalanceDesc().findAll();
    // return List<Loaner>.from(loaners.values);
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
      if (discount < 0) {
        throw Exception('Discount must be non-negative');
      }
      if (discount > total) {
        throw Exception('Discount cannot exceed checkout total');
      }

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

      AppLogger.debug('Checkout products prepared',
          data: {'productCount': clearedProducts.length});
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
          updatedLoaner.balance =
              (updatedLoaner.balance ?? 0) + total.round() - discount;
          final payments = List<EmbeddedMap>.from(
              updatedLoaner.lastPayment ?? [], growable: true);
          payments.add(EmbeddedMap()
            ..key = DateTime.now().toIso8601String()
            ..value = (total.round() - discount).toString()
            ..remaining = updatedLoaner.balance
            ..type = 'sale');
          updatedLoaner.lastPayment = payments;
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
        } catch (e, st) {
          AppLogger.warning('Checkout transaction retry failed', data: {
            'attempt': attempt + 1,
            'maxRetries': maxRetries,
          });
          if (attempt == maxRetries - 1) {
            await AppLogger.captureException(e,
                stackTrace: st,
                area: 'checkout.transaction',
                data: {'attempt': attempt + 1, 'maxRetries': maxRetries});
            rethrow;
          }
          await Future.delayed(Duration(milliseconds: 100 * (attempt + 1)));
        }
      }
      return success;
    } catch (e, st) {
      await AppLogger.captureException(e, stackTrace: st, area: 'checkout');
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
        .sortByBalanceDesc()
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
        (payment) =>
            (payment.type == null || payment.type == 'payment') &&
            DateTime.parse(payment.key!).isAfter(
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

  Future<void> createLocalBackup() => backupService.createLocalBackup();

  Future<void> closeAllIsarInstances() => backupService.closeAllIsarInstances();

  Future<IsolatePool> reOpenPool() => backupService.reOpenPool();

  Future<void> useLocalBacup() => backupService.useLocalBacup();

  Future<void> windows() => backupService.windows();

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
            if (temp.balance! == 0) {
              return DateTime.parse(temp.lastPayment!.last.key!);
            }
            if (temp.balance! - (log.price + hotSum) == 0) {
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
            ..balance = (temp.balance ?? 0) - (log.price + hotSum)
            ..zeroingDate = calculateDate();
          final payments = List<EmbeddedMap>.from(
              temp.lastPayment ?? [], growable: true);
          payments.add(EmbeddedMap()
            ..key = DateTime.now().toIso8601String()
            ..value = (log.price + hotSum).toString()
            ..remaining = temp.balance
            ..type = 'cancel');
          temp.lastPayment = payments;
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
