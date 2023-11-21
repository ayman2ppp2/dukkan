import 'package:dukkan/salesProvider.dart';
import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

import '../list.dart';

class MyListTile extends StatefulWidget {
  late Product product;
  int nmPicker = 1;
  late int index;
  MyListTile({super.key, required this.product, required this.index});

  @override
  State<MyListTile> createState() => _MyListTileState();
}

class _MyListTileState extends State<MyListTile> {
  String weight = "";
  int gg = 0;
  int _multiplyer = 1;

  TextEditingController con = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, li, child) {
        return ListTile(
          leading: (widget.product.offer &&
                  widget.product.count % widget.product.offerCount == 0)
              ? Text(NumberFormat.simpleCurrency()
                  .format(widget.product.offerPrice))
              : Text(NumberFormat.simpleCurrency()
                  .format(widget.product.sellprice)),
          title: Center(child: Text(widget.product.name)),
          trailing: widget.product.weightable
              ? Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${widget.product.count}جم',
                          style: const TextStyle(fontSize: 15)),
                      Flexible(
                          flex: 2,
                          child: Consumer<SalesProvider>(
                            builder: (context, sa, child) => PopupMenuButton(
                              onSelected: (value) {
                                sa.updateSellListCount(
                                    index: widget.index, count: value.toInt());
                                switch (value) {
                                  case 1000:
                                    weight = 'كيلو';
                                  case 500:
                                    weight = 'نص كيلو';
                                  case 250:
                                    weight = 'ربع كيلو';
                                  case 850:
                                    weight = 'تمنة';
                                  case 425:
                                    weight = 'نص تمنة';
                                  case 215:
                                    weight = 'ربع تمنة';
                                  case 450:
                                    weight = 'رطل';
                                  case 225:
                                    weight = 'نص رطل';
                                  case 112.5:
                                    weight = 'ربع رطل';
                                  case 0:
                                    weight = 'وزن';
                                    break;
                                  default:
                                }
                              },
                              itemBuilder: (context) {
                                if (widget.product.wholeUnit == 'كيلو') {
                                  return List.generate(
                                    li.kg.length,
                                    (index) => PopupMenuItem(
                                      enabled: li.getProductCount(
                                              widget.product.name) >=
                                          li.kg.values.elementAt(index),
                                      value: li.kg.values.elementAt(index),
                                      child: Text(
                                        li.kg.keys.elementAt(index),
                                      ),
                                    ),
                                  );
                                }
                                if (widget.product.wholeUnit == 'تمنة') {
                                  return List.generate(
                                    li.kg.length,
                                    (index) => PopupMenuItem(
                                      enabled: li.getProductCount(
                                              widget.product.name) >=
                                          li.toumna.values.elementAt(index),
                                      value: li.toumna.values.elementAt(index),
                                      child: Text(
                                        li.toumna.keys.elementAt(index),
                                      ),
                                    ),
                                  );
                                } else {
                                  return List.generate(
                                    li.pound.length,
                                    (index) => PopupMenuItem(
                                      enabled: li.getProductCount(
                                              widget.product.name) >=
                                          li.pound.values.elementAt(index),
                                      value: li.pound.values.elementAt(index),
                                      child: Text(
                                        li.pound.keys.elementAt(index),
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                          )),

                      Flexible(
                        child: Consumer<SalesProvider>(
                          builder: (context, sa, child) => PopupMenuButton(
                            child: Text(
                              '$_multiplyer',
                              style: TextStyle(fontSize: 20),
                            ),
                            onSelected: (value) {
                              switch (weight) {
                                case 'كيلو':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 1000 * value);
                                case 'نص كيلو':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 500 * value);
                                case 'ربع كيلو':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 250 * value);
                                case 'تمنة':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 850 * value);
                                case 'نص تمنة':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 425 * value);
                                case 'ربع تمنة':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 215 * value);
                                case 'رطل':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 450 * value);
                                case 'نص رطل':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 225 * value);
                                case 'ربع رطل':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 113 * value);
                                case 'وزن':
                                  sa.updateSellListCount(
                                      index: widget.index, count: 0);
                                  break;
                                default:
                              }

                              _multiplyer = value;
                              // li.updateSellListCount(
                              //     index: widget.index,
                              //     count: widget.product.count * value);
                            },
                            itemBuilder: (context) {
                              return const [
                                PopupMenuItem(
                                  value: 1,
                                  child: Text('1'),
                                ),
                                PopupMenuItem(
                                  value: 2,
                                  child: Text('2'),
                                ),
                                PopupMenuItem(
                                  value: 3,
                                  child: Text('3'),
                                ),
                                PopupMenuItem(
                                  value: 4,
                                  child: Text('4'),
                                ),
                                PopupMenuItem(
                                  value: 5,
                                  child: Text('5'),
                                ),
                              ];
                            },
                          ),
                        ),
                      )
                      // NumberPicker(
                      //   value: widget.nmPicker,
                      //   maxValue: li.getProductCount(widget.product.name),
                      //   minValue: 1,
                      //   onChanged: (int value) {
                      //     widget.nmPicker = value;
                      //     li.updateSellListCount(
                      //         index: widget.index,
                      //         count: widget.nmPicker * widget.product.count);
                      //   },
                      //   haptics: true,
                      //   itemHeight: 40,
                      //   itemWidth: 20,
                      //   itemCount: 1,
                      // ),
                    ],
                  ),
                )
              : Consumer<SalesProvider>(
                  builder: (context, sa, child) => NumberPicker(
                    value: widget.product.count,
                    maxValue: li.getProductCount(widget.product.name),
                    minValue: 1,
                    onChanged: (int value) {
                      sa.updateSellListCount(index: widget.index, count: value);
                    },
                    haptics: true,
                    itemHeight: 40,
                    itemWidth: 60,
                    itemCount: 1,
                  ),
                ),
          subtitle: widget.product.weightable && weight == 'وزن'
              ? Consumer<SalesProvider>(
                  builder: (context, sa, child) => TextFormField(
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    controller: con,

                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        gg = (((double.tryParse(value) ?? 0) ~/
                                (widget.product.sellprice)))
                            .toInt();
                        sa.updateSellListCount(index: widget.index, count: gg);
                      }
                      if ((double.tryParse(value) ?? 0) >=
                          li.getProductCount(widget.product.name) *
                              widget.product.sellprice) {
                        // setState(() {
                        con.text = NumberFormat.simpleCurrency().format(
                            (li.getProductCount(widget.product.name) *
                                widget.product.sellprice));
                        sa.updateSellListCount(
                            index: widget.index,
                            count: li.getProductCount(widget.product.name));
                        // });
                      }
                    },
                    // enabled: ,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    (widget.product.offer &&
                            widget.product.count % widget.product.offerCount ==
                                0)
                        ? Text(
                            "total : ${NumberFormat.simpleCurrency().format((widget.product.count * widget.product.offerPrice))}")
                        : Text(
                            "total : ${NumberFormat.simpleCurrency().format((widget.product.count * widget.product.sellprice))}"),
                  ],
                ),
        );
      },
    );
  }
}
// my to do list 
// first change the adapter for hive this is a breacking change that will throw away all of our data
// check if the product is wightable or not to build different ui for it
// implement the collictions style for products from now on
// 

/*DropdownMenu(
                          inputDecorationTheme: const InputDecorationTheme(
                            border: UnderlineInputBorder(),
                          ),
                          onSelected: (value) {
                            weight = (value as double).toString();
                            li.updateSellListCount(
                              index: widget.index,
                              count: double.parse('${value as double}').toInt(),
                            );
                          },
                          width: 120,
                          initialSelection: '0',
                          dropdownMenuEntries:
                              widget.product.wholeUnit == 'كيلو'
                                  ? List.generate(
                                      li.kg.length,
                                      (index) => DropdownMenuEntry(
                                        value: li.kg.values.elementAt(index),
                                        label: li.kg.keys.elementAt(index),
                                      ),
                                    )
                                  : List.generate(
                                      li.kg.length,
                                      (index) => DropdownMenuEntry(
                                        value: li.pound.values.elementAt(index),
                                        label: li.pound.keys.elementAt(index),
                                      ),
                                    ),
                        ),*/


// I need a redisgn of this widget asap