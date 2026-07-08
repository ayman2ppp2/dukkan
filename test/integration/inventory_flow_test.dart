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

  testWidgets('AppBar inventory icon exists', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
      authenticated: true,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });
}
