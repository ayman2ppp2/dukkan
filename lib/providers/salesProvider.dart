// import 'package:dukkan/list.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/db.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
// import 'package:provider/provider.dart';

class SalesProvider extends ChangeNotifier {
  late DB db;
  SalesProvider() {
    db = DB();
  }
  List<Loaner> loanersList = [];
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

  void refreshLoanersList() {
    loanersList = db.getLoaners();
  }

  void payLoaner(double cash, String ID) {
    db.loaners.put(
        ID,
        Loaner(
          name: db.loaners.get(ID).name,
          ID: db.loaners.get(ID).ID,
          phoneNumber: db.loaners.get(ID).phoneNumber,
          location: db.loaners.get(ID).location,
          lastPayment: cash,
          lastPaymentDate: DateTime.now(),
          loanedAmount: db.loaners.get(ID).loanedAmount - cash,
        ));
    refreshLoanersList();
  }

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

  Future<void> refreshProductsList() async {
    productsList = db.getAllProducts();
    notifyListeners();
  }

  void updateProduct(Product product) {
    // product.priceHistory.add({DateTime.now(): product.buyprice});
    db.inventory.put(product.name, product);
    refreshProductsList();
  }

  void search(String keyWord, bool sales) {
    // print('search');
    refreshProductsList();
    // notifyListeners();
    searchTemp.clear();
    for (var i = 0; i < productsList.length; i++) {
      if (productsList[i].name.startsWith(keyWord) ||
          productsList[i].name.contains(keyWord)) {
        searchTemp.add(productsList[i]);

        notifyListeners();
      }
      if (sales) {
        if (searchTemp.isEmpty) {
          searchTemp.add(
            Product(
              name: keyWord,
              ownerName: '',
              barcode: 'barcode',
              buyprice: 1,
              sellprice: 1,
              count: 0,
              weightable: false,
              wholeUnit: 'wholeUnit',
              offer: false,
              offerCount: 0,
              offerPrice: 0,
              priceHistory: {},
              endDate: DateTime.now(),
              hot: true,
            ),
          );
          notifyListeners();
        }
      }
    }
  }

  void addLoaner(
    String name,
    String phone,
    String location,
  ) {
    var uuid = Uuid();

    db.insertLoaner(Loaner(
      name: name,
      ID: uuid.v1(),
      phoneNumber: phone,
      location: location,
      lastPayment: 0,
      lastPaymentDate: DateTime.now(),
      loanedAmount: 0,
    ));

    loanersList = db.getLoaners();

    notifyListeners();
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
          priceHistory: {},
          endDate: DateTime(2024),
          hot: false,
        ),
      );
      return temp.count;
    } else {
      return 909;
    }
  }
}
