import 'dart:convert';

import 'package:dukkan/core/observability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  group('AppLogger redaction', () {
    test('redacts sensitive map fields', () {
      final safe = AppLogger.sanitizeMap({
        'email': 'owner@example.com',
        'userId': 'abc123',
        'barcode': '123456789',
        'filePath': '/tmp/isarInstance.isar',
        'itemCount': 3,
        'productCount': 2,
      });

      expect(safe['email'], '<redacted>');
      expect(safe['userId'], '<redacted>');
      expect(safe['barcode'], '<redacted>');
      expect(safe['filePath'], '<redacted>');
      expect(safe['itemCount'], 3);
      expect(safe['productCount'], 2);
    });

    test('never lets raw objects or DateTimes reach Sentry data', () {
      final when = DateTime(2026, 10, 4, 13, 3);
      final safe = AppLogger.sanitizeMap({
        'when': when,
        'nested': {'since': when},
        'product': Object(),
        'nothing': null,
        'price': 12.5,
        'flag': true,
      });

      expect(safe['when'], isA<String>());
      expect(safe['when'], when.toIso8601String());
      expect((safe['nested'] as Map)['since'], when.toIso8601String());
      expect(safe['product'], isA<String>());
      expect(safe['nothing'], isNull);
      expect(safe['price'], 12.5);
      expect(safe['flag'], true);
      // The payload Sentry serializes must be plain JSON.
      expect(() => jsonEncode(safe), returnsNormally);
    });

    test('redacts emails, pairing addresses, and backup filenames in text', () {
      final safe = AppLogger.sanitizeText(
        'user owner@example.com used 192.168.1.10:30000:123456 for backup.isar at /home/user/store/secret.txt',
      );

      expect(safe, isNot(contains('owner@example.com')));
      expect(safe, isNot(contains('123456')));
      expect(safe, isNot(contains('backup.isar')));
      expect(safe, isNot(contains('/home/user/store/secret.txt')));
      expect(safe, contains('<email>'));
      expect(safe, contains('<pairing-address>'));
      expect(safe, contains('<backup-file>'));
      expect(safe, contains('<path>'));
    });
  });

  group('UserSafeMessages', () {
    test('uses Arabic safe messages instead of raw exception text', () {
      expect(UserSafeMessages.loginFailed, contains('تعذر'));
      expect(UserSafeMessages.syncFailed, contains('فشلت المزامنة'));
      expect(UserSafeMessages.checkoutFailed, contains('فشل تسجيل الفاتورة'));
      expect(UserSafeMessages.generic, isNot(contains('Exception')));
    });
  });

  group('Sentry log configuration', () {
    test('enables Sentry Logs and installs the scrubbing filter', () {
      final options = SentryFlutterOptions();

      AppLogger.configureSentry(options);

      // Config that must not silently regress: `enableLogs` defaults to false
      // (newer SDKs gate on it), and without a `beforeSendLog` the scrubbing
      // and validation-drop would never run.
      expect(options.enableLogs, isTrue);
      expect(options.beforeSendLog, isNotNull);
      expect(options.beforeSend, isNotNull);
    });

    test('log calls are safe when Sentry was never started', () async {
      expect(() => AppLogger.debug('debug before init', data: {'a': 1}),
          returnsNormally);
      expect(() => AppLogger.info('info before init'), returnsNormally);
      await expectLater(AppLogger.warning('warning before init'), completes);
      await expectLater(
        AppLogger.captureException(StateError('boom'), area: 'test'),
        completes,
      );
    });
  });

  group('Sentry log attributes', () {
    test('keeps values typed so they stay queryable', () {
      final attributes = AppLogger.toLogAttributes({
        'area': 'checkout',
        'itemCount': 3,
        'total': 1250.5,
        'loaned': false,
        'nothing': null,
      });

      expect(attributes['area']!.value, 'checkout');
      expect(attributes['itemCount']!.value, 3);
      expect(attributes['total']!.value, 1250.5);
      expect(attributes['loaned']!.value, false);
      expect(attributes.containsKey('nothing'), isFalse);
    });

    test('an assembled log survives jsonEncode', () {
      final log = SentryLog(
        timestamp: DateTime.now(),
        level: SentryLogLevel.info,
        body: 'Checkout completed',
        attributes: AppLogger.toLogAttributes(AppLogger.sanitizeMap({
          'total': 1250.5,
          'when': DateTime(2026, 10, 5, 13, 3),
          'items': [1, 2, 3],
        })),
      );

      expect(() => jsonEncode(log.toJson()), returnsNormally);
    });
  });

  group('Sentry log filter', () {
    SentryLog buildLog({
      required String body,
      Map<String, SentryAttribute>? attributes,
    }) =>
        SentryLog(
          timestamp: DateTime.now(),
          level: SentryLogLevel.info,
          body: body,
          attributes: attributes ?? const {},
        );

    test('drops known validation messages, like beforeSend does', () {
      expect(AppLogger.filterLog(buildLog(body: 'Insufficient stock for "X"')),
          isNull);
      expect(
          AppLogger.filterLog(buildLog(body: 'Discount must be non-negative')),
          isNull);
      expect(
          AppLogger.filterLog(buildLog(body: 'Checkout completed')), isNotNull);
    });

    test('scrubs sensitive values and redacts sensitive keys', () {
      final log = AppLogger.filterLog(buildLog(
        body: 'Contact owner@example.com about the sale',
        attributes: {
          'note': SentryAttribute.string('backup at /home/user/store.isar'),
          'ownerName': SentryAttribute.string('Golden'),
          'itemCount': SentryAttribute.int(2),
        },
      ))!;

      expect(log.body, isNot(contains('owner@example.com')));
      expect(log.attributes['note']!.value,
          isNot(contains('/home/user/store.isar')));
      expect(log.attributes['ownerName']!.value, '<redacted>');
      // Non-sensitive, non-string attributes pass through untouched.
      expect(log.attributes['itemCount']!.value, 2);
    });
  });
}
