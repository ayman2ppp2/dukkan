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
          leading: Text(li.sellList[widget.index].sellprice.toString()),
          title: Center(child: Text(widget.product.name)),
          trailing: NumberPicker(
            value: widget.product.count,
            maxValue: li.getProductCount(widget.product.name),
            minValue: 1,
            onChanged: (int value) {
              li.updateSellListCount(index: widget.index, count: value);
            },
            haptics: true,
            itemHeight: 40,
            itemWidth: 50,
            itemCount: 1,
          ),
          subtitle: Row(
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
