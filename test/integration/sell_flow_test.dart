@Tags(['integration'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';
import '../helpers/test_app.dart';
import '../helpers/test_db.dart';

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

  testWidgets('SellPage renders bottom action buttons', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.pause_circle_outline), findsOneWidget);
    expect(find.byIcon(Icons.price_check_outlined), findsOneWidget);
  });

  testWidgets('cart shows product name when pre-populated', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
      cartProducts: [productFixture(name: 'Sugar', count: 10)],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Sugar'), findsOneWidget);
  });

  testWidgets('empty parked carts state in parking dialog', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.pause_circle_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('لا توجد فواتير معلقة'), findsOneWidget);
  });

  testWidgets('park current cart', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
      cartProducts: [productFixture(name: 'Sugar', count: 10)],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.pause_circle_outline));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('ركن الفاتورة'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('تم ركن الفاتورة'), findsOneWidget);
  });
}
