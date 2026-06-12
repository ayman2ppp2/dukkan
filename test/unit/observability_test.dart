import 'package:dukkan/core/observability.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
