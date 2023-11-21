import 'package:dukkan/list.dart';
import 'package:dukkan/util/db.dart';
import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesProvider extends ChangeNotifier {
  var db;
  SalesProvider() {
    db = DB();
  }
  List<Product> productsList = [];
  List<Product> sellList = [];
  List<Product> searchTemp = [];
  Map<String, double> kg = {
    'كيلو': 1000,
    'نص كيلو': 500,
    'ربع كيلو': 250,
    'وزن': 0,
  };
  Map<String, double> pound = {
    'رطل': 450,
    'نص رطل': 225,
    'ربع رطل': 112.5,
    'وزن': 0,
  };
  Map<String, double> toumna = {
    'تمنة': 850,
    'نص تمنة': 425,
    'ربع تمنة': 212.5,
    'وزن': 0,
  };

  void updateSellListCount({required int index, required int count}) {
    sellList[index].count = count;
    notifyListeners();
  }

  void removeProduct({required int index}) async {
    Product temp = productsList[index];
    productsList.removeAt(index);
    db.inventory.delete(temp.name);
  }

  void refresh() {
    notifyListeners();
  }

  bool isProductOutOFStock(String name) {
    return getProductCount(name) == 0 ? false : true;
  }

  void defaultSellList() {
    sellList = [];
    notifyListeners();
  }

  void refreshProductsList() async {
    productsList = db.getAllProducts();
    notifyListeners();
  }

  void updateProduct(Product product) {
    // product.priceHistory.add({DateTime.now(): product.buyprice});
    db.inventory.put(product.name, product);
    refreshProductsList();
  }

  void search(String keyWord) {
    print('search');
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

  int getProductCount(String name) {
    if (productsList.isNotEmpty) {
      Product temp = productsList.firstWhere(
        (element) => element.name == name,
        orElse: () => Product(
          name: 'name',
          barcode: '',
          buyprice: 0,
          sellprice: 0,
          count: 999,
          ownerName: '',
          weightable: true,
          wholeUnit: '',
          offer: false,
          offerCount: 0,
          offerPrice: 0,
          priceHistory: [],
          endDate: DateTime(2024),
        ),
      );
      return temp.count;
    } else {
      return 909;
    }
  }
}
