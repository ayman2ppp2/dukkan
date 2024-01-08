import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
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
  late Product product;
  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, li, child) {
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
                    child: TextField(
                      autofocus: true,
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(
                        hintText: 'ابحث',
                      ),
                      onChanged: (value) {
                        // Future.delayed(Duration(milliseconds: 200))
                        //     .then((gg) => li.search(value, true));
                        li.search(value, true);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: li.searchTemp.isEmpty
                        ? li.productsList.length
                        : li.searchTemp.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        enabled: li.searchTemp.isEmpty
                            ? li.isProductOutOFStock(
                                li.productsList[index].name)
                            : li.isProductOutOFStock(li.searchTemp[index].name),
                        title: Text(
                          li.searchTemp.isEmpty
                              ? li.productsList[index].name
                              : li.searchTemp[index].name,
                        ),
                        trailing: Text(
                          li.searchTemp.isEmpty
                              ? li.productsList[index].sellprice
                                  .toStringAsFixed(2)
                              : li.searchTemp[index].sellprice
                                  .toStringAsFixed(2),
                        ),
                        onTap: () {
                          li.searchTemp.isEmpty
                              ? product = li.productsList[index]
                              : product = li.searchTemp[index];
                          li.sellList.add(Product(
                            barcode: product.barcode,
                            name: product.name,
                            buyprice: product.buyprice,
                            sellprice: product.sellprice,
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
                      );
                    },
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
