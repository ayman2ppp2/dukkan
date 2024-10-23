import 'package:dukkan/pages/InsertPage.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/addUser.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/myGridItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart' as ii;
import 'package:provider/provider.dart';

import '../providers/list.dart';

class InvPage extends StatefulWidget {
  const InvPage({super.key});

  @override
  State<InvPage> createState() => _InvPageState();
}

class _InvPageState extends State<InvPage> {
  TextEditingController controller = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, as, child) {
        as.initializeStream();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.brown,
            iconTheme: IconThemeData(color: Colors.brown[50]),
            actions: [
              Consumer<Lists>(
                builder: (context, li, child) => IconButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return ChangeNotifierProvider.value(
                          value: li,
                          child: AddUser(),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.person_add),
                  tooltip: 'إضافة مالك',
                ),
              ),
            ],
            title: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'المخزن',
                    style: TextStyle(
                        color: Colors.brown[50],
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Consumer<Lists>(
                    builder: (context, as, child) => StreamBuilder(
                      stream: as.getTotalBuyPrice(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Text(
                              style: TextStyle(
                                  color: Colors.brown[50],
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold),
                              '${snapshot.error.toString()}');
                        }
                        if (snapshot.hasData) {
                          return Text(
                            ' رأس المال : ${ii.NumberFormat.simpleCurrency().format(snapshot.data!.fold(0.0, (previousValue, element) => previousValue + element.buyprice! * element.count!))}',
                            style: TextStyle(
                                color: Colors.brown[50],
                                fontSize: 15,
                                fontWeight: FontWeight.bold),
                          );
                        }
                        return SpinKitChasingDots(
                          color: Colors.brown[50],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.brown[200],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                        controller: controller,
                        textDirection: TextDirection.rtl,
                        decoration: const InputDecoration(hintText: 'إبحث'),
                        onChanged: (value) {
                          as.search(value, false, false).then((value) {
                            setState(() {});
                          });
                        }),
                  ),
                ),
              ),
              Expanded(
                  child: FutureBuilder(
                future: as.search(controller.text, false, false),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  List<Product> products = snapshot.data!;

                  if (products.isEmpty) {
                    return Center(child: Text('No Products found'));
                  }
                  // Implement the sorting logic here
                  // products.sort((a, b) {
                  //   if (a.count == 0 && b.count != 0) {
                  //     return 1; // a should come after b
                  //   } else if (a.count != 0 && b.count == 0) {
                  //     return -1; // a should come before b
                  //   } else {
                  //     return 0; // if both have stock or both are out of stock, leave them in the same order
                  //   }
                  // });

                  // Check if products are empty and sales is true
                  // if (products.isEmpty) {
                  //   if (sales) {
                  //     products.add(
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
                  //   }
                  // }

                  // Now display the products, which includes the hot product if applicable
                  return GridView.builder(
                    itemCount: products.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                    ),
                    itemBuilder: (context, index) {
                      return GridItem(
                        id: products[index].id,
                      );
                    },
                  );
                },
              )),
            ],
          ),
          floatingActionButton: Consumer<Lists>(
            builder: (context, li, child) => FloatingActionButton(
              onPressed: () async {
                showGeneralDialog(
                  barrierDismissible: true,
                  barrierLabel: 'whatever',
                  context: context,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    return ChangeNotifierProvider.value(
                      value: li,
                      child: ChangeNotifierProvider.value(
                        value: as,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 100,
                            bottom: 200,
                          ),
                          child: InPage(
                            id: null,
                            buyPrice: 0,
                            count: 0,
                            name: '',
                            barcode: '',
                            sellPrice: 0,
                            owner: '',
                            weightable: false,
                            wholeUnit: '',
                            index: -1,
                            offer: false,
                            offerCount: 0,
                            offerPrice: 0,
                            endDate: DateTime.now(),
                            priceHistory: [],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }
}
