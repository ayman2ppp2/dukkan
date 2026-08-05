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
import 'package:provider/provider.dart';

Future<void> main() async {
  await AppLogger.bootstrap(() async {
    await DB.initialize();
    runApp(const DukkanApp());
  });
}

class DukkanApp extends StatelessWidget {
  const DukkanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>(create: (context) => AuthAPI()),
        ChangeNotifierProvider<ExpenseProvider>(
          create: (context) => ExpenseProvider(),
        ),
        ChangeNotifierProvider<SalesProvider>(
          create: (context) => SalesProvider(),
        ),
        ChangeNotifierProvider<InventoryProvider>(
          create: (context) => InventoryProvider(),
        ),
        ChangeNotifierProvider<LogProvider>(
          create: (context) => LogProvider(stats: context.read<StatsService>()),
        ),
        ChangeNotifierProvider<OwnerProvider>(
          create: (context) => OwnerProvider(),
        ),
        ChangeNotifierProvider<ShareProvider>(
          create: (context) => ShareProvider(),
        ),
        ChangeNotifierProvider<StatsService>(
          create: (context) => StatsService(),
        ),
      ],
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
