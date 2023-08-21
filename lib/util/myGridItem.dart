import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../list.dart';
import '../pages/InsertPage.dart';

class GridItem extends StatelessWidget {
  final Product product;
  const GridItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        return Padding(
          padding: const EdgeInsets.all(10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.brown[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Expanded(
                  child: Text(
                    'البيع : ${product.sellprice}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الشراء : ${product.buyprice}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الربح : ${(product.sellprice - product.buyprice).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الكمية : ${product.count}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.brown[200],
                        borderRadius: const BorderRadius.only(
                          topRight: Radius.circular(12),
                          bottomLeft: Radius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: GestureDetector(
                          onTap: () {
                            showGeneralDialog(
                              barrierDismissible: true,
                              barrierLabel: 'whatever',
                              context: context,
                              pageBuilder:
                                  (context, animation, secondaryAnimation) {
                                return ChangeNotifierProvider.value(
                                  value: li,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 100,
                                      bottom: 250,
                                    ),
                                    child: InPage(
                                      buyPrice: product.buyprice,
                                      count: product.count,
                                      name: product.name,
                                      sellPrice: product.sellprice,
                                      index: li.productsList.indexWhere(
                                          (element) =>
                                              element.name == product.name),
                                      owner: product.ownerName,
                                      wholeUnit: product.wholeUnit,
                                      weightable: product.weightable,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: const Icon(Icons.edit),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.brown[200],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          bottomRight: Radius.circular(12),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text(
                                    'هل انت متاكد',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        li.removeProduct(
                                          index: li.productsList.indexWhere(
                                              (element) =>
                                                  element.name == product.name),
                                        );
                                        li.refreshProductsList();
                                      },
                                      child: const Text(
                                        'نعم',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'لا',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: const Icon(Icons.delete_outline_rounded),
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
