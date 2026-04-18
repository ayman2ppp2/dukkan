import 'dart:io' as IO;
import 'package:appwrite/appwrite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/widgets.dart';

class SyncProvider extends ChangeNotifier {
  Client client = Client();
  late final Storage storage;

  static const String APPWRITE_PROJECT_ID = "65e616d10bd9110e806f";
  static const String APPWRITE_URL = "https://cloud.appwrite.io/v1";
  static const String BUCKET_ID = "6762672a0033f48ae769";

  SyncProvider() {
    init();
  }

  void init() {
    client.setEndpoint(APPWRITE_URL).setProject(APPWRITE_PROJECT_ID).setSelfSigned();
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
        await storage.getFile(bucketId: BUCKET_ID, fileId: fileId);
        await storage.deleteFile(bucketId: BUCKET_ID, fileId: fileId);
        print('Existing backup deleted.');
      } catch (e) {
        if (e.toString().contains('File not found')) {
          print('No existing backup found. Proceeding with upload.');
        }
      }

      await storage.createFile(
        bucketId: BUCKET_ID,
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

      final fileBytes = await storage.getFileDownload(bucketId: BUCKET_ID, fileId: fileId);
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
      await storage.getFile(bucketId: BUCKET_ID, fileId: fileId);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}