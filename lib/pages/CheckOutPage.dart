// ignore_for_file: use_build_context_synchronously

import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loadingOverlay.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class CheckOut extends StatefulWidget {
  final List<Product> lst;
  final double total;
  final bool inbound;

  CheckOut(
      {super.key,
      required this.lst,
      required this.total,
      required this.inbound});

  @override
  State<CheckOut> createState() => _CheckOutState();
}

class _CheckOutState extends State<CheckOut> {
  int radio = 0;
  int? loanerID;
  int? expenseID;
  TextEditingController con = TextEditingController();

  String discount = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: widget.inbound
            ? Center(
                child: const Text(
                  'فاتورة إدخال',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              )
            : Flex(
                direction: Axis.horizontal,
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    flex: 0,
                    child: const Text(
                      'الفاتورة',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (radio == 1) // Loaner selection
                          Expanded(
                            flex: 4,
                            child: FutureBuilder(
                              future: Provider.of<SalesProvider>(context,
                                      listen: false)
                                  .refreshLoanersList(),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text(snapshot.error.toString());
                                }
                                if (snapshot.hasData) {
                                  var loanerOptions = snapshot.data!
                                      .map((loaner) => DropdownMenuEntry(
                                            value: loaner.ID,
                                            label: loaner.name!,
                                          ))
                                      .toList();
                                  return DropdownMenu(
                                    onSelected: (value) {
                                      loanerID = value;
                                    },
                                    dropdownMenuEntries: loanerOptions,
                                    label: const Text(
                                      'الدائن',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    width: 114,
                                    menuHeight: 300,
                                    menuStyle: const MenuStyle(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }
                                return const SpinKitChasingDots(
                                  color: Colors.white,
                                  size: 50,
                                );
                              },
                            ),
                          ),
                        if (radio == 2) // Expense selection
                          Expanded(
                            flex: 4,
                            child: StreamBuilder(
                              stream: Provider.of<ExpenseProvider>(context,
                                      listen: false)
                                  .getIndvidualExpenses(fixed: false),
                              builder: (context, snapshot) {
                                if (snapshot.hasError) {
                                  return Text(snapshot.error.toString());
                                }
                                if (snapshot.hasData) {
                                  var expenseOptions = snapshot.data!
                                      .map((expense) => DropdownMenuEntry(
                                            value: expense.ID,
                                            label: expense.name!,
                                          ))
                                      .toList();
                                  return DropdownMenu(
                                    onSelected: (value) {
                                      expenseID = value;
                                    },
                                    dropdownMenuEntries: expenseOptions,
                                    label: const Text(
                                      'المنصرف',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    menuStyle: const MenuStyle(
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  );
                                }
                                return const SpinKitChasingDots(
                                  color: Colors.white,
                                  size: 50,
                                );
                              },
                            ),
                          ),
                        Expanded(
                          flex: 0,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Loan radio button
                              Row(
                                children: [
                                  const Text(
                                    'دين',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 17),
                                  ),
                                  Radio(
                                    value: 1,
                                    groupValue: radio,
                                    onChanged: (value) => setState(() {
                                      radio = value!;
                                    }),
                                  ),
                                ],
                              ),
                              // Expense radio button
                              Row(
                                children: [
                                  const Text(
                                    'منصرف',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15),
                                  ),
                                  Radio(
                                    value: 2,
                                    groupValue: radio,
                                    onChanged: (value) => setState(() {
                                      radio = value!;
                                    }),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        backgroundColor: Colors.brown,
      ),
      body: ClipRRect(
        child: Banner(
          location: BannerLocation.bottomStart,
          message: discount.isEmpty ? 'لايوجد خصم' : 'خصم $discount ج',
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: widget.lst.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.brown[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: widget.inbound
                              ? Text(NumberFormat.simpleCurrency()
                                  .format(widget.lst[index].buyprice))
                              : (widget.lst[index].offer! &&
                                      widget.lst[index].count! %
                                              widget.lst[index].offerCount! ==
                                          0)
                                  ? Text(NumberFormat.simpleCurrency()
                                      .format(widget.lst[index].offerPrice))
                                  : Text(NumberFormat.simpleCurrency()
                                      .format(widget.lst[index].sellPrice)),
                          title: Text(widget.lst[index].name!),
                          trailing: Text(widget.lst[index].count.toString()),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              widget.inbound
                                  ? Text(
                                      "${NumberFormat.simpleCurrency().format((widget.lst[index].count! * widget.lst[index].buyprice!))}")
                                  : (widget.lst[index].offer! &&
                                          widget.lst[index].count! %
                                                  widget
                                                      .lst[index].offerCount! ==
                                              0)
                                      ? Text(
                                          "${NumberFormat.simpleCurrency().format((widget.lst[index].count! * widget.lst[index].offerPrice!))}")
                                      : Text(
                                          "${NumberFormat.simpleCurrency().format((widget.lst[index].count! * widget.lst[index].sellPrice!))}"),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Consumer<Lists>(
                  builder: (context, li, child) {
                    // debugPrint('77');
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: TextButton(
                            style: ButtonStyle(
                                backgroundColor:
                                    WidgetStatePropertyAll(Colors.brown[200])),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  actions: [
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          discount = '';
                                        });
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.cancel_outlined),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        setState(() {
                                          discount = con.text;
                                        });
                                        Navigator.pop(context);
                                      },
                                      icon: Icon(Icons.check_rounded),
                                    ),
                                  ],
                                  title: Text(
                                    'أدخل قيمة الخصم',
                                    style: TextStyle(
                                      fontSize: 20,
                                    ),
                                  ),
                                  content: TextFormField(
                                    controller: con,
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      var sum = 0.0;
                                      for (var element in widget.lst) {
                                        sum +=
                                            element.buyprice! * element.count!;
                                      }
                                      if ((double.tryParse(value) ?? 0) >
                                          widget.total - sum) {
                                        con.text = (widget.total - sum)
                                            .toStringAsFixed(2);
                                      }
                                    },
                                    autofocus: true,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        setState(() {});
                                        return 'please enter a number';
                                      }
                                      try {
                                        double.parse(value);
                                        setState(() {});
                                        return null;
                                      } catch (e) {
                                        print('e');
                                        setState(() {});
                                        return 'please enter a valid number';
                                      }
                                    },
                                  ),
                                ),
                              );
                            },
                            child: SizedBox(
                                height: 50,
                                child: Center(
                                    child: Text('خصم', style: TextStyle()))),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            // width: 180 % MediaQuery.of(context).size.width,
                            height: 55 % MediaQuery.of(context).size.height,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.green[400],
                            ),
                            child: Center(
                              child: Text(
                                  'المجموع : ${NumberFormat.simpleCurrency().format((widget.total - (double.tryParse(discount) ?? 0)).round())}'),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Consumer<SalesProvider>(
                            builder: (context, sa, child) => IconButton.filled(
                              onPressed: () async {
                                !(loanerID == null && radio == 1)
                                    ? showDialog(
                                        context: context,
                                        builder: (context) {
                                          return ChangeNotifierProvider.value(
                                            value: sa,
                                            child: AlertDialog(
                                              title: const Text(
                                                'هل انت متاكد',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () async {
                                                    showGeneralDialog(
                                                      context: context,
                                                      pageBuilder: (context,
                                                              animation,
                                                              secondaryAnimation) =>
                                                          LoadingOverlay(),
                                                    );
                                                    await li
                                                        .checkOut(
                                                            lst: widget.lst,
                                                            total: widget.total,
                                                            discount:
                                                                double.tryParse(
                                                                        discount) ??
                                                                    0,
                                                            LoID: loanerID,
                                                            loaned: radio == 1,
                                                            edit: li.editing,
                                                            logID: li.logID,
                                                            expense: radio == 2,
                                                            expenseId:
                                                                expenseID)
                                                        .then((value) =>
                                                            li.editing = false);
                                                    if (!widget.inbound) {
                                                      await sa
                                                          .refreshProductsList();
                                                      await li.refresh();
                                                      li.refreshListOfOwners();
                                                      sa.defaultSellList();
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    } else {
                                                      await li.inboundReceipt(
                                                          lst: widget.lst,
                                                          total: widget.total);
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                      Navigator.pop(context);
                                                    }
                                                  },
                                                  child: const Text(
                                                    'نعم',
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                                ),
                                                TextButton(
                                                  onPressed: () {
                                                    Navigator.pop(context);
                                                  },
                                                  child: const Text(
                                                    'لا',
                                                    style:
                                                        TextStyle(fontSize: 20),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      )
                                    : Null;
                              },
                              icon: const Icon(
                                Icons.checklist_outlined,
                                color: Colors.white,
                                size: 40,
                              ),
                              style: ButtonStyle(
                                backgroundColor: WidgetStatePropertyAll(
                                  Colors.green[500],
                                ),
                                elevation: const WidgetStatePropertyAll(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
