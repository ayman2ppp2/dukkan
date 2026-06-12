import 'dart:async';
// import 'package:mime';
import 'package:dio/dio.dart';
import 'package:restart_app/restart_app.dart';
import 'package:dukkan/core/IsolatePool.dart';
import 'package:dukkan/core/lan_sync.dart';
// import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/prodStats.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/models/searchQuery.dart';
import 'package:dukkan/util/models/LowStockProduct.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:mime/mime.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../util/models/Log.dart';

RootIsolateToken? _getRootIsolateToken() {
  return RootIsolateToken.instance;
}

class Lists extends ChangeNotifier with LanSyncState {
  late DB db;

  late IsolatePool pool;
  List<Owner>? _testOwners;
  bool keepAlive = false;
  bool editing = false;
  Stream<String> downloadProgress = Stream.empty();
  DateTime logID = DateTime.now();
  CancelToken? _syncCancelToken;
  HttpServer? _syncServer;
  // late Socket socket;

  // For self signed certificates, only use for development
  Lists() {
    init();
  }

  @visibleForTesting
  Lists.forTesting(this.db);

  @visibleForTesting
  Lists.detachedForTesting({List<Owner> owners = const []}) {
    _testOwners = owners;
  }

  void init() async {
    db = await DB.getInstance();
    pool = await Pool.init();
  }

  List<Widget> shareList = [];
  bool get canCancelSync => _syncCancelToken != null || _syncServer != null;
  // List<Product> searchTemp = [];
  // List<Product> productsList = [];
  // List<Product> sellList = [];
  List<Owner> ownersList = [];
  List<Log> logsList = [];
  final Map<String, dynamic> _cache = {};
  bool cacheIsValid = false;
  Future<T> getCachedCalculation<T>(
      String cacheKey, Future<T> Function() calculate) async {
    // Check if the value is already in cache
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey] as T;
    }

    // Perform the calculation if not cached
    final result = await calculate();

    // Store the result in cache
    _cache[cacheKey] = result;

    return result;
  }

  void clearAllCache() {
    _cache.clear();
    notifyListeners();
  }

  void clearCache(String cacheKey) {
    _cache.remove(cacheKey);
    notifyListeners();
  }

  // void calculateEachOwnerSales(String ownerName) {

  //   for (var product in db.inventory.values) {
  //     if (product.ownerName == ownerName) {
  //       var temp =
  //           ownersList.firstWhere((element) => element.ownerName == ownerName);
  //       temp.dueMoney += product.sellprice * product.count;
  //       db.owners.put(ownerName, temp);
  //     }
  //   }
  // }

  Future<void> refresh() async {
    notifyListeners();
  }

  void addOwner(Owner owner) {
    db.insertOwner(owner);
    refreshListOfOwners();
    notifyListeners();
  }

  Future<List<Owner>> refreshListOfOwners() async {
    if (_testOwners != null) return _testOwners!;
    return db.getOwnersList();
  }

  Stream<List<Product>> getTotalBuyPrice() {
    return db.getTotalBuyPrice();
  }

  Stream<List<Log>> getPersonsLogs(int? ID) {
    return db.getPersonsLogs(ID);
  }

  Future<void> cancelReceipt(DateTime date, Log log) async {
    double sum = 0;
    List<EmbeddedProduct> products = List.empty(growable: true);
    for (var product in log.products) {
      if (product.hot!) {
        sum += product.buyPrice! * product.count!;
      } else {
        products.add(product);
      }
    }
    await db.cancelReceiptAtomically(
      log: log,
      hotSum: sum,
      wasLoaned: log.loaned,
      productsToRestore: products,
    );
    clearAllCache();
  }

  Future<void> checkOut({
    required List<Product> lst,
    required double total,
    required double discount,
    required int? LoID,
    required bool loaned,
    required bool edit,
    required DateTime logID,
    required bool expense,
    required int? expenseId,
  }) async {
    final ok = await db.checkOut(
        products: lst,
        total: total,
        discount: discount,
        loanerId: LoID,
        loaned: loaned,
        expense: expense,
        expenseId: expenseId);
    if (!ok) {
      throw Exception('Checkout failed');
    }
    clearAllCache();
  }

  Future<double> getAverageProfitPercent() async {
    var temp = await Future.wait([getAllSales(), getAllProfit()]);
    double profit = temp[1];
    double price = temp[0];

    return (profit / (price - profit)) * 100;
  }

  Future<double> getProfitOfTheMonth() {
    return getCachedCalculation('profitOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      return pool.scheduleJob(CgetProfitOfTheMonth(map: map));
    });
  }

  Future<double> getSalesOfTheMonth() {
    return getCachedCalculation('salesOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));

      return pool.scheduleJob(CgetSalesOfTheMonth(map: map));
    });
  }

  Future<double> getDailySales(DateTime time) {
    return getCachedCalculation('dailySales', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = time;
      return pool.scheduleJob(CgetDailySales(map: map));
    });
  }

  Future<double> getDailyProfits(DateTime time) {
    return getCachedCalculation('dailyProfits', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = time;
      return pool.scheduleJob(CgetDailyProfit(map: map));
    });
  }

  Future<double> getAllProfit() {
    return getCachedCalculation('totalProfit', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = DateTime.now();
      return pool.scheduleJob(CgetTotalProfit(map: map));
    });
  }

  Future<double> getAllSales() {
    return getCachedCalculation('allSales', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      return pool.scheduleJob(CgetAllSales(map: map));
    });
  }

  Future<int> getNumberOfSalesForAproduct({required String key}) {
    return getCachedCalculation('numberOfSalesPerProduct', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = key;
      return pool.scheduleJob(CgetNumberOfSalesForAproduct(map: map));
    });
  }

  Future<List<Product>> getSaledProductsByDate(DateTime time) {
    return getCachedCalculation('saledProductsByDate', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = time;
      return pool.scheduleJob(CgetSaledProductsByDate(map: map));
    });
  }

  Future<List<ProdStats>> getSalesPerProduct(int chunkSize) async {
    return getCachedCalculation('salesPerProduct', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = chunkSize;
      return pool
          .scheduleJob(CgetSalesPerProduct(chunkSize: chunkSize, map: map));
    });
  }

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailySalesOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetDailySalesOfTheMonth(map: map));
    });
  }

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailyProfitOfTheMonth', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetDailyProfitOfTheMont(map: map));
    });
  }

  Future<List<SalesStats>> getMonthlySalesOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlySalesOfTheYear', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetMonthlySalesOfTheyear(map: map));
    });
  }

  Future<List<SalesStats>> getMonthlyProfitsOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlyProfitsOfTheYear', () {
      Map map = Map();
      map['1'] = _getRootIsolateToken() ??
          (throw StateError('RootIsolateToken not available'));
      map['2'] = month;
      return pool.scheduleJob(CgetMonthlyProfitsOfTheyear(map: map));
    });
  }

//   import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Assuming you're using this for QrImageView

  Future<void> runServer() async {
    await _syncServer?.close(force: true);
    _syncServer = null;
    setSyncState(
      SyncStatus.connecting,
      message: 'Preparing LAN sync server...',
      progress: 0,
    );

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final networkInfo = NetworkInfo();
      final wifiIp = await networkInfo.getWifiIP();
      if (wifiIp == null) {
        throw Exception('No Wi-Fi IP address found');
      }

      final code = LanSync.generatePairingCode();
      final endpoint = LanSyncEndpoint(
        host: wifiIp,
        port: LanSync.port,
        code: code,
      );
      pairingCode = code;
      pairingAddress = endpoint.qrPayload;

      await db.createLocalBackup();
      final dir = await getApplicationDocumentsDirectory();
      final server = await HttpServer.bind(wifiIp, LanSync.port);
      server.idleTimeout = LanSync.receiveTimeout;
      _syncServer = server;

      setSyncState(
        SyncStatus.done,
        message: 'Server listening. Pairing code: $code',
        progress: 1,
      );

      await for (final request in server) {
        final shouldShutdown = await _handleLanRequest(
          request,
          packageInfo.version,
          dir,
          code,
        );
        if (shouldShutdown) {
          await server.close();
          break;
        }
      }
      if (syncStatus != SyncStatus.cancelled) {
        setSyncState(SyncStatus.done, message: 'Server is down', progress: 1);
      }
    } catch (e) {
      if (syncStatus != SyncStatus.cancelled) {
        setSyncState(
          SyncStatus.error,
          message: 'Server failed',
          error: e.toString(),
        );
      }
    } finally {
      _syncServer = null;
      notifyListeners();
    }
  }

  Future<void> client(String input) async {
    final endpoint = LanSyncEndpoint.tryParse(input);
    if (endpoint == null) {
      setSyncState(
        SyncStatus.error,
        message: 'Invalid pairing address',
        error: 'Use ip:code or ip:port:code from the sender device.',
      );
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final downloadPath = _downloadedBackupPath(dir.path);
    final dio = LanSync.createDio();
    final cancelToken = CancelToken();
    _syncCancelToken = cancelToken;
    pairingCode = endpoint.code;
    pairingAddress = endpoint.qrPayload;

    try {
      setSyncState(
        SyncStatus.connecting,
        message: 'Connecting to sender...',
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
        message: 'Downloading backup...',
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
            message: 'Downloading backup...',
            progress: received / total,
          );
        },
      );
      if (response.statusCode != HttpStatus.ok) {
        throw Exception('Download failed with status ${response.statusCode}');
      }

      setSyncState(
        SyncStatus.verifying,
        message: 'Verifying backup...',
        progress: 1,
      );
      final actualHash = await LanSync.sha256File(File(downloadPath));
      final expectedHash = await dio
          .getUri(endpoint.uri('hash'), cancelToken: cancelToken)
          .then((response) => response.data.toString().trim());
      if (actualHash != expectedHash) {
        await LanSync.deleteIfExists(downloadPath);
        throw Exception('Backup hash mismatch');
      }

      await _shutdownPeer(dio, endpoint, cancelToken);
      setSyncState(
        SyncStatus.restoring,
        message: 'Restoring verified backup...',
        progress: 1,
      );
      await _restoreDownloadedBackup();
      setSyncState(
        SyncStatus.done,
        message: 'Sync completed successfully',
        progress: 1,
      );
    } on DioException catch (e) {
      await LanSync.deleteIfExists(downloadPath);
      if (CancelToken.isCancel(e)) {
        setSyncState(SyncStatus.cancelled, message: 'Sync cancelled');
      } else {
        setSyncState(
          SyncStatus.error,
          message: 'Sync failed',
          error: e.message ?? e.toString(),
        );
      }
    } catch (e) {
      await LanSync.deleteIfExists(downloadPath);
      setSyncState(
        SyncStatus.error,
        message: 'Sync failed',
        error: e.toString(),
      );
    } finally {
      _syncCancelToken = null;
      notifyListeners();
    }
  }

  void cancelSync() {
    _syncCancelToken?.cancel('Sync cancelled');
    _syncCancelToken = null;
    _syncServer?.close(force: true);
    _syncServer = null;
    setSyncState(SyncStatus.cancelled, message: 'Sync cancelled', progress: 0);
  }

  Future<bool> _handleLanRequest(
    HttpRequest request,
    String version,
    Directory dir,
    String code,
  ) async {
    final fileName =
        request.uri.pathSegments.isEmpty ? '' : request.uri.pathSegments.last;
    request.response.deadline = LanSync.receiveTimeout;

    if (!LanSync.isAuthorizedRequest(request, code)) {
      await _respond(request, HttpStatus.unauthorized, 'Unauthorized');
      return false;
    }
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
    } catch (e) {
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
      clearAllCache();
      return;
    }
    await db.useLocalBacup();
    // Keep restart after restore as a conservative safety measure.
    Restart.restartApp();
  }

  void updateOwner(Owner owner) {
    // db.owners.put(owner.ownerName, owner);
  }

  List<Product?> embeddedToProduct(List<EmbeddedProduct> products) {
    List<int> realIds = List.empty(growable: true);
    for (var p in products) {
      if (!p.hot!) {
        realIds.add(p.productId!);
      }
    }
    List<Product?> realProducts = List.empty(growable: true);
    realProducts.addAll(db.embeddedToProduct(realIds));

    List<Product> fakes = List.empty(growable: true);
    for (var f in products) {
      if (f.hot!) {
        var temp = Product.named2(
            name: f.name,
            ownerName: null,
            barcode: null,
            buyprice: f.buyPrice,
            sellPrice: f.sellPrice,
            count: f.count,
            weightable: null,
            wholeUnit: null,
            offer: null,
            offerCount: null,
            offerPrice: null,
            priceHistory: [],
            endDate: null,
            hot: f.hot,
            id: 0);
        fakes.add(temp);
      }
    }
    realProducts.addAll(fakes);
    return realProducts;
  }

  Stream<List<Log>> getLogsStream({
    required int chunkSize,
    required SearchQuery searchQuery,
  }) {
    // Pass the SearchQuery object to the database method
    return db.getLogsStream(
      chunkSize,
      searchQuery, // Convert SearchQuery to a Map
    );
  }

  Future<List<Product?>> editReceipt(DateTime date, Log log) async {
    double sum = 0;
    List<EmbeddedProduct> products = List.empty(growable: true);
    for (var product in log.products) {
      if (product.hot!) {
        sum += product.buyPrice! * product.count!;
      } else {
        products.add(product);
      }
    }
    await db.cancelReceiptAtomically(
      log: log,
      hotSum: sum,
      wasLoaned: log.loaned,
      productsToRestore: products,
    );
    clearAllCache();
    notifyListeners();
    return embeddedToProduct(log.products);
  }

  getLogsChunk(int chunkSize, int currentLog) {
    return db.getLogsChunk(chunkSize, currentLog);
  }

  Future<List<LowStockProduct>> getLowStockItems() async {
    final results = await db.getLowStockProductsWithPercent();
    return results
        .map((r) => LowStockProduct(
              product: r['product'] as Product,
              percentRemaining: r['percentRemaining'] as double,
              currentStock: r['currentStock'] as int,
              soldLast30Days: r['soldLast30Days'] as int,
            ))
        .toList();
  }
}
