import 'package:dukkan/util/models/BC_product.dart';
import 'package:dukkan/util/models/BcLog.dart';
// import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/util/db.dart';
import 'package:dukkan/util/models/prodStats.dart';
import 'package:dukkan/util/models/Product.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:isolate_pool_2/isolate_pool_2.dart';
// import 'package:network_info_plus/network_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../util/models/Log.dart';

class Lists extends ChangeNotifier {
  late DB db;
  late IsolatePool pool;
  bool keepAlive = false;
  bool editing = false;
  String logID = '';
  // late Socket socket;
  Lists() {
    init();
    db = DB();
  }

  void init() async {
    pool = IsolatePool(Platform.numberOfProcessors ~/ 2);
    await pool.start();
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

  void refreshListOfOwners() {
    ownersList = db.getOwnersList();
  }

  void refreshLogsList() {
    logsList = db.getAllLogs();
    // notifyListeners();
  }

  double getTotalBuyPrice() {
    var temp = db.getAllProducts();
    double sum = 0;
    for (var product in temp) {
      sum += product.buyprice * product.count;
    }
    // print(sum);
    return sum;
  }

  List<Log> getPersonsLogs(String ID) {
    List<Log> result = [];
    for (Log log in db.getAllLogs()) {
      if (log.loaned && log.loanerID == ID) {
        result.add(log);
      }
    }
    return result;
  }

  void cancelReceipt(DateTime date, Log log) {
    for (var product in log.products) {
      if (!product.hot) {
        db.inventory.put(
          product.name,
          Product(
            name: product.name,
            barcode: (db.inventory.get(product.name))!.barcode,
            buyprice: (db.inventory.get(product.name))!.buyprice,
            sellprice: (db.inventory.get(product.name))!.sellprice,
            count: (db.inventory.get(product.name))!.count + product.count,
            ownerName: (db.inventory.get(product.name))!.ownerName,
            weightable: (db.inventory.get(product.name))!.weightable,
            wholeUnit: (db.inventory.get(product.name))!.wholeUnit,
            offer: (db.inventory.get(product.name))!.offer,
            offerCount: (db.inventory.get(product.name))!.offerCount,
            offerPrice: (db.inventory.get(product.name))!.offerPrice,
            priceHistory: (db.inventory.get(product.name))!.priceHistory,
            endDate: (db.inventory.get(product.name))!.endDate,
            hot: false,
          ),
        );
      }
    }
    db.logs.delete(
        '${date.year}-${date.month}-${date.day}-${date.hour}-${date.minute}-${date.second}');
    refreshLogsList();
    notifyListeners();
  }

  Future<double> getAverageProfitPercent() async {
    var temp = await Future.wait([getAllSales(), getAllProfit()]);
    double profit = temp[1];
    double price = temp[0];

    return (profit / (price - profit)) * 100;
  }

  Future<double> getProfitOfTheMonth() {
    Map map = Map();
    map['1'] = db.getAllLogsPev();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(_getProfitOfTheMonth(map: map));
  }

  Future<double> getSalesOfTheMonth() {
    Map map = Map();
    map['1'] = db.getAllLogsPev();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(_getSalesOfTheMonth(map: map));
  }

  Future<double> getDailySales(DateTime time) {
    Map map = Map();
    map['1'] = db.getAllLogsPev();
    map['2'] = time;
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(_getDailySales(map: map));
  }

  Future<double> getDailyProfits(DateTime time) {
    Map map = Map();
    map['1'] = db.getAllLogsPev();
    map['2'] = time;
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(_getDailyProfit(map: map));
  }

  Future<double> getAllProfit() {
    Map map = Map();
    map['1'] = db.getAllLogsPev();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(_getTotalProfit(map: map));
  }

  Future<double> getAllSales() {
    Map map = Map();
    map['1'] = db.getAllLogsPev();
    // return Future.delayed(Duration(seconds: 0)).then((value) => 0.0);
    return pool.scheduleJob(_getAllSales(map: map));
  }

  Future<int> getNumberOfSalesForAproduct({required String key}) {
    List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = key;
    map['2'] = logs;
    return pool.scheduleJob(_getNumberOfSalesForAproduct(map: map));
  }

  Future<List<BcProduct>> getSaledProductsByDate(DateTime time) {
    List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = time;
    map['2'] = logs.where((element) =>
        element.date.day == time.day &&
        element.date.month == time.month &&
        element.date.year == time.year);
    return pool.scheduleJob(_getSaledProductsByDate(map: map));
    // return compute(_getSaledProductsByDate, map);
  }

  Future<List<ProdStats>> getSalesPerProduct() async {
    List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = db.getAllProductsPev();
    map['2'] = logs;
    // return pool.scheduleJob()
    return pool.scheduleJob(_getSalesPerProduct(map: map));
    // return compute(_getSalesPerProduct, map);
  }

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) async {
    List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = logs;
    map['2'] = month;
    return pool.scheduleJob(_getDailySalesOfTheMonth(map: map));
    // return await compute(_getDailySalesOfTheMonth, map);
  }

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) async {
    List<BcLog> logs = logsList.map((e) => BcLog.fromLog(e)).toList();
    Map map = Map();
    map['1'] = month;
    map['2'] = logs;
    return pool.scheduleJob(_getDailyProfitOfTheMont(map: map));
  }

  void runServer() async {
    var te = await getApplicationDocumentsDirectory();
    void handleHttpRequest(HttpRequest request) {
      final filePath = request.uri.pathSegments.last;
      print('${te.path}/$filePath');

      final file = File('${te.path}/$filePath');

      if (file.existsSync()) {
        print('Sending file: $filePath');
        file.openRead().pipe(request.response).then((_) {
          print('File sent: $filePath');
        }).catchError((error) {
          print('Error sending file: $error');
          request.response.close();
        });
      } else {
        print('File not found: $filePath');
        request.response.write('File not found: $filePath');
        request.response.close();
      }
    }

    final server = await HttpServer.bind(InternetAddress.anyIPv4, 30000);
    print('Server listening on ${server.address.address}:${server.port}');
    // server.sessionTimeout = 300;

    await for (HttpRequest request in server) {
      if (request.uri.pathSegments.last == 'shutdown') {
        print('byeee');
        server.close(force: true);
      } else {
        handleHttpRequest(request);
      }
    }
  }

  void client(String ip) async {
    var te = await getApplicationDocumentsDirectory();
    final client = HttpClient();

    try {
      List<String> fileNames = [
        'inventoryv2.2.0.hive',
        'logsv2.2.0.hive',
        'ownersv2.2.0.hive',
        'loanersv2.2.0.hive',
        'shutdown',
      ];

      for (var fileName in fileNames) {
        var request = await client.getUrl(
          Uri.parse('$ip:30000/$fileName'),
        );
        var response = await request.close();
        if (fileName != 'shutdown') {
          if (response.statusCode == HttpStatus.ok) {
            print('Receiving file: $fileName');

            await response
                .pipe(File('${te.path}/$fileName').openWrite())
                .then((value) => print('File received: $fileName'));
          } else {
            print('Error: ${response.statusCode}');
          }
        }
      }
    } finally {
      client.close();
    }
  }

  List<int> toIntList(Uint8List source) {
    return List.from(source);
  }

  void updateOwner(Owner owner) {
    db.owners.put(owner.ownerName, owner);
  }
}

class _getSalesOfTheMonth extends PooledJob<double> {
  Map map;
  _getSalesOfTheMonth({required this.map});
  @override
  Future<double> job() async {
    List<BcLog> temp = map['1'];
    double sales = 0;
    for (var log in temp) {
      if (log.date.month == DateTime.now().month &&
          log.date.year == DateTime.now().year) {
        sales += log.price;
      }
    }

    return sales;
  }
}

class _getProfitOfTheMonth extends PooledJob<double> {
  Map map;
  _getProfitOfTheMonth({required this.map});
  @override
  Future<double> job() async {
    List<BcLog> temp = map['1'];
    double profit = 0;
    for (var log in temp) {
      if (log.date.month == DateTime.now().month &&
          log.date.year == DateTime.now().year) {
        profit += log.profit;
      }
    }

    return profit;
  }
}

class _getDailyProfit extends PooledJob<double> {
  Map map;
  _getDailyProfit({required this.map});
  @override
  Future<double> job() async {
    List<BcLog> temp = map['1'];
    double profit = 0;
    var time = map['2'];
    for (var log in temp) {
      if (log.date.day == time.day &&
          log.date.month == time.month &&
          log.date.year == time.year) {
        profit += log.profit;
      }
    }

    return profit;
  }
}

class _getDailySales extends PooledJob<double> {
  Map map;
  _getDailySales({required this.map});
  @override
  Future<double> job() async {
    List<BcLog> temp = map['1'];
    double sales = 0;
    var time = map['2'];
    for (var log in temp) {
      if (log.date.day == time.day &&
          log.date.month == time.month &&
          log.date.year == time.year) {
        sales += log.price;
      }
    }

    return sales;
  }
}

class _getAllSales extends PooledJob<double> {
  _getAllSales({required this.map});
  Map map;
  @override
  Future<double> job() async {
    List<BcLog> temp = map['1'];
    double sales = 0;
    for (var log in temp) {
      sales += log.price;
    }

    return sales;
  }
}

class _getSaledProductsByDate extends PooledJob<List<BcProduct>> {
  Map map;
  _getSaledProductsByDate({required this.map});
  @override
  Future<List<BcProduct>> job() async {
    Iterable<BcLog> temp = map['2'];
    List<BcProduct> products = [];
    List<BcProduct> result = [];
    for (var log in temp) {
      products.addAll(log.products);
    }
    Map<String, int> yy = {};
    for (var product in products) {
      if (yy.containsKey(product.name)) {
        yy.update(product.name, (value) => product.count + value);
      } else {
        yy.addAll({product.name: product.count});
      }
    }
    for (var element in yy.entries) {
      result.add(
        BcProduct(
          name: element.key,
          buyprice: 0,
          barcode: '',
          sellprice: 0,
          count: element.value,
          weightable: true,
          ownerName: '',
          wholeUnit: '',
          offer: false,
          offerCount: 0,
          offerPrice: 0,
          priceHistory: {},
          endDate: DateTime(2024),
          hot: false,
        ),
      );
    }
    return result;
  }
}

class _getTotalProfit extends PooledJob<double> {
  Map map;
  _getTotalProfit({required this.map});
  @override
  Future<double> job() async {
    List<BcLog> temp = map['1'];
    double profit = 0;
    for (var log in temp) {
      profit += log.profit;
    }

    return profit;
  }
}
// List<Product> _getSaledProductsByDate(Map map) {}

class _getNumberOfSalesForAproduct extends PooledJob<int> {
  Map map;
  _getNumberOfSalesForAproduct({required this.map});
  var count = 0;

  @override
  Future<int> job() async {
    List<BcLog> logs = map['2'];
    String key = map['1'];
    for (var log in logs) {
      List<BcProduct> products = log.products;
      for (var product in products) {
        if (product.name == key) {
          count += product.count;
        }
      }
    }

    return count;
  }
}

// int _getNumberOfSalesForAproduct(Map map) {}
class _getSalesPerProduct extends PooledJob<List<ProdStats>> {
  Map map;
  _getSalesPerProduct({required this.map});
  @override
  Future<List<ProdStats>> job() async {
    int getNumberOfSalesForAproduct({required String key}) {
      int count = 0;
      // List<Log> logs = db.getAllLogs();
      for (var log in map['2']) {
        List<BcProduct> products = log.products;
        for (var product in products) {
          if (product.name == key) {
            count += product.count;
          }
        }
      }
      return count;
    }

    List<ProdStats> temp = [];

    // List<Product> products = db.getAllProducts();

    for (var product in map['1']) {
      int gg = getNumberOfSalesForAproduct(key: product.name);
      temp.add(
        ProdStats(
          date: DateTime.now(),
          name: product.name,
          count: gg > 1000 ? (gg).toDouble() : gg.toDouble(),
        ),
      );
    }

    return temp;
  }
}

// List<ProdStats> _getSalesPerProduct(var map) {}

class _getDailyProfitOfTheMont extends PooledJob<List<SalesStats>> {
  Map map;
  _getDailyProfitOfTheMont({required this.map});

  @override
  Future<List<SalesStats>> job() async {
    DateTime month = map['1'];
    List<BcLog> logs = map['2'];
    double getDailyProfits(DateTime time) {
      List<BcLog> temp = logs;
      double profit = 0;
      for (var log in temp) {
        if (log.date.day == time.day &&
            log.date.month == time.month &&
            log.date.year == time.year) {
          profit += log.profit;
        }
      }
      return profit;
    }

    DateTime tt = month;
    List<SalesStats> result = [];
    List<BcLog> temp = logs;
    // temp.sort(
    //   (a, b) => a.date.compareTo(b.date),
    // );
    // temp = temp.reversed.toList();
    for (var log in temp) {
      if (log.date.month == month.month && log.date.year == month.year) {
        if (tt.day == log.date.day) {
          continue;
        } else {
          result.add(
            SalesStats(
              date: log.date,
              sales: getDailyProfits(log.date),
            ),
          );
          if (log.date.compareTo(tt) < 0) {
            tt = log.date;
          }
        }
      }
    }
    return result;
  }
}

// List<SalesStats> _getDailyProfitOfTheMonth(map) {
//   DateTime month = map['1'];
//   List<Log> logs = map['2'];
//   double getDailyProfits(DateTime time) {
//     List<Log> temp = logs;
//     double profit = 0;
//     for (var log in temp) {
//       if (log.date.day == time.day &&
//           log.date.month == time.month &&
//           log.date.year == time.year) {
//         profit += log.profit;
//       }
//     }
//     return profit;
//   }

//   DateTime tt = month;
//   List<SalesStats> result = [];
//   List<Log> temp = logs;
//   // temp.sort(
//   //   (a, b) => a.date.compareTo(b.date),
//   // );
//   // temp = temp.reversed.toList();
//   for (var log in temp) {
//     if (log.date.month == month.month && log.date.year == month.year) {
//       if (tt.day == log.date.day) {
//         continue;
//       } else {
//         result.add(
//           SalesStats(
//             date: log.date,
//             sales: getDailyProfits(log.date),
//           ),
//         );
//         if (log.date.compareTo(tt) < 0) {
//           tt = log.date;
//         }
//       }
//     }
//   }
//   return result;
// }

class _getDailySalesOfTheMonth extends PooledJob<List<SalesStats>> {
  Map map;
  _getDailySalesOfTheMonth({required this.map});
  @override
  Future<List<SalesStats>> job() async {
    double getDailySales(DateTime time) {
      List<BcLog> temp = map['1'];
      double sales = 0;
      for (var log in temp) {
        if (log.date.day == time.day &&
            log.date.month == time.month &&
            log.date.year == time.year) {
          sales += log.price;
        }
      }

      return sales;
    }

    DateTime tt = map['2'];
    List<SalesStats> result = [];
    List<BcLog> temp = map['1'];
    // temp.sort(
    //   (a, b) => a.date.compareTo(b.date),
    // );
    // temp = temp.reversed.toList();
    for (var log in temp) {
      if (log.date.month == map['2'].month && log.date.year == map['2'].year) {
        if (tt.day == log.date.day) {
          continue;
        } else {
          result.add(
            SalesStats(
              date: log.date,
              sales: getDailySales(log.date),
            ),
          );
          if (log.date.compareTo(tt) < 0) {
            tt = log.date;
          }
        }
      }
    }
    return result;
  }
}
// List<SalesStats> _getDailySalesOfTheMonth(Map map) {
  
// }
