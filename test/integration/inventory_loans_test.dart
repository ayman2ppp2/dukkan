@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_utils.dart';
import '../helpers/test_db.dart';
import '../helpers/user_flow.dart';

Future<void> signIn(WidgetTester tester, TestDbHandle handle,
    SharedPreferences prefs) async {
  final auth = authWithFakeLogin();
  await tester.pumpWidget(
      appForJourney(db: handle.db, prefs: prefs, auth: auth));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await signInViaUi(tester, auth);
}

void main() {
  late TestDbHandle handle;
  late SharedPreferences prefs;

  setUp(() async {
    handle = await openTestDb();
    SharedPreferences.setMockInitialValues({'weightPrececsion': 1});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await handle.close();
  });

  testWidgets('owner and product added via inventory persist with all fields',
      (tester) async {
    usePhoneScreen(tester);
    await signIn(tester, handle, prefs);

    await addOwnerViaUi(tester, 'Golden1');
    await pumpUntilDb(
        tester, () async => (await getOwner(handle.db, 'Golden1')) != null);

    await addProductViaUi(
      tester,
      name: 'Coffee1',
      barcode: '777000',
      buyPrice: '8',
      sellPrice: '15',
      count: '20',
      owner: 'Golden1',
    );
    await pumpUntilDb(tester, () async {
      final p = await getProduct(handle.db, 'Coffee1');
      return p != null && p.count == 20;
    });

    final product = await dbRead(tester, () => getProduct(handle.db, 'Coffee1'));
    expect(product, isNotNull);
    expect(product!.barcode, '777000');
    expect(product.buyprice, 8);
    expect(product.sellPrice, 15);
    expect(product.count, 20);
    expect(product.ownerName, 'Golden1');
  });

  testWidgets('loaner added via the loans page persists with zero balance',
      (tester) async {
    usePhoneScreen(tester);
    await signIn(tester, handle, prefs);

    await openLoans(tester);
    await addLoanerViaUi(
      tester,
      name: 'Customer1',
      phone: '0911111111',
      location: 'Downtown',
    );
    await pumpUntilDb(
        tester, () async => (await getLoaner(handle.db, 'Customer1')) != null);

    final loaner = await dbRead(tester, () => getLoaner(handle.db, 'Customer1'));
    expect(loaner!.balance, 0);
    expect(loaner.phoneNumber, '0911111111');
    expect(loaner.location, 'Downtown');
  });
}
