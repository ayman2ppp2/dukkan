// import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/scanner.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  // final List<String> searchList;
  // final TextEditingController controller;

  // void Function(String name) setname;
  // int sellListIndex;

  SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController controller = TextEditingController();
  late Product product;
  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, li, child) {
        li.initializeStream();
        return Material(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.brown[200],
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Flex(
                      direction: Axis.horizontal,
                      children: [
                        Expanded(
                          flex: 6,
                          child: TextField(
                            controller: controller,
                            autofocus: true,
                            textDirection: TextDirection.rtl,
                            decoration: const InputDecoration(
                              hintText: 'ابحث',
                            ),
                            onChanged: (value) {
                              // Future.delayed(Duration(milliseconds: 200))
                              //     .then((gg) => li.search(value, true));
                              li
                                  .search(controller.text, true, false)
                                  .then((value) {
                                setState(() {});
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: IconButton(
                            onPressed: () {
                              showGeneralDialog(
                                context: context,
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ChangeNotifierProvider.value(
                                  value: li,
                                  child: Scanner(),
                                ),
                              );
                            },
                            icon: Icon(Icons.qr_code_scanner),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                    child: FutureBuilder(
                  future: li.search(controller.text, true, false),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData) {
                      return Center(child: CircularProgressIndicator());
                    }
                    // for (var product in snapshot.data!) {
                    //   print(product.toJson());
                    // }
                    List<Product> products = snapshot.data!;

                    for (var element in products) {
                      print(element.toJson());
                    }

                    // Implement the sorting logic here
                    products.sort((a, b) {
                      if (a.count == 0 && b.count != 0) {
                        return 1; // a should come after b
                      } else if (a.count != 0 && b.count == 0) {
                        return -1; // a should come before b
                      } else {
                        return 0; // if both have stock or both are out of stock, leave them in the same order
                      }
                    });

                    // Check if products are empty and sales is true
                    if (products.isEmpty) {
                      products.add(
                        Product.named(
                          name: controller.text,
                          ownerName: '',
                          barcode: 'barcode',
                          buyprice: 1,
                          sellPrice: 1,
                          count: 0,
                          weightable: false,
                          wholeUnit: 'wholeUnit',
                          offer: false,
                          offerCount: 0,
                          offerPrice: 0,
                          priceHistory: [],
                          endDate: DateTime.now(),
                          hot: true,
                        ),
                      );
                    }

                    // Now display the products, which includes the hot product if applicable
                    return ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        return Container(
                          color: li.isProductOutOfDate(products[index].name!)
                              ? Colors.red[100]
                              : Colors.transparent,
                          child: ListTile(
                            enabled:
                                li.isProductOutOFStock(products[index].name!),
                            title: Text(products[index].name!),
                            trailing: Text(
                                products[index].sellPrice!.toStringAsFixed(2)),
                            onTap: () {
                              li.searchTemp.isEmpty
                                  ? product = products[index]
                                  : product = products[index];
                              li.sellList.add(Product.named2(
                                id: product.id,
                                barcode: product.barcode,
                                name: product.name,
                                buyprice: product.buyprice,
                                sellPrice: product.sellPrice,
                                count: 1,
                                ownerName: product.ownerName,
                                weightable: product.weightable,
                                wholeUnit: product.wholeUnit,
                                offer: product.offer,
                                offerCount: product.offerCount,
                                offerPrice: product.offerPrice,
                                priceHistory: product.priceHistory,
                                endDate: product.endDate,
                                hot: product.hot,
                              ));
                              Navigator.pop(context);
                              li.searchTemp.clear();
                              li.refresh();
                            },
                          ),
                        );
                      },
                    );
                  },
                ))
              ],
            ),
          ),
        );
      },
    );
  }
}
