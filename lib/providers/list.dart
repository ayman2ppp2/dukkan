import 'dart:async';
// import 'package:mime';
import 'package:dio/dio.dart';
import 'package:restart_app/restart_app.dart';
import 'package:dukkan/core/sync/lan_sync.dart';
import 'package:dukkan/core/observability.dart';
// import 'package:dukkan/models/Loaner.dart';
import 'package:dukkan/models/Owner.dart';
import 'package:dukkan/core/db/db.dart';
import 'package:dukkan/data/stats/stats_service.dart';
import 'package:dukkan/models/Product.dart';
import 'package:dukkan/models/prodStats.dart';
import 'package:dukkan/models/searchQuery.dart';
import 'package:dukkan/models/LowStockProduct.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dukkan/models/Log.dart';

class Lists extends ChangeNotifier with LanSyncState {
  late DB db;

  late StatsService stats;
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
  Lists.forTesting(this.db) {
    stats = StatsService.forTesting(db);
  }

  @visibleForTesting
  Lists.detachedForTesting({List<Owner> owners = const []}) {
    _testOwners = owners;
  }

  void init() async {
    db = await DB.getInstance();
    stats = StatsService(db);
  }

  List<Widget> shareList = [];
  bool get canCancelSync => _syncCancelToken != null || _syncServer != null;
  // List<Product> searchTemp = [];
  // List<Product> productsList = [];
  // List<Product> sellList = [];
  List<Owner> ownersList = [];
  List<Log> logsList = [];

  bool get cacheIsValid => stats.cacheIsValid;

  Future<T> getCachedCalculation<T>(
          String cacheKey, Future<T> Function() calculate) =>
      stats.getCachedCalculation(cacheKey, calculate);

  int get cacheVersion => stats.cacheVersion;

  void clearAllCache() {
    stats.clearAllCache();
    notifyListeners();
  }

  void clearCache(String cacheKey) {
    stats.clearCache(cacheKey);
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
        sum += product.sellPrice! * product.count!;
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

  Future<YearlyTotals> getYearlyTotals() => stats.getYearlyTotals();

  Future<double> getAverageProfitPercent() => stats.getAverageProfitPercent();

  Future<double> getYearlyInflation() => stats.getYearlyInflation();

  Future<double> getAllProfit() => stats.getAllProfit();

  Future<double> getAllSales() => stats.getAllSales();

  Future<double> getProfitOfTheMonth() => stats.getProfitOfTheMonth();

  Future<double> getSalesOfTheMonth() => stats.getSalesOfTheMonth();

  Future<double> getDailySales(DateTime time) => stats.getDailySales(time);

  Future<double> getDailyProfits(DateTime time) => stats.getDailyProfits(time);

  Future<int> getNumberOfSalesForAproduct({required String key}) =>
      stats.getNumberOfSalesForAproduct(key: key);

  Future<List<Product>> getSaledProductsByDate(DateTime time) =>
      stats.getSaledProductsByDate(time);

  Future<List<ProdStats>> getSalesPerProduct(int chunkSize) =>
      stats.getSalesPerProduct(chunkSize);

  Future<List<LoanerComparison>> getLoanerComparison() =>
      stats.getLoanerComparison();

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) =>
      stats.getDailySalesOfTheMonth(month);

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) =>
      stats.getDailyProfitOfTheMonth(month);

  Future<List<SalesStats>> getMonthlySalesOfTheYear(DateTime month) =>
      stats.getMonthlySalesOfTheYear(month);

  Future<List<SalesStats>> getMonthlyProfitsOfTheYear(DateTime month) =>
      stats.getMonthlyProfitsOfTheYear(month);

//   import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Assuming you're using this for QrImageView

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

  Future<void> client(String input) async {
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
            buyprice: f.buyPrice ?? 0,
            sellPrice: f.sellPrice ?? 0,
            count: f.count ?? 0,
            weightable: null,
            wholeUnit: null,
            offer: false,
            offerCount: 0,
            offerPrice: 0,
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
        sum += product.sellPrice! * product.count!;
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
    var result = embeddedToProduct(log.products);
    Map<int, int> originalCounts = {};
    for (var ep in log.products) {
      if (!ep.hot! && ep.productId != null) {
        originalCounts.update(
          ep.productId!,
          (v) => v + (ep.count ?? 0),
          ifAbsent: () => ep.count ?? 0,
        );
      }
    }
    for (var p in result) {
      if (p != null && !p.hot! && originalCounts.containsKey(p.id)) {
        p.count = originalCounts[p.id]!;
      }
    }
    return result;
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
