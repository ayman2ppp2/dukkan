import 'package:dukkan/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('backup helpers', () {
    test('gzip round-trips the database bytes', () {
      final original = List<int>.generate(10000, (i) => i % 251);
      final compressed = AuthAPI.compressBackup(original);
      final restored = AuthAPI.decompressBackup(compressed);
      expect(restored, original);
      // Compression should shrink repetitive data by a good margin.
      expect(compressed.length, lessThan(original.length));
    });

    test('hash is stable for identical bytes and changes when bytes change', () {
      final bytes = [1, 2, 3, 4, 5];
      expect(AuthAPI.backupHash(bytes), AuthAPI.backupHash(List.of(bytes)));

      final mutated = List.of(bytes)..[0] = 9;
      expect(AuthAPI.backupHash(mutated), isNot(AuthAPI.backupHash(bytes)));
    });
  });
}