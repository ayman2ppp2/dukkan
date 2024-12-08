import 'package:dukkan/providers/salesProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';
import '../pages/InsertPage.dart';

class GridItem extends StatelessWidget {
  final int id;

  const GridItem({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    var li = Provider.of<SalesProvider>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: StreamBuilder(
            stream: li.watchProduct(id),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        snapshot.data!.name!,
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
                        'البيع : ${NumberFormat.simpleCurrency().format((snapshot.data!.sellPrice))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'الشراء : ${NumberFormat.simpleCurrency().format((snapshot.data!.buyprice))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'الربح : ${NumberFormat.simpleCurrency().format((snapshot.data!.sellPrice! - snapshot.data!.buyprice!))}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'الكمية : ${snapshot.data!.count}',
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
                                    pageBuilder: (context, animation,
                                        secondaryAnimation) {
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
                                              id: snapshot.data!.id,
                                              buyPrice:
                                                  snapshot.data!.buyprice!,
                                              count: snapshot.data!.count!,
                                              name: snapshot.data!.name!,
                                              barcode: snapshot.data!.barcode!,
                                              sellPrice:
                                                  snapshot.data!.sellPrice!,
                                              index: li.productsList.indexWhere(
                                                  (element) =>
                                                      element.id ==
                                                      snapshot.data!.id),
                                              owner: snapshot.data!.ownerName!,
                                              wholeUnit:
                                                  snapshot.data!.wholeUnit!,
                                              weightable:
                                                  snapshot.data!.weightable!,
                                              offer: snapshot.data!.offer!,
                                              offerCount:
                                                  snapshot.data!.offerCount!,
                                              offerPrice:
                                                  snapshot.data!.offerPrice!,
                                              endDate: snapshot.data!.endDate!,
                                              priceHistory: List.from(
                                                  snapshot.data!.priceHistory,
                                                  growable: true),
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
                                  '${(100 * (snapshot.data!.sellPrice! - snapshot.data!.buyprice!) / snapshot.data!.buyprice!).toStringAsFixed(2)}%'),
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
                                            onPressed: () async {
                                              Navigator.pop(context);
                                              await li.removeProduct(
                                                  id: snapshot.data!.id);
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
                );
              }
              if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              }
              return SpinKitChasingDots(
                color: Colors.brown[200],
              );
            }),
      ),
    );
  }
}
