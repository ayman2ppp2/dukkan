import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dukkan/list.dart';
import 'package:dukkan/pages/homePage.dart';
import 'package:dukkan/salesProvider.dart';
import 'package:dukkan/util/adapters.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var te = await getApplicationDocumentsDirectory();
  print(te.path);
  Hive.init(te.path);

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(LogAdapter());
  Hive.registerAdapter(OwnerAdapter());

  runApp(const MyApp());
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
                // pause: const Duration(milliseconds: 200),
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
          ],
          builder: (context, child) => const HomePage(),
        ),
      ),
    );
  }
}
