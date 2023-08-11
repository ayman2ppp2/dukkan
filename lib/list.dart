import 'package:dukkan/util/db.dart';
import 'package:dukkan/util/prodStats.dart';
import 'package:dukkan/util/product.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

import 'util/Log.dart';

class Lists extends ChangeNotifier {
  late DB db;
  // late Socket socket;
  Lists() {
    db = DB();
  }
  List<Widget> shareList = [];
  List<Product> searchTemp = [];
  List<Product> productsList = [];
  List<Product> sellList = [];
  List<Log> logsList = [];
  Map kg = {
    'كيلو': 1000,
    'نص كيلو': 1000,
    'ربع كيلو': 1000,
    'وزن': 0,
  };
  Map pound = {
    'كيلو': 1000,
    'نص كيلو': 1000,
    'ربع كيلو': 1000,
    'وزن': 0,
  };

  void refreshLogsList() {
    logsList = db.getAllLogs();
  }

  int getProductCount(String name) {
    if (productsList.isNotEmpty) {
      Product temp = productsList.firstWhere(
        (element) => element.name == name,
        orElse: () => Product(
          name: 'name',
          buyprice: 0,
          sellprice: 0,
          count: 999,
          ownerName: '',
          weightable: true,
          wholeUnit: '',
        ),
      );
      return temp.count;
    } else {
      return 909;
    }
  }

  bool isProductOutOFStock(String name) {
    return getProductCount(name) == 0 ? false : true;
  }

  void defaultSellList() {
    sellList = [];
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  void refreshProductsList() async {
    productsList = await db.getAllProducts();
    notifyListeners();
  }

  double getTotalBuyPrice() {
    var temp = db.getAllProducts();
    double sum = 0;
    for (var product in temp) {
      sum += product.buyprice * product.count;
    }
    return sum;
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

  double getDailySales() {
    List<Log> temp = db.getAllLogs();
    double sales = 0;
    for (var log in temp) {
      if (log.date.day == DateTime.now().day &&
          log.date.month == DateTime.now().month &&
          log.date.year == DateTime.now().year) {
        sales += log.price;
      }
    }

    return sales;
  }

  double getDailyProfits() {
    List<Log> temp = db.getAllLogs();
    double profit = 0;
    for (var log in temp) {
      if (log.date.day == DateTime.now().day &&
          log.date.month == DateTime.now().month &&
          log.date.year == DateTime.now().year) {
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

  void search(String keyWord) {
    refreshProductsList();
    notifyListeners();
    searchTemp.clear();
    for (var i = 0; i < productsList.length; i++) {
      if (productsList[i].name.startsWith(keyWord) ||
          productsList[i].name.contains(keyWord)) {
        searchTemp.add(productsList[i]);
        notifyListeners();
      }
    }
  }

  void updateSellListCount({required int index, required int count}) {
    sellList[index].count = count;
    notifyListeners();
  }

  // void SelectProduct({required Product product, required int sellListIndex}) {
  //   sellList[sellListIndex].name = product.name;
  //   sellList[sellListIndex].sellprice = product.sellprice;
  //   sellList[sellListIndex].buyprice = product.buyprice;

  //   notifyListeners();
  // }

  void removeProduct({required int index}) async {
    Product temp = productsList[index];
    db.inventory.delete(temp.name);
  }

  void updateProduct(Product product) {
    db.inventory.put(product.name, product);
    refreshProductsList();
  }

  int getNumberOfSalesForAproduct(
      {required String key, required DateTime time}) {
    int count = 0;
    List<Log> logs = db.getAllLogs();
    for (var log in logs) {
      if (log.date.day == time.day) {
        List<Product> products = log.products;
        for (var product in products) {
          if (product.name == key) {
            count += product.count;
          }
        }
      }
    }
    return count;
  }

  List<Product> getSaledProductsByDate(DateTime time) {
    Iterable<Log> temp =
        db.getAllLogs().where((element) => element.date.day == time.day);
    List<Product> products = [];
    List<Product> result = [];
    for (var log in temp) {
      products.addAll(log.products);
      // if (log.date.day == time.day) {}
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
        sellprice: 0,
        count: element.value,
        weightable: true,
        ownerName: '',
        wholeUnit: '',
      ));
    }
    return result;
  }

  List<ProdStats> getSalesPerProduct() {
    List<ProdStats> temp = [];

    List<Product> products = db.getAllProducts();

    for (var product in products) {
      temp.add(
        ProdStats(
          date: DateTime.now(),
          name: product.name,
          count: getNumberOfSalesForAproduct(
            key: product.name,
            time: DateTime.now(),
          ),
        ),
      );
    }

    return temp;
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

            if (message == 'send inv') {
              await File('storage/emulated/0/dukkan/inventory.hive')
                  .openRead()
                  .pipe(client);
              shareList.add(const Text('Sent inventory'));
              notifyListeners();
              client.close();
            }
            if (message == 'send logs') {
              await File('storage/emulated/0/dukkan/logs.hive')
                  .openRead()
                  .pipe(client);
              shareList.add(const Text('Sent logs'));
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
    if (socket.remoteAddress.address != '127.0.0.1') {
      try {
        shareList.add(Text(
            'Connected to :${socket.remoteAddress.address}:${socket.remotePort}'));
        notifyListeners();
        socket.write('send inv');

        var file = File('storage/emulated/0/dukkan/inventory.hive').openWrite();
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
    try {
      shareList.add(Text("Connected to :"
          '${socket.remoteAddress.address}:${socket.remotePort}'));
      notifyListeners();
      socket.write('send logs');

      var file = File('storage/emulated/0/dukkan/logs.hive').openWrite();
      try {
        await socket.map(toIntList).pipe(file);
      } finally {
        shareList.add(const Text('logs received'));
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
}
