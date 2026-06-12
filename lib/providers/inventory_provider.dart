import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/models/LowStockProduct.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';

class InventoryProvider extends ChangeNotifier {
  late DB db;

  InventoryProvider() {
    init();
  }

  @visibleForTesting
  InventoryProvider.forTesting(this.db);

  Future<void> init() async {
    db = await DB.getInstance();
  }

  Future<List<Product>> search(String text) async {
    final searchTerm = text.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      return db.getAllProducts();
    }
    var query = db.isar!.products.filter();
    QueryBuilder<Product, Product, QAfterFilterCondition> filterQuery =
        query.nameContains(searchTerm, caseSensitive: false);
    filterQuery =
        filterQuery.or().barcodeContains(searchTerm, caseSensitive: false);
    return filterQuery.findAll();
  }

  Future<List<Product>> searchByBarcode(String barcode) async {
    return db.isar!.products.filter().barcodeEqualTo(barcode).findAll();
  }

  List<Product?> embeddedToProduct(List<EmbeddedProduct> products) {
    List<int> realIds = List.empty(growable: true);
    for (var p in products) {
      if (!p.hot!) {
        realIds.add(p.productId!);
      }
    }
    return db.embeddedToProduct(realIds);
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<List<Product>> getAllProducts() async {
    return db.getAllProducts();
  }

  Stream<List<Product>> watchProducts() {
    return db.isar!.products.watchLazy().asyncMap((_) => db.getAllProducts());
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
