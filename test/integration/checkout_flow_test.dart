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

  testWidgets('checkout dialog opens with products', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
      cartProducts: [productFixture(name: 'Sugar', count: 10, sellPrice: 10)],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.price_check_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('نقدي'), findsOneWidget);
    expect(find.text('دين'), findsOneWidget);
    expect(find.text('منصرف'), findsOneWidget);
    expect(find.text('خصم'), findsOneWidget);
  });

  testWidgets('discount dialog opens and saves', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
      cartProducts: [productFixture(name: 'Sugar', count: 10, sellPrice: 10)],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.price_check_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.text('خصم'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('أدخل قيمة الخصم'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), '2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.byIcon(Icons.check_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('خصم'), findsOneWidget);
  });

  testWidgets('cash checkout shows confirmation dialog', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
      cartProducts: [productFixture(name: 'Sugar', count: 10, sellPrice: 10)],
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.price_check_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(find.byIcon(Icons.checklist_outlined));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('هل أنت متأكد؟'), findsOneWidget);
  });
}
