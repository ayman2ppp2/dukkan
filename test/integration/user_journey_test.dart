@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_utils.dart';
import '../helpers/test_db.dart';
import '../helpers/user_flow.dart';

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

  testWidgets('full journey: sign in → add → sell → loan → cancel → edit',
      (tester) async {
    usePhoneScreen(tester);
    final auth = authWithFakeLogin();
    await tester.pumpWidget(
        appForJourney(db: handle.db, prefs: prefs, auth: auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Sign in through the login page.
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    await signInViaUi(tester, auth);
    expect(find.byIcon(Icons.monetization_on_outlined), findsOneWidget);

    // 2. Add an owner and a product.
    await addOwnerViaUi(tester, 'Golden');
    await pumpUntilDb(
        tester, () async => (await getOwner(handle.db, 'Golden')) != null);

    await addProductViaUi(
      tester,
      name: 'Sugar',
      barcode: '123456',
      buyPrice: '6',
      sellPrice: '10',
      count: '10',
      owner: 'Golden',
    );
    await pumpUntilDb(tester, () async {
      final p = await getProduct(handle.db, 'Sugar');
      return p != null && p.count == 10;
    });

    var product = await dbRead(tester, () => getProduct(handle.db, 'Sugar'));
    expect(product, isNotNull);
    expect(product!.sellPrice, 10);

    await backToHome(tester);

    // 3. Sell one unit for cash.
    await addToCartViaUi(tester, 'Sugar');
    await checkoutCashViaUi(tester);
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      return logs.length == 1;
    });

    product = await dbRead(tester, () => getProduct(handle.db, 'Sugar'));
    expect(product!.count, 9);
    var logs = await dbRead(tester, () => getLogs(handle.db));
    expect(logs!.single.price, 10);
    expect(logs.single.profit, 4);
    expect(logs.single.loaned, isFalse);
    final owner = await dbRead(tester, () => getOwner(handle.db, 'Golden'));
    expect(owner!.dueMoney, 6);

    // 4. Add a loaner (debtor).
    await openLoans(tester);
    await addLoanerViaUi(tester, name: 'Customer', phone: '0910000000');
    await pumpUntilDb(
        tester, () async => (await getLoaner(handle.db, 'Customer')) != null);

    var loaner = await dbRead(tester, () => getLoaner(handle.db, 'Customer'));
    expect(loaner!.balance, 0);
    await backToHome(tester);

    // 5. Sell one unit on credit to the loaner.
    await addToCartViaUi(tester, 'Sugar');
    await checkoutDebtViaUi(tester, 'Customer');
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      return logs.where((l) => l.loaned).length == 1;
    });

    product = await dbRead(tester, () => getProduct(handle.db, 'Sugar'));
    expect(product!.count, 8);
    logs = await dbRead(tester, () => getLogs(handle.db));
    expect(logs, hasLength(2));
    final creditLog = logs!.singleWhere((l) => l.loaned);
    expect(creditLog.price, 10);
    loaner = await dbRead(tester, () => getLoaner(handle.db, 'Customer'));
    expect(loaner!.balance, 10);

    // 6. Cancel the credit receipt.
    await openLogs(tester);
    await cancelLoanedReceiptViaUi(tester, 'Customer');
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      return logs.length == 1 && logs.every((l) => !l.loaned);
    });

    product = await dbRead(tester, () => getProduct(handle.db, 'Sugar'));
    expect(product!.count, 9);
    loaner = await dbRead(tester, () => getLoaner(handle.db, 'Customer'));
    expect(loaner!.balance, 0);

    // 7. Edit the cash receipt → products return to the sell cart.
    await editReceiptViaUi(tester);
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      final p = await getProduct(handle.db, 'Sugar');
      return logs.isEmpty && p != null && p.count == 10;
    });

    await pumpUntilFound(tester, find.text('Sugar'));

    // 8. Re-sell the restored cart.
    await checkoutCashViaUi(tester);
    await pumpUntilDb(tester, () async {
      final logs = await getLogs(handle.db);
      final p = await getProduct(handle.db, 'Sugar');
      return logs.length == 1 && p != null && p.count == 9;
    });

    product = await dbRead(tester, () => getProduct(handle.db, 'Sugar'));
    expect(product!.count, 9);
    logs = await dbRead(tester, () => getLogs(handle.db));
    expect(logs, hasLength(1));
  });
}
