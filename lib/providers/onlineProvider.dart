import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

import 'package:flutter/widgets.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:package_info_plus/package_info_plus.dart';

const String APPWRITE_PROJECT_ID = "65e616d10bd9110e806f";
const String APPWRITE_DATABASE_ID = "";
const String APPWRITE_URL = "https://cloud.appwrite.io/v1";
const String COLLECTION_MESSAGES = "";

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier {
  Client client = Client();
  late final Account account;

  late User _currentUser;

  AuthStatus _status = AuthStatus.uninitialized;

  // Getter methods
  User get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get username => _currentUser.name;
  String? get email => _currentUser.email;
  String? get userid => _currentUser.$id;

  // Constructor
  AuthAPI() {
    init();
    loadUser();
  }

  // Initialize the Appwrite client
  init() async {
    client
        .setEndpoint(APPWRITE_URL)
        .setProject(APPWRITE_PROJECT_ID)
        .setSelfSigned();

    account = Account(client);
  }

  loadUser() async {
    try {
      final user = await account.get();
      _status = AuthStatus.authenticated;
      _currentUser = user;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<User> createUser(
      {required String email,
      required String password,
      required String name}) async {
    notifyListeners();

    try {
      final user = await account.create(
          userId: ID.unique(),
          email: email,
          password: password,
          name: 'Simon G');
      return user;
    } finally {
      createEmailSession(email: email, password: password);
      notifyListeners();
    }
  }

  Future<int> verifyUser({required String email}) async {
    int temp = Random().nextInt(9999);
    String username = 'dukkansud@gmail.com';
    String password = 'opto foyd pbiv qrlt';
    final smtpServer = gmail(username, password);
    final message = Message()
      ..from = Address(username, 'Dukkan')
      ..recipients.add(email)
      ..subject = 'Dukkan email verfication :: ${DateTime.now()}'
      ..text = 'copy the below number and paste it in your app'
      ..html = '''
                              <head>
                              <style>
                              h1 {text-align: center;}
                              </style>
                              </head>
                              <body>
                              <h1>copy the below number</h1>
                              <h1>$temp</h1>
                              </body>
                            ''';

    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      return temp;
    } on MailerException catch (e) {
      print('Message not sent.');
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
      return 0;
    }
  }

  Future<Session> anonymosSignIn() async {
    return await account.createAnonymousSession();
  }

  Future<Session> createEmailSession(
      {required String email, required String password}) async {
    notifyListeners();

    try {
      final session =
          await account.createEmailSession(email: email, password: password);
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      return session;
    } finally {
      notifyListeners();
    }
  }

// Future<void> test(params) async{
//   final sessionToken = await account.createVerification(
//     url: '/account/verification'
// );
// }

  signInWithProvider({required String provider}) async {
    try {
      // PackageInfo packageInfo = await PackageInfo.fromPlatform();
      // print(packageInfo!.packageName);
      final session = await account.createOAuth2Session(
        provider: 'google',
      );

      print('successful login');
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      notifyListeners();
      return session;
    } catch (e) {
      print('failed login $e');
    } finally {
      notifyListeners();
    }
  }

  signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<Preferences> getUserPreferences() async {
    return await account.getPrefs();
  }

  updatePreferences({required String bio}) async {
    return account.updatePrefs(prefs: {'bio': bio});
  }
}
