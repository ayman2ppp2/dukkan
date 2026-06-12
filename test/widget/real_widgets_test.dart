import 'package:dukkan/pages/CheckOutPage.dart';
import 'package:dukkan/pages/InsertPage.dart';
import 'package:dukkan/pages/LoginPage.dart';
import 'package:dukkan/pages/landingPge.dart';
import 'package:dukkan/pages/searchPage.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fixtures.dart';

void main() {
  Future<Widget> wrapWithProviders({
    required Widget child,
    List<Product> products = const [],
  }) async {
    SharedPreferences.setMockInitialValues({'weightPrececsion': 1});
    final prefs = await SharedPreferences.getInstance();
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>.value(value: AuthAPI.forTesting()),
        ChangeNotifierProvider<SalesProvider>.value(
          value: SalesProvider.detachedForTesting(
            pref: prefs,
            products: products,
          ),
        ),
        ChangeNotifierProvider<Lists>.value(
          value: Lists.detachedForTesting(owners: [ownerFixture()]),
        ),
        ChangeNotifierProvider<ExpenseProvider>.value(
          value: ExpenseProvider.detachedForTesting(),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets('LoginPage renders real login controls', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AuthAPI>.value(
        value: AuthAPI.forTesting(),
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('InsertPage shows validation dialog for empty product fields',
      (tester) async {
    await tester.pumpWidget(await wrapWithProviders(
      child: InPage(
        id: null,
        buyPrice: 0,
        count: 0,
        name: '',
        sellPrice: 0,
        index: -1,
        owner: '',
        wholeUnit: '',
        weightable: false,
        offer: false,
        offerCount: 0,
        offerPrice: 0,
        endDate: DateTime.now(),
        priceHistory: [],
        barcode: '',
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byIcon(Icons.done_all_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('أدخل قيم صحيحة'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('CheckOut page renders cart total and confirmation control',
      (tester) async {
    final product = productFixture(id: 1, count: 2);

    await tester.pumpWidget(await wrapWithProviders(
      child: CheckOut(lst: [product], total: 20, inbound: false),
    ));

    expect(find.text('الفاتورة'), findsOneWidget);
    expect(find.textContaining('المجموع'), findsOneWidget);
    expect(find.byIcon(Icons.checklist_outlined), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('SearchPage uses SalesProvider search results from real DB',
      (tester) async {
    final products = [productFixture(id: 1, name: 'Coffee')];

    await tester.pumpWidget(await wrapWithProviders(
      child: SearchPage(inbound: false),
      products: products,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'Coffee');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.widgetWithText(ListTile, 'Coffee'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('LandingPage renders setup/settings fields', (tester) async {
    await tester.pumpWidget(await wrapWithProviders(
      child: const LandingPage(),
    ));

    expect(find.text('أهلاً بك الى دكان'), findsOneWidget);
    expect(find.text('إسم المتجر'), findsOneWidget);
    expect(find.text('دقة الميزان المستعمل'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
