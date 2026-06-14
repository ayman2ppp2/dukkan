import 'package:appwrite/enums.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secureStorageChannel =
      MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
  });

  Map<String, String> offlineSession({required DateTime loginTime}) {
    return {
      AuthAPI.KEY_SESSION_TIME: loginTime.millisecondsSinceEpoch.toString(),
      AuthAPI.KEY_USER_EMAIL: 'owner@example.com',
      AuthAPI.KEY_USER_ID: 'user-1',
      AuthAPI.KEY_USER_NAME: 'Owner',
    };
  }

  test('valid offline session authenticates without network login', () async {
    FlutterSecureStorage.setMockInitialValues(
      offlineSession(
          loginTime: DateTime.now().subtract(const Duration(days: 1))),
    );
    final auth = AuthAPI.forTesting();

    final ok = await auth.checkOfflineSession();

    expect(ok, isTrue);
    expect(auth.status, AuthStatus.authenticated);
    expect(auth.isOffline, isTrue);
    expect(auth.email, 'owner@example.com');
  });

  test('expired offline session is rejected', () async {
    FlutterSecureStorage.setMockInitialValues(
      offlineSession(
          loginTime: DateTime.now().subtract(const Duration(days: 4))),
    );
    final auth = AuthAPI.forTesting();

    final ok = await auth.checkOfflineSession();

    expect(ok, isFalse);
    expect(auth.status, AuthStatus.uninitialized);
    expect(auth.isOffline, isFalse);
  });

  test('missing offline session keys are rejected', () async {
    FlutterSecureStorage.setMockInitialValues({
      AuthAPI.KEY_SESSION_TIME:
          DateTime.now().millisecondsSinceEpoch.toString(),
      AuthAPI.KEY_USER_EMAIL: 'owner@example.com',
    });
    final auth = AuthAPI.forTesting();

    final ok = await auth.checkOfflineSession();

    expect(ok, isFalse);
    expect(auth.status, AuthStatus.uninitialized);
  });

  test('clearing session removes offline auth keys', () async {
    FlutterSecureStorage.setMockInitialValues(
      offlineSession(loginTime: DateTime.now()),
    );
    final auth = AuthAPI.forTesting();
    final storage = FlutterSecureStorage();

    await auth.clearSessionForTesting();

    expect(await storage.read(key: AuthAPI.KEY_SESSION_TIME), isNull);
    expect(await storage.read(key: AuthAPI.KEY_USER_EMAIL), isNull);
    expect(auth.isOffline, isFalse);
  });

  test('offline session check fails safely when secure storage is unavailable',
      () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secureStorageChannel, null);
    final auth = AuthAPI.forTesting();

    final ok = await auth.checkOfflineSession();

    expect(ok, isFalse);
    expect(auth.status, AuthStatus.uninitialized);
  });

  test('oauth provider mapping uses requested provider', () {
    expect(AuthAPI.oauthProviderForTesting('google'), OAuthProvider.google);
    expect(AuthAPI.oauthProviderForTesting('github'), OAuthProvider.github);
    expect(
        () => AuthAPI.oauthProviderForTesting('unknown'), throwsArgumentError);
  });
}
