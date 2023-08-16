import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

import '../list.dart';

class MyListTile extends StatefulWidget {
  late Product product;

  late int index;
  MyListTile({super.key, required this.product, required this.index});

  @override
  State<MyListTile> createState() => _MyListTileState();
}

class _MyListTileState extends State<MyListTile> {
  String weight = "";
  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        return ListTile(
          leading: Text(widget.product.sellprice.toString()),
          title: Center(child: Text(widget.product.name)),
          trailing: widget.product.weightable
              ? Container(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('${widget.product.count}ج',
                          style: const TextStyle(fontSize: 15)),
                      PopupMenuButton(
                        onSelected: (value) {
                          li.updateSellListCount(
                              index: widget.index, count: value.toInt());
                          switch (value) {
                            case 1000:
                              weight = 'كيلو';
                            case 500:
                              weight = 'نص كيلو';
                            case 250:
                              weight = 'ربع كيلو';
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
                                value: li.kg.values.elementAt(index),
                                child: Text(
                                  li.kg.keys.elementAt(index),
                                ),
                              ),
                            );
                          } else {
                            return List.generate(
                              li.kg.length,
                              (index) => PopupMenuItem(
                                value: li.pound.values.elementAt(index),
                                child: Text(
                                  li.pound.keys.elementAt(index),
                                ),
                              ),
                            );
                          }
                        },
                      )
                    ],
                  ),
                )
              : NumberPicker(
                  value: widget.product.count,
                  maxValue: li.getProductCount(widget.product.name),
                  minValue: 1,
                  onChanged: (int value) {
                    li.updateSellListCount(index: widget.index, count: value);
                  },
                  haptics: true,
                  itemHeight: 40,
                  itemWidth: 60,
                  itemCount: 1,
                ),
          subtitle: widget.product.weightable && weight == 'وزن'
              ? TextField(
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      int gg = (double.parse(value) / widget.product.sellprice)
                          .ceil();
                      li.updateSellListCount(index: widget.index, count: gg);
                    }
                  },
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        "total : ${(widget.product.count * widget.product.sellprice).toStringAsFixed(2)}"),
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