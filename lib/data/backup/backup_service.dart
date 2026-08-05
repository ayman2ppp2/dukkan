import 'dart:io';

import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/core/observability.dart';
import 'package:dukkan/core/pool/isolate_pool.dart';
import 'package:dukkan/models/Expense.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:dukkan/models/Product.dart';
import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:path_provider/path_provider.dart';

RootIsolateToken? _getRootIsolateToken() {
  return RootIsolateToken.instance;
}

class BackupService {
  final DB db;
  BackupService(this.db);

  Future<void> createLocalBackup() async {
    final backupFilePath =
        '${(await db.getDocumentsDirectory()).path}/backup.isar';
    final backupFile = File(backupFilePath);

    if (await backupFile.exists()) {
      await backupFile.delete();
    }

    await db.isar!.copyToFile(backupFilePath);
    AppLogger.info('Local backup created', data: {'area': 'backup.local'});
  }

  Future<void> closeAllIsarInstances() async {
    IsolatePool pool = await Pool.init();
    final token = _getRootIsolateToken();
    if (token == null) {
      AppLogger.warning('RootIsolateToken not available',
          data: {'area': 'database.isolate'});
      return;
    }
    List<Future> futures = [];
    for (var i = 0; i < pool.numberOfIsolates; i++) {
      futures.add(pool.scheduleJob(StopIsar(map: {'1': token})));
    }
    await Future.wait(futures);
  }

  Future<IsolatePool> reOpenPool() async {
    return Pool.reInit();
  }

  Future<void> useLocalBacup() async {
    final dir = await db.getDocumentsDirectory();
    await _replaceLiveIsarWithFile('${dir.path}/backup.isar');
  }

  Future<void> windows() async {
    final dir = await db.getDocumentsDirectory();
    await _replaceLiveIsarWithFile('${dir.path}/backup.isar.received');
  }

  Future<void> _replaceLiveIsarWithFile(String sourcePath) async {
    final dir = await db.getDocumentsDirectory();
    final livePath = '${dir.path}/${db.isarInstanceName}.isar';
    final sourceFile = File(sourcePath);
    final liveFile = File(livePath);
    final bakFile = File('$livePath.bak');

    await _verifyIsarFile(sourcePath);
    if (!db.usesOverriddenDocumentsDirectory) {
      await closeAllIsarInstances();
    }
    await db.isar!.close();

    if (await bakFile.exists()) {
      await bakFile.delete();
    }
    if (await liveFile.exists()) {
      await liveFile.rename(bakFile.path);
    }

    try {
      await sourceFile.copy(livePath);
      db.isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: db.isarInstanceName,
      );
      if (await bakFile.exists()) {
        await bakFile.delete();
      }
    } catch (e) {
      if (await liveFile.exists()) {
        await liveFile.delete();
      }
      if (await bakFile.exists()) {
        await bakFile.rename(livePath);
        db.isar = await Isar.open(
          [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
          directory: dir.path,
          name: db.isarInstanceName,
        );
      }
      rethrow;
    }
  }

  Future<void> _verifyIsarFile(String sourcePath) async {
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Backup file not found at $sourcePath');
    }
    if (await sourceFile.length() < 4096) {
      throw Exception('Backup file is too small to be a valid database');
    }

    final tempDir = await db.getDocumentsDirectory();
    final verifyName = 'isar_verify_${DateTime.now().microsecondsSinceEpoch}';
    final verifyPath = '${tempDir.path}/$verifyName.isar';
    Isar? verifyIsar;

    try {
      await sourceFile.copy(verifyPath);
      verifyIsar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: tempDir.path,
        name: verifyName,
      );
      await verifyIsar.close();
      verifyIsar = null;
    } catch (e) {
      throw Exception('Backup file is corrupted or invalid: $e');
    } finally {
      if (verifyIsar != null) {
        try {
          await verifyIsar.close();
        } catch (_) {}
      }
      final verifyFile = File(verifyPath);
      if (await verifyFile.exists()) {
        await verifyFile.delete();
      }
    }
  }
}

class StopIsar extends PooledJob<bool> {
  Map map;
  StopIsar({required this.map});
  @override
  Future<bool> job() async {
    BackgroundIsolateBinaryMessenger.ensureInitialized(map['1']);

    Isar isar;
    try {
      final dir = await getApplicationDocumentsDirectory();
      isar = await Isar.open(
        [LogSchema, ProductSchema, LoanerSchema, OwnerSchema, ExpenseSchema],
        directory: dir.path,
        name: 'isarInstance',
      );
    } catch (e) {
      final fallbackDir = await getApplicationDocumentsDirectory();
      isar = await DB.openIsarSafely(fallbackDir.path);
    }
    return isar.close();
  }
}
