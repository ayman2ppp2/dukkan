@Tags(['integration'])
library;

import 'dart:io';

import 'package:dukkan/providers/log_provider.dart';
import 'package:dukkan/providers/sales_provider.dart';
import 'package:dukkan/models/Expense.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:dukkan/models/Product.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect(loaner!.balance, 20);
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
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('loan payment reduces balance and appends history', () async {
      final loanerId = await handle.db.insertLoaner(loanerFixture(amount: 100));
      final provider =
          SalesProvider.forTesting(db: handle.db, pref: prefs);

      await provider.payLoaner(25, loanerId);

      final loaner = await handle.db.isar!.loaners.get(loanerId);
      expect(loaner!.balance, 75);
      expect(loaner.lastPayment!.last.value, '25.0');
      expect(loaner.lastPayment!.last.remaining, 75);
    });

    test('reset loan account zeroes balance and records reset marker',
        () async {
      final loanerId = await handle.db.insertLoaner(loanerFixture(amount: 100));
      final provider =
          SalesProvider.forTesting(db: handle.db, pref: prefs);

      await provider.resetLoanerAcount(loanerId);

      final loaner = await handle.db.isar!.loaners.get(loanerId);
      expect(loaner!.balance, 0);
      expect(loaner.lastPayment!.last.value, '0');
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
      final provider =
          SalesProvider.forTesting(db: handle.db, pref: prefs);
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

  group('Real receipt edit tests', () {
    test('hot products restored for editing carry non-null offer fields',
        () async {
      final lists = LogProvider.forTesting(handle.db);
      final ep = EmbeddedProduct()
        ..productId = 1
        ..name = 'Hot'
        ..buyPrice = 100
        ..sellPrice = 200
        ..count = 1
        ..hot = true;

      final products = lists.embeddedToProduct([ep]);

      final hot = products.single;
      expect(hot!.hot, isTrue);
      expect(hot.offer, isNotNull);
      expect(hot.offerCount, isNotNull);
      expect(hot.offerPrice, isNotNull);
      expect(hot.sellPrice, 200);
    });

    test('edit receipt subtracts hot sell value (not buy value) from balance',
        () async {
      final product = await insertProduct(name: 'Sugar', count: 10);
      final loanerId =
          await handle.db.insertLoaner(loanerFixture(amount: 500));
      final normal = EmbeddedProduct()
        ..productId = product.id
        ..name = product.name
        ..buyPrice = product.buyprice
        ..sellPrice = product.sellPrice
        ..count = 2
        ..hot = false;
      final hot = EmbeddedProduct()
        ..productId = 0
        ..name = 'Hot'
        ..buyPrice = 100
        ..sellPrice = 200
        ..count = 1
        ..hot = true;
      final log = Log.named2(
        price: 80,
        profit: 0,
        date: DateTime.now(),
        products: [normal, hot],
        discount: 0,
        loaned: true,
        loanerID: loanerId,
        expense: false,
        expenseId: null,
      );
      await handle.db.isar!.writeTxn(() async {
        await handle.db.isar!.logs.put(log);
      });

      final lists = LogProvider.forTesting(handle.db);
      await lists.editReceipt(log.date, log);

      final loaner = await handle.db.isar!.loaners.get(loanerId);
      expect(loaner!.balance, 220);
    });
  });

  group('Inventory product update refresh', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('updateProduct persists before notifying inventory listeners',
        () async {
      final product = await insertProduct(name: 'Sugar', count: 10);
      final sa = SalesProvider.forTesting(db: handle.db, pref: prefs);

      var notified = false;
      sa.onInventoryChanged = () => notified = true;

      final updated = Product.named2(
        id: product.id,
        name: 'Sugar',
        ownerName: product.ownerName!,
        barcode: product.barcode ?? '',
        buyprice: 7,
        sellPrice: 12,
        count: 5,
        weightable: product.weightable ?? false,
        wholeUnit: product.wholeUnit ?? '',
        offer: product.offer ?? false,
        offerCount: product.offerCount ?? 0,
        offerPrice: product.offerPrice ?? 0,
        priceHistory: product.priceHistory,
        endDate: product.endDate ?? DateTime.now(),
        hot: false,
      );

      await sa.updateProduct(updated);

      expect(notified, isTrue);
      final persisted =
          (await handle.db.isar!.products.get(product.id))!;
      expect(persisted.buyprice, 7);
      expect(persisted.sellPrice, 12);
      expect(persisted.count, 5);
    });

    test('insertProducts notifies inventory listeners after persisting',
        () async {
      final sa = SalesProvider.forTesting(db: handle.db, pref: prefs);

      var notified = false;
      sa.onInventoryChanged = () => notified = true;

      final product =
          productFixture(name: 'Rice', count: 3, buyPrice: 5, sellPrice: 8);
      await sa.insertProducts(products: [product]);

      expect(notified, isTrue);
      final persisted = await handle.db.isar!.products
          .where()
          .nameEqualTo('Rice')
          .findFirst();
      expect(persisted, isNotNull);
    });
  });
}
