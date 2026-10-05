import 'dart:convert';

import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:dukkan/models/PendingCart.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/providers/sales_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

void main() {
  group('Product JSON (FLUTTER-8 regression)', () {
    test('jsonEncode survives a product with a live endDate', () {
      final product = productFixture();

      expect(() => jsonEncode(product.toJson()), returnsNormally);
      // Same shape the removed lifecycle save encoded: a list of products.
      expect(() => jsonEncode([product.toJson()]), returnsNormally);
    });

    test('jsonEncode survives a product with empty/null fields', () {
      final product = Product()
        ..id = 7
        ..name = 'Bare';

      expect(() => jsonEncode(product.toJson()), returnsNormally);
    });

    test('writes endDate as an ISO-8601 string, not a raw DateTime', () {
      final json = jsonDecode(jsonEncode(productFixture().toJson()))
          as Map<String, dynamic>;

      expect(json['endDate'], isA<String>());
      expect(DateTime.tryParse(json['endDate'] as String), isNotNull);
    });

    test('round-trips endDate and priceHistory through ISO strings', () {
      final product = productFixture(priceDate: DateTime(2026, 1, 2, 3, 4, 5));

      final decoded = Product.fromJson(
          map:
              jsonDecode(jsonEncode(product.toJson())) as Map<String, dynamic>);

      expect(decoded.id, product.id);
      expect(decoded.name, product.name);
      expect(decoded.ownerName, product.ownerName);
      expect(decoded.buyprice, product.buyprice);
      expect(decoded.count, product.count);
      expect(decoded.endDate, product.endDate);
      expect(decoded.priceHistory, hasLength(1));
      expect(decoded.priceHistory.first.date, product.priceHistory.first.date);
      expect(decoded.priceHistory.first.buyPrice,
          product.priceHistory.first.buyPrice);
    });

    test('tolerates an already-decoded DateTime in the input map', () {
      final when = DateTime(2025, 5, 5);

      final decoded = Product.fromJson(map: {'endDate': when});

      expect(decoded.endDate, when);
    });

    test('tolerates a missing endDate instead of casting', () {
      final decoded = Product.fromJson(map: <String, Object?>{});

      expect(decoded.endDate, isNull);
      expect(decoded.priceHistory, isEmpty);
    });
  });

  group('EmbeddedProduct JSON', () {
    test('round-trips endDate as a string', () {
      final embedded = productFixture().toEmbedded();

      final decoded = EmbeddedProduct.fromJson(
          map: jsonDecode(jsonEncode(embedded.toJson())));

      expect(decoded.productId, embedded.productId);
      expect(decoded.name, embedded.name);
      expect(decoded.endDate, embedded.endDate);
    });

    test('tolerates a raw DateTime in the input map (FLUTTER-9 shape)', () {
      final when = DateTime(2024, 12, 31);

      final decoded = EmbeddedProduct.fromJson(map: {'endDate': when});

      expect(decoded.endDate, when);
    });
  });

  group('Owner JSON', () {
    test('round-trips lastPaymentDate as an ISO string', () {
      final owner = ownerFixture();

      final decoded = Owner.fromJson(
          map: jsonDecode(jsonEncode(owner.toJson())) as Map<String, Object?>);

      expect(decoded.ownerName, owner.ownerName);
      expect(decoded.lastPaymentDate, owner.lastPaymentDate);
      expect(decoded.dueMoney, owner.dueMoney);
    });
  });

  group('Loaner maps', () {
    test('toMap serializes dates as ISO strings', () {
      final loaner = loanerFixture(paymentDate: DateTime(2026, 9, 1))
        ..lastPaymentDate = DateTime(2026, 9, 1);

      final map = loaner.toMap();

      expect(map['lastPaymentDate'], isA<String>());
      expect(map['zeroingDate'], isA<String>());
      expect(() => jsonEncode(map), returnsNormally);
    });

    test('fromMap accepts ISO strings without throwing', () {
      final loaner = Loaner.fromMap(map: {
        'ID': 5,
        'name': 'عميل',
        'phoneNumber': '0900000000',
        'location': 'السوق',
        'lastPaymentDate': '2026-09-01T00:00:00.000',
        'lastPayment': 100.0,
        'balance': 250.0,
      });

      expect(loaner.ID, 5);
      expect(loaner.balance, 250.0);
      expect(loaner.lastPayment, hasLength(1));
      expect(loaner.lastPayment!.single.key, '2026-09-01T00:00:00.000');
    });
  });

  group('PendingCart persistence', () {
    test('park/restore round-trip keeps product identity', () {
      final product = productFixture(id: 42);
      final cart = PendingCart(
        name: 'فاتورة 13:03',
        products: [product],
        parkedAt: DateTime(2026, 10, 4, 13, 3),
      );

      final restored = PendingCart.fromJson(
          jsonDecode(jsonEncode(cart.toJson())) as Map<String, dynamic>);

      expect(restored.name, cart.name);
      expect(restored.parkedAt, cart.parkedAt);
      expect(restored.products, hasLength(1));

      final p = restored.products.single;
      expect(p.id, 42);
      expect(p.name, product.name);
      expect(p.endDate, product.endDate);
      expect(p.priceHistory, hasLength(1));
      expect(p.priceHistory.first.date, product.priceHistory.first.date);
    });
  });

  group('SalesProvider lifecycle (FLUTTER-8)', () {
    test('is no longer a lifecycle observer, so backgrounding cannot encode',
        () async {
      SharedPreferences.setMockInitialValues({'weightPrececsion': 1});
      final prefs = await SharedPreferences.getInstance();
      final provider = SalesProvider.detachedForTesting(
        pref: prefs,
        products: [productFixture()],
      );

      expect(provider, isNot(isA<WidgetsBindingObserver>()));
      // The orphaned write this test guards had no reader since acfbdfe.
      expect(prefs.getString('productList'), isNull);
    });
  });
}
