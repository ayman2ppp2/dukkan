import 'dart:isolate';

import 'package:dukkan/util/Owner.dart';
import 'package:dukkan/util/db.dart';
import 'package:dukkan/util/prodStats.dart';
import 'package:dukkan/util/product.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:cron/cron.dart';
import 'package:path_provider/path_provider.dart';
import 'util/Log.dart';

class Lists extends ChangeNotifier {
  late DB db;
  // late Socket socket;
  Lists() {
    db = DB();
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

  void refresh() {
    notifyListeners();
  }
  // Future<bool> calculateEachOwnertotals(int value) {
  //   return compute(_calculate, value);
  // }

  // bool _calculate(int value) {
  //   if (value == 1) {
  //     return false;
  //   }
  //   for (int i = 2; i < value; ++i) {
  //     if (value % i == 0) {
  //       return false;
  //     }
  //   }
  //   return true;
  // }

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

  void cancelReceipt(DateTime date, Log log) {
    for (var product in log.products) {
      db.inventory.put(
        product.name,
        Product(
          name: product.name,
          barcode: product.barcode,
          buyprice: product.buyprice,
          sellprice: product.sellprice,
          count: (db.inventory.get(product.name))!.count + product.count,
          ownerName: product.ownerName,
          weightable: product.weightable,
          wholeUnit: product.wholeUnit,
          offer: product.offer,
          offerCount: product.offerCount,
          offerPrice: product.offerPrice,
          priceHistory: product.priceHistory,
          endDate: product.endDate,
        ),
      );
    }
    db.logs.delete(
        '${date.year}-${date.month}-${date.day}-${date.hour}-${date.minute}-${date.second}');
    refreshLogsList();
  }

  double getAverageProfitPercent() {
    double profit = 0;
    double price = 0;
    for (var log in db.getAllLogs()) {
      price += log.price;
      profit += log.profit;
    }
    return (profit / price) * 100;
  }

  double getProfitOfTheMonth() {
    List<Log> temp = db.getAllLogs();
    double profit = 0;
    for (var log in temp) {
      if (log.date.month == DateTime.now().month &&
          log.date.year == DateTime.now().year) {
        profit += log.profit;
      }
    }

    return profit;
  }

  double getSalesOfTheMonth() {
    List<Log> temp = db.getAllLogs();
    double sales = 0;
    for (var log in temp) {
      if (log.date.month == DateTime.now().month &&
          log.date.year == DateTime.now().year) {
        sales += log.price;
      }
    }

    return sales;
  }

  double getDailySales(DateTime time) {
    List<Log> temp = db.getAllLogs();
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

  double getDailyProfits(DateTime time) {
    List<Log> temp = db.getAllLogs();
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

  double getAllProfit() {
    List<Log> temp = db.getAllLogs();
    double profit = 0;
    for (var log in temp) {
      profit += log.profit;
    }

    return profit;
  }

  double getAllSales() {
    List<Log> temp = db.getAllLogs();
    double sales = 0;
    for (var log in temp) {
      sales += log.price;
    }

    return sales;
  }

  int getNumberOfSalesForAproduct({required String key}) {
    int count = 0;
    List<Log> logs = db.getAllLogs();
    for (var log in logs) {
      List<Product> products = log.products;
      for (var product in products) {
        if (product.name == key) {
          count += product.count;
        }
      }
    }
    return count;
  }

  Future<List<Product>> getSaledProductsByDate(DateTime time) {
    Map map = Map();
    map['1'] = time;
    map['2'] = db.getAllLogs().where((element) =>
        element.date.day == time.day &&
        element.date.month == time.month &&
        element.date.year == time.year);
    return compute(_getSaledProductsByDate, map);
  }

  Future<List<ProdStats>> getSalesPerProduct() async {
    Map map = Map();
    map['1'] = db.getAllProducts();
    map['2'] = db.getAllLogs();
    return compute(_getSalesPerProduct, map);
  }

  Future<List<SalesStats>> getDailySalesOfTheMonth(DateTime month) async {
    Map map = Map();
    map['1'] = db.getAllLogs();
    map['2'] = month;
    return await compute(_getDailySalesOfTheMonth, map);
  }

  Future<List<SalesStats>> getDailyProfitOfTheMonth(DateTime month) async {
    Map map = Map();
    map['1'] = month;
    map['2'] = db.getAllLogs();
    return await compute(_getDailyProfitOfTheMonth, map);
  }

  void runServer() async {
    final server = await ServerSocket.bind('0.0.0.0', 30000);
    shareList.clear();
    shareList.add(
        Text('server listening on : ${server.address.host} : ${server.port}'));
    notifyListeners();
    server.listen(
      (client) async {
        client.listen(
          (data) async {
            final message = String.fromCharCodes(data);
            var te = await getApplicationDocumentsDirectory();
            if (message == 'send inv') {
              await File('${te.path}/inventory.hive').openRead().pipe(client);
              shareList.add(const Text('Sent inventory'));
              notifyListeners();
              client.close();
            }
            if (message == 'send logs') {
              await File('${te.path}/logs.hive').openRead().pipe(client);
              shareList.add(const Text('Sent logs'));
              notifyListeners();
            }
            if (message == 'send owners') {
              await File('${te.path}/owners.hive').openRead().pipe(client);
              shareList.add(const Text('Sent owners data'));
              notifyListeners();
            }
          },
          onDone: () {
            shareList.add(const Text('Server closed'));
            notifyListeners();
            client.destroy();
            server.close();
          },
        );
      },
    );
  }

  void reciveInv() async {
    String? ip = await NetworkInfo().getWifiGatewayIP();
    Socket socket = await Socket.connect(ip, 30000);
    var te = await getApplicationDocumentsDirectory();
    if (socket.remoteAddress.address != '127.0.0.1') {
      try {
        shareList.add(Text(
            'Connected to :${socket.remoteAddress.address}:${socket.remotePort}'));
        notifyListeners();
        socket.write('send inv');

        var file = File('${te.path}/inventory.hive').openWrite();
        try {
          await socket.map(toIntList).pipe(file);
        } finally {
          shareList.add(const Text('inventory received'));
          notifyListeners();
          await file.close();
        }
      } finally {
        // socket.destroy();
        reciveLog();
      }
    } else {
      socket.close();
      shareList.add(const Text(
          'you are sending files to your self the operation will be terminated'));
      notifyListeners();
    }
  }

  void reciveLog() async {
    String? ip = await NetworkInfo().getWifiGatewayIP();
    Socket socket = await Socket.connect(ip, 30000);
    var te = await getApplicationDocumentsDirectory();
    try {
      shareList.add(Text("Connected to :"
          '${socket.remoteAddress.address}:${socket.remotePort}'));
      notifyListeners();
      socket.write('send logs');

      var file = File('${te.path}/logs.hive').openWrite();
      try {
        await socket.map(toIntList).pipe(file);
      } finally {
        shareList.add(const Text('logs received'));
        notifyListeners();
        await file.close();
      }
    } finally {
      reciveOwners();
    }
  }

  void reciveOwners() async {
    String? ip = await NetworkInfo().getWifiGatewayIP();
    Socket socket = await Socket.connect(ip, 30000);
    var te = await getApplicationDocumentsDirectory();
    try {
      shareList.add(Text("Connected to :"
          '${socket.remoteAddress.address}:${socket.remotePort}'));
      notifyListeners();
      socket.write('send owners');

      var file = File('${te.path}/owners.hive').openWrite();
      try {
        await socket.map(toIntList).pipe(file);
      } finally {
        shareList.add(const Text('owners data received'));
        notifyListeners();
        await file.close();
      }
    } finally {
      socket.destroy();
      socket.destroy();
    }
  }

  List<int> toIntList(Uint8List source) {
    return List.from(source);
  }

  void updateOwner(Owner owner) {
    db.owners.put(owner.ownerName, owner);
  }
}

List<Product> _getSaledProductsByDate(Map map) {
  Iterable<Log> temp = map['2'];
  // db.getAllLogs().where((element) =>
  //     element.date.day == time.day &&
  //     element.date.month == time.month &&
  //     element.date.year == time.year);
//@to-do sort the list by date
  List<Product> products = [];
  List<Product> result = [];
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
    result.add(Product(
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
        priceHistory: [],
        endDate: DateTime(2024)));
  }
  return result;
}

int _getNumberOfSalesForAproduct(Map map) {
  int count = 0;
  List<Log> logs = map['2'];
  String key = map['1'];
  for (var log in logs) {
    List<Product> products = log.products;
    for (var product in products) {
      if (product.name == key) {
        count += product.count;
      }
    }
  }
  return count;
}

List<ProdStats> _getSalesPerProduct(var map) {
  int getNumberOfSalesForAproduct({required String key}) {
    int count = 0;
    // List<Log> logs = db.getAllLogs();
    for (var log in map['2']) {
      List<Product> products = log.products;
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

List<SalesStats> _getDailyProfitOfTheMonth(map) {
  DateTime month = map['1'];
  List<Log> logs = map['2'];
  double getDailyProfits(DateTime time) {
    List<Log> temp = logs;
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
  List<Log> temp = logs;
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

List<SalesStats> _getDailySalesOfTheMonth(Map map) {
  double getDailySales(DateTime time) {
    List<Log> temp = map['1'];
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
  List<Log> temp = map['1'];
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
