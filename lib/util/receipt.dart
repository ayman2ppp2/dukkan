import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loadingOverlay.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
    return Consumer<SalesProvider>(builder: (context, sa, child) {
      return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.brown[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        '${DateFormat.yMEd().add_jmz().format(widget.log.date)}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(NumberFormat.simpleCurrency()
                                .format(widget.log.price) +
                            ' : السعر'),
                        Text(NumberFormat.simpleCurrency()
                                .format(widget.log.profit) +
                            ' : الربح'),
                        Consumer<Lists>(
                          builder: (context, li, child) =>
                              Consumer<SalesProvider>(
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
                                          onPressed: () async {
                                            // LoadingOverlay();
                                            showGeneralDialog(
                                              context: context,
                                              pageBuilder: (context, animation,
                                                      secondaryAnimation) =>
                                                  LoadingOverlay(),
                                            );
                                            await li.cancelReceipt(
                                                widget.log.date, widget.log);
                                            Navigator.pop(context);
                                            Navigator.pop(context);
                                            // sa.refreshProductsList();
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
                        Text(NumberFormat.simpleCurrency()
                                .format(widget.log.discount) +
                            ' : الخصم'),
                        Text(NumberFormat.simpleCurrency()
                                .format(countSpecial(widget.log)) +
                            ' : سلع خاصة'),
                        Consumer<Lists>(
                          builder: (context, li, child) =>
                              Consumer<SalesProvider>(
                            builder: (context, sa, child) => IconButton(
                              // onPressed: null,
                              onPressed: () async {
                                // var temp = await li.editReceipt(
                                //     widget.log.date, widget.log);
                                // li.editing = true;
                                // li.logID = widget.log.date;
                                // sa.sellList.addAll(
                                //     temp.nonNulls.map((e) => Product.named2(
                                //         name: e.name,
                                //         ownerName: e.ownerName,
                                //         barcode: e.barcode,
                                //         buyprice: e.buyprice,
                                //         sellPrice: e.sellPrice,
                                //         count: widget.log.products.firstWhere(
                                //           (element) =>
                                //               element.productId == e.id,
                                //           orElse: () {
                                //             return EmbeddedProduct()
                                //               ..count = e.count
                                //               ..buyPrice = 1
                                //               ..sellPrice = 1
                                //               ..hot = true;
                                //           },
                                //         ).count,
                                //         weightable: e.weightable,
                                //         wholeUnit: e.wholeUnit,
                                //         offer: e.hot! ? false : e.offer,
                                //         offerCount: e.offerCount,
                                //         offerPrice: e.offerPrice,
                                //         priceHistory: e.priceHistory,
                                //         endDate: e.endDate,
                                //         hot: e.hot,
                                //         id: e.id)));
                                // sa.refresh();

                                // // li.db.logs.delete(
                                // //     '${widget.log.date.year}-${widget.log.date.month}-${widget.log.date.day}-${widget.log.date.hour}-${widget.log.date.minute}-${widget.log.date.second}');
                                // Navigator.pop(context);
                              },

                              icon: Icon(
                                Icons.edit_note_rounded,
                              ),
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
                                      leading: Text(
                                          NumberFormat.simpleCurrency()
                                              .format(e.sellPrice)),
                                      trailing: Text('${e.count}'),
                                      subtitle: Text(
                                          "total : ${NumberFormat.simpleCurrency().format((e.count! * e.sellPrice!))}"),
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                        : Container()
                  ],
                ),
              ),
              if (widget.log.loaned)
                Positioned.fill(
                  child: ClipRRect(
                      child: FutureBuilder(
                    future: sa.getLoanerName(id: widget.log.loanerID!),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        return Banner(
                          message: snapshot.data!.name!,
                          location: BannerLocation.topEnd,
                          child: SizedBox(),
                        );
                      }
                      return SpinKitChasingDots(
                        color: Colors.brown[200],
                      );
                    },
                  )),
                )
            ],
          ));
    });
  }

  double countSpecial(Log log) {
    var sum = 0.0;
    for (var element in widget.log.products!) {
      if (element.hot!) {
        sum += element.sellPrice! * element.count!;
      }
    }
    return sum;
  }
}
