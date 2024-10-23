import 'dart:async';
import 'dart:ffi';
// import 'package:mime';
import 'package:dio/dio.dart';
import 'package:dukkan/core/IsolatePool.dart';
import 'package:dukkan/util/models/BC_product.dart';
import 'package:dukkan/util/models/BcLog.dart';
import 'package:dukkan/util/models/Emap.dart';
import 'package:dukkan/util/models/Loaner.dart';
// import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/prodStats.dart';
import 'package:dukkan/util/models/Product.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
import 'package:mime/mime.dart';
import 'package:package_info_plus/package_info_plus.dart';
// import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../util/models/Log.dart';
import 'package:appwrite/appwrite.dart';

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
    // pool = Pool.pool;

    // await pool.start();
  }

  List<Widget> shareList = [];
  // List<Product> searchTemp = [];
  // List<Product> productsList = [];
  // List<Product> sellList = [];
  List<Owner> ownersList = [];
  List<Log> logsList = [];

  void calculateEachOwnerSales(String ownerName) {
    // refreshListOfOwners();

    for (var product in db.inventory.values) {
      if (product.ownerName == ownerName) {
        var temp =
            ownersList.firstWhere((element) => element.ownerName == ownerName);
        temp.dueMoney += product.sellprice * product.count;
        db.owners.put(ownerName, temp);
      }
    }
  }

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

  // Future<List<Log>> refreshLogsList() async {
  //   try {
  //     logsList = await db.getAllLogs();
  //     // for (var log in logsList) {
  //     //   await log.products.load();
  //     // }
  //     return logsList;
  //   } on Exception catch (e, stacktrace) {
  //     print(stacktrace);
  //     return [];
  //   }
  //   // notifyListeners();
  // }

  Stream<List<Product>> getTotalBuyPrice() {
    return db.getTotalBuyPrice();
    // double sum = 0;
    // for (var product in temp) {
    //   sum += product.buyprice! * product.count!;
    // }
    // // print(sum);
    // return sum;
  }

  Future<List<Log>> getPersonsLogs(int? ID) async {
    return db.getPersonsLogs(ID);
    // List<Log> result = [];
    // for (Log log in await db.getAllLogs()) {
    //   if (log.loaned && log.loanerID == ID) {
    //     result.add(log);
    //   }
    // }
    // return result;
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
    await db.deleteLog(log);
  }

  Future<double> getAverageProfitPercent() async {
    var temp = await Future.wait([getAllSales(), getAllProfit()]);
    double profit = temp[1];
    double price = temp[0];

    return (profit / (price - profit)) * 100;
  }

  Future<double> getProfitOfTheMonth() {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    // map['1'] = logsList
    //     .map((e) => BcLog.fromLog(e))
    //     .toList()
    //     .takeWhile((value) =>
    //         value.date.month == DateTime.now().month &&
    //         value.date.year == DateTime.now().year)
    //     .toList();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(CgetProfitOfTheMonth(map: map));
  }

  Future<double> getSalesOfTheMonth() {
    // db.closeAll();
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;

    // logsList
    //     .map((e) => BcLog.fromLog(e))
    //     .toList()
    //     .takeWhile((value) =>
    //         value.date.month == DateTime.now().month &&
    //         value.date.year == DateTime.now().year)
    //     .toList();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(CgetSalesOfTheMonth(map: map));
  }

  Future<double> getDailySales(DateTime time) {
    Map map = Map();
    // map['1'] = logsList
    //     .map((e) => BcLog.fromLog(e))
    //     .toList()
    //     .takeWhile((value) =>
    //         value.date.day == DateTime.now().day &&
    //         value.date.month == DateTime.now().month &&
    //         value.date.year == DateTime.now().year)
    //     .toList();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = time;
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(CgetDailySales(map: map));
  }

  Future<double> getDailyProfits(DateTime time) {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = time;
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(CgetDailyProfit(map: map));
  }

  Future<double> getAllProfit() {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    // map['1'] = logsList.map((e) => BcLog.fromLog(e)).toList();
    map['2'] = DateTime.now();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);

    return pool.scheduleJob(CgetTotalProfit(map: map));
  }

  Future<double> getAllSales() {
    // refreshLogsList();
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    // map['1'] = logsList.map((e) => BcLog.fromLog(e)).toList();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(CgetAllSales(map: map));
  }

  Future<int> getNumberOfSalesForAproduct({required String key}) {
    // List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = key;
    // map['2'] = logs;
    return pool.scheduleJob(CgetNumberOfSalesForAproduct(map: map));
  }

  Future<List<Product>> getSaledProductsByDate(DateTime time) {
    // List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = time;
    // map['2'] = logs.where((element) =>
    //     element.date.day == time.day &&
    //     element.date.month == time.month &&
    //     element.date.year == time.year);
    return pool.scheduleJob(CgetSaledProductsByDate(map: map));
    // return compute(_getSaledProductsByDate, map);
  }

  Future<List<ProdStats>> getSalesPerProduct(int chunkSize) async {
    // List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    // map['2'] = logs;
    // return pool.scheduleJob()
    return pool.scheduleJob(CgetSalesPerProduct(
      chunkSize: chunkSize,
      map: map,
    ));
    // return compute(CgetSalesPerProduct, map);
  }

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) async {
    // List<BcLog> logs = logsList
    //     .map((e) => BcLog.fromLog(e))
    //     .toList()
    //     .where((value) =>
    //         value.date.month == month.month && value.date.year == month.year)
    //     .toList();

    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = month;

    return pool.scheduleJob(CgetDailySalesOfTheMonth(map: map));
    // return await compute(CgetDailySalesOfTheMonth, map);
  }

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) async {
    // List<BcLog> logs = logsList
    //     .map((e) => BcLog.fromLog(e))
    //     .toList()
    //     .where((value) =>
    //         value.date.month == month.month && value.date.year == month.year)
    //     .toList();
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = month;
    // map['2'] = logs;
    return pool.scheduleJob(CgetDailyProfitOfTheMont(map: map));
  }

  Future<List<SalesStats>> getMonthlySalesOfTheYear(DateTime month) async {
    // List<BcLog> logs = logsList
    //     .map((e) => BcLog.fromLog(e))
    //     .toList()
    //     .where((value) => value.date.year == month.year)
    //     .toList();
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = month;
    // map['2'] = logs;
    return pool.scheduleJob(CgetMonthlySalesOfTheyear(map: map));
  }

  Future<List<SalesStats>> getMonthlyProfitsOfTheYear(DateTime month) async {
    Map map = Map();
    map['1'] = RootIsolateToken.instance!;
    map['2'] = month;
    // map['2'] = logs;
    return pool.scheduleJob(CgetMonthlyProfitsOfTheyear(map: map));
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
      // Fetch the version first
      try {
        var versionResponse = await dio.get(
          'http://$ip/version',
          onReceiveProgress: (count, total) => print(count),
        );
        version = versionResponse.data.toString();
        shareList.add(Text(version));
        notifyListeners();
        // print(version);
      } catch (e) {
        shareList.add(Text('Error fetching version: $e'));
        notifyListeners();
        // print('Error fetching version: $e');
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
      } else if (version.startsWith('2.3.')) {
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
    db.owners.put(owner.ownerName, owner);
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
    List<int> realProductIds =
        log.products.map((e) => e.productId ?? 0).toList();
    return embeddedToProduct(log.products);
  }

  getLogsChunk(int chunkSize, int currentLog) {
    return db.getLogsChunk(chunkSize, currentLog);
  }
}
