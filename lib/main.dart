import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dukkan/pages/LoginPage.dart';
import 'package:dukkan/pages/landingPge.dart';
import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/pages/homePage.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
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
            ChangeNotifierProvider<Lists>(
              create: (context) => Lists(),
            ),
            ChangeNotifierProvider<SalesProvider>(
              create: (context) => SalesProvider(),
            ),
            ChangeNotifierProvider<AuthAPI>(
              create: (context) => AuthAPI(),
            ),
            ChangeNotifierProvider<ExpenseProvider>(
              create: (context) => ExpenseProvider(),
            )
          ],
          builder: (context, child) {
            WidgetsBinding.instance
                .addObserver(Provider.of<SalesProvider>(context));
            return Consumer<AuthAPI>(
              builder: (context, auth, child) {
                print('Auth Status: ${auth.status}');
                if (auth.status == AuthStatus.uninitialized) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (auth.status == AuthStatus.authenticated) {
                  return Provider.of<SalesProvider>(context)
                              .getWeightPrececsion() ==
                          null
                      ? LandingPage()
                      : HomePage();
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
