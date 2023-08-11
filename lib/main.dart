import 'package:dukkan/list.dart';
import 'package:dukkan/pages/homePage.dart';
import 'package:dukkan/util/adapters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive/hive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Hive.init('storage/emulated/0/dukkan/backup');

  Hive.registerAdapter(ProductAdapter());
  Hive.registerAdapter(LogAdapter());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dukkan ',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.brown),
        useMaterial3: true,
      ),
      home: ChangeNotifierProvider(
        create: (context) => Lists(),
        builder: (context, child) => const HomePage(),
      ),
    );
  }
}
