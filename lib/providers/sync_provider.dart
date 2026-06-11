import 'dart:io' as IO;
import 'package:appwrite/appwrite.dart';
import 'package:dukkan/core/appwrite_config.dart';
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
      final file = IO.File('${dir.path}/isarinstance.isar');
      final fileId = 'backup_$userId.isar';

      if (!await file.exists()) {
        print('Backup file does not exist at ${file.path}');
        return;
      }

      try {
        await storage.getFile(bucketId: AppwriteConfig.bucketId, fileId: fileId);
        await storage.deleteFile(bucketId: AppwriteConfig.bucketId, fileId: fileId);
        print('Existing backup deleted.');
      } catch (e) {
        if (e.toString().contains('File not found')) {
          print('No existing backup found. Proceeding with upload.');
        }
      }

      await storage.createFile(
        bucketId: AppwriteConfig.bucketId,
        fileId: fileId,
        file: InputFile(path: file.path, filename: 'backup.isar'),
      );
      print('Backup uploaded successfully');
    } catch (e) {
      print('Error uploading backup: $e');
    }
    notifyListeners();
  }

  Future<void> downloadBackup(String userId) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileId = 'backup_$userId.isar';

      final fileBytes = await storage.getFileDownload(bucketId: AppwriteConfig.bucketId, fileId: fileId);
      final saveFile = IO.File('${dir.path}/downloaded_backup.isar');
      await saveFile.writeAsBytes(fileBytes);
      print('Backup downloaded successfully');
    } catch (e) {
      print('Error downloading backup: $e');
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