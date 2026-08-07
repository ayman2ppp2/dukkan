import 'package:appwrite/models.dart' show Session;
import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/models/Expense.dart';
import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/providers/auth_provider.dart';
import 'package:dukkan/widgets/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'pump_utils.dart';
import 'test_app.dart';

/// A minimal but valid Appwrite [Session] returned by the fake login hook.
Session fakeSession({String email = 'owner@dukkan.test'}) {
  final now = DateTime.now().toIso8601String();
  return Session(
    $id: 'test-session',
    $createdAt: now,
    $updatedAt: now,
    userId: 'test-user',
    expire: DateTime.now().add(const Duration(days: 7)).toIso8601String(),
    provider: 'email',
    providerUid: email,
    providerAccessToken: '',
    providerAccessTokenExpiry: '',
    providerRefreshToken: '',
    ip: '127.0.0.1',
    osCode: 'test',
    osName: 'Test',
    osVersion: '1',
    clientType: 'test',
    clientCode: 'test',
    clientName: 'Test',
    clientVersion: '1',
    clientEngine: 'test',
    clientEngineVersion: '1',
    deviceName: 'Test',
    deviceBrand: 'Test',
    deviceModel: 'Test',
    countryCode: 'US',
    countryName: 'United States',
    current: true,
    factors: const [],
    secret: '',
    mfaUpdatedAt: now,
  );
}

/// Builds an [AuthAPI] whose login completes offline through [loginOverrideForTesting].
AuthAPI authWithFakeLogin({String email = 'owner@dukkan.test'}) {
  final auth = AuthAPI.forTesting();
  auth.loginOverrideForTesting =
      ({required String email, required String password}) async =>
          fakeSession(email: email);
  return auth;
}

/// Pumps until `finder` matches, then waits for transient spinner frames.
Future<void> settle(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump(const Duration(milliseconds: 150));
  await pumpRealAsync(tester);
}

// ---------------------------------------------------------------------------
// DB assertions
// ---------------------------------------------------------------------------

Future<Product?> getProduct(DB db, String name) async {
  return db.isar!.products.where().nameEqualTo(name).findFirst();
}

Future<List<Log>> getLogs(DB db) async {
  return db.isar!.logs.where().findAll();
}

Future<Loaner?> getLoaner(DB db, String name) async {
  return db.isar!.loaners.where().filter().nameEqualTo(name).findFirst();
}

Future<Owner?> getOwner(DB db, String name) async {
  return db.isar!.owners.where().filter().ownerNameEqualTo(name).findFirst();
}

/// Runs a DB read on the real event loop (Isar futures created in the widget
/// test's fake-async zone never complete on their own).
Future<T?> dbRead<T>(WidgetTester tester, Future<T> Function() read) {
  return tester.runAsync(read);
}

Future<ExpenseRecord> getExpense(DB db, String name) async {
  return ExpenseRecord(db, name);
}

class ExpenseRecord {
  ExpenseRecord(this.db, this.name);

  final DB db;
  final String name;

  Future<double?> amount() async {
    final e = await db.isar!.expenses
        .where()
        .filter()
        .nameEqualTo(name)
        .findFirst();
    return e?.amount;
  }
}

// ---------------------------------------------------------------------------
// Sign in
// ---------------------------------------------------------------------------

Future<void> signInViaUi(
  WidgetTester tester,
  AuthAPI auth, {
  String email = 'owner@dukkan.test',
  String password = 'secret123',
}) async {
  auth.setStatusForTesting(AuthStatus.unauthenticated);

  await tester.enterText(find.byType(TextField).at(0), email);
  await tester.enterText(find.byType(TextField).at(1), password);
  await tester.tap(find.text('تسجيل الدخول'));
  await settle(tester);

  await pumpUntilFound(tester, find.byIcon(Icons.monetization_on_outlined));
  await settle(tester);
}

/// Returns a [TestApp] wired for a full unauthenticated → signed-in journey.
TestApp appForJourney({
  required DB db,
  required SharedPreferences prefs,
  AuthAPI? auth,
  bool authenticated = false,
}) {
  return TestApp(
    db: db,
    prefs: prefs,
    auth: auth ?? authWithFakeLogin(),
    authenticated: authenticated,
  );
}

// ---------------------------------------------------------------------------
// Inventory: add owner + add product
// ---------------------------------------------------------------------------

Future<void> openInventory(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.inventory_2_outlined));
  await pumpUntilFound(tester, find.text('المخزن'));
  await settle(tester);
}

Future<void> addOwnerViaUi(WidgetTester tester, String ownerName) async {
  await openInventory(tester);
  await tester.tap(find.byIcon(Icons.person_add).first);
  await pumpUntilFound(tester, find.text('إضافة مالك'));
  await settle(tester);
  await tester.enterText(find.byType(TextFormField).last, ownerName);
  await tester.tap(find.byIcon(Icons.person_add).last);
  await settle(tester);
  await pumpUntilFound(tester, find.byType(FloatingActionButton));
}

Future<void> addProductViaUi(
  WidgetTester tester, {
  required String name,
  required String barcode,
  required String buyPrice,
  required String sellPrice,
  required String count,
  required String owner,
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await pumpUntilFound(tester, find.text('إضافة منتج جديد'));
  await settle(tester);

  await tester.enterText(find.widgetWithText(TextFormField, 'الاسم'), name);
  await tester.enterText(find.widgetWithText(TextFormField, 'الباركود'), barcode);
  await tester.enterText(find.widgetWithText(TextFormField, 'سعر الشراء'), buyPrice);
  await tester.enterText(find.widgetWithText(TextFormField, 'سعر البيع'), sellPrice);
  await tester.enterText(find.widgetWithText(TextFormField, 'الكمية بالجرام/العدد'), count);

  await pumpUntilFound(tester, find.byType(DropdownMenu<String>));
  await tester.tap(find.byType(DropdownMenu<String>).first);
  await pumpUntilFound(tester, find.text(owner));
  await tester.tap(find.text(owner).last);
  await settle(tester);

  await tester.tap(find.byIcon(Icons.done_all_rounded));
  await settle(tester);

  // Force the grid to refresh through the search field.
  await tester.enterText(find.widgetWithText(TextField, 'بحث'), 'x');
  await settle(tester);
  await tester.enterText(find.widgetWithText(TextField, 'بحث'), '');
  await pumpUntilFound(tester, find.text(name));
}

Future<void> backToHome(WidgetTester tester) async {
  await tester.pageBack();
  await settle(tester);
}

// ---------------------------------------------------------------------------
// Sell / checkout
// ---------------------------------------------------------------------------

Future<void> addToCartViaUi(WidgetTester tester, String productName) async {
  await tester.tap(find.byIcon(Icons.add).first);
  await pumpUntilFound(tester, find.widgetWithText(ListTile, productName),
      timeout: const Duration(seconds: 5));
  await tester.tap(find.widgetWithText(ListTile, productName));
  await settle(tester);
  await pumpUntilFound(tester, find.text(productName));
}

Future<void> openCheckout(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.price_check_outlined));
  await pumpUntilFound(tester, find.text('نقدي'));
  await settle(tester);
}

Future<void> confirmCheckout(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.checklist_outlined));
  await pumpUntilFound(tester, find.text('هل أنت متأكد؟'));
  await tester.tap(find.text('نعم'));
  await pumpUntilFound(tester, find.text('نجاح'));
  await tester.tap(find.text('موافق'));
  await pumpUntilFound(tester, find.byIcon(Icons.price_check_outlined));
  await settle(tester);
}

Future<void> checkoutCashViaUi(WidgetTester tester) async {
  await openCheckout(tester);
  await confirmCheckout(tester);
}

Future<void> checkoutDebtViaUi(WidgetTester tester, String loanerName) async {
  await openCheckout(tester);
  await tester.tap(find.text('دين'));
  await pumpUntilFound(tester, find.byType(DropdownMenu<int>));
  await tester.tap(find.byType(DropdownMenu<int>).first);
  await pumpUntilFound(tester, find.text(loanerName));
  await tester.tap(find.text(loanerName).last);
  await settle(tester);
  await confirmCheckout(tester);
}

// ---------------------------------------------------------------------------
// Loans
// ---------------------------------------------------------------------------

Future<void> openLoans(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.menu));
  await pumpUntilFound(tester, find.text('الديون'));
  await settle(tester);
  await tester.tap(find.text('الديون'));
  await pumpUntilFound(tester, find.byType(FloatingActionButton));
  await settle(tester);
}

Future<void> addLoanerViaUi(
  WidgetTester tester, {
  required String name,
  String phone = '0910000000',
  String location = 'Market',
}) async {
  await tester.tap(find.byType(FloatingActionButton));
  await pumpUntilFound(tester, find.text('إضافة دائن'));
  await tester.enterText(find.widgetWithText(TextFormField, 'الاسم'), name);
  await tester.enterText(find.widgetWithText(TextFormField, 'رقم الهاتف'), phone);
  await tester.enterText(find.widgetWithText(TextFormField, 'المكان'), location);
  await tester.tap(find.text('حفظ'));
  await pumpUntilFound(tester, find.text(name));
  await settle(tester);
}

// ---------------------------------------------------------------------------
// Receipts (logs): cancel + edit
// ---------------------------------------------------------------------------

Future<void> openLogs(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.receipt_long_sharp));
  await pumpUntilFound(tester, find.text('الفواتير'));
  await settle(tester);
}

Future<void> cancelReceiptViaUi(WidgetTester tester) async {
  await pumpUntilFound(tester, find.byIcon(Icons.keyboard_return_rounded));
  await tester.tap(find.byIcon(Icons.keyboard_return_rounded).first);
  await pumpUntilFound(tester, find.text('هل أنت متأكد؟'));
  await tester.tap(find.text('نعم'));
  await pumpUntilIdle(tester);
}

/// Cancels the loaned receipt (located by inspecting each [Receipt]'s log,
/// since the banner name relies on an Isar Future that never settles in the
/// fake-async test zone).
Future<void> cancelLoanedReceiptViaUi(
  WidgetTester tester,
  String loanerName,
) async {
  await pumpUntilFound(tester, find.byType(Receipt));
  Element? target;
  for (final e in find.byType(Receipt).evaluate()) {
    if ((e.widget as Receipt).log.loaned) {
      target = e;
      break;
    }
  }
  if (target == null) {
    throw StateError('No loaned receipt found for $loanerName');
  }
  await tester.tap(find.descendant(
    of: find.byWidget(target.widget),
    matching: find.byIcon(Icons.keyboard_return_rounded),
  ));
  await pumpUntilFound(tester, find.text('هل أنت متأكد؟'));
  await tester.tap(find.text('نعم'));
  await pumpUntilIdle(tester);
}

Future<void> editReceiptViaUi(WidgetTester tester) async {
  await pumpUntilFound(tester, find.byIcon(Icons.edit_note_rounded));
  await tester.tap(find.byIcon(Icons.edit_note_rounded).first);
  await pumpUntilFound(tester, find.text('هل تريد تعديل الفاتورة؟'));
  await tester.tap(find.text('نعم'));
  await pumpUntilIdle(tester);
}
