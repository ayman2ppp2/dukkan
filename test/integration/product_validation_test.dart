import 'package:flutter_test/flutter_test.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_db.dart';

void main() {
  group('Product validation', () {
    test('valid product passes validation', () {
      expect(productFixture().validateForCreate(), isNull);
    });

    test('requires name', () {
      expect(productFixture(name: '').validateForCreate(), contains('name'));
    });

    test('requires owner', () {
      expect(
          productFixture(ownerName: '').validateForCreate(), contains('Owner'));
    });

    test('rejects negative buy price', () {
      expect(productFixture(buyPrice: -1).validateForCreate(), contains('Buy'));
    });

    test('rejects negative sell price', () {
      expect(
          productFixture(sellPrice: -1).validateForCreate(), contains('Sell'));
    });

    test('rejects negative count', () {
      expect(productFixture(count: -1).validateForCreate(), contains('Count'));
    });

    test('offer requires positive offer count', () {
      expect(
        productFixture(offer: true, offerCount: 0, offerPrice: 1)
            .validateForCreate(),
        contains('Offer count'),
      );
    });

    test('offer price must be lower than regular bundle price', () {
      expect(
        productFixture(offer: true, offerCount: 2, offerPrice: 20)
            .validateForCreate(),
        contains('Offer price'),
      );
    });
  });

  group('Checkout validation', () {
    test('rejects negative discount before writing', () async {
      final handle = await openTestDb();
      addTearDown(handle.close);
      final product = productFixture();
      await handle.db.insertProducts(products: [product]);

      expect(
        () => handle.db.checkOut(
          products: [productFixture(id: product.id, count: 1)],
          total: 10,
          discount: -1,
        ),
        throwsException,
      );
    });
  });
}
