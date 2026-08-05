import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/core/pool/isolate_pool.dart';
import 'package:dukkan/data/stats/jobs.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/prodStats.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';

RootIsolateToken? _getRootIsolateToken() {
  return RootIsolateToken.instance;
}

/// Single owner of the pooled stats computations and their cache.
///
/// Registered at the app root so pages and the receipt flow all share one
/// cache instance.
class StatsService extends ChangeNotifier {
  late DB db;
  late IsolatePool pool;

  final Map<String, dynamic> _cache = {};
  int cacheVersion = 0;
  bool cacheIsValid = false;

  StatsService() {
    init();
  }

  /// Bypasses async pool initialization; used by test harnesses and
  /// `@visibleForTesting` provider constructors.
  StatsService.forTesting(this.db);

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
    cacheVersion++;
    notifyListeners();
  }

  void clearCache(String cacheKey) {
    _cache.remove(cacheKey);
    notifyListeners();
  }

  Map _jobMap({Object? arg}) {
    Map map = Map();
    map['1'] = _getRootIsolateToken() ??
        (throw StateError('RootIsolateToken not available'));
    if (arg != null) map['2'] = arg;
    return map;
  }

  Future<YearlyTotals> getYearlyTotals() {
    return getCachedCalculation('yearlyTotals',
        () => pool.scheduleJob(CgetYearlyTotals(map: _jobMap())));
  }

  Future<double> getAverageProfitPercent() async {
    return (await getYearlyTotals()).profitPercent;
  }

  Future<double> getYearlyInflation() async {
    return (await getYearlyTotals()).yearlyInflation;
  }

  Future<double> getAllProfit() {
    return getYearlyTotals().then((t) => t.yearlyProfit);
  }

  Future<double> getAllSales() {
    return getYearlyTotals().then((t) => t.yearlySales);
  }

  Future<double> getProfitOfTheMonth() {
    return getCachedCalculation('profitOfTheMonth',
        () => pool.scheduleJob(CgetProfitOfTheMonth(map: _jobMap())));
  }

  Future<double> getSalesOfTheMonth() {
    return getCachedCalculation('salesOfTheMonth',
        () => pool.scheduleJob(CgetSalesOfTheMonth(map: _jobMap())));
  }

  Future<double> getDailySales(DateTime time) {
    return getCachedCalculation('dailySales',
        () => pool.scheduleJob(CgetDailySales(map: _jobMap(arg: time))));
  }

  Future<double> getDailyProfits(DateTime time) {
    return getCachedCalculation('dailyProfits',
        () => pool.scheduleJob(CgetDailyProfit(map: _jobMap(arg: time))));
  }

  Future<int> getNumberOfSalesForAproduct({required String key}) {
    return getCachedCalculation(
        'numberOfSalesPerProduct',
        () => pool.scheduleJob(
            CgetNumberOfSalesForAproduct(map: _jobMap(arg: key))));
  }

  Future<List<Product>> getSaledProductsByDate(DateTime time) {
    return getCachedCalculation('saledProductsByDate',
        () => pool.scheduleJob(CgetSaledProductsByDate(map: _jobMap(arg: time))));
  }

  Future<List<ProdStats>> getSalesPerProduct(int chunkSize) async {
    return getCachedCalculation('salesPerProduct', () {
      return pool
          .scheduleJob(CgetSalesPerProduct(chunkSize: chunkSize, map: _jobMap(arg: chunkSize)));
    });
  }

  Future<List<LoanerComparison>> getLoanerComparison() async {
    return getCachedCalculation('loanerComparison',
        () => pool.scheduleJob(CgetLoanerComparison(map: _jobMap())));
  }

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailySalesOfTheMonth',
        () => pool.scheduleJob(CgetDailySalesOfTheMonth(map: _jobMap(arg: month))));
  }

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailyProfitOfTheMonth',
        () => pool.scheduleJob(CgetDailyProfitOfTheMont(map: _jobMap(arg: month))));
  }

  Future<List<SalesStats>> getMonthlySalesOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlySalesOfTheYear',
        () => pool.scheduleJob(CgetMonthlySalesOfTheyear(map: _jobMap(arg: month))));
  }

  Future<List<SalesStats>> getMonthlyProfitsOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlyProfitsOfTheYear',
        () => pool.scheduleJob(CgetMonthlyProfitsOfTheyear(map: _jobMap(arg: month))));
  }

  Future<double> getTotalProfit() {
    return getCachedCalculation(
        'totalProfit',
        () => pool.scheduleJob(
            CgetTotalProfit(map: _jobMap(arg: DateTime.now()))));
  }

  Stream<List<Product>> getTotalBuyPrice() {
    return db.getTotalBuyPrice();
  }
}
