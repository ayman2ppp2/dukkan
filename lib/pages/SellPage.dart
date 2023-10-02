import 'package:dukkan/list.dart';
import 'package:dukkan/pages/CheckOutPage.dart';
import 'package:dukkan/util/myListItem.dart';
import 'package:dukkan/util/product.dart';
import 'package:dukkan/util/searchPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: li.sellList.length,
                itemBuilder: (context, index) {
                  return Dismissible(
                    background: Container(
                      decoration: BoxDecoration(
                        color: Colors.brown[100],
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.brown,
                          ),
                        ],
                      ),
                    ),
                    key: ValueKey<Product>(li.sellList[index]),
                    onDismissed: (DismissDirection direction) {
                      setState(() {
                        li.sellList.removeAt(index);
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.brown[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MyListTile(
                          product: li.sellList[index],
                          index: index,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  child: IconButton.filled(
                    onPressed: () {
                      li.refreshProductsList();
                      showGeneralDialog(
                        barrierDismissible: true,
                        barrierLabel: 'tet',
                        context: context,
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ChangeNotifierProvider.value(
                          value: li,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(40, 150, 40, 10),
                            child: SearchPage(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                    iconSize: 40,
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                        Colors.brown[400],
                      ),
                      elevation: const MaterialStatePropertyAll(20),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  child: Container(
                    width: 100,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.brown[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                        child: Text(
                            'total : ${NumberFormat.simpleCurrency().format((li.sellList.fold(00.0, (previousValue, element) => previousValue + ((element.offer && element.count % element.offerCount == 0) ? (element.offerPrice * element.count) : (element.sellprice * element.count)))))}')),
                  ),
                ),
                // 2nd button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  child: IconButton.filled(
                    onPressed: () {
                      showGeneralDialog(
                        context: context,
                        pageBuilder: (context, animation, secondaryAnimation) {
                          return ChangeNotifierProvider.value(
                            value: li,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 100,
                              ),
                              child: CheckOut(
                                lst: li.sellList,
                                total: (li.sellList.fold(
                                  00.0,
                                  (previousValue, element) =>
                                      previousValue +
                                      ((element.offer &&
                                              element.count %
                                                      element.offerCount ==
                                                  0)
                                          ? (element.offerPrice * element.count)
                                          : (element.sellprice *
                                              element.count)),
                                )),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    icon: const Icon(
                      Icons.price_check_outlined,
                      color: Colors.white,
                    ),
                    iconSize: 40,
                    style: ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                        Colors.brown[400],
                      ),
                      elevation: const MaterialStatePropertyAll(20),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
