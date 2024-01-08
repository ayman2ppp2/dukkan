import 'package:dukkan/providers/salesProvider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';
import '../pages/InsertPage.dart';

class GridItem extends StatelessWidget {
  final String name;

  const GridItem({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, li, child) {
        int index = li.productsList.indexWhere(
          (element) => element.name == name,
        );
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
                    li.productsList[index].name,
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
                    'البيع : ${NumberFormat.simpleCurrency().format((li.productsList[index].sellprice))}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الشراء : ${NumberFormat.simpleCurrency().format((li.productsList[index].buyprice))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الربح : ${NumberFormat.simpleCurrency().format((li.productsList[index].sellprice - li.productsList[index].buyprice))}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    'الكمية : ${li.productsList[index].count}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Consumer<Lists>(
                  builder: (context, as, child) => Row(
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
                                    value: as,
                                    child: ChangeNotifierProvider.value(
                                      value: li,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                          top: 100,
                                          bottom: 250,
                                        ),
                                        child: InPage(
                                          buyPrice:
                                              li.productsList[index].buyprice,
                                          count: li.productsList[index].count,
                                          name: li.productsList[index].name,
                                          sellPrice:
                                              li.productsList[index].sellprice,
                                          index: index,
                                          owner:
                                              li.productsList[index].ownerName,
                                          wholeUnit:
                                              li.productsList[index].wholeUnit,
                                          weightable:
                                              li.productsList[index].weightable,
                                          offer: li.productsList[index].offer,
                                          offerCount:
                                              li.productsList[index].offerCount,
                                          offerPrice:
                                              li.productsList[index].offerPrice,
                                          endDate:
                                              li.productsList[index].endDate,
                                          priceHistory: li
                                              .productsList[index].priceHistory,
                                        ),
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
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              '${(100 * (li.productsList[index].sellprice - li.productsList[index].buyprice) / li.productsList[index].buyprice).toStringAsFixed(2)}%'),
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
                                          li.removeProduct(index: index);
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
