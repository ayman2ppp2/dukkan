import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/pages/CheckOutPage.dart';
import 'package:dukkan/providers/salesProvider.dart';
// import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/myListItem.dart';
import 'package:dukkan/pages/searchPage.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SellPage extends StatefulWidget {
  const SellPage({super.key});

  @override
  State<SellPage> createState() => _SellPageState();
}

class _SellPageState extends State<SellPage> {
  TrackingScrollController con = TrackingScrollController();

  @override
  Widget build(BuildContext context) {
    var exp = Provider.of<ExpenseProvider>(context, listen: false);

    return Consumer<SalesProvider>(
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
                              childAspectRatio:
                                  (MediaQuery.of(context).size.width /
                                          MediaQuery.of(context).size.height) *
                                      0.9,
                            ),
                            itemCount: sa.sellList.length,
                            itemBuilder: (context, index) {
                              return Dismissible(
                                key: ValueKey(sa.sellList[index]),
                                onDismissed: (direction) {
                                  sa.sellList.removeAt(index);
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
                            itemCount: sa.sellList.length,
                            itemBuilder: (context, index) {
                              return Dismissible(
                                key: ValueKey(sa.sellList[index]),
                                onDismissed: (direction) {
                                  sa.sellList.removeAt(index);
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
                          )),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    child: IconButton.filled(
                      onPressed: () {
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
                              'total : ${NumberFormat.simpleCurrency().format((sa.sellList.fold(00.0, (previousValue, element) => previousValue + ((element.offer! && element.count! % element.offerCount! == 0) ? (element.offerPrice! * element.count!) : (element.sellPrice! * element.count!)))))}')),
                    ),
                  ),
                  // 2nd button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    child: Consumer<Lists>(
                      builder: (context, li, child) => IconButton.filled(
                        onPressed: () {
                          sa.refreshLoanersList();
                          if (sa.sellList.isNotEmpty) {
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
                                          lst: sa.sellList,
                                          total: (sa.sellList.fold(
                                            00.0,
                                            (previousValue, element) =>
                                                previousValue +
                                                ((element.offer! &&
                                                        element.count! %
                                                                element
                                                                    .offerCount! ==
                                                            0)
                                                    ? (element.offerPrice! *
                                                        element.count!)
                                                    : (element.sellPrice! *
                                                        element.count!)),
                                          )),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
    );
  }
}
