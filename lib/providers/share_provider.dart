import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/core/lan_sync.dart';
import 'package:dukkan/core/observability.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:restart_app/restart_app.dart';

class ShareProvider extends ChangeNotifier with LanSyncState {
  late DB db;
  List<Widget> shareList = [];
  CancelToken? _syncCancelToken;
  HttpServer? _syncServer;
  bool get canCancelSync => _syncCancelToken != null || _syncServer != null;

  ShareProvider() {
    init();
  }

  Future<void> init() async {
    db = await DB.getInstance();
  }

  void clearShareList() {
    shareList.clear();
    notifyListeners();
  }

  Future<void> runServer() async {
    await _syncServer?.close(force: true);
    _syncServer = null;
    setSyncState(
      SyncStatus.connecting,
      message: 'جار تجهيز خادم المزامنة المحلية...',
      progress: 0,
    );

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final networkInfo = NetworkInfo();
      final wifiIp = await networkInfo.getWifiIP();
      if (wifiIp == null) {
        throw Exception('لم يتم العثور على عنوان Wi-Fi');
      }

      final endpoint = LanSyncEndpoint(
        host: wifiIp,
        port: LanSync.port,
      );
      shareAddress = endpoint.qrPayload;

      await db.createLocalBackup();
      final dir = await getApplicationDocumentsDirectory();
      final server = await HttpServer.bind(wifiIp, LanSync.port);
      server.idleTimeout = LanSync.receiveTimeout;
      _syncServer = server;

      setSyncState(
        SyncStatus.done,
        message: 'الخادم جاهز. استخدم عنوان المشاركة الظاهر.',
        progress: 1,
      );

      await for (final request in server) {
        final shouldShutdown = await _handleLanRequest(
          request,
          packageInfo.version,
          dir,
        );
        if (shouldShutdown) {
          await server.close();
          break;
        }
      }
      if (syncStatus != SyncStatus.cancelled) {
        setSyncState(SyncStatus.done, message: 'تم إيقاف الخادم', progress: 1);
      }
    } catch (e, st) {
      await AppLogger.captureException(e, stackTrace: st, area: 'sync.server');
      if (syncStatus != SyncStatus.cancelled) {
        setSyncState(
          SyncStatus.error,
          message: 'فشل تشغيل الخادم',
          error: UserSafeMessages.syncFailed,
        );
      }
    } finally {
      _syncServer = null;
      notifyListeners();
    }
  }

  Future<void> syncFromServer(String input) async {
    final endpoint = LanSyncEndpoint.tryParse(input);
    if (endpoint == null) {
      setSyncState(
        SyncStatus.error,
        message: 'عنوان المشاركة غير صحيح',
        error: 'استخدم IP أو IP:PORT من جهاز الإرسال.',
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final downloadPath = _downloadedBackupPath(dir.path);
    final dio = LanSync.createDio();
    final cancelToken = CancelToken();
    _syncCancelToken = cancelToken;
    shareAddress = endpoint.qrPayload;

    try {
      setSyncState(
        SyncStatus.connecting,
        message: 'جار الاتصال بجهاز الإرسال...',
        progress: 0,
      );
      await db.createLocalBackup();

      final versionResponse = await dio.getUri(
        endpoint.uri('version'),
        cancelToken: cancelToken,
      );
      final version = versionResponse.data.toString().trim();
      final fileNames = LanSync.filesForVersion(version);
      final fileName = fileNames.single;

      await LanSync.deleteIfExists(downloadPath);
      setSyncState(
        SyncStatus.downloading,
        message: 'جار تنزيل النسخة الاحتياطية...',
        progress: 0,
      );
      final response = await dio.downloadUri(
        endpoint.uri(fileName),
        downloadPath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total <= 0) return;
          setSyncState(
            SyncStatus.downloading,
            message: 'جار تنزيل النسخة الاحتياطية...',
            progress: received / total,
          );
        },
      );
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('فشل التنزيل بالحالة ${response.statusCode}');
      }

      setSyncState(
        SyncStatus.verifying,
        message: 'جار التحقق من النسخة الاحتياطية...',
        progress: 1,
      );
      final actualHash = await LanSync.sha256File(File(downloadPath));
      final expectedHash = await dio
          .getUri(endpoint.uri('hash'), cancelToken: cancelToken)
          .then((response) => response.data.toString().trim());
      if (actualHash != expectedHash) {
        await LanSync.deleteIfExists(downloadPath);
        throw Exception('فشل التحقق من تطابق النسخة الاحتياطية');
      }

      await _shutdownPeer(dio, endpoint, cancelToken);
      setSyncState(
        SyncStatus.restoring,
        message: 'جار استعادة النسخة التي تم التحقق منها...',
        progress: 1,
      );
      await _restoreDownloadedBackup();
      setSyncState(
        SyncStatus.done,
        message: 'اكتملت المزامنة بنجاح',
        progress: 1,
      );
    } on DioException catch (e, st) {
      await LanSync.deleteIfExists(downloadPath);
      if (CancelToken.isCancel(e)) {
        setSyncState(SyncStatus.cancelled, message: 'تم إلغاء المزامنة');
      } else {
        await AppLogger.captureException(e,
            stackTrace: st, area: 'sync.client');
        setSyncState(
          SyncStatus.error,
          message: 'فشلت المزامنة',
          error: UserSafeMessages.syncFailed,
        );
      }
    } catch (e, st) {
      await LanSync.deleteIfExists(downloadPath);
      await AppLogger.captureException(e, stackTrace: st, area: 'sync.client');
      setSyncState(
        SyncStatus.error,
        message: 'فشلت المزامنة',
        error: UserSafeMessages.syncFailed,
      );
    } finally {
      _syncCancelToken = null;
      notifyListeners();
    }
  }

  void cancelSync() {
    _syncCancelToken?.cancel('تم إلغاء المزامنة');
    _syncCancelToken = null;
    _syncServer?.close(force: true);
    _syncServer = null;
    setSyncState(SyncStatus.cancelled,
        message: 'تم إلغاء المزامنة', progress: 0);
  }

  Future<bool> _handleLanRequest(
    HttpRequest request,
    String version,
    Directory dir,
  ) async {
    final fileName =
        request.uri.pathSegments.isEmpty ? '' : request.uri.pathSegments.last;
    request.response.deadline = LanSync.receiveTimeout;

    if (!LanSync.isAllowedSegment(fileName)) {
      await _respond(request, HttpStatus.notFound, 'File not found');
      return false;
    }

    if (fileName == 'shutdown') {
      await _respond(request, HttpStatus.ok, 'server is down');
      return true;
    }
    if (fileName == 'version') {
      await _respond(request, HttpStatus.ok, version);
      return false;
    }

    final backupFile = File('${dir.path}/${LanSync.backupFileName}');
    if (!await backupFile.exists()) {
      await _respond(request, HttpStatus.notFound, 'Backup file not found');
      return false;
    }
    if (fileName == 'hash') {
      await _respond(
          request, HttpStatus.ok, await LanSync.sha256File(backupFile));
      return false;
    }

    try {
      final mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
      request.response.headers.set(HttpHeaders.contentTypeHeader, mimeType);
      request.response.headers.set(
        HttpHeaders.contentLengthHeader,
        await backupFile.length(),
      );
      request.response.headers.set(
        HttpHeaders.contentDisposition,
        'attachment; filename="$fileName"',
      );
      await backupFile.openRead().pipe(request.response);
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'sync.server_send');
      try {
        await _respond(
            request, HttpStatus.internalServerError, 'Error sending file');
      } catch (_) {}
    }
    return false;
  }

  Future<void> _respond(
      HttpRequest request, int statusCode, String message) async {
    request.response.statusCode = statusCode;
    request.response.write(message);
    await request.response.close();
  }

  String _downloadedBackupPath(String directoryPath) {
    if (Platform.isWindows || Platform.isLinux) {
      return '$directoryPath/${LanSync.backupFileName}.received';
    }
    return '$directoryPath/${LanSync.backupFileName}';
  }

  Future<void> _shutdownPeer(
    Dio dio,
    LanSyncEndpoint endpoint,
    CancelToken cancelToken,
  ) async {
    try {
      await dio.getUri(endpoint.uri('shutdown'), cancelToken: cancelToken);
    } catch (_) {
      // Sync has already succeeded; a shutdown failure should not roll it back.
    }
  }

  Future<void> _restoreDownloadedBackup() async {
    if (Platform.isWindows || Platform.isLinux) {
      await db.windows();
      return;
    }
    await db.useLocalBacup();
    // Keep restart after restore as a conservative safety measure.
    Restart.restartApp();
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}
