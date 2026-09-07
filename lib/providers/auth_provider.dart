import 'dart:async';
import 'dart:io' as IO;

import 'package:appwrite/appwrite.dart';
import 'package:appwrite/client_io.dart' as appwrite_io;
import 'package:appwrite/enums.dart';
import 'package:appwrite/models.dart';
import 'package:crypto/crypto.dart';
import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/core/observability.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:dukkan/core/config/appwrite_config.dart';

enum AuthStatus {
  uninitialized,
  authenticated,
  unauthenticated,
}

class AuthAPI extends ChangeNotifier with WidgetsBindingObserver {
  late final Client client;
  late final Account account;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String KEY_SESSION_TIME = 'last_login_time';
  static const String KEY_USER_EMAIL = 'user_email';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_USER_NAME = 'user_name';
  static const String KEY_LAST_BACKUP_HASH = 'last_backup_hash';
  static const Duration offlineSessionDuration = Duration(days: 3);
  static const Duration revalidationInterval = Duration(minutes: 5);
  static const Duration heartbeatInterval = Duration(minutes: 30);

  User? _currentUser;
  AuthStatus _status = AuthStatus.uninitialized;
  bool _isOffline = false;
  Timer? _revalidationTimer;
  bool _isPinging = false;
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
  void setStatusForTesting(AuthStatus status) => _status = status;

  /// Test-only hook to complete a login without hitting Appwrite. When set,
  /// [createEmailSession] awaits it, marks the session authenticated, notifies
  /// listeners, and returns its result.
  @visibleForTesting
  Future<Session> Function({
    required String email,
    required String password,
  })? loginOverrideForTesting;

  @visibleForTesting
  Future<void> clearSessionForTesting() => _clearSession();

  @visibleForTesting
  static OAuthProvider oauthProviderForTesting(String provider) =>
      _oauthProvider(provider);

  void init() {
    if (!AppwriteConfig.isConfigured) {
      AppLogger.warning('Appwrite is not configured; add --dart-define values',
          data: {'area': 'appwrite.config'});
    }
    client = Client();
    client
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    if (!AppwriteConfig.isCloud) {
      client.setSelfSigned();
    }
    account = Account(client);
    storage = Storage(client);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _initialize() async {
    await loadUser();
    _startRevalidationTimer();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _revalidationTimer?.cancel();
      _revalidationTimer = null;
    } else if (state == AppLifecycleState.resumed &&
        _status == AuthStatus.authenticated) {
      _startRevalidationTimer();
    }
  }

  @override
  void dispose() {
    _revalidationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _pingServer({required String area}) async {
    if (_isPinging) return;
    _isPinging = true;
    try {
      final user = await account.get();
      _isOffline = false;
      _currentUser = user;
      await _updateLastPingTime();
      AppLogger.debug('Heartbeat ok', data: {'area': area});
    } catch (_) {
      _isOffline = true;
      AppLogger.debug('Heartbeat ping failed (offline?)',
          data: {'area': area});
    } finally {
      _isPinging = false;
      _startRevalidationTimer();
    }
  }

  Future<void> _updateLastPingTime() async {
    try {
      await _secureStorage.write(
        key: KEY_SESSION_TIME,
        value: DateTime.now().millisecondsSinceEpoch.toString(),
      );
    } catch (e) {
      AppLogger.debug('Failed to update session time',
          data: {'area': 'auth.ping_time', 'error': e.toString()});
    }
  }

  // keep-alive so Appwrite does not flag the project as inactive
  void _startRevalidationTimer() {
    _revalidationTimer?.cancel();
    _revalidationTimer = Timer(
      _isOffline ? revalidationInterval : heartbeatInterval,
      () async {
        if (_status != AuthStatus.authenticated) return;
        await _pingServer(area: 'auth.heartbeat');
      },
    );
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
      AppLogger.setUser(user.$id, email: user.email, username: user.name);
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

  Future<Session> createEmailSession({
    required String email,
    required String password,
  }) async {
    final override = loginOverrideForTesting;
    if (override != null) {
      final session = await override(email: email, password: password);
      _status = AuthStatus.authenticated;
      _isOffline = false;
      notifyListeners();
      return session;
    }
    try {
      final session = await account.createEmailPasswordSession(
        email: email,
        password: password,
      );
      _currentUser = await account.get();
      _status = AuthStatus.authenticated;
      _isOffline = false;
      await _saveSession(_currentUser!);
      AppLogger.setUser(_currentUser!.$id,
          email: _currentUser!.email, username: _currentUser!.name);
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
      AppLogger.setUser(_currentUser!.$id,
          email: _currentUser!.email, username: _currentUser!.name);
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
    _revalidationTimer?.cancel();
    _revalidationTimer = null;
    AppLogger.clearUser();
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

  @visibleForTesting
  static List<int> compressBackup(List<int> bytes) => IO.gzip.encode(bytes);

  @visibleForTesting
  static List<int> decompressBackup(List<int> bytes) => IO.gzip.decode(bytes);

  @visibleForTesting
  static String backupHash(List<int> bytes) =>
      sha256.convert(bytes).toString();
  Future<void> uploadBackup() async {
    return AppLogger.trace<void>('backup.upload', 'backup', () async {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = IO.File('${dir.path}/${DB.liveDatabaseFileName}');
        if (!await file.exists()) return;

        final fileId = 'backup_${_currentUser!.$id}.isar.gz';
        final fileBytes = await file.readAsBytes();

        // Skip re-uploading when the local DB has not changed since last time.
        final hash = sha256.convert(fileBytes).toString();
        final lastHash = await _secureStorage.read(key: KEY_LAST_BACKUP_HASH);
        if (lastHash == hash) {
          AppLogger.debug('Backup unchanged, skipping upload',
              data: {'area': 'backup.upload'});
          return;
        }

        final compressed = IO.gzip.encode(fileBytes);

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
          file: InputFile.fromBytes(
            bytes: compressed,
            filename: 'backup_${_currentUser!.$id}.isar.gz',
          ),
        );
        await _secureStorage.write(key: KEY_LAST_BACKUP_HASH, value: hash);
        AppLogger.info('Backup uploaded',
            data: {'area': 'backup.upload', 'sizeBytes': fileBytes.length});
      } catch (e, st) {
        await AppLogger.captureException(e,
            stackTrace: st, area: 'backup.upload');
        rethrow;
      }
    }, data: {'userId': _currentUser?.$id});
  }

  Future<void> downloadBackup() async {
    return AppLogger.trace<void>('backup.download', 'backup', () async {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final filePath = '${dir.path}/${DB.liveDatabaseFileName}';
        final fileId = 'backup_${_currentUser!.$id}.isar.gz';

        final response = await storage!.getFileDownload(
          bucketId: AppwriteConfig.bucketId,
          fileId: fileId,
        );

        final decompressed = IO.gzip.decode(response);
        final file = IO.File(filePath);
        await file.writeAsBytes(decompressed);
        // Invalidate the skip marker so the next upload is not skipped.
        await _secureStorage.delete(key: KEY_LAST_BACKUP_HASH);
        AppLogger.info('Backup downloaded',
            data: {'area': 'backup.download'});
      } catch (e, st) {
        await AppLogger.captureException(e,
            stackTrace: st, area: 'backup.download');
        rethrow;
      }
    }, data: {'userId': _currentUser?.$id});
  }

  void uploadPaymentReceipt({required IO.File receipt}) {}

  Future<User> setSubscriptionPlan(int s) {
    return account.updatePrefs(prefs: {
      'subscriptionPlan': s,
      'subscriptionExpiry':
          DateTime.now().add(Duration(days: s)).toIso8601String(),
    });
  }
}
