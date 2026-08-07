import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/LowStockProduct.dart';
import 'package:flutter/material.dart';

class InventoryProvider extends ChangeNotifier {
  late DB db;

  InventoryProvider() {
    init();
  }

  @visibleForTesting
  InventoryProvider.forTesting(this.db);

  Future<void>? _initFuture;

  /// Initializes the provider's backing resources. Safe to call more than
  /// once: only the first invocation runs the initialization.
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    db = await DB.getInstance();
  }

  Future<List<LowStockProduct>> getLowStockItems(
      {double thresholdPercent = 0.25}) async {
    final results = await db.getLowStockProductsWithPercent(
        thresholdPercent: thresholdPercent);
    return results
        .map((r) => LowStockProduct(
              product: r['product'] as Product,
              percentRemaining: r['percentRemaining'] as double,
              currentStock: r['currentStock'] as int,
              soldLast30Days: r['soldLast30Days'] as int,
            ))
        .toList();
  }
}
