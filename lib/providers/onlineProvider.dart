import 'dart:io' as IO;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/client_io.dart' as appwrite_io;
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/core/observability.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:dukkan/core/appwrite_config.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier {
  late final Client client;
  late final Account account;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String KEY_SESSION_TIME = 'last_login_time';
  static const String KEY_USER_EMAIL = 'user_email';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_USER_NAME = 'user_name';
  static const Duration offlineSessionDuration = Duration(days: 3);
  static const Duration revalidationInterval = Duration(minutes: 5);

  User? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isOffline = false;
  Storage? storage;

  User? get currentUser => _currentUser;
  AuthStatus get status => _status;
  String? get username => _currentUser?.name;
  String? get email => _currentUser?.email;
  String? get userid => _currentUser?.$id;
  bool get isOffline => _isOffline;

  AuthAPI() {
    init();
    _initialize();
  }

  @visibleForTesting
  AuthAPI.forTesting();

  @visibleForTesting
  Future<void> clearSessionForTesting() => _clearSession();

  @visibleForTesting
  static OAuthProvider oauthProviderForTesting(String provider) =>
      _oauthProvider(provider);

  void init() {
    client = Client();
    client
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    if (!AppwriteConfig.isCloud) {
      client.setSelfSigned();
    }
    account = Account(client);
    storage = Storage(client);
  }

  Future<void> _initialize() async {
    await loadUser();
    _startRevalidationTimer();
  }

// just a test
  void _startRevalidationTimer() {
    Future.delayed(revalidationInterval, () async {
      if (_status == AuthStatus.authenticated && _isOffline) {
        try {
          await account.get();
          _isOffline = false;
          await _saveSession(_currentUser!);
          notifyListeners();
        } catch (e, st) {
          await AppLogger.captureException(e,
              stackTrace: st, area: 'auth.revalidate');
        }
        _startRevalidationTimer();
      }
    });
  }

  Future<bool> checkOfflineSession() async {
    try {
      final lastLoginTime = await _secureStorage.read(key: KEY_SESSION_TIME);
      if (lastLoginTime == null) return false;

      final lastLoginMillis = int.tryParse(lastLoginTime);
      if (lastLoginMillis == null) return false;

      final lastLogin = DateTime.fromMillisecondsSinceEpoch(lastLoginMillis);
      final difference = DateTime.now().difference(lastLogin);

      if (difference.inDays < offlineSessionDuration.inDays) {
        final email = await _secureStorage.read(key: KEY_USER_EMAIL);
        final userId = await _secureStorage.read(key: KEY_USER_ID);
        final name = await _secureStorage.read(key: KEY_USER_NAME);

        if (email != null && userId != null && name != null) {
          _status = AuthStatus.authenticated;
          _isOffline = true;
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
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.offline_session');
      return false;
    }
  }

  Future<void> _saveSession(User user) async {
    try {
      await _secureStorage.write(
        key: KEY_SESSION_TIME,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
      await _secureStorage.write(key: KEY_USER_EMAIL, value: user.email);
      await _secureStorage.write(key: KEY_USER_ID, value: user.$id);
      await _secureStorage.write(key: KEY_USER_NAME, value: user.name);
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.save_session');
    }
  }

  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: KEY_SESSION_TIME);
      await _secureStorage.delete(key: KEY_USER_EMAIL);
      await _secureStorage.delete(key: KEY_USER_ID);
      await _secureStorage.delete(key: KEY_USER_NAME);
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.clear_session');
    }
    _isOffline = false;
  }

  Future<void> loadUser() async {
    try {
      final user = await account.get();
      _status = AuthStatus.authenticated;
      _isOffline = false;
      _currentUser = user;
      await _saveSession(user);
    } catch (_) {
      if (await checkOfflineSession()) {
        AppLogger.info('Using offline auth session', data: {'area': 'auth'});
        return;
      }
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<User> createUser({
    required String email,
    required String password,
    required String name,
  }) async {
    final user = await account.create(
      userId: ID.unique(),
      email: email,
      password: password,
      name: name,
    );
    return user;
  }

  Future<void> sendVerification() async {
    await account.createVerification(url: 'dukkan://verify');
  }

  Future<bool> confirmVerification({
    required String userId,
    required String secret,
  }) async {
    try {
      await account.updateVerification(userId: userId, secret: secret);
      return true;
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'auth.verify_email');
      return false;
    }
  }

  Future<Session> anonymosSignIn() async {
    return await account.createAnonymousSession();
  }

  Future<Session> createEmailSession({
    required String email,
    required String password,
  }) async {
    try {
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      _isOffline = false;
      await _saveSession(_currentUser!);
      return session;
    } finally {
      notifyListeners();
    }
  }

  Future<void> signInWithProvider({required String provider}) async {
    try {
      final oauthProvider = _oauthProvider(provider);
      if (_usesDesktopBrowserOAuth) {
        await _createDesktopOAuthSession(oauthProvider);
      } else {
        await account.createOAuth2Session(provider: oauthProvider);
      }
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      _isOffline = false;
      await _saveSession(_currentUser!);
      notifyListeners();
    } catch (e, st) {
      await AppLogger.captureException(e, stackTrace: st, area: 'auth.oauth');
      notifyListeners();
      rethrow;
    }
  }

  static OAuthProvider _oauthProvider(String provider) {
    switch (provider.toLowerCase()) {
      case 'google':
        return OAuthProvider.google;
      case 'github':
        return OAuthProvider.github;
      default:
        throw ArgumentError.value(provider, 'provider', 'Unsupported provider');
    }
  }

  bool get _usesDesktopBrowserOAuth =>
      IO.Platform.isLinux || IO.Platform.isWindows;

  Future<void> _createDesktopOAuthSession(OAuthProvider provider) async {
    // Keep the callback stable so it can be allow-listed in Appwrite.
    final callbackUri = Uri.parse('http://localhost:43871/oauth2');
    final endpoint = Uri.parse(client.endPoint);
    final endpointPath = endpoint.path.endsWith('/')
        ? endpoint.path.substring(0, endpoint.path.length - 1)
        : endpoint.path;
    final oauthUri = endpoint.replace(
      path: '$endpointPath/account/sessions/oauth2/${provider.value}',
      queryParameters: {
        'project': AppwriteConfig.projectId,
        'success': callbackUri.toString(),
        'failure': callbackUri.toString(),
      },
    );

    final result = await FlutterWebAuth2.authenticate(
      url: oauthUri.toString(),
      callbackUrlScheme: callbackUri.toString(),
      options: const FlutterWebAuth2Options(
        useWebview: false,
        timeout: 300,
        landingPageHtml: _desktopOAuthLandingPageHtml,
      ),
    );
    final redirectedUri = Uri.parse(result);
    final key = redirectedUri.queryParameters['key'];
    final secret = redirectedUri.queryParameters['secret'];
    if (key == null || secret == null) {
      throw AppwriteException('OAuth sign-in did not complete.', 500);
    }

    final cookie = IO.Cookie(key, secret)
      ..domain = endpoint.host
      ..httpOnly = true
      ..path = '/';
    final clientIo = client as appwrite_io.ClientIO;
    await clientIo.init();
    await clientIo.cookieJar.saveFromResponse(endpoint, [cookie]);
  }

  static const _desktopOAuthLandingPageHtml = '''
<!doctype html>
<html>
<head><meta charset="utf-8"><title>Dukkan</title></head>
<body style="font-family:sans-serif;text-align:center;padding:3rem">
  <h1>تم تسجيل الدخول</h1>
  <p>يمكنك إغلاق هذه الصفحة والعودة إلى دكان.</p>
</body>
</html>
''';

  signOut() async {
    try {
      await account.deleteSession(sessionId: 'current');
    } finally {
      _status = AuthStatus.unauthenticated;
      _isOffline = false;
      await _clearSession();
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
      final file = IO.File('${dir.path}/${DB.liveDatabaseFileName}');
      final fileId = 'backup_${_currentUser!.$id}.isar';

      if (!await file.exists()) return;

      try {
        await storage!.getFile(
          bucketId: AppwriteConfig.bucketId,
          fileId: fileId,
        );
        await storage!.deleteFile(
          bucketId: AppwriteConfig.bucketId,
          fileId: fileId,
        );
      } catch (e, st) {
        await AppLogger.captureException(e,
            stackTrace: st, area: 'backup.upload.delete_existing');
      }

      await storage!.createFile(
        bucketId: AppwriteConfig.bucketId,
        fileId: fileId,
        file: InputFile.fromPath(
          path: file.path,
          filename: 'backup_${_currentUser!.$id}.isar',
        ),
      );
      AppLogger.info('Backup uploaded', data: {'area': 'backup.upload'});
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'backup.upload');
      rethrow;
    }
  }

  Future<void> downloadBackup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${DB.liveDatabaseFileName}';
      final fileId = 'backup_${_currentUser!.$id}.isar';

      final response = await storage!.getFileDownload(
        bucketId: AppwriteConfig.bucketId,
        fileId: fileId,
      );

      final file = IO.File(filePath);
      await file.writeAsBytes(response);
      AppLogger.info('Backup downloaded', data: {'area': 'backup.download'});
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'backup.download');
      rethrow;
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
