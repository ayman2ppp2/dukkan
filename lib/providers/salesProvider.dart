// import 'package:dukkan/list.dart';
import 'dart:math';

import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/core/db.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:isar/isar.dart';
import 'package:uuid/uuid.dart';
// import 'package:provider/provider.dart';

class SalesProvider extends ChangeNotifier {
  late DB db;
  SalesProvider() {
    db = DB();
    // initializeStream();
  }
  late Stream<List<Product>> _ResultsStream;
  late Stream<List<Product>> _searchResultsStream;
  late Stream<List<Product>> _fallbackStream;
  Stream<List<Product>> get searchResultsStream => _searchResultsStream;

  void initializeStream() {
    _searchResultsStream =
        db.isar.products.where().watch(fireImmediately: true);
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

  Future<List<Loaner>> refreshLoanersList() async {
    return db.getLoaners();
  }

  Future<int> payLoaner(double cash, int ID) async {
    var temp = await db.isar.loaners.get(ID);
    var list = List<EmbeddedMap>.from(temp!.lastPayment!, growable: true);
    list.add(
      EmbeddedMap()
        ..key = DateTime.now().toIso8601String()
        ..value = cash.toString(),
    );
    return db.insertLoaner(Loaner(
      name: temp.name,
      // ID: db.loaners.get(ID).ID,
      phoneNumber: temp.phoneNumber,
      location: temp.location,
      lastPayment: list,
      // lastPaymentDate: DateTime.now(),
      loanedAmount: temp.loanedAmount! - cash,
    )..ID = ID);
// fix this shit
    // refresh();
  }

  void updateSellListCount({required int index, required int count}) {
    sellList[index].count = count;
    notifyListeners();
  }

  Future<bool> removeProduct({required int id}) async {
    int index = productsList.indexWhere((element) => element.id == id);
    // productsList.removeAt(index);
    return db.deleteProduct(id);
  }

  void refresh() {
    notifyListeners();
  }

  bool isProductOutOFStock(String name) {
    return getProductCount(name) == 0 ? false : true;
  }

  bool isProductOutOfDate(String name) {
    try {
      final product =
          productsList.firstWhere((element) => element.name == name);
      return product.endDate!
          .isBefore(DateTime.now()); // Check if the product is out of date
    } catch (e) {
      // If no product is found, handle it (for example, return true or false, or throw an error)
      return false; // Or handle it as needed
    }
  }

  void defaultSellList() {
    sellList = [];
    notifyListeners();
  }

  Future<List<Product>> refreshProductsList() async {
    productsList = await db.getAllProducts();
    notifyListeners();
    return productsList;
  }

  void updateProduct(Product product) {
    // product.priceHistory.add({DateTime.now(): product.buyprice});
    db.isar.writeTxn(() => db.isar.products.put(product));
    refreshProductsList();
  }

  // searchTemp.clear();
  // searchTemp.insert(
  //     0,
  //     productsList.firstWhere((element) => element.barcode == keyWord,
  //         orElse: null));
  Future<List<Product>> search(String keyWord, bool sales, bool barcode) {
    if (keyWord.isEmpty) {
      return db.isar.products.where().findAll();
    }
    if (barcode) {
      return db.isar.products.filter().barcodeEqualTo(keyWord).findAll();
    }
    return db.isar.products
        .filter()
        .nameEqualTo(keyWord) // Exact match
        .or()
        .nameStartsWith(keyWord) // Products starting with keyword
        .or()
        .nameContains(keyWord)
        .sortByName()
        .thenByCount()
        .thenByOffer() // Partial match
        // Sorting as described earlier
        .findAll();
  }

  // for (var i = 0; i < productsList.length; i++) {
  //   if (productsList[i].name!.startsWith(keyWord) ||
  //       productsList[i].name!.contains(keyWord)) {
  //     searchTemp.insert(0, productsList[i]);
  //     searchTemp.sort((a, b) {
  //       if (a.count == 0 && b.count != 0) {
  //         return 1; // a should come after b
  //       } else if (a.count != 0 && b.count == 0) {
  //         return -1; // a should come before b
  //       } else {
  //         return 0; // if both have stock or both are out of stock, leave them in the same order
  //       }
  //     });
  //     // searchTemp.
  //     notifyListeners();
  //   }
  // }
  // if (sales) {
  //   if (searchTemp.isEmpty) {
  //     searchTemp.add(
  //       Product.named(
  //         name: keyWord,
  //         ownerName: '',
  //         barcode: 'barcode',
  //         buyprice: 1,
  //         sellPrice: 1,
  //         count: 0,
  //         weightable: false,
  //         wholeUnit: 'wholeUnit',
  //         offer: false,
  //         offerCount: 0,
  //         offerPrice: 0,
  //         priceHistory: [],
  //         endDate: DateTime.now(),
  //         hot: true,
  //       ),
  //     );
  //     notifyListeners();
  //   }
  // }

  Future<void> addLoaner(
    String name,
    String phone,
    String location,
  ) async {
    var uuid = Uuid();

    db.insertLoaner(Loaner(
      name: name,
      // ID: uuid.v1(),
      phoneNumber: phone,
      location: location,
      lastPayment: [],
      // lastPaymentDate: DateTime.now(),
      loanedAmount: 0,
    )..ID);

    loanersList = await db.getLoaners();

    notifyListeners();
  }

  int generateLoanerId() {
    // Get the current time in milliseconds since epoch
    int millisecondsSinceEpoch = DateTime.now().millisecondsSinceEpoch;

    // Create an instance of the Random class with a time-based seed
    Random random = Random(millisecondsSinceEpoch);

    // Generate a random 4-digit number
    int min = 1000;
    int max = 9999;
    int random4DigitNumber = min + random.nextInt(max - min + 1);

    return random4DigitNumber;
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

  int getProductCount(String name) {
    if (productsList.isNotEmpty) {
      Product temp = productsList.firstWhere(
        (element) => element.name == name,
        orElse: () => Product.named(
          name: 'name',
          barcode: '',
          buyprice: 0,
          sellPrice: 0,
          count: 999,
          ownerName: '',
          weightable: true,
          wholeUnit: '',
          offer: false,
          offerCount: 0,
          offerPrice: 0,
          priceHistory: [],
          endDate: DateTime(2024),
          hot: false,
        ),
      );
      return temp.count!;
    } else {
      return 909;
    }
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
}
