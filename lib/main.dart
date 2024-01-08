import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/pages/homePage.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/adapters/adapters.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
// import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var te = await getApplicationDocumentsDirectory();
  // print('storage/emulated/0/dukkan/V2');
  // 'storage/emulated/0/dukkan/v2'
  Hive.initFlutter(te.path);

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(LogAdapter());
  Hive.registerAdapter(OwnerAdapter());
  Hive.registerAdapter(LoanerAdapter());

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
