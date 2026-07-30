import 'dart:io';
import 'package:isar_community/isar.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:dukkan/util/models/Emap.dart';

const dbDir = '/home/ayman/Documents';

void main(List<String> args) async {
  await Isar.initializeIsarCore(download: true);

  final dir = Directory(dbDir);
  if (!await dir.exists()) {
    print('ERROR: Database directory not found: $dbDir');
    exit(1);
  }

  final isar = await Isar.open(
    [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
    directory: dir.path,
    name: 'isarInstance',
  );

  final logs = await isar.logs.where().sortByDate().findAll();
  final allProducts = await isar.products.where().findAll();
  final productMap = <int, Product>{};
  for (final p in allProducts) {
    productMap[p.id] = p;
  }

  print('=== DATABASE OVERVIEW ===');
  print('Total logs: ${logs.length}');
  print('Total products: ${allProducts.length}');
  print('Products with priceHistory entries: ${allProducts.where((p) => p.priceHistory.isNotEmpty).length}');
  print('Products with empty priceHistory: ${allProducts.where((p) => p.priceHistory.isEmpty).length}');

  print('\n=== PRODUCT PRICE HISTORY ===');
  for (final p in allProducts) {
    if (p.priceHistory.isNotEmpty) {
      print('\nProduct: ${p.name} (id: ${p.id})');
      print('  Current buyPrice: ${p.buyprice}  |  Current sellPrice: ${p.sellPrice}');
      print('  Price history (${p.priceHistory.length} entries):');
      for (var i = 0; i < p.priceHistory.length; i++) {
        final e = p.priceHistory[i];
        print('    [$i] buyPrice: ${e.buyPrice}, sellPrice: ${e.sellPrice}, date: ${e.date}');
      }
    }
  }

  print('\n\n=== PROFIT CALCULATION TRACE ===');
  print('Showing last 20 logs (most recent):');
  print('');

  final displayLogs =  logs;

  for (final log in displayLogs) {
    print('━' * 70);
    print('Log #${log.id} | Date: ${log.date} | Discount: ${log.discount}');
    print('  Products in this sale: ${log.products.length}');
    print('');

    double subtotalNew = 0;
    double subtotalOld = 0;

    for (final ep in log.products) {
      if (ep.hot == true) {
        print('  ⚠ SKIP: ${ep.name} (hot product)');
        continue;
      }

      final product = (ep.productId != null && ep.productId! > 0)
          ? productMap[ep.productId]
          : null;

      // --- NEW calculation (next priceHistory) ---
      double buyPriceNew;
      String sourceNew;

      if (product != null) {
        sourceNew = 'product found (id=${product.id}, name=${product.name})';
        if (product.priceHistory.isNotEmpty) {
          Emap? next;
          for (final entry in product.priceHistory) {
            if (entry.date != null && !entry.date!.isBefore(log.date)) {
              if (next == null || entry.date!.isBefore(next.date!)) {
                next = entry;
              }
            }
          }
          if (next != null) {
            buyPriceNew = next.buyPrice ?? product.buyprice ?? ep.buyPrice ?? 0;
            sourceNew = '→ NEXT entry: buyPrice=${next.buyPrice} (date=${next.date})';
          } else {
            buyPriceNew = product.buyprice ?? ep.buyPrice ?? 0;
            sourceNew = '→ no NEXT entry → current buyprice=${product.buyprice}';
          }
        } else {
          buyPriceNew = product.buyprice ?? ep.buyPrice ?? 0;
          sourceNew = '→ empty priceHistory → current buyprice=${product.buyprice}';
        }
      } else {
        buyPriceNew = ep.buyPrice ?? 0;
        sourceNew = '→ product NOT in map → ep.buyPrice snapshot=${ep.buyPrice}';
      }

      // --- OLD calculation (current product.buyprice) ---
      final buyPriceOld = (ep.productId != null && ep.productId! > 0)
          ? (productMap[ep.productId]?.buyprice ?? (ep.buyPrice ?? 0))
          : (ep.buyPrice ?? 0);

      final profitNew = ((ep.sellPrice ?? 0) - buyPriceNew) * (ep.count ?? 0);
      final profitOld = ((ep.sellPrice ?? 0) - buyPriceOld) * (ep.count ?? 0);

      subtotalNew += profitNew;
      subtotalOld += profitOld;

      final epName = ep.name ?? '(unnamed)';
      print('  📦 $epName (productId: ${ep.productId})');
      print('     Snapshot: sellPrice=${ep.sellPrice}, buyPrice=${ep.buyPrice}, count=${ep.count}');
      print('     $sourceNew');
      if (product != null && product.priceHistory.isNotEmpty) {
        print('     All priceHistory entries:');
        for (var i = 0; i < product.priceHistory.length; i++) {
          final e = product.priceHistory[i];
          final marker = (e.date != null && !e.date!.isBefore(log.date))
              ? ' ← ≥ log.date'
              : '';
          print('       [$i] buyPrice: ${e.buyPrice}, date: ${e.date}$marker');
        }
      }
      print('     NEW: (${ep.sellPrice} - $buyPriceNew) × ${ep.count} = $profitNew');
      print('     OLD: (${ep.sellPrice} - $buyPriceOld) × ${ep.count} = $profitOld');
      print('');
    }

    final totalNew = subtotalNew - log.discount;
    final totalOld = subtotalOld - log.discount;
    print('  SUBTOTAL before discount: NEW=$subtotalNew, OLD=$subtotalOld');
    print('  DISCOUNT: ${log.discount}');
    print('  TOTAL:   NEW=$totalNew, OLD=$totalOld');
  }

  print('\n\n=== MONTHLY PROFIT COMPARISON ===');
  final Map<String, double> monthlyNew = {};
  final Map<String, double> monthlyOld = {};
  for (final log in logs) {
    final key = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
    monthlyNew[key] = (monthlyNew[key] ?? 0) + recalculateProfit([log], productMap);
    monthlyOld[key] = (monthlyOld[key] ?? 0) + oldRecalculateProfit([log], productMap);
  }

  final sortedKeys = monthlyNew.keys.toList()..sort();
  print('Month       | NEW Profit   | OLD Profit   | DIFF');
  print('-' .padRight(55, '-'));
  for (final key in sortedKeys) {
    final n = monthlyNew[key] ?? 0;
    final o = monthlyOld[key] ?? 0;
    final diff = n - o;
    print('$key  | ${n.toStringAsFixed(2).padLeft(12)} | ${o.toStringAsFixed(2).padLeft(12)} | ${diff.toStringAsFixed(2).padLeft(10)}');
  }

  // Yearly
  final yearNew = monthlyNew.values.fold(0.0, (a, b) => a + b);
  final yearOld = monthlyOld.values.fold(0.0, (a, b) => a + b);
  print('-' .padRight(55, '-'));
  print('YEAR TOTAL | ${yearNew.toStringAsFixed(2).padLeft(12)} | ${yearOld.toStringAsFixed(2).padLeft(12)} | ${(yearNew - yearOld).toStringAsFixed(2).padLeft(10)}');

  // Log count per month
  print('\n=== LOG COUNT PER MONTH ===');
  final monthlyCount = <String, int>{};
  for (final log in logs) {
    final key = '${log.date.year}-${log.date.month.toString().padLeft(2, '0')}';
    monthlyCount[key] = (monthlyCount[key] ?? 0) + 1;
  }
  for (final key in sortedKeys) {
    print('  $key: ${monthlyCount[key]} logs');
  }

  print('\n=== END OF TRACE ===');

  await isar.close();
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

double oldRecalculateProfit(Iterable<Log> logs, Map<int, Product> productMap) {
  double total = 0;
  for (final log in logs) {
    double subtotal = 0;
    for (final ep in log.products) {
      if (ep.hot == true) continue;
      final buyPrice = (ep.productId != null && ep.productId! > 0)
          ? (productMap[ep.productId]?.buyprice ?? (ep.buyPrice ?? 0))
          : (ep.buyPrice ?? 0);
      subtotal += ((ep.sellPrice ?? 0) - buyPrice) * (ep.count ?? 0);
    }
    total += subtotal - log.discount;
  }
  return total;
}
