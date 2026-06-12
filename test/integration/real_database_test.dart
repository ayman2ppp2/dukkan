import 'dart:io';

import 'package:dukkan/providers/loan_provider.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

void main() {
  late TestDbHandle handle;

  Future<Product> insertProduct({
    String name = 'Sugar',
    int count = 10,
    double buyPrice = 6,
    double sellPrice = 10,
    bool offer = false,
    double offerCount = 0,
    double offerPrice = 0,
  }) async {
    final product = productFixture(
      name: name,
      count: count,
      buyPrice: buyPrice,
      sellPrice: sellPrice,
      offer: offer,
      offerCount: offerCount,
      offerPrice: offerPrice,
    );
    await handle.db.insertProducts(products: [product]);
    final inserted =
        await handle.db.isar!.products.where().nameEqualTo(name).findFirst();
    return inserted ?? (throw StateError('Product was not inserted'));
  }

  setUp(() async {
    handle = await openTestDb();
  });

  tearDown(() async {
    await handle.close();
  });

  group('Real checkout DB tests', () {
    test('normal sale writes log, reduces stock, and updates owner due money',
        () async {
      await handle.db.insertOwner(ownerFixture());
      final product = await insertProduct();

      final ok = await handle.db.checkOut(
        products: [productFixture(id: product.id, count: 2)],
        total: 20,
      );

      final storedProduct = await handle.db.isar!.products.get(product.id);
      final logs = await handle.db.isar!.logs.where().findAll();
      final owner = await handle.db.isar!.owners.where().findFirst();

      expect(ok, isTrue);
      expect(storedProduct!.count, 8);
      expect(logs, hasLength(1));
      expect(logs.single.price, 20);
      expect(logs.single.profit, 8);
      expect(owner!.dueMoney, 12);
    });

    test('discount reduces sale price and profit', () async {
      final product = await insertProduct();

      await handle.db.checkOut(
        products: [productFixture(id: product.id, count: 2)],
        total: 20,
        discount: 5,
      );

      final log = await handle.db.isar!.logs.where().findFirst();
      expect(log!.price, 15);
      expect(log.profit, 3);
    });

    test('offer pricing keeps current bundle and remainder behavior', () async {
      final product = await insertProduct(
        offer: true,
        offerCount: 3,
        offerPrice: 8,
      );

      await handle.db.checkOut(
        products: [
          productFixture(
            id: product.id,
            count: 4,
            offer: true,
            offerCount: 3,
            offerPrice: 8,
          ),
        ],
        total: 40,
      );

      final log = await handle.db.isar!.logs.where().findFirst();
      expect(log!.price, 34);
      expect(log.profit, 10);
    });

    test('loan sale updates loaner and marks log as loaned', () async {
      final product = await insertProduct();
      final loanerId = await handle.db.insertLoaner(loanerFixture());

      await handle.db.checkOut(
        products: [productFixture(id: product.id, count: 2)],
        total: 20,
        loaned: true,
        loanerId: loanerId,
      );

      final loaner = await handle.db.isar!.loaners.get(loanerId);
      final log = await handle.db.isar!.logs.where().findFirst();
      expect(loaner!.loanedAmount, 20);
      expect(log!.loaned, isTrue);
      expect(log.loanerID, loanerId);
    });

    test('expense sale updates selected expense total', () async {
      final product = await insertProduct();
      final expenseId = await handle.db.addExpense(
        name: 'Delivery',
        amount: 5,
        period: 0,
        fixed: false,
      );

      await handle.db.checkOut(
        products: [productFixture(id: product.id, count: 2)],
        total: 20,
        expense: true,
        expenseId: expenseId,
      );

      final expense = await handle.db.isar!.expenses.get(expenseId);
      expect(expense!.amount, 25);
    });

    test('insufficient stock throws and leaves database unchanged', () async {
      final product = await insertProduct(count: 1);

      expect(
        () => handle.db.checkOut(
          products: [productFixture(id: product.id, count: 2)],
          total: 20,
        ),
        throwsException,
      );

      final storedProduct = await handle.db.isar!.products.get(product.id);
      final logs = await handle.db.isar!.logs.where().findAll();
      expect(storedProduct!.count, 1);
      expect(logs, isEmpty);
    });

    test('discount cannot exceed total', () async {
      final product = await insertProduct();

      expect(
        () => handle.db.checkOut(
          products: [productFixture(id: product.id, count: 1)],
          total: 10,
          discount: 11,
        ),
        throwsException,
      );
    });
  });

  group('Real low stock tests', () {
    test('returns products below threshold using recent sales', () async {
      final low = await insertProduct(name: 'Low', count: 2);
      final healthy = await insertProduct(name: 'Healthy', count: 10);

      await handle.db.isar!.writeTxn(() async {
        await handle.db.isar!.logs.putAll([
          logFixture(product: low, count: 10),
          logFixture(product: healthy, count: 10),
        ]);
      });

      final results = await handle.db.getLowStockProductsWithPercent();
      final names = results.map((r) => (r['product'] as Product).name).toList();

      expect(names, contains('Low'));
      expect(names, isNot(contains('Healthy')));
      expect(
          results.singleWhere(
            (r) => (r['product'] as Product).name == 'Low',
          )['percentRemaining'],
          closeTo(2 / 12, 0.001));
    });
  });

  group('Real loan tests', () {
    test('loan payment reduces balance and appends history', () async {
      final loanerId = await handle.db.insertLoaner(loanerFixture(amount: 100));
      final provider = LoanProvider.forTesting(handle.db);

      await provider.payLoaner(25, loanerId);

      final loaner = await handle.db.isar!.loaners.get(loanerId);
      expect(loaner!.loanedAmount, 75);
      expect(loaner.lastPayment!.last.value, '25.0');
      expect(loaner.lastPayment!.last.remaining, 75);
    });

    test('reset loan account zeroes balance and records reset marker',
        () async {
      final loanerId = await handle.db.insertLoaner(loanerFixture(amount: 100));
      final provider = LoanProvider.forTesting(handle.db);

      await provider.resetLoanerAcount(loanerId);

      final loaner = await handle.db.isar!.loaners.get(loanerId);
      expect(loaner!.loanedAmount, 0);
      expect(loaner.lastPayment!.last.value, 'تصفير حساب');
    });

    test('account statement includes loan receipts and payments', () async {
      final product = await insertProduct();
      final loanerId = await handle.db.insertLoaner(loanerFixture(amount: 30));
      await handle.db.isar!.writeTxn(() async {
        await handle.db.isar!.logs.put(logFixture(
          product: product,
          count: 5,
          loanerId: loanerId,
        ));
      });
      final provider = LoanProvider.forTesting(handle.db);
      await provider.payLoaner(20, loanerId);

      final statement = await handle.db.getAccountStatementData(loanerId);
      expect(statement['totalLoaned'], 50);
      expect(statement['totalPaidAmount'], 20);
      expect(statement['currentBalance'], 30);
      expect(statement['transactionHistory'], isNotEmpty);
    });
  });

  group('Real backup/restore tests', () {
    test('createLocalBackup and useLocalBacup restore previous DB contents',
        () async {
      final product = await insertProduct(count: 7);
      await handle.db.createLocalBackup();

      await handle.db.isar!.writeTxn(() async {
        product.count = 1;
        await handle.db.isar!.products.put(product);
      });

      await handle.db.useLocalBacup();
      final restored = await handle.db.isar!.products.get(product.id);
      expect(restored!.count, 7);
    });

    test('invalid backup is rejected and current database remains available',
        () async {
      final product = await insertProduct(count: 7);
      final backupFile = File('${handle.directory.path}/backup.isar');
      await backupFile.writeAsString('not an isar database');

      await expectLater(handle.db.useLocalBacup(), throwsException);
      final stillLive = await handle.db.isar!.products.get(product.id);
      expect(stillLive!.count, 7);
    });

    test('windows restore path uses verified .received backup', () async {
      final product = await insertProduct(count: 7);
      await handle.db.createLocalBackup();
      await File('${handle.directory.path}/backup.isar')
          .copy('${handle.directory.path}/backup.isar.received');

      await handle.db.isar!.writeTxn(() async {
        product.count = 1;
        await handle.db.isar!.products.put(product);
      });

      await handle.db.windows();
      final restored = await handle.db.isar!.products.get(product.id);
      expect(restored!.count, 7);
    });
  });
}
