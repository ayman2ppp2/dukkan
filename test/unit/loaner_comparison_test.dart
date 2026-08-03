import 'package:flutter_test/flutter_test.dart';
import 'package:dukkan/core/db.dart'
    show computeLoanerComparison, debtWindowStart;
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';

Loaner _makeLoaner({
  required int id,
  required String name,
  double balance = 100,
}) {
  return Loaner.named(
    name: name,
    ID: id,
    phoneNumber: '0',
    location: '',
    lastPaymentTemp: 0,
    lastPaymentDate: null,
    balance: balance,
  );
}

Product _makeProduct({
  required int id,
  required double buyPrice,
}) {
  return Product.named2(
    id: id,
    name: 'Test',
    ownerName: 'Owner',
    barcode: '123',
    buyprice: buyPrice,
    sellPrice: 100,
    count: 10,
    weightable: false,
    wholeUnit: '',
    offer: false,
    offerCount: 0,
    offerPrice: 0,
    priceHistory: [],
    endDate: DateTime.now().add(const Duration(days: 30)),
    hot: false,
  );
}

EmbeddedProduct _makeEmbedded({
  required int? productId,
  required double buyPrice,
  required double sellPrice,
  required int count,
  bool hot = false,
}) {
  final ep = EmbeddedProduct();
  ep.productId = productId;
  ep.name = 'Test';
  ep.buyPrice = buyPrice;
  ep.sellPrice = sellPrice;
  ep.count = count;
  ep.hot = hot;
  return ep;
}

Log _makeLoanedLog({
  required int loanerId,
  required List<EmbeddedProduct> products,
  required DateTime date,
  double discount = 0,
}) {
  final price = products.fold<double>(
        0,
        (sum, ep) => sum + ((ep.sellPrice ?? 0) * (ep.count ?? 0)),
      ) -
      discount;
  return Log.named2(
    price: price,
    profit: 0,
    date: date,
    products: products,
    discount: discount,
    loaned: true,
    loanerID: loanerId,
    expense: false,
    expenseId: null,
  );
}

void main() {
  group('debtWindowStart', () {
    test('returns null for empty logs', () {
      expect(debtWindowStart(balance: 100, logsNewestFirst: []), isNull);
    });

    test('returns null when balance is not positive', () {
      final log = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 30, count: 2),
        ],
      );
      expect(debtWindowStart(balance: 0, logsNewestFirst: [log]), isNull);
    });

    test('returns null when logs do not cover the balance', () {
      final newer = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 30, count: 2),
        ],
      );
      final older = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 4, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 1),
        ],
      );
      expect(
        debtWindowStart(balance: 250, logsNewestFirst: [newer, older]),
        isNull,
      );
    });

    test('returns the newest log date when it alone covers the balance', () {
      final newest = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 2),
        ],
      );
      final older = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 4, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 30, count: 2),
        ],
      );
      expect(
        debtWindowStart(balance: 50, logsNewestFirst: [newest, older]),
        newest.date,
      );
    });

    test('returns the oldest log date when coverage spans multiple logs', () {
      final newer = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 2),
        ],
      );
      final older = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 4, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 30, count: 3),
        ],
      );
      expect(
        debtWindowStart(balance: 150, logsNewestFirst: [newer, older]),
        older.date,
      );
    });

    test('returns the boundary log when the balance is covered exactly', () {
      final newest = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 2),
        ],
      );
      final older = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 4, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 30, count: 2),
        ],
      );
      expect(
        debtWindowStart(balance: 80, logsNewestFirst: [newest, older]),
        newest.date,
      );
    });

    test('skips logs with zero price', () {
      final zero = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 20),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 0, count: 2),
        ],
      );
      final newest = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 2),
        ],
      );
      expect(
        debtWindowStart(balance: 50, logsNewestFirst: [zero, newest]),
        newest.date,
      );
    });

    test('discount is included in the log price used for coverage', () {
      final newest = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 2),
        ],
        discount: 30,
      );
      expect(
        debtWindowStart(balance: 50, logsNewestFirst: [newest]),
        newest.date,
      );
    });
  });

  group('computeLoanerComparison', () {
    test('empty inputs return empty list', () {
      expect(computeLoanerComparison(loaners: [], loanedLogs: [], productMap: {}),
          isEmpty);
    });

    test('uses the log price for loaned amount and buy price for current value',
        () {
      final product = _makeProduct(id: 1, buyPrice: 10);
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 150);
      final log = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(
              productId: 1, buyPrice: 10, sellPrice: 30, count: 2),
          _makeEmbedded(
              productId: 1, buyPrice: 10, sellPrice: 30, count: 3),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [log],
        productMap: {1: product},
      );

      expect(result, hasLength(1));
      expect(result.first.name, 'Ahmed');
      expect(result.first.loanedAmount, (30 * 2) + (30 * 3));
      expect(result.first.currentValue, (10 * 2) + (10 * 3));
    });

    test('loaner balance is deducted from the log price', () {
      final product = _makeProduct(id: 1, buyPrice: 10);
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 50);
      final log = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        discount: 10,
        products: [
          _makeEmbedded(
              productId: 1, buyPrice: 10, sellPrice: 30, count: 2),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [log],
        productMap: {1: product},
      );

      expect(result.first.loanedAmount, 50);
      expect(result.first.currentValue, 20);
    });

    test('missing product in map falls back to receipt buy price snapshot', () {
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 160);
      final log = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 999, buyPrice: 15, sellPrice: 40, count: 4),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [log],
        productMap: {},
      );

      expect(result.first.loanedAmount, 40 * 4);
      expect(result.first.currentValue, 15 * 4);
    });

    test('scales the boundary log to the outstanding balance', () {
      final product = _makeProduct(id: 1, buyPrice: 10);
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 100);
      final log = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 5),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [log],
        productMap: {1: product},
      );

      expect(result.first.loanedAmount, 100);
      expect(result.first.currentValue, 25);
    });

    test('counts newer logs fully and scales the boundary log', () {
      final product = _makeProduct(id: 1, buyPrice: 10);
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 100);
      final newer = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 1),
        ],
      );
      final older = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 4, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 50, count: 6),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [newer, older],
        productMap: {1: product},
      );

      expect(result.first.loanedAmount, 100);
      expect(result.first.currentValue, 22);
    });

    test('boundary reached exactly uses the full log', () {
      final product = _makeProduct(id: 1, buyPrice: 10);
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 200);
      final log = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 40, count: 5),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [log],
        productMap: {1: product},
      );

      expect(result.first.loanedAmount, 200);
      expect(result.first.currentValue, 50);
    });

    test('skips hot products from the current value only', () {
      final product = _makeProduct(id: 1, buyPrice: 10);
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 260);
      final log = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 1, buyPrice: 10, sellPrice: 30, count: 2),
          _makeEmbedded(
            productId: 2,
            buyPrice: 100,
            sellPrice: 200,
            count: 1,
            hot: true,
          ),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [log],
        productMap: {1: product, 2: _makeProduct(id: 2, buyPrice: 100)},
      );

      expect(result.first.loanedAmount, (30 * 2) + (200 * 1));
      expect(result.first.currentValue, 20);
    });

    test('loaner with no loaned logs is skipped', () {
      final loaner = _makeLoaner(id: 5, name: 'Ahmed');
      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [],
        productMap: {},
      );
      expect(result, isEmpty);
    });

    test('loaner with non-positive balance is skipped', () {
      final loaner = _makeLoaner(id: 5, name: 'Ahmed', balance: 0);
      final log = _makeLoanedLog(
        loanerId: 5,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 999, buyPrice: 10, sellPrice: 20, count: 5),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [log],
        productMap: {},
      );

      expect(result, isEmpty);
    });

    test('results are sorted by loaned amount descending', () {
      final loanerA = _makeLoaner(id: 1, name: 'A', balance: 100);
      final loanerB = _makeLoaner(id: 2, name: 'B', balance: 20);
      final logA = _makeLoanedLog(
        loanerId: 1,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 999, buyPrice: 10, sellPrice: 20, count: 5),
        ],
      );
      final logB = _makeLoanedLog(
        loanerId: 2,
        date: DateTime(2026, 5, 10),
        products: [
          _makeEmbedded(productId: 999, buyPrice: 10, sellPrice: 20, count: 1),
        ],
      );

      final result = computeLoanerComparison(
        loaners: [loanerA, loanerB],
        loanedLogs: [logA, logB],
        productMap: {},
      );

      expect(result.map((e) => e.name).toList(), ['A', 'B']);
    });
  });
}
