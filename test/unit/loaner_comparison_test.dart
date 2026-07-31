import 'package:flutter_test/flutter_test.dart';
import 'package:dukkan/core/db.dart'
    show computeLoanerComparison, loanComparisonWindowStart;
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';

Loaner _makeLoaner({
  required int id,
  required String name,
}) {
  return Loaner.named(
    name: name,
    ID: id,
    phoneNumber: '0',
    location: '',
    lastPaymentTemp: 0,
    lastPaymentDate: null,
    balance: 0,
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
}) {
  final ep = EmbeddedProduct();
  ep.productId = productId;
  ep.name = 'Test';
  ep.buyPrice = buyPrice;
  ep.sellPrice = sellPrice;
  ep.count = count;
  ep.hot = false;
  return ep;
}

Log _makeLoanedLog({
  required int loanerId,
  required List<EmbeddedProduct> products,
  required DateTime date,
}) {
  return Log.named2(
    price: 0,
    profit: 0,
    date: date,
    products: products,
    discount: 0,
    loaned: true,
    loanerID: loanerId,
    expense: false,
    expenseId: null,
  );
}

void main() {
  group('loanComparisonWindowStart', () {
    test('is exactly 45 days before the given date', () {
      final now = DateTime(2026, 5, 31);
      expect(loanComparisonWindowStart(now), DateTime(2026, 4, 16));
    });

    test('does not roll over on month boundaries', () {
      final now = DateTime(2026, 5, 31);
      final start = loanComparisonWindowStart(now);
      final log40DaysBack = now.subtract(const Duration(days: 40));
      final log50DaysBack = now.subtract(const Duration(days: 50));
      expect(start.isAfter(log50DaysBack), isTrue);
      expect(start.isBefore(log40DaysBack), isTrue);
    });
  });

  group('computeLoanerComparison', () {
    test('empty inputs return empty list', () {
      expect(computeLoanerComparison(loaners: [], loanedLogs: [], productMap: {}),
          isEmpty);
    });

    test('aggregates loaned amount at sell price and current value at buy price',
        () {
      final product = _makeProduct(id: 1, buyPrice: 10);
      final loaner = _makeLoaner(id: 5, name: 'Ahmed');
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

    test('missing product in map falls back to receipt buy price snapshot', () {
      final loaner = _makeLoaner(id: 5, name: 'Ahmed');
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

    test('loaner with no loaned logs is skipped', () {
      final loaner = _makeLoaner(id: 5, name: 'Ahmed');
      final result = computeLoanerComparison(
        loaners: [loaner],
        loanedLogs: [],
        productMap: {},
      );
      expect(result, isEmpty);
    });

    test('results are sorted by loaned amount descending', () {
      final loanerA = _makeLoaner(id: 1, name: 'A');
      final loanerB = _makeLoaner(id: 2, name: 'B');
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
