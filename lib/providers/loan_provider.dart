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
    loaner!.balance = 0;
    loaner.zeroingDate = DateTime.now();
    var temp = loaner.lastPayment!.toList(growable: true);
    temp.add(EmbeddedMap()
      ..value = 'تصفير حساب'
      ..key = DateTime.now().toIso8601String()
      ..remaining = 0
      ..type = 'reset');
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
        ..remaining = temp.balance! - cash
        ..type = 'payment',
    );
    return db.insertLoaner(Loaner(
      name: temp.name,
      phoneNumber: temp.phoneNumber,
      location: temp.location,
      lastPayment: list,
      balance: temp.balance! - cash,
    )
      ..ID = ID
      ..zeroingDate =
          (temp.balance! - cash) == 0 ? DateTime.now() : temp.zeroingDate);
  }

  Future<int> withdrawFromBalance(double cash, int ID) async {
    var temp = await db.isar!.loaners.get(ID);
    if (temp == null) throw Exception('Loaner not found');
    if ((temp.balance ?? 0) >= 0) {
      throw Exception('Cannot withdraw: balance is not negative');
    }
    var list = List<EmbeddedMap>.from(temp.lastPayment!, growable: true);
    list.add(
      EmbeddedMap()
        ..key = DateTime.now().toIso8601String()
        ..value = cash.toString()
        ..remaining = temp.balance! + cash
        ..type = 'withdraw',
    );
    return db.insertLoaner(Loaner(
      name: temp.name,
      phoneNumber: temp.phoneNumber,
      location: temp.location,
      lastPayment: list,
      balance: temp.balance! + cash,
    )
      ..ID = ID
      ..zeroingDate =
          (temp.balance! + cash) == 0 ? DateTime.now() : temp.zeroingDate);
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}
