import 'dart:io';

import 'package:dukkan/core/db.dart';
import 'package:isar_community/isar.dart';

bool _isarCoreInitialized = false;

class TestDbHandle {
  TestDbHandle(this.db, this.directory);

  final DB db;
  final Directory directory;

  Future<void> close() async {
    await db.isar?.close(deleteFromDisk: true);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}

Future<TestDbHandle> openTestDb({String? name}) async {
  if (!_isarCoreInitialized) {
    final localCore = File('libisar.so');
    if (!await localCore.exists()) {
      await Isar.initializeIsarCore(download: true);
    }
    _isarCoreInitialized = true;
  }
  final directory = await Directory.systemTemp.createTemp('dukkan_test_db_');
  final db = await DB.createForTesting(
    directoryPath: directory.path,
    name: name ?? 'isar_${DateTime.now().microsecondsSinceEpoch}',
  );
  return TestDbHandle(db, directory);
}
