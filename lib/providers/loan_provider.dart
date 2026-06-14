import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:flutter/material.dart';

class LoanProvider extends ChangeNotifier {
  late DB db;

  LoanProvider() {
    init();
  }

  @visibleForTesting
  LoanProvider.forTesting(this.db);

  Future<void> init() async {
    db = await DB.getInstance();
  }

  List<Loaner> loanersList = [];

  Future<List<Loaner>> refreshLoanersList() async {
    return db.getLoaners();
  }

  Future<int> resetLoanerAcount(int ID) async {
    var loaner = await db.isar!.loaners.get(ID);
    loaner!.loanedAmount = 0;
    loaner.zeroingDate = DateTime.now();
    var temp = loaner.lastPayment!.toList(growable: true);
    temp.add(EmbeddedMap()
      ..value = 'تصفير حساب'
      ..key = DateTime.now().toIso8601String()
      ..remaining = 0);
    loaner.lastPayment = temp;

    return await db.insertLoaner(loaner);
  }

  Future<int> payLoaner(double cash, int ID) async {
    var temp = await db.isar!.loaners.get(ID);
    var list = List<EmbeddedMap>.from(temp!.lastPayment!, growable: true);
    list.add(
      EmbeddedMap()
        ..key = DateTime.now().toIso8601String()
        ..value = cash.toString()
        ..remaining = temp.loanedAmount! - cash,
    );
    return db.insertLoaner(Loaner(
      name: temp.name,
      phoneNumber: temp.phoneNumber,
      location: temp.location,
      lastPayment: list,
      loanedAmount: temp.loanedAmount! - cash,
    )
      ..ID = ID
      ..zeroingDate =
          (temp.loanedAmount! - cash) == 0 ? DateTime.now() : temp.zeroingDate);
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}
