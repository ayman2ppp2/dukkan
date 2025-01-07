// import 'package:dukkan/providers/list.dart';
import 'dart:async';

import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/scanner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController controller = TextEditingController();
  Future<List<Product>>? productsList;
  late SalesProvider li;

  @override
  void initState() {
    li = Provider.of<SalesProvider>(context, listen: false);
    super.initState();
    productsList = li.search('', true, false);
  }

  void _onSearchChanged(String query, SalesProvider li) {
    setState(() {
      productsList = li.search(query.trim(), true, false);
    });
  }

  @override
  Widget build(BuildContext context) {
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
                        onChanged: (value) => _onSearchChanged(value,
                            Provider.of<SalesProvider>(context, listen: false)),
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
              child: FutureBuilder<List<Product>>(
                key: ValueKey(controller.text),
                future: productsList,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}',
                          style: TextStyle(color: Colors.red)),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  List<Product> products = snapshot.data!;
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
                      var li =
                          Provider.of<SalesProvider>(context, listen: false);
                      return Container(
                        color: li.isProductOutOfDate(products[index].endDate!)
                            ? Colors.red[100]
                            : Colors.transparent,
                        child: ListTile(
                          enabled: li.isProductOutOFStock(products[index].id),
                          title: Text(products[index].name!),
                          trailing: Text(
                              products[index].sellPrice!.toStringAsFixed(2)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'المخزون: ${products[index].count}',
                                style: TextStyle(
                                  color: products[index].count == 0
                                      ? Colors.red
                                      : Colors.green,
                                ),
                              ),
                              if (products[index].offer!)
                                Text(
                                  'عرض: ${products[index].offerCount} بسعر ${(products[index].offerPrice! * products[index].offerCount!).toStringAsFixed(0)}',
                                  style: TextStyle(color: Colors.blue),
                                ),
                            ],
                          ),
                          onTap: () {
                            final selectedProduct = products[index];
                            li.sellList.add(Product.named2(
                              id: selectedProduct.id,
                              barcode: selectedProduct.barcode,
                              name: selectedProduct.name,
                              buyprice: selectedProduct.buyprice,
                              sellPrice: selectedProduct.sellPrice,
                              count: 1,
                              ownerName: selectedProduct.ownerName,
                              weightable: selectedProduct.weightable,
                              wholeUnit: selectedProduct.wholeUnit,
                              offer: selectedProduct.offer,
                              offerCount: selectedProduct.offerCount,
                              offerPrice: selectedProduct.offerPrice,
                              priceHistory: selectedProduct.priceHistory,
                              endDate: selectedProduct.endDate,
                              hot: selectedProduct.hot,
                            ));

                            // Clear search and notify
                            controller.clear();
                            li.searchTemp.clear();
                            li.refresh();

                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
