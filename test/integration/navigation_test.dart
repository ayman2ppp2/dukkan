@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/pump_utils.dart';
import '../helpers/test_db.dart';
import '../helpers/user_flow.dart';

/// Opens the home drawer and waits for it to settle.
Future<void> openDrawer(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await pumpUntilFound(tester, find.text('الديون'));
  await settle(tester);
}

/// Taps a drawer item, asserts its page title, then returns home.
Future<void> expectDrawerDestination(
  WidgetTester tester,
  String item,
  String title,
) async {
  await openDrawer(tester);
  await tester.tap(find.text(item));
  await pumpUntilFound(tester, find.text(title));
  await settle(tester);
  await tester.pageBack();
  await pumpUntilIdle(tester);
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

  testWidgets('home appbar buttons navigate to logs and inventory and back',
      (tester) async {
    usePhoneScreen(tester);
    final auth = authWithFakeLogin();
    await tester.pumpWidget(
        appForJourney(db: handle.db, prefs: prefs, auth: auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await signInViaUi(tester, auth);

    await tester.tap(find.byIcon(Icons.receipt_long_sharp));
    await pumpUntilFound(tester, find.text('الفواتير'));
    await settle(tester);
    await tester.pageBack();
    await pumpUntilIdle(tester);

    await tester.tap(find.byIcon(Icons.inventory_2_outlined));
    await pumpUntilFound(tester, find.text('المخزن'));
    await settle(tester);
    await tester.pageBack();
    await pumpUntilIdle(tester);

    expect(find.byIcon(Icons.monetization_on_outlined), findsOneWidget);
  });

  testWidgets('drawer navigates to every destination and closes on tap',
      (tester) async {
    usePhoneScreen(tester);
    final auth = authWithFakeLogin();
    await tester.pumpWidget(
        appForJourney(db: handle.db, prefs: prefs, auth: auth));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await signInViaUi(tester, auth);

    await expectDrawerDestination(tester, 'الديون', 'الديون');
    await expectDrawerDestination(tester, 'المنصرفات', 'المنصرفات');
    await expectDrawerDestination(tester, 'فاتورة داخل', 'فاتورة واردة');
    await expectDrawerDestination(
        tester, 'عناصر منخفضة المخزون', 'عناصر منخفضة المخزون');
    await expectDrawerDestination(tester, 'الإعدادات', 'الإعدادت');
  });
}
