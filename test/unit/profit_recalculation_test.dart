import 'package:flutter_test/flutter_test.dart';
import 'package:dukkan/data/stats/jobs.dart' show recalculateProfit;
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/Emap.dart';

Product _makeProduct({
  int id = 1,
  String name = 'Test',
  double buyPrice = 10,
  double sellPrice = 20,
  List<Emap>? priceHistory,
}) {
  return Product.named2(
    id: id,
    name: name,
    ownerName: 'Owner',
    barcode: '123',
    buyprice: buyPrice,
    sellPrice: sellPrice,
    count: 100,
    weightable: false,
    wholeUnit: '',
    offer: false,
    offerCount: 0,
    offerPrice: 0,
    priceHistory: priceHistory ?? [],
    endDate: DateTime.now().add(const Duration(days: 30)),
    hot: false,
  );
}

EmbeddedProduct _makeEmbedded({
  int? productId = 1,
  String name = 'Test',
  double buyPrice = 10,
  double sellPrice = 20,
  int count = 1,
  bool hot = false,
}) {
  final ep = EmbeddedProduct();
  ep.productId = productId;
  ep.name = name;
  ep.buyPrice = buyPrice;
  ep.sellPrice = sellPrice;
  ep.count = count;
  ep.hot = hot;
  return ep;
}

Log _makeLog({
  List<EmbeddedProduct>? products,
  double discount = 0,
  DateTime? date,
}) {
  return Log.named2(
    price: 0,
    profit: 0,
    date: date ?? DateTime.now(),
    products: products ?? [],
    discount: discount,
    loaned: false,
    loanerID: null,
    expense: false,
    expenseId: null,
  );
}

void main() {
  group('recalculateProfit', () {
    test('empty logs returns 0', () {
      expect(recalculateProfit([], {}), 0);
    });

    test('product with empty priceHistory uses current buyprice', () {
      final product = _makeProduct(buyPrice: 10, sellPrice: 20);
      final ep = _makeEmbedded(buyPrice: 10, sellPrice: 20, count: 1);
      final log = _makeLog(products: [ep]);
      final map = {product.id: product};

      expect(recalculateProfit([log], map), (20 - 10) * 1);
    });

    test('priceHistory entry after log date is used as next', () {
      final now = DateTime.now();
      final logDate = now.subtract(const Duration(days: 10));
      final restockDate = now.subtract(const Duration(days: 5));
      final product = _makeProduct(
        buyPrice: 30,
        sellPrice: 50,
        priceHistory: [
          Emap()..buyPrice = 20..date = restockDate,
        ],
      );
      final ep = _makeEmbedded(
        productId: product.id,
        buyPrice: 20,
        sellPrice: 50,
        count: 2,
      );
      final log = _makeLog(products: [ep], date: logDate);
      final map = {product.id: product};

      expect(recalculateProfit([log], map), (50 - 20) * 2);
    });

    test('log between two priceHistory entries uses next entry', () {
      final now = DateTime.now();
      final logDate = now.subtract(const Duration(days: 7));
      final restock1 = now.subtract(const Duration(days: 15));
      final restock2 = now.subtract(const Duration(days: 3));
      final product = _makeProduct(
        buyPrice: 40,
        sellPrice: 50,
        priceHistory: [
          Emap()..buyPrice = 20..date = restock1,
          Emap()..buyPrice = 30..date = restock2,
        ],
      );
      final ep = _makeEmbedded(
        productId: product.id,
        buyPrice: 20,
        sellPrice: 50,
        count: 3,
      );
      final log = _makeLog(products: [ep], date: logDate);
      final map = {product.id: product};
      expect(recalculateProfit([log], map), (50 - 30) * 3);
    });

    test('log after last priceHistory entry uses current buyprice', () {
      final now = DateTime.now();
      final lastRestock = now.subtract(const Duration(days: 10));
      final product = _makeProduct(
        buyPrice: 50,
        sellPrice: 80,
        priceHistory: [
          Emap()..buyPrice = 20..date = now.subtract(const Duration(days: 30)),
          Emap()..buyPrice = 30..date = lastRestock,
        ],
      );
      final ep = _makeEmbedded(
        productId: product.id,
        buyPrice: 30,
        sellPrice: 80,
        count: 1,
      );
      final log = _makeLog(products: [ep], date: now);
      final map = {product.id: product};

      expect(recalculateProfit([log], map), (80 - 50) * 1);
    });

    test('hot product is skipped', () {
      final product = _makeProduct(buyPrice: 10, sellPrice: 20);
      final ep = _makeEmbedded(
        buyPrice: 10, sellPrice: 20, count: 5, hot: true,
      );
      final log = _makeLog(products: [ep]);
      final map = {product.id: product};

      expect(recalculateProfit([log], map), 0);
    });

    test('discount is subtracted from subtotal', () {
      final product = _makeProduct(buyPrice: 10, sellPrice: 20);
      final ep = _makeEmbedded(buyPrice: 10, sellPrice: 20, count: 1);
      final log = _makeLog(products: [ep], discount: 3);
      final map = {product.id: product};

      expect(recalculateProfit([log], map), (20 - 10) * 1 - 3);
    });

    test('multiple logs are summed correctly', () {
      final product = _makeProduct(buyPrice: 10, sellPrice: 20);
      final ep1 = _makeEmbedded(buyPrice: 10, sellPrice: 20, count: 2);
      final ep2 = _makeEmbedded(buyPrice: 10, sellPrice: 20, count: 3);
      final log1 = _makeLog(products: [ep1], discount: 1);
      final log2 = _makeLog(products: [ep2], discount: 2);
      final map = {product.id: product};

      expect(
        recalculateProfit([log1, log2], map),
        (20 - 10) * 2 - 1 + (20 - 10) * 3 - 2,
      );
    });

    test('product not in map falls back to ep.buyPrice snapshot', () {
      final ep = _makeEmbedded(
        productId: 999, buyPrice: 15, sellPrice: 30, count: 4,
      );
      final log = _makeLog(products: [ep]);
      final map = <int, Product>{};

      expect(recalculateProfit([log], map), (30 - 15) * 4);
    });

    test('productId <= 0 uses ep.buyPrice snapshot', () {
      final ep = _makeEmbedded(
        productId: 0, buyPrice: 12, sellPrice: 25, count: 2,
      );
      final log = _makeLog(products: [ep]);
      final map = <int, Product>{};

      expect(recalculateProfit([log], map), (25 - 12) * 2);
    });

    test('null productId uses ep.buyPrice snapshot', () {
      final ep = _makeEmbedded(
        productId: null, buyPrice: 8, sellPrice: 15, count: 10,
      );
      final log = _makeLog(products: [ep]);
      final map = <int, Product>{};

      expect(recalculateProfit([log], map), (15 - 8) * 10);
    });
  });
}
