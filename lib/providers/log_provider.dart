import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';

class LogProvider extends ChangeNotifier {
  late DB db;

  LogProvider() {
    init();
  }

  Future<void> init() async {
    db = await DB.getInstance();
  }

  Stream<List<Log>> getPersonsLogs(int? ID) {
    return db.getPersonsLogs(ID);
  }

  Future<void> cancelReceipt(DateTime date, Log log) async {
    double sum = 0;
    for (var product in log.products) {
      if (product.hot!) {
        sum += product.buyPrice! * product.count!;
      }
    }
    if (log.loaned) {
      db.updateLoaner(log, sum);
    }

    List<EmbeddedProduct> products = List.empty(growable: true);
    for (var product in log.products) {
      if (!(product.hot!)) {
        products.add(product);
      }
    }
    await db.updateProducts(products);
    await db.deleteLog(log);
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
    await db.checkOut(
        products: lst,
        total: total,
        discount: discount,
        loanerId: LoID,
        loaned: loaned,
        expense: expense,
        expenseId: expenseId);
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}