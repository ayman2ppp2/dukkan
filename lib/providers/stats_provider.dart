import 'package:dukkan/core/db.dart';
import 'package:dukkan/core/IsolatePool.dart';
import 'package:dukkan/util/models/prodStats.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';

RootIsolateToken? _getRootIsolateToken() {
  return RootIsolateToken.instance;
}

class StatsProvider extends ChangeNotifier {
  late DB db;
  late IsolatePool pool;
  final Map<String, dynamic> _cache = {};
  bool cacheIsValid = false;

  StatsProvider() {
    init();
  }

  Future<void> init() async {
    db = await DB.getInstance();
    pool = await Pool.init();
  }

  Future<T> getCachedCalculation<T>(
      String cacheKey, Future<T> Function() calculate) async {
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as T;
    }
    final result = await calculate();
    _cache[cacheKey] = result;
    return result;
  }

  void clearAllCache() {
    _cache.clear();
    notifyListeners();
  }

  void clearCache(String cacheKey) {
    _cache.remove(cacheKey);
    notifyListeners();
  }

  Future<void> refresh() async {
    notifyListeners();
  }

  Future<double> getAverageProfitPercent() async {
    var temp = await Future.wait([getAllSales(), getAllProfit()]);
    double profit = temp[1];
    double price = temp[0];
    return (profit / (price - profit)) * 100;
  }

  Future<double> getProfitOfTheMonth() {
    return getCachedCalculation('profitOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      return pool.scheduleJob(CgetProfitOfTheMonth(map: map));
    });
  }

  Future<double> getSalesOfTheMonth() {
    return getCachedCalculation('salesOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      return pool.scheduleJob(CgetSalesOfTheMonth(map: map));
    });
  }

  Future<double> getDailySales(DateTime time) {
    return getCachedCalculation('dailySales', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = time;
      return pool.scheduleJob(CgetDailySales(map: map));
    });
  }

  Future<double> getDailyProfits(DateTime time) {
    return getCachedCalculation('dailyProfits', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = time;
      return pool.scheduleJob(CgetDailyProfit(map: map));
    });
  }

  Future<double> getAllProfit() {
    return getCachedCalculation('totalProfit', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = DateTime.now();
      return pool.scheduleJob(CgetTotalProfit(map: map));
    });
  }

  Future<double> getAllSales() {
    return getCachedCalculation('allSales', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      return pool.scheduleJob(CgetAllSales(map: map));
    });
  }

  Future<int> getNumberOfSalesForAproduct({required String key}) {
    return getCachedCalculation('numberOfSalesPerProduct', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = key;
      return pool.scheduleJob(CgetNumberOfSalesForAproduct(map: map));
    });
  }

  Future<List<ProdStats>> getSaledProductsByDate(DateTime time) {
    return getCachedCalculation('saledProductsByDate', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = time;
      return pool.scheduleJob(CgetSaledProductsByDate(map: map));
    });
  }

  Future<List<ProdStats>> getSalesPerProduct(int chunkSize) async {
    return getCachedCalculation('salesPerProduct', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = chunkSize;
      return pool.scheduleJob(CgetSalesPerProduct(chunkSize: chunkSize, map: map));
    });
  }

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailySalesOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetDailySalesOfTheMonth(map: map));
    });
  }

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailyProfitOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetDailyProfitOfTheMont(map: map));
    });
  }

  Future<List<SalesStats>> getMonthlySalesOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlySalesOfTheYear', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetMonthlySalesOfTheyear(map: map));
    });
  }

  Future<List<SalesStats>> getMonthlyProfitsOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlyProfitsOfTheYear', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ?? (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetMonthlyProfitsOfTheyear(map: map));
    });
  }

  Stream<List<Product>> getTotalBuyPrice() {
    return db.getTotalBuyPrice();
  }
}