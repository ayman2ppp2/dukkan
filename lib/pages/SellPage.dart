import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/pages/CheckOutPage.dart';
import 'package:dukkan/providers/salesProvider.dart';
// import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/myListItem.dart';
import 'package:dukkan/util/models/Product.dart';
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
    return Consumer<SalesProvider>(
      builder: (context, sa, child) {
        return Column(
          children: [
            Expanded(
              child: Scrollbar(
                controller: con,
                interactive: true,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: con,
                  scrollDirection: Axis.vertical,
                  itemCount: sa.sellList.length,
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
                      key: ValueKey<Product>(sa.sellList[index]),
                      onDismissed: (DismissDirection direction) {
                        debugPrint(direction.name);
                        setState(() {
                          sa.sellList.removeAt(index);
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
                            product: sa.sellList[index],
                            index: index,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  child: IconButton.filled(
                    onPressed: () {
                      // var LoID = '1e88c930-7a71-1e48-bab5-1de85dfff6fa';
                      // print(sa.db.loaners.values.elementAt(2).ID);
                      // sa.db.loaners.put(
                      //     LoID,
                      //     Loaner(
                      //       name: sa.db.loaners.get(LoID).name,
                      //       ID: sa.db.loaners.get(LoID).ID,
                      //       phoneNumber: sa.db.loaners.get(LoID).phoneNumber,
                      //       location: sa.db.loaners.get(LoID).location,
                      //       lastPayment: sa.db.loaners.get(LoID).lastPayment,
                      //       lastPaymentDate:
                      //           sa.db.loaners.get(LoID).lastPaymentDate,
                      //       loanedAmount: 5450,
                      //     ));
                      sa.refreshProductsList();
                      showGeneralDialog(
                        barrierDismissible: true,
                        barrierLabel: 'tet',
                        context: context,
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ChangeNotifierProvider.value(
                          value: sa,
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
                            'total : ${NumberFormat.simpleCurrency().format((sa.sellList.fold(00.0, (previousValue, element) => previousValue + ((element.offer! && element.count! % element.offerCount! == 0) ? (element.offerPrice! * element.count!) : (element.sellPrice! * element.count!)))))}')),
                  ),
                ),
                // 2nd button
                Padding(
                  padding: const EdgeInsets.only(bottom: 20, top: 10),
                  child: Consumer<Lists>(
                    builder: (context, li, child) => IconButton.filled(
                      onPressed: () {
                        var exp = Provider.of<ExpenseProvider>(context,
                            listen: false);
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
                        backgroundColor: MaterialStatePropertyAll(
                          Colors.brown[400],
                        ),
                        elevation: const MaterialStatePropertyAll(20),
                      ),
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
