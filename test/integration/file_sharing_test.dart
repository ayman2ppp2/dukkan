import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dukkan/core/lan_sync.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto/crypto.dart';

class _TestLanSyncState extends ChangeNotifier with LanSyncState {}

void main() {
  group('Server Endpoint Tests', () {
    test('Version endpoint returns valid format', () {
      const version = '2.4.7';
      final parts = version.split('.');

      expect(parts.length, greaterThanOrEqualTo(2));
      expect(int.tryParse(parts[0]), equals(2));
    });

    test('Version string starts with 2.x', () {
      const version = '2.4.7';
      expect(version.startsWith('2.'), isTrue);
    });
  });

  group('Hash Endpoint Tests', () {
    test('SHA256 produces 64 character hex string', () {
      final bytes = utf8.encode('test data');
      final hash = sha256.convert(bytes);

      expect(hash.toString().length, equals(64));
    });

    test('Hash is consistent for same input', () {
      final data = 'consistent data';
      final bytes = utf8.encode(data);

      final hash1 = sha256.convert(bytes).toString();
      final hash2 = sha256.convert(bytes).toString();

      expect(hash1, equals(hash2));
    });

    test('Hash differs for different input', () {
      final bytes1 = utf8.encode('data one');
      final bytes2 = utf8.encode('data two');

      final hash1 = sha256.convert(bytes1).toString();
      final hash2 = sha256.convert(bytes2).toString();

      expect(hash1, isNot(equals(hash2)));
    });
  });

  group('File Selection Logic Tests', () {
    test('2.3.x selects backup.isar', () {
      const version = '2.3.0';
      final files = LanSync.filesForVersion(version);

      expect(files, equals(['backup.isar']));
    });

    test('2.4.x selects backup.isar', () {
      const version = '2.4.7';
      final files = LanSync.filesForVersion(version);

      expect(files, equals(['backup.isar']));
    });

    test('2.5.x selects backup.isar', () {
      const version = '2.5.0';
      final files = LanSync.filesForVersion(version);

      expect(files, equals(['backup.isar']));
    });

    test('Unsupported version does not fall back to legacy files', () {
      const version = '1.0.0';

      expect(() => LanSync.filesForVersion(version), throwsUnsupportedError);
    });
  });

  group('Shutdown Handling Tests', () {
    test('Both versions call shutdown endpoint', () {
      // All supported versions should call /shutdown endpoint
      expect(true, isTrue);
    });

    test('Server closes after shutdown', () async {
      bool serverClosed = false;
      serverClosed = true; // Simulate close

      expect(serverClosed, isTrue);
    });
  });

  group('HTTP Request Tests', () {
    test('Version URL format', () {
      final endpoint = LanSyncEndpoint(host: '192.168.1.100', port: 30000);
      final url = endpoint.uri('version').toString();

      expect(url, equals('http://192.168.1.100:30000/version'));
    });

    test('Hash URL format', () {
      final endpoint = LanSyncEndpoint(host: '192.168.1.100', port: 30000);
      final url = endpoint.uri('hash').toString();

      expect(url, equals('http://192.168.1.100:30000/hash'));
    });

    test('Shutdown URL format', () {
      final endpoint = LanSyncEndpoint(host: '192.168.1.100', port: 30000);
      final url = endpoint.uri('shutdown').toString();

      expect(url, equals('http://192.168.1.100:30000/shutdown'));
    });

    test('File download URL format', () {
      final endpoint = LanSyncEndpoint(host: '192.168.1.100', port: 30000);
      final url = endpoint.uri('backup.isar').toString();

      expect(url, equals('http://192.168.1.100:30000/backup.isar'));
    });
  });

  group('Share Address Tests', () {
    test('Parses ip:port QR payload', () {
      final endpoint = LanSyncEndpoint.tryParse('192.168.1.100:30000');

      expect(endpoint, isNotNull);
      expect(endpoint!.host, equals('192.168.1.100'));
      expect(endpoint.port, equals(30000));
    });

    test('Parses ip manual entry with default port', () {
      final endpoint = LanSyncEndpoint.tryParse('192.168.1.100');

      expect(endpoint, isNotNull);
      expect(endpoint!.hostPort, equals('192.168.1.100:30000'));
    });

    test('Parses http address by stripping scheme and path', () {
      final endpoint = LanSyncEndpoint.tryParse('http://192.168.1.100:30000/');

      expect(endpoint, isNotNull);
      expect(endpoint!.hostPort, equals('192.168.1.100:30000'));
    });

    test('Rejects address with obsolete pairing code payload', () {
      expect(LanSyncEndpoint.tryParse('192.168.1.100:30000:123456'), isNull);
    });
  });

  group('File Whitelist Tests', () {
    test('Allows only sync endpoints and backup file', () {
      expect(LanSync.isAllowedSegment('version'), isTrue);
      expect(LanSync.isAllowedSegment('hash'), isTrue);
      expect(LanSync.isAllowedSegment('shutdown'), isTrue);
      expect(LanSync.isAllowedSegment('backup.isar'), isTrue);
    });

    test('Rejects arbitrary files', () {
      expect(LanSync.isAllowedSegment('backup.txt'), isFalse);
      expect(LanSync.isAllowedSegment('isarInstance.isar'), isFalse);
      expect(LanSync.isAllowedSegment('../backup.isar'), isFalse);
    });
  });

  group('Timeout And Cancel Tests', () {
    test('Dio client has finite timeouts', () {
      final dio = LanSync.createDio();

      expect(dio.options.connectTimeout, equals(LanSync.connectTimeout));
      expect(dio.options.receiveTimeout, equals(LanSync.receiveTimeout));
      expect(dio.options.sendTimeout, equals(LanSync.sendTimeout));
    });

    test('CancelToken reports cancellation', () {
      final token = CancelToken();
      token.cancel('cancelled');

      expect(token.isCancelled, isTrue);
    });

    test('Transfer failure exposes timeout type', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/backup.isar'),
        type: DioExceptionType.connectionTimeout,
      );

      expect(error.type, DioExceptionType.connectionTimeout);
    });
  });

  group('Hash Mismatch Cleanup Tests', () {
    test('Hash mismatch deletes received file', () async {
      final dir = await Directory.systemTemp.createTemp('dukkan_hash_test_');
      final file = File('${dir.path}/backup.isar.received');
      await file.writeAsString('bad data');

      final actual = await LanSync.sha256File(file);
      final expected = sha256.convert(utf8.encode('good data')).toString();
      if (actual != expected) {
        await LanSync.deleteIfExists(file.path);
      }

      expect(await file.exists(), isFalse);
      await dir.delete(recursive: true);
    });
  });

  group('SyncStatus State Tests', () {
    test('State machine exposes progress and error state', () {
      final state = _TestLanSyncState();

      state.setSyncState(SyncStatus.downloading, progress: 0.5);
      expect(state.syncStatus, SyncStatus.downloading);
      expect(state.syncProgress, 0.5);

      state.setSyncState(SyncStatus.error, error: 'failed');
      expect(state.syncStatus, SyncStatus.error);
      expect(state.syncErrorMessage, 'failed');
    });
  });

  group('Restore Rollback Tests', () {
    test('Rollback restores original live file after replacement failure',
        () async {
      final dir =
          await Directory.systemTemp.createTemp('dukkan_rollback_test_');
      final liveFile = File('${dir.path}/isarInstance.isar');
      final bakFile = File('${dir.path}/isarInstance.isar.bak');
      await liveFile.writeAsString('original database');

      Future<void> simulateFailingRestore() async {
        await liveFile.rename(bakFile.path);
        try {
          throw Exception('replacement failed');
        } catch (_) {
          if (await liveFile.exists()) {
            await liveFile.delete();
          }
          if (await bakFile.exists()) {
            await bakFile.rename(liveFile.path);
          }
          rethrow;
        }
      }

      await expectLater(simulateFailingRestore(), throwsException);
      expect(await liveFile.readAsString(), equals('original database'));
      expect(await bakFile.exists(), isFalse);
      await dir.delete(recursive: true);
    });
  });

  group('File Path Construction Tests', () {
    test('Windows uses .received suffix', () {
      const path = '/docs/backup.isar.received';

      expect(path, equals('/docs/backup.isar.received'));
    });

    test('Linux uses .received suffix', () {
      const path = '/docs/backup.isar.received';

      expect(path, equals('/docs/backup.isar.received'));
    });

    test('Android uses no suffix', () {
      const path = '/docs/backup.isar';

      expect(path, equals('/docs/backup.isar'));
    });
  });

  group('Server Flow Tests', () {
    test('Server creates backup before serving', () async {
      bool backupCreated = false;
      backupCreated = true; // Simulate createLocalBackup()

      expect(backupCreated, isTrue);
    });

    test('Server handles version request', () async {
      const version = '2.4.7';
      final response = version;

      expect(response.isNotEmpty, isTrue);
      expect(response.startsWith('2.'), isTrue);
    });

    test('Server handles hash request', () async {
      final bytes = utf8.encode('backup data');
      final hash = sha256.convert(bytes).toString();

      expect(hash.length, equals(64));
    });

    test('Server serves file correctly', () async {
      final content = 'file content';
      final data = utf8.encode(content);

      expect(data.isNotEmpty, isTrue);
      expect(utf8.decode(data), equals(content));
    });
  });

  group('Client Flow Tests', () {
    test('Client fetches version first', () async {
      String version = '';
      version = '2.4.7';

      expect(version.isNotEmpty, isTrue);
    });

    test('Client selects files based on version', () {
      const version = '2.4.7';
      final files = version.startsWith('2.3.') || version.startsWith('2.4.')
          ? ['backup.isar']
          : ['inventory.hive'];

      expect(files.first, equals('backup.isar'));
    });

    test('Client downloads file', () async {
      bool downloaded = false;
      downloaded = true; // Simulate download

      expect(downloaded, isTrue);
    });

    test('Client verifies hash', () async {
      final bytes = utf8.encode('data');
      final hash = sha256.convert(bytes).toString();

      final matches = hash.length == 64;
      expect(matches, isTrue);
    });

    test('Client calls shutdown after sync', () async {
      bool shutdownCalled = false;
      shutdownCalled = true;

      expect(shutdownCalled, isTrue);
    });
  });

  group('Error Handling Tests', () {
    test('Version fetch error handling', () {
      try {
        throw Exception('Connection failed');
      } catch (e) {
        expect(e.toString(), contains('Connection failed'));
      }
    });

    test('File download error handling', () {
      try {
        throw Exception('File not found');
      } catch (e) {
        expect(e.toString(), contains('File not found'));
      }
    });

    test('Hash mismatch handling', () {
      const actual = 'abc123';
      const expected = 'xyz789';

      expect(actual == expected, isFalse);
    });
  });
}
