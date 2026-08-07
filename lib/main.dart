import 'package:dukkan/core/router/app_router.dart';
import 'package:dukkan/data/stats/stats_service.dart';
import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/core/observability.dart';
import 'package:dukkan/providers/auth_provider.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/providers/inventory_provider.dart';
import 'package:dukkan/providers/log_provider.dart';
import 'package:dukkan/providers/owner_provider.dart';
import 'package:dukkan/providers/sales_provider.dart';
import 'package:dukkan/providers/share_provider.dart';
import 'package:flutter/material.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  await AppLogger.bootstrap(() async {
    await DB.initialize();

    // Bootstrap every provider before the first frame. Waiting on each
    // (idempotent) `init()` here guarantees that `db`, `pool`, `_pref` and
    // `stats` are initialized before any page reads them, so pages never race
    // against a provider's async initialization.
    final auth = AuthAPI();
    final expense = ExpenseProvider();
    final sales = SalesProvider();
    final inventory = InventoryProvider();
    final stats = StatsService();
    final log = LogProvider(stats: stats);
    final owner = OwnerProvider();
    final share = ShareProvider();
    await Future.wait([
      expense.init(),
      sales.init(),
      inventory.init(),
      log.init(),
      owner.init(),
      share.init(),
      stats.init(),
    ]);

    runApp(DukkanApp(
      auth: auth,
      expense: expense,
      sales: sales,
      inventory: inventory,
      log: log,
      owner: owner,
      share: share,
      stats: stats,
    ));
  });
}

/// The providers registered once at the app root. Instances are passed in
/// (created and awaited in `main()`) so providers never depend on each other
/// via `context.read` inside a `create:` callback.
List<SingleChildWidget> appProviderList({
  required AuthAPI auth,
  required ExpenseProvider expense,
  required SalesProvider sales,
  required InventoryProvider inventory,
  required LogProvider log,
  required OwnerProvider owner,
  required ShareProvider share,
  required StatsService stats,
}) {
  return [
    ChangeNotifierProvider<AuthAPI>.value(value: auth),
    ChangeNotifierProvider<ExpenseProvider>.value(value: expense),
    ChangeNotifierProvider<SalesProvider>.value(value: sales),
    ChangeNotifierProvider<InventoryProvider>.value(value: inventory),
    ChangeNotifierProvider<LogProvider>.value(value: log),
    ChangeNotifierProvider<OwnerProvider>.value(value: owner),
    ChangeNotifierProvider<ShareProvider>.value(value: share),
    ChangeNotifierProvider<StatsService>.value(value: stats),
  ];
}

class DukkanApp extends StatelessWidget {
  const DukkanApp({
    super.key,
    required this.auth,
    required this.expense,
    required this.sales,
    required this.inventory,
    required this.log,
    required this.owner,
    required this.share,
    required this.stats,
  });

  final AuthAPI auth;
  final ExpenseProvider expense;
  final SalesProvider sales;
  final InventoryProvider inventory;
  final LogProvider log;
  final OwnerProvider owner;
  final ShareProvider share;
  final StatsService stats;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
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
      child: _AppScope(
        child: MaterialApp.router(
          title: 'دكان',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
            useMaterial3: true,
          ),
          routerConfig: AppRouter.create(),
        ),
      ),
    );
  }
}

/// Runs once, after all providers are available, to wire the cross-provider
/// side effects that previously lived in `main.dart`'s builder.
class _AppScope extends StatefulWidget {
  const _AppScope({required this.child});

  final Widget child;

  @override
  State<_AppScope> createState() => _AppScopeState();
}

class _AppScopeState extends State<_AppScope> {
  @override
  void initState() {
    super.initState();
    final sa = context.read<SalesProvider>();
    WidgetsBinding.instance.addObserver(sa);
    sa.onInventoryChanged = context.read<StatsService>().clearAllCache;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
