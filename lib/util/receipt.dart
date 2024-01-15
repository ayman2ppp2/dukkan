import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';

class Receipt extends StatefulWidget {
  final Log log;

  Receipt({required this.log, super.key});

  @override
  State<Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  bool expand = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.brown[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('${DateFormat.yMEd().add_jmz().format(widget.log.date)}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(NumberFormat.simpleCurrency().format(widget.log.price) +
                    ' : السعر'),
                Text(NumberFormat.simpleCurrency().format(widget.log.profit) +
                    ' : الربح'),
                Consumer<Lists>(
                  builder: (context, li, child) => Consumer<SalesProvider>(
                    builder: (context, sa, child) => IconButton(
                      // Provider.of<Lists>(context, listen: false)
                      //       .cancelReceipt(widget.log.date, widget.log);
                      //   Provider.of<SalesProvider>(context, listen: false)
                      //       .refreshProductsList();
                      onPressed: () {
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
                                    li.cancelReceipt(
                                        widget.log.date, widget.log);
                                    sa.refreshProductsList();
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
                      icon: Icon(Icons.keyboard_return_rounded),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      expand = !expand;
                    });
                  },
                  icon: expand
                      ? Icon(Icons.expand_less_rounded)
                      : Icon(Icons.expand_more_rounded),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(NumberFormat.simpleCurrency().format(widget.log.discount) +
                    ' : الخصم'),
                Text(NumberFormat.simpleCurrency()
                        .format(countSpecial(widget.log)) +
                    ' : سلع خاصة'),
                Consumer<Lists>(
                  builder: (context, li, child) => Consumer<SalesProvider>(
                    builder: (context, sa, child) => IconButton(
                      onPressed: () {
                        li.editing = true;
                        li.logID =
                            '${widget.log.date.year}-${widget.log.date.month}-${widget.log.date.day}-${widget.log.date.hour}-${widget.log.date.minute}-${widget.log.date.second}';
                        sa.sellList.addAll(widget.log.products);
                        sa.refresh();
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.edit_note_rounded),
                    ),
                  ),
                ),
              ],
            ),
            expand
                ? SizedBox(
                    height: 200,
                    child: ListView(
                      children: widget.log.products
                          .map(
                            (e) => ListTile(
                              title: Text('${e.name}'),
                              leading: (e.offer && e.count % e.offerCount == 0)
                                  ? Text(NumberFormat.simpleCurrency()
                                      .format(e.offerPrice))
                                  : Text(NumberFormat.simpleCurrency()
                                      .format(e.sellprice)),
                              trailing: Text('${e.count}'),
                              subtitle: (e.offer && e.count % e.offerCount == 0)
                                  ? Text(
                                      "total : ${NumberFormat.simpleCurrency().format((e.count * e.offerPrice))}")
                                  : Text(
                                      "total : ${NumberFormat.simpleCurrency().format((e.count * e.sellprice))}"),
                            ),
                          )
                          .toList(),
                    ),
                  )
                : Container()
          ],
        ),
      ),
    );
  }

  double countSpecial(Log log) {
    var sum = 0.0;
    for (var element in widget.log.products) {
      if (element.hot) {
        sum += element.sellprice * element.count;
      }
    }
    return sum;
  }
}
