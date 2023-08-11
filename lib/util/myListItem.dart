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
                  child: DropdownMenu(
                    onSelected: (value) {
                      li.updateSellListCount(
                          index: widget.index, count: int.parse(value));
                    },
                    width: 120,
                    initialSelection: '0',
                    dropdownMenuEntries:
                        widget.product.wholeUnit == 'كيلو' ? li.kg : li.pound,
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
          subtitle: widget.product.weightable && widget.product.count == 0
              ? TextField(
                  onChanged: (value) {
                    int gg =
                        (double.parse(value) / widget.product.sellprice).ceil();
                    li.updateSellListCount(index: widget.index, count: gg);
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

