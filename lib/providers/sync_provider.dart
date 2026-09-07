import 'package:appwrite/appwrite.dart';
import 'package:dukkan/core/config/appwrite_config.dart';
import 'package:dukkan/core/observability.dart';
import 'package:flutter/widgets.dart';

class SyncProvider extends ChangeNotifier {
  Client client = Client();
  late final Storage storage;

  SyncProvider() {
    init();
  }

  @visibleForTesting
  SyncProvider.forTesting() {
    storage = Storage(client);
  }

  void init() {
    if (!AppwriteConfig.isConfigured) {
      AppLogger.warning('Appwrite is not configured; add --dart-define values',
          data: {'area': 'appwrite.config'});
    }
    client
        .setEndpoint(AppwriteConfig.endpoint)
        .setProject(AppwriteConfig.projectId);
    if (!AppwriteConfig.isCloud) {
      client.setSelfSigned();
    }
    storage = Storage(client);
  }

  Future<void> refresh() async {
    notifyListeners();
  }
}