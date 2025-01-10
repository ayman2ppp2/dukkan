import 'dart:async';
// import 'package:mime';
import 'package:dio/dio.dart';
import 'package:dukkan/core/IsolatePool.dart';
// import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/prodStats.dart';
import 'package:dukkan/util/models/Product.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../util/models/Log.dart';

class Lists extends ChangeNotifier {
  late DB db;

  late IsolatePool pool;
  bool keepAlive = false;
  bool editing = false;
  Stream<String> downloadProgress = Stream.empty();
  DateTime logID = DateTime.now();
  // late Socket socket;

  // For self signed certificates, only use for development
  Lists() {
    init();

    db = DB();
  }

  void init() async {
    pool = await Pool.init();
    _initializeStreamListener();
    // pool = Pool.pool;

    // await pool.start();
  }

  List<Widget> shareList = [];
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

  void _initializeStreamListener() {
    db.isar!.products.watchLazy(fireImmediately: true).listen((_) {
      // Call clearCache with the desired cacheKey
      clearCache(
          'salesPerProduct'); // Replace 'yourCacheKey' with the actual key
    });
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
    for (var product in log.products) {
      if (product.hot!) {
        sum += product.buyPrice! * product.count!;
      }
    }
    if (log.loaned) {
      db.updateLoaner(log, sum);
    }

    List<EmbeddedProduct> products = List.empty(growable: true);
    for (var product in log.products) {
      if (!(product.hot!)) {
        products.add(product);
      }
    }
    await db.updateProducts(products);
    await db.deleteLog(log);
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
    await db.checkOut(
        lst: lst,
        total: total,
        discount: discount,
        LoID: LoID,
        loaned: loaned,
        edit: edit,
        logID: logID,
        expense: expense,
        expenseId: expenseId);
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
      map['1'] = RootIsolateToken.instance!;
      return pool.scheduleJob(CgetProfitOfTheMonth(map: map));
    });
  }

  Future<double> getSalesOfTheMonth() {
    return getCachedCalculation('salesOfTheMonth', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;

      return pool.scheduleJob(CgetSalesOfTheMonth(map: map));
    });
  }

  Future<double> getDailySales(DateTime time) {
    return getCachedCalculation('dailySales', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = time;
      return pool.scheduleJob(CgetDailySales(map: map));
    });
  }

  Future<double> getDailyProfits(DateTime time) {
    return getCachedCalculation('dailyProfits', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = time;
      return pool.scheduleJob(CgetDailyProfit(map: map));
    });
  }

  Future<double> getAllProfit() {
    return getCachedCalculation('totalProfit', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = DateTime.now();
      return pool.scheduleJob(CgetTotalProfit(map: map));
    });
  }

  Future<double> getAllSales() {
    return getCachedCalculation('allSales', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      return pool.scheduleJob(CgetAllSales(map: map));
    });
  }

  Future<int> getNumberOfSalesForAproduct({required String key}) {
    return getCachedCalculation('numberOfSalesPerProduct', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = key;
      return pool.scheduleJob(CgetNumberOfSalesForAproduct(map: map));
    });
  }

  Future<List<Product>> getSaledProductsByDate(DateTime time) {
    return getCachedCalculation('saledProductsByDate', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = time;
      return pool.scheduleJob(CgetSaledProductsByDate(map: map));
    });
  }

  Future<List<ProdStats>> getSalesPerProduct(int chunkSize) async {
    return getCachedCalculation('salesPerProduct', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = chunkSize;
      return pool
          .scheduleJob(CgetSalesPerProduct(chunkSize: chunkSize, map: map));
    });
  }

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailySalesOfTheMonth', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = month;
      return pool.scheduleJob(CgetDailySalesOfTheMonth(map: map));
    });
  }

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) async {
    return getCachedCalculation('dailyProfitOfTheMonth', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = month;
      return pool.scheduleJob(CgetDailyProfitOfTheMont(map: map));
    });
  }

  Future<List<SalesStats>> getMonthlySalesOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlySalesOfTheYear', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = month;
      return pool.scheduleJob(CgetMonthlySalesOfTheyear(map: map));
    });
  }

  Future<List<SalesStats>> getMonthlyProfitsOfTheYear(DateTime month) async {
    return getCachedCalculation('monthlyProfitsOfTheYear', () {
      Map map = Map();
      map['1'] = RootIsolateToken.instance!;
      map['2'] = month;
      return pool.scheduleJob(CgetMonthlyProfitsOfTheyear(map: map));
    });
  }

//   import 'dart:io';
// import 'package:path_provider/path_provider.dart';
// import 'package:qr_flutter/qr_flutter.dart'; // Assuming you're using this for QrImageView

  void runServer() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    // Getting available network address (fallback for multiple interface names)
    String? ipAddress = await NetworkInterface.list().then((interfaces) {
      try {
        return interfaces
            .expand((interface) => interface.addresses)
            .firstWhere(
              (address) =>
                  address.type == InternetAddressType.IPv4 &&
                  !address
                      .isLoopback, // Avoid loopback addresses like 127.0.0.1
            )
            .address;
      } catch (e) {
        shareList.add(Text('No suitable network interface found'));
        notifyListeners();
        // print('No suitable network interface found');
        return null;
      }
    });

    if (ipAddress == null) {
      shareList.add(Text('No IP address found'));
      notifyListeners();
      // print('No IP address found');
      return;
    }

    // Show QR code with the server's IP and port
    shareList.add(QrImageView(data: '$ipAddress:30000'));
    notifyListeners();

    // Get the application documents directory
    var te = await getApplicationDocumentsDirectory();

    // Handle file requests dynamically
    void handleHttpRequest(HttpRequest request) async {
      final fileName =
          request.uri.pathSegments.last; // Get the requested file name
      if (fileName == 'version') {
        String version = packageInfo.version;
        request.response.write(version);
        request.response.close();
        shareList.add(Text('vsersion sent'));
        notifyListeners();
      } else {
        final file = File('${te.path}/$fileName'); // Path to the requested file
        if (await file.exists()) {
          print('Sending file: $fileName');
          shareList.add(Text('Sending file: $fileName'));
          notifyListeners();

          try {
            // Set headers based on file type (dynamically)
            var mimeType =
                lookupMimeType(fileName) ?? 'application/octet-stream';
            request.response.headers
                .set(HttpHeaders.contentTypeHeader, mimeType);
            request.response.headers.set(HttpHeaders.contentDisposition,
                'attachment; filename="$fileName"');

            await file.openRead().pipe(request.response);
            shareList.add(Text('File sent: $fileName'));
            notifyListeners();
          } catch (error) {
            print('Error sending file: $error');
            request.response.statusCode = HttpStatus.internalServerError;
            request.response.write('Error sending file');
            request.response.close();
          }
        } else {
          print('File not found: $fileName');
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('File not found: $fileName');
          request.response.close();
        }
      }
    }

    // Start the HTTP server
    try {
      final server = await HttpServer.bind(ipAddress, 30000);
      print('Server listening on ${server.address.address}:${server.port}');
      shareList.add(
          Text('Server listening on ${server.address.address}:${server.port}'));
      notifyListeners();

      // Listen for requests
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
          handleHttpRequest(request); // Handle file requests dynamically
        }
      }
    } catch (e) {
      print('Error starting server: $e');
      shareList.add(Text('Error starting server: $e'));
      notifyListeners();
    }
  }

  void client(String ip) async {
    String version = ''; // e.g., "1.0.0"
    var te = await getApplicationDocumentsDirectory();
    Dio dio = Dio();

    try {
      try {
        var versionResponse = await dio.get(
          'http://$ip/version',
          onReceiveProgress: (count, total) => print(count),
        );
        version = versionResponse.data.toString();
        shareList.add(Text(version));
        notifyListeners();
      } catch (e) {
        shareList.add(Text('Error fetching version: $e'));
        notifyListeners();
        return; // Exit if version can't be fetched
      }

      // Determine file list based on version
      List<String> fileNames;
      if (version.startsWith('2.2.')) {
        fileNames = [
          'inventoryv2.2.0.hive',
          'logsv2.2.0.hive',
          'ownersv2.2.0.hive',
          'loanersv2.2.0.hive',
          'shutdown'
        ];
      } else if (version.startsWith('2.3.') || version.startsWith('2.4.')) {
        fileNames = ['isarInstance.isar', 'shutdown'];
      } else {
        shareList.add(Text('Unsupported version: $version'));
        notifyListeners();
        // print('Unsupported version: $version');
        fileNames = [
          'inventoryv2.2.0.hive',
          'logsv2.2.0.hive',
          'ownersv2.2.0.hive',
          'loanersv2.2.0.hive',
          'shutdown'
        ];
        // return; // Exit if the version is unsupported
      }

      // Loop through the file list and download each one
      for (var fileName in fileNames) {
        var filePath = Platform.isWindows
            ? '${te.path}/$fileName+1'
            : '${te.path}/$fileName'; // Local file path

        // Handle shutdown separately
        if (fileName == 'shutdown') {
          try {
            var response = await dio.get('http://$ip/shutdown');

            shareList.add(Text(response.data));
            notifyListeners();
            // print('Server shut down successfully');
          } catch (e) {
            shareList.add(Text('Error shutting down the server: $e'));
            notifyListeners();
            // print('Error shutting down the server: $e');
          }
          continue; // Skip the shutdown file download
        }

        // Download the file
        try {
          shareList.add(Text('receiving : $fileName'));
          notifyListeners();
          var response = await dio.download('http://$ip/$fileName', filePath);

          if (response.statusCode == 200) {
            shareList.add(Text('File received: $fileName'));
            notifyListeners();
            // print('File received: $fileName');
          } else {
            shareList
                .add(Text('Error receiving $fileName: ${response.statusCode}'));
            notifyListeners();
            // print('Error receiving $fileName: ${response.statusCode}');
          }
        } catch (e) {
          shareList.add(Text('Failed to download $fileName: $e'));
          notifyListeners();
          // print('Failed to download $fileName: $e');
        }
      }
    } catch (e) {
      shareList.add(Text('Error: $e'));

      // print('Error: $e');
    }
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

  Stream<List<Log>> getLogsStream({required int chunkSize}) {
    return db.getLogsStream(chunkSize);
  }

  Future<List<Product?>> editReceipt(DateTime date, Log log) async {
    double sum = 0;
    for (var product in log.products) {
      if (product.hot!) {
        sum += product.buyPrice! * product.count!;
      }
    }
    if (log.loaned) {
      db.updateLoaner(log, sum);
      // Loaner temp =
      //     (await db.isar.loaners.where().iDEqualTo(log.loanerID!).findFirst())!;
      // db.loaners.put(
      //   log.loanerID,
      //   Loaner(
      //     name: temp.name,
      //     // ID: temp.ID,
      //     phoneNumber: temp.phoneNumber,
      //     location: temp.location,
      //     lastPayment: temp.lastPayment,
      //     lastPaymentDate: temp.lastPaymentDate,
      //     loanedAmount: temp.loanedAmount - (log.price + sum),
      //   ),
      // );
    }
    List<EmbeddedProduct> products = List.empty(growable: true);
    for (var product in log.products) {
      if (!(product.hot!)) {
        products.add(product);
      }
    }
    await db.updateProducts(products);
    db.deleteLog(log);
    // db.logs.delete(
    //     '${date.year}-${date.month}-${date.day}-${date.hour}-${date.minute}-${date.second}');
    // refreshLogsList();
    notifyListeners();

    clearAllCache();
    return embeddedToProduct(log.products);
  }

  getLogsChunk(int chunkSize, int currentLog) {
    return db.getLogsChunk(chunkSize, currentLog);
  }
}
