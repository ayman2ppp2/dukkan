import 'dart:math';

import 'package:dukkan/util/Log.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
            Text(
                '${widget.log.date.year}-${widget.log.date.month}-${widget.log.date.day}-${widget.log.date.hour}-${widget.log.date.minute}-${widget.log.date.second}'),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(NumberFormat.simpleCurrency().format(widget.log.price) +
                    ' : السعر'),
                Text(NumberFormat.simpleCurrency().format(widget.log.profit) +
                    ' : الربح'),
                IconButton(
                  onPressed: () {
                    setState(() {
                      expand = !expand;
                    });
                  },
                  icon: expand
                      ? Icon(Icons.expand_less_rounded)
                      : Icon(Icons.expand_more_rounded),
                )
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
}
