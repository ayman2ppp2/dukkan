import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

enum SyncStatus {
  idle,
  connecting,
  downloading,
  verifying,
  restoring,
  done,
  error,
  cancelled,
}

extension SyncStatusLabel on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.idle:
        return 'Ready';
      case SyncStatus.connecting:
        return 'Connecting';
      case SyncStatus.downloading:
        return 'Downloading';
      case SyncStatus.verifying:
        return 'Verifying';
      case SyncStatus.restoring:
        return 'Restoring';
      case SyncStatus.done:
        return 'Done';
      case SyncStatus.error:
        return 'Error';
      case SyncStatus.cancelled:
        return 'Cancelled';
    }
  }
}

mixin LanSyncState on ChangeNotifier {
  SyncStatus syncStatus = SyncStatus.idle;
  String syncMessage = SyncStatus.idle.label;
  String? syncErrorMessage;
  double syncProgress = 0;
  String? pairingAddress;
  String? pairingCode;

  void setSyncState(
    SyncStatus status, {
    String? message,
    String? error,
    double? progress,
  }) {
    syncStatus = status;
    syncMessage = message ?? status.label;
    syncErrorMessage = error;
    if (progress != null) {
      syncProgress = progress.clamp(0, 1).toDouble();
    }
    notifyListeners();
  }
}

class LanSyncEndpoint {
  LanSyncEndpoint({
    required this.host,
    required this.port,
    required this.code,
  });

  final String host;
  final int port;
  final String code;

  String get hostPort => '$host:$port';
  String get qrPayload => '$host:$port:$code';

  Uri uri(String path) {
    return Uri.parse('http://$hostPort/$path').replace(
      queryParameters: {'code': code},
    );
  }

  static LanSyncEndpoint? tryParse(String raw) {
    final input = raw.trim().replaceFirst(RegExp(r'^https?://'), '');
    if (input.isEmpty) return null;

    final parts = input.split(':').where((part) => part.isNotEmpty).toList();
    if (parts.length == 2 && LanSync.isPairingCode(parts[1])) {
      return LanSyncEndpoint(
          host: parts[0], port: LanSync.port, code: parts[1]);
    }
    if (parts.length == 3 && LanSync.isPairingCode(parts[2])) {
      final port = int.tryParse(parts[1]);
      if (port == null || port <= 0 || port > 65535) return null;
      return LanSyncEndpoint(host: parts[0], port: port, code: parts[2]);
    }
    return null;
  }
}

class LanSync {
  static const int port = 30000;
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const String backupFileName = 'backup.isar';
  static const Set<String> allowedSegments = {
    'version',
    'hash',
    'shutdown',
    backupFileName,
  };

  static String generatePairingCode({Random? random}) {
    final generator = random ?? Random.secure();
    return (generator.nextInt(900000) + 100000).toString();
  }

  static bool isPairingCode(String value) {
    return RegExp(r'^\d{6}$').hasMatch(value);
  }

  static bool isAllowedSegment(String value) {
    return allowedSegments.contains(value);
  }

  static bool isAuthorizedRequest(HttpRequest request, String code) {
    return request.uri.queryParameters['code'] == code;
  }

  static Dio createDio() {
    return Dio(BaseOptions(
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      sendTimeout: sendTimeout,
    ));
  }

  static List<String> filesForVersion(String version) {
    final parts = version.split('.');
    if (parts.length < 2) {
      throw UnsupportedError('Unsupported LAN sync version: $version');
    }
    final major = int.tryParse(parts[0]);
    final minor = int.tryParse(parts[1]);
    if (major == 2 && minor != null && minor >= 3) {
      return [backupFileName];
    }
    throw UnsupportedError('Unsupported LAN sync version: $version');
  }

  static Future<String> sha256File(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  static Future<void> deleteIfExists(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
