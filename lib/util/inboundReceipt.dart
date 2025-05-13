import 'package:dukkan/pages/CheckOutPage.dart';
import 'package:dukkan/pages/searchPage.dart';
import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/inboundListItem.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/myListItem.dart';
import 'package:dukkan/util/scanner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';

class inboundReceipt extends StatefulWidget {
  const inboundReceipt({super.key});

  @override
  State<inboundReceipt> createState() => _inboundReceiptState();
}

class _inboundReceiptState extends State<inboundReceipt> {
  TrackingScrollController con = TrackingScrollController();

  @override
  Widget build(BuildContext context) {
    var exp = Provider.of<ExpenseProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('فاتورة واردة'),
        backgroundColor: Colors.brown,
      ),
      body: Consumer<SalesProvider>(
        builder: (context, sa, child) {
          return LayoutBuilder(builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 800;

            return Column(
              children: [
                Expanded(
                  child: Scrollbar(
                      controller: con,
                      interactive: true,
                      thumbVisibility: true,
                      child: isDesktop
                          ? GridView.builder(
                              controller: con,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    (MediaQuery.of(context).size.width ~/ 180)
                                        .clamp(1, 5),
                                crossAxisSpacing:
                                    (MediaQuery.of(context).size.width * 0.09)
                                        .clamp(5.0, 20.0),
                                mainAxisSpacing:
                                    (MediaQuery.of(context).size.width * 0.05)
                                        .clamp(5.0, 20.0),
                                childAspectRatio: (MediaQuery.of(context)
                                            .size
                                            .width /
                                        MediaQuery.of(context).size.height) *
                                    0.9,
                              ),
                              itemCount: sa.inboundList.length,
                              itemBuilder: (context, index) {
                                return Dismissible(
                                  key: ValueKey(sa.sellList[index]),
                                  onDismissed: (direction) {
                                    setState(() {
                                      sa.sellList.removeAt(index);
                                    });
                                  },
                                  background: Container(
                                    color: Colors.red[100],
                                    alignment: Alignment.centerRight,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child:
                                          Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.brown[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: MyListTile(
                                        product: sa.sellList[index],
                                        index: index,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : ListView.builder(
                              controller: con,
                              itemCount: sa.inboundList.length,
                              itemBuilder: (context, index) {
                                return Dismissible(
                                  key: ValueKey(sa.inboundList[index]),
                                  onDismissed: (direction) {
                                    setState(() {
                                      sa.inboundList.removeAt(index);
                                    });
                                  },
                                  background: Container(
                                    color: Colors.red[100],
                                    alignment: Alignment.centerRight,
                                    child: const Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 20),
                                      child:
                                          Icon(Icons.delete, color: Colors.red),
                                    ),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.brown[200],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: inboundItem(
                                        product: sa.inboundList[index],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 10),
                      child: IconButton.filled(
                        onPressed: () {
                          // print(sa.db.hasna(id: 9533));
                          sa.refreshProductsList();
                          showGeneralDialog(
                            barrierDismissible: true,
                            barrierLabel: 'tet',
                            context: context,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    ChangeNotifierProvider.value(
                              value: sa,
                              child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(40, 150, 40, 10),
                                child: SearchPage(
                                  inbound: true,
                                ),
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
                          backgroundColor: WidgetStatePropertyAll(
                            Colors.brown[400],
                          ),
                          elevation: const WidgetStatePropertyAll(20),
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
                                'total : ${NumberFormat.simpleCurrency().format((sa.inboundList.fold(00.0, (previousValue, element) => previousValue + (element.buyprice! * element.count!))))}')),
                      ),
                    ),
                    // 2nd button
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20, top: 10),
                      child: Consumer<Lists>(
                        builder: (context, li, child) => IconButton.filled(
                          onPressed: () {
                            // sa.refreshLoanersList();
                            if (sa.inboundList.isNotEmpty) {
                              showGeneralDialog(
                                context: context,
                                pageBuilder:
                                    (context, animation, secondaryAnimation) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 20,
                                      top: 100,
                                    ),
                                    child: ChangeNotifierProvider.value(
                                      value: exp,
                                      child: ChangeNotifierProvider.value(
                                        value: sa,
                                        child: ChangeNotifierProvider.value(
                                          value: li,
                                          child: CheckOut(
                                            total: (sa.inboundList.fold(
                                              00.0,
                                              (previousValue, element) =>
                                                  previousValue +
                                                  (element.buyprice! *
                                                      element.count!),
                                            )),
                                            lst: sa.inboundList,
                                            inbound: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('يجب تحديد منتجات اولآ ')));
                            }
                          },
                          icon: const Icon(
                            Icons.price_check_outlined,
                            color: Colors.white,
                          ),
                          iconSize: 40,
                          style: ButtonStyle(
                            backgroundColor: WidgetStatePropertyAll(
                              Colors.brown[400],
                            ),
                            elevation: const WidgetStatePropertyAll(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          });
        },
      ),
    );
  }
}
