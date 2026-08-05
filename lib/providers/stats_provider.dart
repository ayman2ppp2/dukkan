import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/data/stats/stats_service.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/prodStats.dart';
import 'package:flutter/material.dart';

/// Legacy provider kept for registration compatibility.
///
/// Dead in the UI: nothing reads this provider (see `main.dart` for the
/// remaining registration). All computation and caching is owned by
/// [StatsService]; this class only delegates there and is a candidate for
/// removal once the `Lists` migration is complete.
class StatsProvider extends ChangeNotifier {
  late DB db;
  late StatsService stats;

  StatsProvider() {
    init();
  }

  @visibleForTesting
  StatsProvider.forTesting(this.db) {
    stats = StatsService.forTesting(db);
  }

  Future<void> init() async {
    db = await DB.getInstance();
    stats = StatsService(db);
  }

  Future<T> getCachedCalculation<T>(
          String cacheKey, Future<T> Function() calculate) =>
      stats.getCachedCalculation(cacheKey, calculate);

  void clearAllCache() => stats.clearAllCache();

  void clearCache(String cacheKey) => stats.clearCache(cacheKey);

  Future<double> getAverageProfitPercent() => stats.getAverageProfitPercent();

  Future<double> getProfitOfTheMonth() => stats.getProfitOfTheMonth();

  Future<double> getSalesOfTheMonth() => stats.getSalesOfTheMonth();

  Future<double> getDailySales(DateTime time) => stats.getDailySales(time);

  Future<double> getDailyProfits(DateTime time) => stats.getDailyProfits(time);

  Future<double> getAllProfit() => stats.getAllProfit();

  Future<double> getAllSales() => stats.getAllSales();

  Future<int> getNumberOfSalesForAproduct({required String key}) =>
      stats.getNumberOfSalesForAproduct(key: key);

  Future<List<Product>> getSaledProductsByDate(DateTime time) =>
      stats.getSaledProductsByDate(time);

  Future<List<ProdStats>> getSalesPerProduct(int chunkSize) =>
      stats.getSalesPerProduct(chunkSize);

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) =>
      stats.getDailySalesOfTheMonth(month);

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) =>
      stats.getDailyProfitOfTheMonth(month);

  Future<List<SalesStats>> getMonthlySalesOfTheYear(DateTime month) =>
      stats.getMonthlySalesOfTheYear(month);

  Future<List<SalesStats>> getMonthlyProfitsOfTheYear(DateTime month) =>
      stats.getMonthlyProfitsOfTheYear(month);

  Stream<List<Product>> getTotalBuyPrice() => stats.getTotalBuyPrice();
}
