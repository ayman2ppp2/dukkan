import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dukkan/core/db.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ShareProvider extends ChangeNotifier {
  late DB db;
  List<Widget> shareList = [];

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
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final NetworkInfo _networkInfo = NetworkInfo();

    String? wifiIp = await _networkInfo.getWifiIP();

    if (wifiIp == null) {
      shareList.add(Text('No IP address found'));
      notifyListeners();
      return;
    }

    shareList.add(QrImageView(data: '$wifiIp:30000'));
    notifyListeners();

    var te = await getApplicationDocumentsDirectory();

    void handleHttpRequest(HttpRequest request) async {
      final fileName = request.uri.pathSegments.last;
      if (fileName == 'version') {
        String version = packageInfo.version;
        request.response.write(version);
        await request.response.close();
        shareList.add(Text('vsersion sent'));
        notifyListeners();
      } else {
        final file = File('${te.path}/$fileName');
        if (await file.exists()) {
          print('Sending file: $fileName');
          shareList.add(Text('Sending file: $fileName'));
          notifyListeners();

          try {
            var mimeType = lookupMimeType(fileName) ?? 'application/octet-stream';
            var fileSize = await file.length();
            request.response.headers.set(HttpHeaders.contentTypeHeader, mimeType);
            request.response.headers.set(HttpHeaders.contentLengthHeader, fileSize);
            request.response.headers.set(HttpHeaders.contentDisposition, 'attachment; filename="$fileName"');

            final fileStream = file.openRead();
            await for (final chunk in fileStream) {
              request.response.add(chunk);
            }
            await request.response.flush();
            await request.response.close();
            shareList.add(Text('File sent: $fileName'));
            notifyListeners();
          } catch (error) {
            print('Error sending file: $error');
            try {
              request.response.statusCode = HttpStatus.internalServerError;
              request.response.write('Error sending file');
              await request.response.close();
            } catch (_) {}
          }
        } else {
          print('File not found: $fileName');
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('File not found: $fileName');
          request.response.close();
        }
      }
    }

    try {
      final server = await HttpServer.bind(wifiIp, 30000);
      print('Server listening on ${server.address.address}:${server.port}');
      shareList.add(Text('Server listening on ${server.address.address}:${server.port}'));
      notifyListeners();

      await for (HttpRequest request in server) {
        if (request.uri.pathSegments.last == 'shutdown') {
          request.response.write('server is down');
          request.response.close();
          print('Shutting down server...');
          shareList.add(Text('Server shutting down...'));
          notifyListeners();
          await server.close();
          shareList.add(Text('Server is down'));
          notifyListeners();
          break;
        } else {
          handleHttpRequest(request);
        }
      }
    } catch (e) {
      print('Error starting server: $e');
      shareList.add(Text('Error starting server: $e'));
      notifyListeners();
    }
  }

  Future<void> syncFromServer(String ip) async {
    String version = '';
    var te = await getApplicationDocumentsDirectory();
    Dio dio = Dio();

    Future<void> createBackup() async {
      await db.createLocalBackup();
      shareList.add(Text('Backup created for : isarInstance.isar'));
      notifyListeners();
    }

    await createBackup();

    try {
      try {
        var versionResponse = await dio.get('http://$ip/version');
        version = versionResponse.data.toString();
        shareList.add(Text(version));
        notifyListeners();
      } catch (e) {
        shareList.add(Text('Error fetching version: $e'));
        notifyListeners();
        return;
      }

      List<String> fileNames;
      if (version.startsWith('2.2.')) {
        fileNames = ['inventoryv2.2.0.hive', 'logsv2.2.0.hive', 'ownersv2.2.0.hive', 'loanersv2.2.0.hive', 'shutdown'];
      } else if (version.startsWith('2.3.') || version.startsWith('2.4.')) {
        fileNames = ['isarInstance.isar', 'shutdown'];
      } else {
        shareList.add(Text('Unsupported version: $version'));
        notifyListeners();
        fileNames = ['inventoryv2.2.0.hive', 'logsv2.2.0.hive', 'ownersv2.2.0.hive', 'loanersv2.2.0.hive', 'shutdown'];
      }

      for (var fileName in fileNames) {
        var filePath = Platform.isWindows ? '${te.path}/$fileName+1' : '${te.path}/$fileName';

        if (fileName == 'shutdown') {
          try {
            var response = await dio.get('http://$ip/shutdown');
            shareList.add(Text(response.data));
            notifyListeners();
          } catch (e) {
            shareList.add(Text('Error shutting down the server: $e'));
            notifyListeners();
          }
          continue;
        }

        try {
          shareList.add(Text('receiving : $fileName'));
          notifyListeners();
          var response = await dio.download('http://$ip/$fileName', filePath).then((value) {
            if (Platform.isWindows) {
              db.windows();
              return value;
            }
            return value;
          });

          if (response.statusCode == 200) {
            shareList.add(Text('File received: $fileName'));
            notifyListeners();
          } else {
            shareList.add(Text('Error receiving $fileName: ${response.statusCode}'));
            notifyListeners();
          }
        } catch (e) {
          shareList.add(Text('Failed to download $fileName: $e'));
          notifyListeners();
        }
      }
    } catch (e) {
      shareList.add(Text('Error: $e'));
    }
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}