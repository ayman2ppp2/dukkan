import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/core/router/app_router.dart';
import 'package:dukkan/data/stats/stats_service.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/providers/inventory_provider.dart';
import 'package:dukkan/providers/log_provider.dart';
import 'package:dukkan/providers/auth_provider.dart';
import 'package:dukkan/providers/owner_provider.dart';
import 'package:dukkan/providers/sales_provider.dart';
import 'package:dukkan/providers/share_provider.dart';
import 'package:dukkan/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.db,
    required this.prefs,
    this.products = const [],
    this.cartProducts = const [],
    this.authenticated = false,
  });

  final DB db;
  final SharedPreferences prefs;
  final List<Product> products;
  final List<Product> cartProducts;
  final bool authenticated;

  @override
  Widget build(BuildContext context) {
    final auth = AuthAPI.forTesting();
    auth.setStatusForTesting(
      authenticated ? AuthStatus.authenticated : AuthStatus.unauthenticated,
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>.value(value: auth),
        ChangeNotifierProvider<ExpenseProvider>.value(
          value: ExpenseProvider.forTesting(db),
        ),
        ChangeNotifierProvider<SalesProvider>.value(
          value: products.isNotEmpty
              ? SalesProvider.detachedForTesting(
                  pref: prefs,
                  products: products,
                )
              : SalesProvider.forTesting(
                  db: db,
                  pref: prefs,
                ),
        ),
        ChangeNotifierProvider<InventoryProvider>.value(
          value: InventoryProvider.forTesting(db),
        ),
        ChangeNotifierProvider<LogProvider>.value(
          value: LogProvider.forTesting(db),
        ),
        ChangeNotifierProvider<OwnerProvider>.value(
          value: OwnerProvider.forTesting(db),
        ),
        ChangeNotifierProvider<ShareProvider>.value(
          value: ShareProvider.forTesting(db),
        ),
        ChangeNotifierProvider<StatsService>.value(
          value: StatsService.forTesting(db),
        ),
      ],
      child: _CartInjector(
        cartProducts: cartProducts,
        child: MaterialApp.router(
          title: 'دكان',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
            useMaterial3: true,
          ),
          routerConfig: AppRouter.create(initialLocation: '/'),
        ),
      ),
    );
  }
}

class _CartInjector extends StatefulWidget {
  const _CartInjector({
    required this.cartProducts,
    required this.child,
  });

  final List<Product> cartProducts;
  final Widget child;

  @override
  State<_CartInjector> createState() => _CartInjectorState();
}

class _CartInjectorState extends State<_CartInjector> {
  @override
  void initState() {
    super.initState();
    if (widget.cartProducts.isNotEmpty) {
      final sa = context.read<SalesProvider>();
      sa.sellList.addAll(widget.cartProducts);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
