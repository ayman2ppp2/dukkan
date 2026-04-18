import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:isar_community/isar.dart';

class InventoryProvider extends ChangeNotifier {
  late DB db;

  InventoryProvider() {
    init();
  }

  Future<void> init() async {
    db = await DB.getInstance();
  }

  Future<List<Product>> search(String text) async {
    final searchTerm = text.trim().toLowerCase();
    if (searchTerm.isEmpty) {
      return db.getAllProducts();
    }
    var query = db.isar!.products.filter();
    QueryBuilder<Product, Product, QAfterFilterCondition> filterQuery = query.nameContains(searchTerm, caseSensitive: false);
    filterQuery = filterQuery.or().barcodeContains(searchTerm, caseSensitive: false);
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
}