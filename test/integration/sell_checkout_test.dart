@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_utils.dart';
import '../helpers/test_db.dart';
import '../helpers/user_flow.dart';

/// Signs in, seeds one owner and one product, and returns to the sell page.
Future<void> seedOwnerAndProduct(
  WidgetTester tester,
  TestDbHandle handle,
  SharedPreferences prefs, {
  required String owner,
  required String product,
  String barcode = '111111',
  String buyPrice = '6',
  String sellPrice = '10',
  String count = '10',
}) async {
  final auth = authWithFakeLogin();
  await tester.pumpWidget(
      appForJourney(db: handle.db, prefs: prefs, auth: auth));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
  await signInViaUi(tester, auth);
  await addOwnerViaUi(tester, owner);
  await pumpUntilDb(
      tester, () async => (await getOwner(handle.db, owner)) != null);
  await addProductViaUi(
    tester,
    name: product,
    barcode: barcode,
    buyPrice: buyPrice,
    sellPrice: sellPrice,
    count: count,
    owner: owner,
  );
  await pumpUntilDb(tester, () async {
    final p = await getProduct(handle.db, product);
    return p != null && p.count == int.parse(count);
  });
  await backToHome(tester);
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

  testWidgets('cash sale decrements stock, credits owner and logs profit',
      (tester) async {
    usePhoneScreen(tester);
    await seedOwnerAndProduct(tester, handle, prefs,
        owner: 'O1', product: 'Sugar1');

    await addToCartViaUi(tester, 'Sugar1');
    await checkoutCashViaUi(tester);
    await pumpUntilDb(
        tester, () async => (await getLogs(handle.db)).length == 1);

    final product = await dbRead(tester, () => getProduct(handle.db, 'Sugar1'));
    expect(product!.count, 9);

    final logs = await dbRead(tester, () => getLogs(handle.db));
    expect(logs!.single.price, 10);
    expect(logs.single.profit, 4);
    expect(logs.single.loaned, isFalse);

    final owner = await dbRead(tester, () => getOwner(handle.db, 'O1'));
    expect(owner!.dueMoney, 6);
  });

  testWidgets('debt sale adds to loaner balance and marks the log as loaned',
      (tester) async {
    usePhoneScreen(tester);
    await seedOwnerAndProduct(tester, handle, prefs,
        owner: 'O2', product: 'Sugar2');

    await addToCartViaUi(tester, 'Sugar2');

    await openLoans(tester);
    await addLoanerViaUi(tester, name: 'Customer2');
    await pumpUntilDb(
        tester, () async => (await getLoaner(handle.db, 'Customer2')) != null);
    await backToHome(tester);

    await checkoutDebtViaUi(tester, 'Customer2');
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      return logs.where((l) => l.loaned).length == 1;
    });

    final product = await dbRead(tester, () => getProduct(handle.db, 'Sugar2'));
    expect(product!.count, 9);

    final logs = await dbRead(tester, () => getLogs(handle.db));
    expect(logs!.single.loaned, isTrue);
    expect(logs.single.price, 10);

    final loaner = await dbRead(tester, () => getLoaner(handle.db, 'Customer2'));
    expect(loaner!.balance, 10);
  });

  testWidgets('cancelling a cash receipt restores stock and dueMoney',
      (tester) async {
    usePhoneScreen(tester);
    await seedOwnerAndProduct(tester, handle, prefs,
        owner: 'O3', product: 'Sugar3');

    await addToCartViaUi(tester, 'Sugar3');
    await checkoutCashViaUi(tester);
    await pumpUntilDb(
        tester, () async => (await getLogs(handle.db)).length == 1);

    await openLogs(tester);
    await cancelReceiptViaUi(tester);
    await pumpUntilDb(
        tester, () async => (await getLogs(handle.db)).isEmpty);

    final product = await dbRead(tester, () => getProduct(handle.db, 'Sugar3'));
    expect(product!.count, 10);
  });

  testWidgets('editing a receipt moves products back into the sell cart',
      (tester) async {
    usePhoneScreen(tester);
    await seedOwnerAndProduct(tester, handle, prefs,
        owner: 'O4', product: 'Sugar4');

    await addToCartViaUi(tester, 'Sugar4');
    await checkoutCashViaUi(tester);
    await pumpUntilDb(
        tester, () async => (await getLogs(handle.db)).length == 1);

    await openLogs(tester);
    await editReceiptViaUi(tester);
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      final p = await getProduct(handle.db, 'Sugar4');
      return logs.isEmpty && p != null && p.count == 10;
    });

    await pumpUntilFound(tester, find.text('Sugar4'));

    await checkoutCashViaUi(tester);
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      final p = await getProduct(handle.db, 'Sugar4');
      return logs.length == 1 && p != null && p.count == 9;
    });
  });
}
