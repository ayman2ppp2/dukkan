import 'dart:io';

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
        return 'جاهز';
      case SyncStatus.connecting:
        return 'جار الاتصال';
      case SyncStatus.downloading:
        return 'جار التنزيل';
      case SyncStatus.verifying:
        return 'جار التحقق';
      case SyncStatus.restoring:
        return 'جار الاستعادة';
      case SyncStatus.done:
        return 'اكتمل';
      case SyncStatus.error:
        return 'خطأ';
      case SyncStatus.cancelled:
        return 'تم الإلغاء';
    }
  }
}

mixin LanSyncState on ChangeNotifier {
  SyncStatus syncStatus = SyncStatus.idle;
  String syncMessage = SyncStatus.idle.label;
  String? syncErrorMessage;
  double syncProgress = 0;
  String? shareAddress;

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
  });

  final String host;
  final int port;

  String get hostPort => '$host:$port';
  String get qrPayload => hostPort;

  Uri uri(String path) {
    return Uri.parse('http://$hostPort/$path');
  }

  static LanSyncEndpoint? tryParse(String raw) {
    final input =
        raw.trim().replaceFirst(RegExp(r'^https?://'), '').split('/').first;
    if (input.isEmpty) return null;

    final parts = input.split(':').where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) {
      return LanSyncEndpoint(host: parts[0], port: LanSync.port);
    }
    if (parts.length == 2) {
      final port = int.tryParse(parts[1]);
      if (port == null || port <= 0 || port > 65535) return null;
      return LanSyncEndpoint(host: parts[0], port: port);
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

  static bool isAllowedSegment(String value) {
    return allowedSegments.contains(value);
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
