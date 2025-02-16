import 'dart:math';

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:dukkan/secrets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/widgets.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'dart:io' as IO;

// import 'package:package_info_plus/package_info_plus.dart';

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

  SharedPreferences? _prefs;
  static const String KEY_SESSION_TIME = 'last_login_time';
  static const String KEY_USER_EMAIL = 'user_email';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_USER_NAME = 'user_name';

  User? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  Storage? storage;

  // Getter methods
  User? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get username => _currentUser?.name;
  String? get email => _currentUser?.email;
  String? get userid => _currentUser?.$id;

  // Constructor
  AuthAPI() {
    init();
    _initialize();
  }

  void init() {
    print('Initializing Appwrite client...');
    client
        .setEndpoint(APPWRITE_URL)
        .setProject(APPWRITE_PROJECT_ID)
        .setSelfSigned();
    account = Account(client);
    storage = Storage(client);
    print('Appwrite client initialized');
  }

  Future<void> _initialize() async {
    print('Initializing AuthAPI...');
    await _initPrefs();
    await loadUser();
    print('AuthAPI initialization complete');
  }

  Future<void> _initPrefs() async {
    print('Initializing SharedPreferences...');
    _prefs = await SharedPreferences.getInstance();
    print('SharedPreferences initialized');
  }

  Future<bool> checkOfflineSession() async {
    print('Checking offline session...');
    if (_prefs == null) {
      print('SharedPreferences is null');
      return false;
    }

    final lastLoginTime = _prefs!.getInt(KEY_SESSION_TIME);
    if (lastLoginTime == null) {
      print('No last login time found');
      return false;
    }

    final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginTime);
    final now = DateTime.now();
    final difference = now.difference(lastLogin);
    print('Last login was ${difference.inDays} days ago');

    // Check if less than 3 days have passed
    if (difference.inDays < 3) {
      // Load offline user data
      final email = _prefs!.getString(KEY_USER_EMAIL);
      final userId = _prefs!.getString(KEY_USER_ID);
      final name = _prefs!.getString(KEY_USER_NAME);

      print('Stored credentials - Email: $email, UserId: $userId, Name: $name');

      if (email != null && userId != null && name != null) {
        print('Creating offline user object');
        _status = AuthStatus.authenticated;
        // Create a basic User object for offline mode
        _currentUser = User(
          targets: [],
          mfa: false,
          $id: userId,
          email: email,
          name: name,
          emailVerification: false,
          phoneVerification: false,
          status: true,
          labels: const [],
          prefs: Preferences(data: {}),
          registration: DateTime.now().toIso8601String(),
          passwordUpdate: DateTime.now().toIso8601String(),
          $createdAt: DateTime.now().toIso8601String(),
          $updatedAt: DateTime.now().toIso8601String(),
          phone: '',
          accessedAt: '',
        );
        notifyListeners();
        return true;
      }
    }
    return false;
  }

  Future<void> _saveSession(User user) async {
    if (_prefs == null) {
      print('Cannot save session: SharedPreferences is null');
      return;
    }

    try {
      print('Saving session for user: ${user.email}');
      await _prefs!
          .setInt(KEY_SESSION_TIME, DateTime.now().millisecondsSinceEpoch);
      await _prefs!.setString(KEY_USER_EMAIL, user.email);
      await _prefs!.setString(KEY_USER_ID, user.$id);
      await _prefs!.setString(KEY_USER_NAME, user.name);
      print('Session saved successfully');
    } catch (e) {
      print('Error saving session: $e');
    }
  }

  Future<void> _clearSession() async {
    if (_prefs == null) return;

    await _prefs!.remove(KEY_SESSION_TIME);
    await _prefs!.remove(KEY_USER_EMAIL);
    await _prefs!.remove(KEY_USER_ID);
    await _prefs!.remove(KEY_USER_NAME);
  }

  Future<void> loadUser() async {
    try {
      print('Loading user...');
      // First try online login
      final user = await account.get();
      _status = AuthStatus.authenticated;
      _currentUser = user;
      await _saveSession(user);
      print('Online login successful');
    } catch (e) {
      print('Online login failed, trying offline session');
      // If online login fails, check for offline session
      if (await checkOfflineSession()) {
        print('Offline session valid, user loaded');
        _status = AuthStatus.authenticated;
        return;
      }
      print('Both online and offline login failed');
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
          userId: ID.unique(), email: email, password: password, name: name);
      return user;
    } finally {
      createEmailSession(email: email, password: password);
      notifyListeners();
    }
  }

  Future<int> verifyUser({required String email}) async {
    int temp = Random().nextInt(9999);
    String username = User_Name;
    String password = Password;
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
      final session = await account.createEmailPasswordSession(
          email: email, password: password);
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      print('Saving session for user: ${_currentUser?.email}');
      await _saveSession(_currentUser!);
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
        provider: OAuthProvider.google,
      );

      print('successful login');
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      await _saveSession(_currentUser!);
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
      await _clearSession();
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

  Future<void> uploadBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = IO.File('${dir.path}/isarinstance.isar');
      final fileId = 'backup_${_currentUser!.$id}.isar';

      if (!await file.exists()) {
        print('Backup file does not exist at ${file.path}');
        return;
      }

      // Check if the file exists in storage
      try {
        await storage!.getFile(
          bucketId: '6762672a0033f48ae769',
          fileId: fileId,
        );

        // If the file exists, delete it
        await storage!.deleteFile(
          bucketId: '6762672a0033f48ae769',
          fileId: fileId,
        );
        print('Existing backup deleted.');
      } catch (e) {
        if (e.toString().contains('File not found')) {
          print('No existing backup found. Proceeding with upload.');
        } else {
          print('Error checking for existing backup: $e');
          return;
        }
      }

      // Upload the new backup
      final response = await storage!.createFile(
        bucketId: '6762672a0033f48ae769',
        fileId: fileId,
        file: InputFile.fromPath(
          path: file.path,
          filename: 'backup_${_currentUser!.$id}.isar',
        ),
      );

      print('Backup uploaded: ${response.$id}');
    } catch (e, stackTrace) {
      print('Error uploading backup: $e\n$stackTrace');
    }
  }

  Future<void> downloadBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/isarinstance.isar';
      final fileId = 'backup_${_currentUser!.$id}.isar';

      // Download the backup file
      final response = await storage!.getFileDownload(
        bucketId: '6762672a0033f48ae769',
        fileId: fileId,
      );

      // Write the downloaded content to the local file
      final file = IO.File(filePath);
      await file.writeAsBytes(response);

      print('Backup downloaded and saved to $filePath');
    } catch (e, stackTrace) {
      print('Error downloading backup: $e\n$stackTrace');
    }
  }

  void uploadPaymentReceipt({required IO.File receipt}) {}

  Future<User> setSubscriptionPlan(int s) {
    return account.updatePrefs(prefs: {
      'subscriptionPlan': s,
      'subscriptionExpiry':
          DateTime.now().add(Duration(days: s)).toIso8601String(),
    });
  }

  Future<String> getSubscriptionStatus() {
    return account
        .getPrefs()
        .then((value) => value.data['subscriptionPlan'] ?? '');
  }
}
