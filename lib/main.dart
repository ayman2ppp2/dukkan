import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dukkan/pages/LoginPage.dart';
import 'package:dukkan/pages/landingPge.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/providers/inventory_provider.dart';
import 'package:dukkan/providers/log_provider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/loan_provider.dart';
import 'package:dukkan/pages/homePage.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/owner_provider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/providers/share_provider.dart';
import 'package:dukkan/providers/stats_provider.dart';
import 'package:dukkan/providers/sync_provider.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/core/observability.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  await AppLogger.bootstrap(() async {
    await DB.initialize();
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'دكان',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: AnimatedSplashScreen(
        centered: true,
        backgroundColor: Colors.brown[400]!,
        splashTransition: SplashTransition.scaleTransition,
        splash: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront,
              size: 80,
              color: Colors.white,
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: AnimatedTextKit(
                animatedTexts: [
                  TypewriterAnimatedText(
                    'دكان',
                    textStyle: const TextStyle(
                      fontSize: 32.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    speed: const Duration(milliseconds: 200),
                  ),
                ],
                totalRepeatCount: 3,
                displayFullTextOnTap: true,
                stopPauseOnTap: true,
              ),
            ),
          ],
        ),
        nextScreen: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthAPI>(
              create: (context) => AuthAPI(),
            ),
            ChangeNotifierProvider<ExpenseProvider>(
              create: (context) => ExpenseProvider(),
            ),
            ChangeNotifierProvider<SalesProvider>(
              create: (context) => SalesProvider(),
            ),
            ChangeNotifierProvider<LoanProvider>(
              create: (context) => LoanProvider(),
            ),
            ChangeNotifierProvider<StatsProvider>(
              create: (context) => StatsProvider(),
            ),
            ChangeNotifierProvider<InventoryProvider>(
              create: (context) => InventoryProvider(),
            ),
            ChangeNotifierProvider<LogProvider>(
              create: (context) => LogProvider(),
            ),
            ChangeNotifierProvider<OwnerProvider>(
              create: (context) => OwnerProvider(),
            ),
            ChangeNotifierProvider<ShareProvider>(
              create: (context) => ShareProvider(),
            ),
            ChangeNotifierProvider<SyncProvider>(
              create: (context) => SyncProvider(),
            ),
            // Keep Lists for backward compatibility during migration
            ChangeNotifierProvider<Lists>(
              create: (context) => Lists(),
            ),
          ],
          builder: (context, child) {
            WidgetsBinding.instance.addObserver(context.read<SalesProvider>());
            return Consumer<AuthAPI>(
              builder: (context, auth, child) {
                if (auth.status == AuthStatus.uninitialized) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (auth.status == AuthStatus.authenticated) {
                  final content =
                      context.read<SalesProvider>().getWeightPrececsion() ==
                              null
                          ? const LandingPage()
                          : const HomePage();
                  return content;
                }
                return LoginPage();
              },
            );
          },
        ),
      ),
    );
  }
}
