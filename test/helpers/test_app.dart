import 'package:dukkan/core/db.dart';
import 'package:dukkan/pages/LoginPage.dart';
import 'package:dukkan/pages/homePage.dart';
import 'package:dukkan/pages/landingPge.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/providers/inventory_provider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/log_provider.dart';
import 'package:dukkan/providers/loan_provider.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/owner_provider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/providers/share_provider.dart';
import 'package:dukkan/providers/stats_provider.dart';
import 'package:dukkan/providers/sync_provider.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestApp extends StatelessWidget {
  const TestApp({
    super.key,
    required this.db,
    required this.prefs,
    this.home,
    this.products = const [],
    this.cartProducts = const [],
    this.authenticated = false,
  });

  final DB db;
  final SharedPreferences prefs;
  final Widget? home;
  final List<Product> products;
  final List<Product> cartProducts;
  final bool authenticated;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthAPI>.value(
          value: AuthAPI.forTesting(),
        ),
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
        ChangeNotifierProvider<LoanProvider>.value(
          value: LoanProvider.forTesting(db),
        ),
        ChangeNotifierProvider<StatsProvider>.value(
          value: StatsProvider.forTesting(db),
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
        ChangeNotifierProvider<SyncProvider>.value(
          value: SyncProvider.forTesting(),
        ),
        ChangeNotifierProvider<Lists>.value(
          value: Lists.forTesting(db),
        ),
      ],
      child: _CartInjector(
        cartProducts: cartProducts,
        child: MaterialApp(
          title: 'دكان',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
            useMaterial3: true,
          ),
          home: home ??
              Builder(builder: (context) {
                if (!authenticated) return const LoginPage();
                return context
                            .read<SalesProvider>()
                            .getWeightPrececsion() ==
                        null
                    ? const LandingPage()
                    : const HomePage();
              }),
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
