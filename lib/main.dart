import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:dukkan/pages/LoginPage.dart';
// import 'package:appwrite/appwrite.dart';
// import 'package:dukkan/pages/LoginPage.dart';
import 'package:dukkan/providers/expenseProvider.dart';
// import 'package:dukkan/firebase_options.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/pages/homePage.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/salesProvider.dart';
// import 'package:dukkan/util/models/Emap.dart';
// import 'package:dukkan/util/models/Loaner.dart';
// import 'package:dukkan/util/models/Log.dart';
// import 'package:dukkan/util/models/Owner.dart';
// import 'package:dukkan/util/models/Product.dart';
// import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
// import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
// import 'package:hive/hive.dart';
// import 'package:appwrite/models.dart' as models;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );
  var dir = await getApplicationDocumentsDirectory();
  // print(te.path);
  // 'storage/emulated/0/dukkan/v2'
  Hive.initFlutter(dir.path);

  // Hive.registerAdapter(ProductAdapter());
  // Hive.registerAdapter(LogAdapter());
  // Hive.registerAdapter(OwnerAdapter());
  // Hive.registerAdapter(LoanerAdapter());

  runApp(MyApp());
}

// class MyApp extends StatefulWidget {
//   final Account account;

//   MyApp({required this.account});

//   @override
//   MyAppState createState() {
//     return MyAppState();
//   }
// }

// class MyAppState extends State<MyApp> {
//   models.User? loggedInUser;
//   final TextEditingController emailController = TextEditingController();
//   final TextEditingController passwordController = TextEditingController();
//   final TextEditingController nameController = TextEditingController();

//   Future<void> login(String email, String password) async {
//     await widget.account.createEmailSession(email: email, password: password);
//     final user = await widget.account.get();
//     setState(() {
//       loggedInUser = user;
//     });
//   }

//   Future<void> register(String email, String password, String name) async {
//     await widget.account.createVerification(url: 'https://google.com');
//     await widget.account.create(
//         userId: ID.unique(), email: email, password: password, name: name);
//     await login(email, password);
//   }

//   Future<void> logout() async {
//     await widget.account.deleteSession(sessionId: 'current');
//     setState(() {
//       loggedInUser = null;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         body: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: <Widget>[
//             Text(loggedInUser != null
//                 ? 'Logged in as ${loggedInUser!.name}'
//                 : 'Not logged in'),
//             SizedBox(height: 16.0),
//             TextField(
//               controller: emailController,
//               decoration: InputDecoration(labelText: 'Email'),
//             ),
//             SizedBox(height: 16.0),
//             TextField(
//               controller: passwordController,
//               decoration: InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             SizedBox(height: 16.0),
//             TextField(
//               controller: nameController,
//               decoration: InputDecoration(labelText: 'Name'),
//             ),
//             SizedBox(height: 16.0),
//             Row(
//               mainAxisAlignment: MainAxisAlignment.start,
//               children: <Widget>[
//                 ElevatedButton(
//                   onPressed: () {
//                     login(emailController.text, passwordController.text);
//                   },
//                   child: Text('Login'),
//                 ),
//                 SizedBox(width: 16.0),
//                 ElevatedButton(
//                   onPressed: () {
//                     register(emailController.text, passwordController.text,
//                         nameController.text);
//                   },
//                   child: Text('Register'),
//                 ),
//                 SizedBox(width: 16.0),
//                 ElevatedButton(
//                   onPressed: () {
//                     logout();
//                   },
//                   child: Text('Logout'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

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
                  return HomePage();
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
