// import 'package:dukkan/list.dart';

import 'dart:convert';

import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:provider/provider.dart';

class SalesProvider with ChangeNotifier, WidgetsBindingObserver {
  late SharedPreferences _pref;
  late DB db;
  SalesProvider() {
    init();
    db = DB();
  }
  Future<void> init() async {
    _pref = await SharedPreferences.getInstance();
    // _pref.clear();
  }

  List<Loaner> loanersList = [];
  // List<Product> productsList = [];
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

  int? getWeightPrececsion() {
    return _pref.getInt('weightPrececsion');
  }

  void setWeightPrececsion(int value) {
    _pref.setInt('weightPrececsion', value);
  }

  String? getStoreName() {
    return _pref.getString('storeName');
  }

  void setStoreName(String name) {
    _pref.setString('storeName', name);
  }

  void removeItemAt(int index) {
    sellList.removeAt(index);
    notifyListeners();
  }

  Future<List<Loaner>> refreshLoanersList() async {
    return db.getLoaners();
  }

  Future<int> resetLoanerAcount(int ID) async {
    var loaner = await db.isar!.loaners.get(ID);
    loaner!.loanedAmount = 0;
    loaner.zeroingDate = DateTime.now();
    var temp = loaner.lastPayment!.toList(growable: true);
    temp.add(EmbeddedMap()
      ..value = 'تصفير حساب'
      ..key = DateTime.now().toIso8601String()
      ..remaining = 0);
    loaner.lastPayment = temp;

    return await db.insertLoaner(loaner);
  }

  Future<int> payLoaner(double cash, int ID) async {
    var temp = await db.isar!.loaners.get(ID);
    var list = List<EmbeddedMap>.from(temp!.lastPayment!, growable: true);
    list.add(
      EmbeddedMap()
        ..key = DateTime.now().toIso8601String()
        ..value = cash.toString()
        ..remaining = temp.loanedAmount! - cash,
    );
    return db.insertLoaner(Loaner(
      name: temp.name,
      // ID: db.loaners.get(ID).ID,
      phoneNumber: temp.phoneNumber,
      location: temp.location,
      lastPayment: list,
      // lastPaymentDate: DateTime.now(),
      loanedAmount: temp.loanedAmount! - cash,
    )
      ..ID = ID
      ..zeroingDate =
          (temp.loanedAmount! - cash) == 0 ? DateTime.now() : temp.zeroingDate);
// fix this shit
    // refresh();
  }

  void updateSellListCount({required int index, required int count}) {
    sellList[index].count = count;
    notifyListeners();
  }

  Future<bool> removeProduct({required int id}) async {
    // productsList.removeAt(index);
    return db.deleteProduct(id);
  }

  void refresh() {
    notifyListeners();
  }

  bool isProductOutOFStock(int id) {
    return getProductCount(id) == 0 ? false : true;
  }

  bool isProductOutOfDate(DateTime endDate) {
    try {
      return endDate.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  void defaultSellList() {
    sellList = [];
    notifyListeners();
  }

  Future<List<Product>> refreshProductsList() async {
    return await db.getAllProducts();
  }

  void updateProduct(Product product) {
    // product.priceHistory.add({DateTime.now(): product.buyprice});
    db.isar!.writeTxn(() => db.isar!.products.put(product));
    refreshProductsList();
  }

  Future<List<Product>> search(String keyWord, bool sales, bool barcode) {
    final searchTerm = keyWord.trim().toLowerCase();

    if (searchTerm.isEmpty) {
      return db.isar!.products.where().sortByName().findAll();
    }

    if (barcode) {
      return db.isar!.products.filter().barcodeEqualTo(keyWord).findAll();
    }

    if (sales) {
      return db.isar!.products
          .filter()
          .nameContains(searchTerm, caseSensitive: false)
          .or()
          .barcodeContains(searchTerm, caseSensitive: false)
          .sortByEndDateDesc() // Ensure non-expired items are prioritized
          .thenByCountDesc() // Ensure items with stock are prioritized
          .thenByName() // Sort alphabetically for items with the same count and end date
          .findAll();
    } else {
      return db.isar!.products
          .filter()
          .nameContains(searchTerm, caseSensitive: false)
          .or()
          .barcodeContains(searchTerm, caseSensitive: false)
          .sortByCountDesc()
          .thenByName()
          .findAll();
    }
  }

  Future<void> addLoaner(
    String name,
    String phone,
    String location,
  ) async {
    // var uuid = Uuid();

    db.insertLoaner(
      Loaner(
        name: name,
        // ID: uuid.v1(),
        phoneNumber: phone,
        location: location,
        lastPayment: [],
        // lastPaymentDate: DateTime.now(),
        loanedAmount: 0,
      ),
    );

    loanersList = await db.getLoaners();

    notifyListeners();
  }

  int generateLoanerId() {
    return DateTime.now().millisecondsSinceEpoch.remainder(10000);
  }

  Stream<List<Loaner>> getLoanersStream() {
    return db.getLoanersStream();
    // refreshLoanersList();
    // var temp = await db.getLoaners();
    // return temp.fold<double>(
    //     0.0, (previousValue, element) => previousValue + element.loanedAmount!);
  }

  Future<void> deleteLoaner(int id) {
    return db.deleteLoaner(id).then((value) => refresh());
  }

  int getProductCount(int id) {
    var temp = db.isar!.products.getSync(id);

    return temp == null ? 999 : temp.count!;
    // refreshProductsList();
    // if (productsList.isNotEmpty) {
    //   Product temp = productsList.firstWhere(
    //     (element) => element.name == name,
    //     orElse: () => Product.named(
    //       name: 'name',
    //       barcode: '',
    //       buyprice: 0,
    //       sellPrice: 0,
    //       count: 999,
    //       ownerName: '',
    //       weightable: true,
    //       wholeUnit: '',
    //       offer: false,
    //       offerCount: 0,
    //       offerPrice: 0,
    //       priceHistory: [],
    //       endDate: DateTime(2024),
    //       hot: false,
    //     ),
    //   );
    //   return temp.count!;
    // } else {
    //   return 909;
    // }
  }

  Future<Loaner?> getLoanerName({required int id}) {
    return db.getLoanerName(id: id);
  }

  Stream<Loaner?> watchLoaner(int id) {
    return db.watchLoaner(id);
  }

  Stream<Product?> watchProduct(int id) {
    return db.watchProduct(id);
  }

  Future<void> saveProductsToSharedPreferences(List<Product> products) async {
    final productListJson =
        products.map((product) => product.toJson()).toList();
    _pref.setString('productList', jsonEncode(productListJson));
  }

  Future<List<Product>> loadProductsFromSharedPreferences() async {
    var _productListJson = _pref.getString('productList');
    if (_productListJson != null) {
      final List<dynamic> jsonList = jsonDecode(_productListJson);
      return jsonList.map((json) => Product.fromJson(map: json)).toList();
    }
    return [];
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      print("ggs");
      saveProductsToSharedPreferences(sellList);
    }
  }

  @override
  void dispose() {
    var sellListMap;
    if (sellList.isNotEmpty) {
      sellListMap = sellList
          .map(
            (e) => e.toJson(),
          )
          .toList();
    }
    print(sellListMap);
    super.dispose();
  }
}
