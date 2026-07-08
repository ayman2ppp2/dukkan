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

  testWidgets('LoginPage renders all controls', (tester) async {
    await tester.pumpWidget(TestApp(
      db: handle.db,
      prefs: prefs,
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('البريد الإلكتروني'), findsOneWidget);
    expect(find.text('كلمة المرور'), findsOneWidget);
    expect(find.text('تسجيل الدخول'), findsOneWidget);
    expect(find.text('إنشاء حساب'), findsOneWidget);
  });
}
