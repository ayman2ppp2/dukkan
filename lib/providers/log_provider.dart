import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/data/stats/stats_service.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/searchQuery.dart';
import 'package:flutter/material.dart';

class LogProvider extends ChangeNotifier {
  late DB db;
  late StatsService stats;
  bool editing = false;
  DateTime logID = DateTime.now();

  LogProvider({StatsService? stats}) : _injectedStats = stats {
    init();
  }

  @visibleForTesting
  LogProvider.forTesting(this.db) {
    stats = StatsService.forTesting(db);
  }

  @visibleForTesting
  LogProvider.detachedForTesting();

  StatsService? _injectedStats;

  Future<void>? _initFuture;

  /// Initializes the provider's backing resources. Safe to call more than
  /// once: only the first invocation runs the initialization.
  Future<void> init() => _initFuture ??= _doInit();

  Future<void> _doInit() async {
    db = await DB.getInstance();
    stats = _injectedStats ?? StatsService();
  }

  Stream<List<Log>> getPersonsLogs(int? ID) {
    return db.getPersonsLogs(ID);
  }

  Stream<List<Log>> getLogsStream({
    required int chunkSize,
    required SearchQuery searchQuery,
  }) {
    return db.getLogsStream(
      chunkSize,
      searchQuery,
    );
  }

  Future<void> cancelReceipt(DateTime date, Log log) async {
    double sum = 0;
    List<EmbeddedProduct> products = List.empty(growable: true);
    for (var product in log.products) {
      if (product.hot!) {
        sum += product.sellPrice! * product.count!;
      } else {
        products.add(product);
      }
    }
    await db.cancelReceiptAtomically(
      log: log,
      hotSum: sum,
      wasLoaned: log.loaned,
      productsToRestore: products,
    );
    stats.clearAllCache();
    notifyListeners();
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
    final ok = await db.checkOut(
        products: lst,
        total: total,
        discount: discount,
        loanerId: LoID,
        loaned: loaned,
        expense: expense,
        expenseId: expenseId);
    if (!ok) {
      throw Exception('Checkout failed');
    }
    stats.clearAllCache();
    notifyListeners();
  }

  Future<List<Product?>> editReceipt(DateTime date, Log log) async {
    double sum = 0;
    List<EmbeddedProduct> products = List.empty(growable: true);
    for (var product in log.products) {
      if (product.hot!) {
        sum += product.sellPrice! * product.count!;
      } else {
        products.add(product);
      }
    }
    await db.cancelReceiptAtomically(
      log: log,
      hotSum: sum,
      wasLoaned: log.loaned,
      productsToRestore: products,
    );
    stats.clearAllCache();
    notifyListeners();
    var result = embeddedToProduct(log.products);
    Map<int, int> originalCounts = {};
    for (var ep in log.products) {
      if (!ep.hot! && ep.productId != null) {
        originalCounts.update(
          ep.productId!,
          (v) => v + (ep.count ?? 0),
          ifAbsent: () => ep.count ?? 0,
        );
      }
    }
    for (var p in result) {
      if (p != null && !p.hot! && originalCounts.containsKey(p.id)) {
        p.count = originalCounts[p.id]!;
      }
    }
    return result;
  }

  List<Product?> embeddedToProduct(List<EmbeddedProduct> products) {
    List<int> realIds = List.empty(growable: true);
    for (var p in products) {
      if (!p.hot!) {
        realIds.add(p.productId!);
      }
    }
    List<Product?> realProducts = List.empty(growable: true);
    realProducts.addAll(db.embeddedToProduct(realIds));

    List<Product> fakes = List.empty(growable: true);
    for (var f in products) {
      if (f.hot!) {
        var temp = Product.named2(
            name: f.name,
            ownerName: null,
            barcode: null,
            buyprice: f.buyPrice ?? 0,
            sellPrice: f.sellPrice ?? 0,
            count: f.count ?? 0,
            weightable: null,
            wholeUnit: null,
            offer: false,
            offerCount: 0,
            offerPrice: 0,
            priceHistory: [],
            endDate: null,
            hot: f.hot,
            id: 0);
        fakes.add(temp);
      }
    }
    realProducts.addAll(fakes);
    return realProducts;
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}
