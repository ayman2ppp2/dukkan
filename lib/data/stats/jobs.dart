import 'package:dukkan/core/observability.dart';
import 'package:dukkan/models/Emap.dart';
import 'package:dukkan/models/Expense.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/prodStats.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:path_provider/path_provider.dart';

Future<Isar> openPoolIsar() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
      directory: dir.path,
      name: 'isarInstance',
    );
  } catch (e) {
    final fallbackDir = await getApplicationDocumentsDirectory();
    return openIsarSafely(fallbackDir.path);
  }
}

Future<Isar> openIsarSafely(String directoryPath) async {
  try {
    final existing = await Isar.getInstance('isarInstance');
    if (existing != null) return existing;
    return await Isar.open(
      [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
      directory: directoryPath,
      name: 'isarInstance',
    );
  } catch (e, st) {
    await AppLogger.captureException(e,
        stackTrace: st, area: 'database.open');
    final fallback = await Isar.getInstance('isarInstance');
    if (fallback != null) return fallback;
    throw StateError('No Isar instance available: $e');
  }
}

Future<Isar?> _openPoolIsarExistingOnly() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
      directory: dir.path,
      name: 'isarInstance',
    );
  } catch (e) {
    return await Isar.getInstance('isarInstance');
  }
}


class CgetLowStockItemsPerMonth extends PooledJob<List<Product>> {
  Map map;
  CgetLowStockItemsPerMonth({required this.map});
  @override
  Future<List<Product>> job() async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);

    final isar = await openPoolIsar();
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
      AppLogger.warning('Low-stock calculation failed',
          data: {'area': 'stats.low_stock'});
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

    final isar = await openPoolIsar();
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
      final isar = await openPoolIsar();
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
      final logs = await isar.logs
          .filter()
          .dateBetween(startOfMonth, endOfMonth)
          .findAll();
      final allProducts = await isar.products.where().findAll();
      final productMap = <int, Product>{};
      for (final p in allProducts) {
        productMap[p.id] = p;
      }
      return recalculateProfit(logs, productMap);
    } on Exception {
      AppLogger.warning('Monthly profit calculation failed',
          data: {'area': 'stats.monthly_profit'});
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
      final isar = await openPoolIsar();
      final time = map['2'] as DateTime;
      final startOfDay = DateTime(time.year, time.month, time.day);
      final endOfDay = DateTime(time.year, time.month, time.day, 23, 59, 59);
      final logs = await isar.logs
          .filter()
          .dateBetween(startOfDay, endOfDay)
          .findAll();
      final allProducts = await isar.products.where().findAll();
      final productMap = <int, Product>{};
      for (final p in allProducts) {
        productMap[p.id] = p;
      }
      return recalculateProfit(logs, productMap);
    } catch (e) {
      AppLogger.warning('Daily profit calculation failed',
          data: {'area': 'stats.daily_profit'});
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
      final isar = await openPoolIsar();
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
      AppLogger.warning('Daily sales calculation failed',
          data: {'area': 'stats.daily_sales'});
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
      final isar = await openPoolIsar();
      List<Log> temp = await isar.logs.where().anyId().findAll();
      double sales = 0;
      for (var log in temp) {
        sales += log.price;
      }

      return sales;
    } catch (e) {
      AppLogger.warning('All-sales calculation failed',
          data: {'area': 'stats.all_sales'});
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
      final isar = await _openPoolIsarExistingOnly();
      if (isar == null) {
        AppLogger.warning('No Isar instance available',
            data: {'area': 'stats.saled_products'});
        return [];
      }
      Iterable<Log> temp = await isar.logs.where().anyId().findAll();
      DateTime time = map['2'];
      temp = temp.where((element) =>
          element.date.day == time.day &&
          element.date.month == time.month &&
          element.date.year == time.year);
      AppLogger.debug('Daily sale-product query completed',
          data: {'resultCount': temp.length});
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
      AppLogger.warning('Saled-products query failed',
          data: {'area': 'stats.saled_products'});
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
      final isar = await openPoolIsar();
      List<Log> temp = await isar.logs.where().anyId().findAll();
      double profit = 0;
      for (var log in temp) {
        profit += log.profit;
      }

      return profit;
    } catch (e) {
      AppLogger.warning('Total profit calculation failed',
          data: {'area': 'stats.total_profit'});
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
      final isar = await openPoolIsar();
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
      AppLogger.warning('Product sales count calculation failed',
          data: {'area': 'stats.product_sales_count'});
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
      AppLogger.warning('Product stats calculation failed',
          data: {'area': 'stats.sales_per_product'});
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
      final isar = await openPoolIsar();
      final month = map['2'] as DateTime;
      final startOfMonth = DateTime(month.year, month.month, 1);
      final endOfMonth = DateTime(month.year, month.month + 1, 0);
      final logs = await isar.logs
          .filter()
          .dateBetween(startOfMonth, endOfMonth)
          .sortByDateDesc()
          .findAll();
      final allProducts = await isar.products.where().findAll();
      final productMap = <int, Product>{};
      for (final p in allProducts) {
        productMap[p.id] = p;
      }

      final Map<String, double> dailySales = {};
      for (final log in logs) {
        final date =
            "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}-${log.date.day.toString().padLeft(2, '0')}";
        dailySales[date] = (dailySales[date] ?? 0) + recalculateProfit([log], productMap);
      }
      return dailySales.entries
          .map((e) => SalesStats(date: DateTime.parse(e.key), sales: e.value))
          .toList();
    } catch (e) {
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
      final isar = await openPoolIsar();
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
      AppLogger.warning('Daily sales of month calculation failed',
          data: {'area': 'stats.daily_sales_month'});
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
      final isar = await openPoolIsar();
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
      AppLogger.warning('Monthly sales calculation failed',
          data: {'area': 'stats.monthly_sales'});
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
      final isar = await openPoolIsar();
      final year = (map['2'] as DateTime).year;
      final startOfYear = DateTime(year, 1, 1);
      final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
      final logs = await isar.logs
          .filter()
          .dateBetween(startOfYear, endOfYear)
          .findAll();
      final allProducts = await isar.products.where().findAll();
      final productMap = <int, Product>{};
      for (final p in allProducts) {
        productMap[p.id] = p;
      }

      final Map<String, double> monthlySales = {};
      for (final log in logs) {
        final key = "${log.date.year}-${log.date.month.toString().padLeft(2, '0')}";
        monthlySales[key] = (monthlySales[key] ?? 0) + recalculateProfit([log], productMap);
      }
      final result = monthlySales.entries
          .map((e) => SalesStats(
              date: DateTime.parse("${e.key}-01"), sales: e.value))
          .toList();
      result.sort((a, b) => b.date.compareTo(a.date));
      return result;
    } catch (e) {
      AppLogger.warning('Monthly profit series calculation failed',
          data: {'area': 'stats.monthly_profit_series'});
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
              if (value.type != null && value.type != 'payment') return false;
              try {
                final paymentDate = DateTime.parse(value.key!);
                return paymentDate.year == year && paymentDate.month == month;
              } catch (e) {
                AppLogger.warning('Payment date parse failed',
                    data: {'area': 'stats.loan_payments'});
                return false;
              }
            }).fold(
                0.0,
                (previousValue, element) =>
                    double.parse(element.value ?? '0') + previousValue);
      });
    } catch (e) {
      AppLogger.warning('Total payments calculation failed',
          data: {'area': 'stats.loan_payments'});
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

      final allReceipts = await isar.logs
          .filter()
          .loanedEqualTo(true)
          .dateBetween(startOfMonth, endOfMonth)
          .findAll();

      final excludedLoaners = await isar.loaners
          .filter()
          .balanceLessThan(0)
          .findAll();
      final excludedIds = excludedLoaners.map((l) => l.ID).toSet();
      final receipts = allReceipts.where((r) => !excludedIds.contains(r.loanerID)).toList();

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
      AppLogger.warning('Monthly loans calculation failed',
          data: {'area': 'stats.monthly_loans'});
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
      final isar = await openPoolIsar();
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
      AppLogger.warning('Expense total calculation failed',
          data: {'area': 'stats.expense_total'});
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

      final allReceipts = await isar.logs
          .filter()
          .loanedEqualTo(true)
          .dateBetween(startOfDay, endOfDay)
          .findAll();

      final excludedLoaners = await isar.loaners
          .filter()
          .balanceLessThan(0)
          .findAll();
      final excludedIds = excludedLoaners.map((l) => l.ID).toSet();
      final receipts = allReceipts.where((r) => !excludedIds.contains(r.loanerID)).toList();

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
      AppLogger.warning('Daily loans calculation failed',
          data: {'area': 'stats.daily_loans'});
      return -1;
    }
  }
}

class CgetLoanerComparison extends PooledJob<List<LoanerComparison>> {
  Map map;
  CgetLoanerComparison({required this.map});

  @override
  Future<List<LoanerComparison>> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final isar = await _openPoolIsarExistingOnly();
      if (isar == null) {
        AppLogger.warning('No Isar instance available',
            data: {'area': 'stats.loaner_comparison'});
        return [];
      }

      final loaners = await isar.loaners.where().findAll();
      final eligible = loaners.where((l) => (l.balance ?? 0) > 0).toList();
      final allProducts = await isar.products.where().findAll();
      final productMap = <int, Product>{};
      for (final p in allProducts) {
        productMap[p.id] = p;
      }

      final allLoanedLogs = <Log>[];
      for (final loaner in eligible) {
        allLoanedLogs.addAll(await _loadLoanerDebtTail(isar, loaner));
      }

      return computeLoanerComparison(
        loaners: eligible,
        loanedLogs: allLoanedLogs,
        productMap: productMap,
      );
    } catch (e) {
      AppLogger.warning('Loaner comparison calculation failed',
          data: {'area': 'stats.loaner_comparison'});
      return [];
    }
  }
}

Future<List<Log>> _loadLoanerDebtTail(Isar isar, Loaner loaner,
    {int batch = 200}) async {
  final balance = loaner.balance ?? 0;
  final logs = <Log>[];
  var offset = 0;
  while (true) {
    final chunk = await isar.logs
        .filter()
        .loanedEqualTo(true)
        .loanerIDEqualTo(loaner.ID)
        .sortByDateDesc()
        .offset(offset)
        .limit(batch)
        .findAll();
    if (chunk.isEmpty) break;
    logs.addAll(chunk);
    if (debtWindowStart(balance: balance, logsNewestFirst: logs) != null) {
      break;
    }
    offset += batch;
  }
  return logs;
}

@visibleForTesting
DateTime? debtWindowStart({
  required double balance,
  required List<Log> logsNewestFirst,
}) {
  if (balance <= 0 || logsNewestFirst.isEmpty) return null;
  var remaining = balance;
  for (final log in logsNewestFirst) {
    final value = logLoanedValue(log);
    if (value <= 0) continue;
    remaining -= value;
    if (remaining <= 0) return log.date;
  }
  return null;
}

/// The sell value of the hot products in a log. Hot products are not tracked
/// in the product catalog (no reliable buy price), so this value is excluded
/// from the loaner comparison chart but reconciles a loaner's balance with its
/// tracked loaned amount.
@visibleForTesting
double hotSellValue(Log log) {
  double value = 0;
  for (final ep in log.products) {
    if (ep.hot == true) {
      value += (ep.sellPrice ?? 0) * (ep.count ?? 0);
    }
  }
  return value;
}

/// The full sell value of a log, including hot products. A loaner's recorded
/// balance is raised by this total on checkout, so the debt window must be
/// sized with it even though the chart itself only shows tracked products.
@visibleForTesting
double logLoanedValue(Log log) => log.price + hotSellValue(log);

@visibleForTesting
List<LoanerComparison> computeLoanerComparison({
  required Iterable<Loaner> loaners,
  required Iterable<Log> loanedLogs,
  required Map<int, Product> productMap,
}) {
  final logsByLoaner = <int, List<Log>>{};
  for (final log in loanedLogs) {
    final id = log.loanerID;
    if (id == null) continue;
    logsByLoaner.putIfAbsent(id, () => []).add(log);
  }

  final results = <LoanerComparison>[];
  for (final loaner in loaners) {
    if ((loaner.balance ?? 0) <= 0) continue;
    final loanerLogs = logsByLoaner[loaner.ID];
    if (loanerLogs == null || loanerLogs.isEmpty) continue;

    double loanedAmount = 0;
    double currentValue = 0;
    var remaining = loaner.balance ?? 0;

    final sorted = [...loanerLogs]..sort((a, b) => b.date.compareTo(a.date));
    for (final log in sorted) {
      final value = logLoanedValue(log);
      if (value <= 0) continue;

      double logCurrentValue = 0;
      for (final ep in log.products) {
        if (ep.hot == true) continue;
        final count = ep.count ?? 0;
        final buyPrice = (ep.productId != null && ep.productId! > 0)
            ? (productMap[ep.productId]?.buyprice ?? (ep.buyPrice ?? 0))
            : (ep.buyPrice ?? 0);
        logCurrentValue += buyPrice * count;
      }

      if (remaining <= value) {
        final fraction = remaining / value;
        loanedAmount += log.price * fraction;
        currentValue += logCurrentValue * fraction;
        break;
      }
      loanedAmount += log.price;
      currentValue += logCurrentValue;
      remaining -= value;
    }

    if (loanedAmount == 0 && currentValue == 0) continue;

    results.add(LoanerComparison(
      name: loaner.name ?? 'Unknown',
      loanedAmount: loanedAmount,
      currentValue: currentValue,
    ));
  }

  results.sort((a, b) => b.loanedAmount.compareTo(a.loanedAmount));
  return results;
}

double recalculateProfit(Iterable<Log> logs, Map<int, Product> productMap) {
  double total = 0;
  for (final log in logs) {
    double subtotal = 0;
    for (final ep in log.products) {
      if (ep.hot == true) continue;
      double buyPrice;
      final product = (ep.productId != null && ep.productId! > 0)
          ? productMap[ep.productId]
          : null;
      if (product != null) {
        Emap? next;
        for (final entry in product.priceHistory) {
          if (entry.date != null && !entry.date!.isBefore(log.date)) {
            if (next == null || entry.date!.isBefore(next.date!)) {
              next = entry;
            }
          }
        }
        buyPrice = next?.buyPrice ?? product.buyprice ?? ep.buyPrice ?? 0;
      } else {
        buyPrice = ep.buyPrice ?? 0;
      }
      subtotal += ((ep.sellPrice ?? 0) - buyPrice) * (ep.count ?? 0);
    }
    total += subtotal - log.discount;
  }
  return total;
}

class CgetYearlyTotals extends PooledJob<YearlyTotals> {
  Map map;
  CgetYearlyTotals({required this.map});

  @override
  Future<YearlyTotals> job() async {
    try {
      BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);
      final isar = await _openPoolIsarExistingOnly();
      if (isar == null) {
        AppLogger.warning('No Isar instance available',
            data: {'area': 'stats.yearly_totals'});
        return YearlyTotals(yearlyProfit: 0, yearlySales: 0);
      }

      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);
      final endOfYear = DateTime(now.year, 12, 31, 23, 59, 59);

      final logs = await isar.logs
          .filter()
          .dateBetween(startOfYear, endOfYear)
          .findAll();
      final allProducts = await isar.products.where().findAll();
      final productMap = <int, Product>{};
      for (final p in allProducts) {
        productMap[p.id] = p;
      }

      final yearlyProfit = recalculateProfit(logs, productMap);
      double yearlySales = 0;
      for (final log in logs) {
        yearlySales += log.price;
      }

      double totalInflation = 0;
      int inflationCount = 0;
      for (final p in allProducts) {
        if (p.priceHistory.isEmpty) continue;
        Emap? beforeYear;
        for (final entry in p.priceHistory) {
          if (entry.date != null && !entry.date!.isAfter(startOfYear)) {
            if (beforeYear == null || entry.date!.isAfter(beforeYear.date!)) {
              beforeYear = entry;
            }
          }
        }
        if (beforeYear?.buyPrice == null || beforeYear!.buyPrice == 0) continue;
        final currentPrice = p.buyprice;
        if (currentPrice == null || currentPrice == 0) continue;
        totalInflation += ((currentPrice - beforeYear.buyPrice!) / beforeYear.buyPrice!) * 100;
        inflationCount++;
      }
      final yearlyInflation = inflationCount > 0 ? totalInflation / inflationCount : 0.0;

      return YearlyTotals(yearlyProfit: yearlyProfit, yearlySales: yearlySales, yearlyInflation: yearlyInflation);
    } catch (e) {
      AppLogger.warning('Yearly totals calculation failed',
          data: {'area': 'stats.yearly_totals'});
      return YearlyTotals(yearlyProfit: 0, yearlySales: 0);
    }
  }
}