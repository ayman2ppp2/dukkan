@Tags(['integration'])
library;

import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/data/stats/stats_service.dart';
import 'package:dukkan/main.dart';
import 'package:dukkan/providers/auth_provider.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/providers/inventory_provider.dart';
import 'package:dukkan/providers/log_provider.dart';
import 'package:dukkan/providers/owner_provider.dart';
import 'package:dukkan/providers/sales_provider.dart';
import 'package:dukkan/providers/share_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/test_db.dart';

void main() {
  late TestDbHandle handle;
  late DB db;
  late SharedPreferences prefs;

  setUp(() async {
    handle = await openTestDb();
    SharedPreferences.setMockInitialValues({'weightPrececsion': 1});
    prefs = await SharedPreferences.getInstance();
    db = handle.db;
  });

  tearDown(() async {
    await handle.close();
  });

  test('appProviderList registers exactly one provider of each type', () {
    final providers = appProviderList(
      auth: AuthAPI.forTesting(),
      expense: ExpenseProvider.forTesting(db),
      sales: SalesProvider.forTesting(db: db, pref: prefs),
      inventory: InventoryProvider.forTesting(db),
      log: LogProvider.forTesting(db),
      owner: OwnerProvider.forTesting(db),
      share: ShareProvider.forTesting(db),
      stats: StatsService.forTesting(db),
    );

    expect(providers, hasLength(8));
    expect(providers.map((p) => p.runtimeType).toSet(), hasLength(8),
        reason: 'exactly one provider per type, no duplicates');
  });

  testWidgets(
      'every app provider is reachable and identical from a deep descendant',
      (tester) async {
    final auth = AuthAPI.forTesting();
    final expense = ExpenseProvider.forTesting(db);
    final sales = SalesProvider.forTesting(db: db, pref: prefs);
    final inventory = InventoryProvider.forTesting(db);
    final log = LogProvider.forTesting(db);
    final owner = OwnerProvider.forTesting(db);
    final share = ShareProvider.forTesting(db);
    final stats = StatsService.forTesting(db);
    final instances = [auth, expense, sales, inventory, log, owner, share, stats];

    await tester.pumpWidget(
      MultiProvider(
        providers: appProviderList(
          auth: auth,
          expense: expense,
          sales: sales,
          inventory: inventory,
          log: log,
          owner: owner,
          share: share,
          stats: stats,
        ),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final resolved = <Object>[
                context.read<AuthAPI>(),
                context.read<ExpenseProvider>(),
                context.read<SalesProvider>(),
                context.read<InventoryProvider>(),
                context.read<LogProvider>(),
                context.read<OwnerProvider>(),
                context.read<ShareProvider>(),
                context.read<StatsService>(),
              ];
              expect(resolved, hasLength(instances.length));
              for (var i = 0; i < instances.length; i++) {
                expect(identical(resolved[i], instances[i]), isTrue,
                    reason: 'provider at index $i should be the injected '
                        'instance, not a lazily recreated one');
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  });
}
