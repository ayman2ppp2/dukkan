import 'dart:ui';

import 'package:dukkan/core/IsolatePool.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:flutter/material.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';

class ExpenseProvider extends ChangeNotifier {
  late DB db;
  late IsolatePool pool;
  ExpenseProvider() {
    db = DB();
    init();
  }
  init() async {
    pool = await Pool.init();
    // pool = Pool.pool;
  }

  void refresh() {
    notifyListeners();
  }

  Map Amap = {
    30: 1,
    7: 4,
    1: 30,
  };

  Stream<Expense?> watchExpense({required int id}) {
    return db.watchExpense(id: id);
  }

  Future<int> addExpense(
      {required String name,
      required double amount,
      required int period,
      int? payDate,
      required bool fixed}) {
    return db
        .addExpense(
            amount: amount,
            name: name,
            period: period,
            payDate: payDate,
            fixed: fixed)
        .then((value) {
      refresh();
      return value;
    });
  }

  Future<double> getProfitOfTheMonth() {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    return pool.scheduleJob(CgetProfitOfTheMonth(map: map));
  }

  Stream<List<Expense>> getIndvidualExpenses({required bool fixed}) {
    return db.getExpenses(fixed: fixed);
  }

  Future<double> getLoansOfMonth() {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    return pool.scheduleJob(CgetMonthlyloans(map: map));
  }

  Future<double> getDailyLoans() {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    return pool.scheduleJob(CgetDailyloans(map: map));
  }

  Future<double> getRealProfit() async {
    return await getProfitOfTheMonth() -
        await getLoansOfMonth() -
        await getTotalExpenses();
  }

  Future<double> getTotalExpenses() async {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    return pool.scheduleJob(getTotalExpenseNow(map: map));
    // return (await getIndvidualExpenses()).fold<double>(
    //     0.0,
    //     (previousValue, element) =>
    //         element.amount! * Amap[element.period] + previousValue);
  }

  Future<bool> deleteExpense({required int id}) {
    return db.deleteExpense(id: id);
  }
}
