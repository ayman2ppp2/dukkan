import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:isar_community/isar.dart';

import '../test/helpers/fixtures.dart';
import '../test/helpers/test_db.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app smoke: records a real local sale flow', (tester) async {
    final handle = await openTestDb();
    addTearDown(handle.close);

    await handle.db.insertOwner(ownerFixture());
    await handle.db.insertProducts(products: [productFixture(count: 5)]);
    final products = await handle.db.isar!.products.where().anyId().findAll();
    final product = products.isNotEmpty
        ? products.first
        : (throw StateError('Product fixture was not inserted'));

    await tester.pumpWidget(MaterialApp(
      home: _SmokeSaleHarness(product: product, handle: handle),
    ));

    expect(find.text('Smoke sale ready'), findsOneWidget);
    await tester.tap(find.text('Record sale'));
    await tester.pumpAndSettle();

    expect(find.text('Sale recorded'), findsOneWidget);
    final stored = await handle.db.isar!.products.get(product.id);
    final logs = await handle.db.isar!.logs.where().anyId().findAll();
    expect(stored!.count, 3);
    expect(logs, hasLength(1));
  });
}

class _SmokeSaleHarness extends StatefulWidget {
  const _SmokeSaleHarness({required this.product, required this.handle});

  final Product product;
  final TestDbHandle handle;

  @override
  State<_SmokeSaleHarness> createState() => _SmokeSaleHarnessState();
}

class _SmokeSaleHarnessState extends State<_SmokeSaleHarness> {
  String status = 'Smoke sale ready';

  Future<void> _recordSale() async {
    await widget.handle.db.checkOut(
      products: [productFixture(id: widget.product.id, count: 2)],
      total: 20,
    );
    setState(() {
      status = 'Sale recorded';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(status),
            ElevatedButton(
              onPressed: _recordSale,
              child: const Text('Record sale'),
            ),
          ],
        ),
      ),
    );
  }
}
