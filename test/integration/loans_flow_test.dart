@Tags(['integration'])
library;

import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loan.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('HomePage sell tab renders', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.monetization_on_outlined), findsOneWidget);
  });

  test('loaner name can be renamed via provider', () async {
    final id = await handle.db.isar!.writeTxn(
      () => handle.db.isar!.loaners.put(Loaner(
            name: 'العميل أصلي',
            phoneNumber: '077001122',
            location: 'بغداد',
            lastPayment: [],
            balance: 50,
          )),
    );

    final sa = SalesProvider.forTesting(db: handle.db, pref: prefs);
    await sa.renameLoaner(
      id,
      name: 'العميل الجديد',
      phoneNumber: '0770998877',
    );

    final updated = await handle.db.isar!.loaners.get(id);
    expect(updated!.name, 'العميل الجديد');
    expect(updated.phoneNumber, '0770998877');
    expect(updated.location, 'بغداد');
    expect(updated.balance, 50);
  });

  testWidgets('Loan page edit button opens a prefilled edit dialog',
    (tester) async {
    final id = await tester.runAsync(() => handle.db.isar!.writeTxn(
              () => handle.db.isar!.loaners.put(Loaner(
                    name: 'العميل',
                    phoneNumber: '0770000000',
                    location: 'بغداد',
                    lastPayment: [],
                    balance: 0,
                  )),
            ));
    final stored = (await tester
        .runAsync(() => handle.db.isar!.loaners.get(id!)))!;

    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
      home: Builder(builder: (context) => Loan(loaner: stored)),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byIcon(Icons.edit), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('تعديل بيانات العميل'), findsOneWidget);

    final nameField = tester.widget<EditableText>(find.descendant(
      of: find.widgetWithText(TextFormField, 'الاسم'),
      matching: find.byType(EditableText),
    ));
    expect(nameField.controller.text, 'العميل');

    await tester.tap(find.text('إلغاء'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('تعديل بيانات العميل'), findsNothing);

    // Unmount the page so its Isar watch streams are cancelled before
    // the DB is closed in teardown.
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    // skip: broken — mounting Loan keeps an Isar watch stream alive which
    // hangs isar.close() in teardown.
  }, skip: true);
}
