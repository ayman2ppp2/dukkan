import 'dart:io' as IO;
import 'package:appwrite/appwrite.dart';
import 'package:dukkan/core/appwrite_config.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/core/observability.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';

class SyncProvider extends ChangeNotifier {
  Client client = Client();
  late final Storage storage;

  SyncProvider() {
    init();
  }

  void init() {
    client
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    if (!AppwriteConfig.isCloud) {
      client.setSelfSigned();
    }
    storage = Storage(client);
  }

  Future<void> uploadBackup(String userId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = IO.File('${dir.path}/${DB.liveDatabaseFileName}');
      final fileId = 'backup_$userId.isar';

      if (!await file.exists()) {
        AppLogger.warning('Backup file missing before upload',
            data: {'area': 'backup.upload', 'filePath': file.path});
        return;
      }

      try {
        await storage.getFile(
            bucketId: AppwriteConfig.bucketId, fileId: fileId);
        await storage.deleteFile(
            bucketId: AppwriteConfig.bucketId, fileId: fileId);
      } catch (e) {
        if (e.toString().contains('File not found')) {
          AppLogger.debug('No existing remote backup before upload',
              data: {'area': 'backup.upload'});
        }
      }

      await storage.createFile(
        bucketId: AppwriteConfig.bucketId,
        fileId: fileId,
        file: InputFile(path: file.path, filename: 'backup.isar'),
      );
      AppLogger.info('Backup uploaded', data: {'area': 'backup.upload'});
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'backup.upload');
      rethrow;
    }
    notifyListeners();
  }

  Future<void> downloadBackup(String userId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileId = 'backup_$userId.isar';

      final fileBytes = await storage.getFileDownload(
          bucketId: AppwriteConfig.bucketId, fileId: fileId);
      final saveFile = IO.File('${dir.path}/downloaded_backup.isar');
      await saveFile.writeAsBytes(fileBytes);
      AppLogger.info('Backup downloaded', data: {'area': 'backup.download'});
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'backup.download');
      rethrow;
    }
    notifyListeners();
  }

  Future<bool> hasBackup(String userId) async {
    try {
      final fileId = 'backup_$userId.isar';
      await storage.getFile(bucketId: AppwriteConfig.bucketId, fileId: fileId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}
