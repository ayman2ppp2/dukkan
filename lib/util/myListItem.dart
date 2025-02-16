import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:provider/provider.dart';

class MyListTile extends StatefulWidget {
  late final Product product;
  // int nmPicker = 1;
  late final int index;
  MyListTile({super.key, required this.product, required this.index});

  @override
  State<MyListTile> createState() => _MyListTileState();
}

class _MyListTileState extends State<MyListTile> {
  String weight = "";
  int gg = 0;
  int _multiplyer = 1;
  int precession = 0;

  TextEditingController con = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, li, child) {
        precession = li.getWeightPrececsion() ?? 0;
        return ListTile(
          leading: !widget.product.hot!
              ? (widget.product.offer! &&
                      widget.product.count! % widget.product.offerCount! == 0)
                  ? Text(NumberFormat.simpleCurrency()
                      .format(widget.product.offerPrice))
                  : Text(NumberFormat.simpleCurrency()
                      .format(widget.product.sellPrice))
              : SizedBox(),
          title: Flex(
            mainAxisSize: MainAxisSize.min,
            direction: Axis.horizontal,
            children: [
              Center(
                child: Text(widget.product.name!),
              ),
            ],
          ),
          trailing: !widget.product.hot!
              ? widget.product.weightable!
                  ? Container(
                      constraints: BoxConstraints(
                          maxWidth: 140 % MediaQuery.of(context).size.width),
                      child: Flex(
                        direction: Axis.horizontal,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              '${widget.product.count}جم',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Consumer<SalesProvider>(
                              builder: (context, sa, child) => Center(
                                child: PopupMenuButton(
                                  onSelected: (value) {
                                    sa.updateSellListCount(
                                        index: widget.index,
                                        count: value.toInt());
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
                                                  widget.product.id) >=
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
                                                  widget.product.id) >=
                                              li.toumna.values.elementAt(index),
                                          value:
                                              li.toumna.values.elementAt(index),
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
                                                  widget.product.id) >=
                                              li.pound.values.elementAt(index),
                                          value:
                                              li.pound.values.elementAt(index),
                                          child: Text(
                                            li.pound.keys.elementAt(index),
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          widget.product.weightable! && !(weight == 'وزن')
                              ? Expanded(
                                  flex: 2,
                                  child: Consumer<SalesProvider>(
                                    builder: (context, sa, child) => Center(
                                      child: PopupMenuButton(
                                        constraints:
                                            BoxConstraints(maxHeight: 300),
                                        child: Text(
                                          maxLines: 1,
                                          '$_multiplyer',
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        onSelected: (value) {
                                          switch (weight) {
                                            case 'كيلو':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 1000 * value);
                                            case 'نص كيلو':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 500 * value);
                                            case 'ربع كيلو':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 250 * value);
                                            case 'تمنة':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 850 * value);
                                            case 'نص تمنة':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 425 * value);
                                            case 'ربع تمنة':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 215 * value);
                                            case 'رطل':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 450 * value);
                                            case 'نص رطل':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 225 * value);
                                            case 'ربع رطل':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 113 * value);
                                            case 'وزن':
                                              sa.updateSellListCount(
                                                  index: widget.index,
                                                  count: 0);
                                              break;
                                            default:
                                          }

                                          _multiplyer = value;
                                          // li.updateSellListCount(
                                          //     index: widget.index,
                                          //     count: widget.product.count * value);
                                        },
                                        itemBuilder: (context) {
                                          return List.generate(
                                            100,
                                            (index) => PopupMenuItem(
                                              value: index + 1,
                                              child: Text('${index + 1}'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                )
                              : SizedBox(),
                        ],
                      ),
                    )
                  : Consumer<SalesProvider>(
                      builder: (context, sa, child) => NumberPicker(
                        value: widget.product.count!,
                        maxValue: li.getProductCount(widget.product.id),
                        minValue: 1,
                        onChanged: (int value) {
                          sa.updateSellListCount(
                              index: widget.index, count: value);
                        },
                        haptics: true,
                        itemHeight: 40,
                        itemWidth: 60,
                        itemCount: 1,
                      ),
                    )
              : SizedBox(),
          subtitle: !widget.product.hot!
              ? widget.product.weightable! && weight == 'وزن'
                  ? Consumer<SalesProvider>(
                      builder: (context, sa, child) => TextFormField(
                        autofocus: true,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        controller: con,

                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            gg = ((((((double.tryParse(value) ?? 0) ~/
                                            (widget.product.sellPrice!))) /
                                        precession)
                                    .ceil()) *
                                precession);
                            sa.updateSellListCount(
                                index: widget.index, count: gg);
                          }
                          if ((double.tryParse(value) ?? 0) >=
                              li.getProductCount(widget.product.id) *
                                  widget.product.sellPrice!) {
                            // setState(() {
                            con.text = (li.getProductCount(widget.product.id) *
                                    widget.product.sellPrice!)
                                .toStringAsFixed(2);
                            sa.updateSellListCount(
                                index: widget.index,
                                count: li.getProductCount(widget.product.id));
                            // });
                          }
                        },
                        // enabled: ,
                      ),
                    )
                  : Flex(
                      mainAxisSize: MainAxisSize.min,
                      direction: Axis.horizontal,
                      children: [
                        (widget.product.offer! &&
                                widget.product.count! %
                                        widget.product.offerCount! ==
                                    0)
                            ? Expanded(
                                flex: 0,
                                child: Text(
                                    "total : ${NumberFormat.simpleCurrency().format((widget.product.count! * widget.product.offerPrice!))}"))
                            : Expanded(
                                flex: 0,
                                child: Text(
                                    "total : ${NumberFormat.simpleCurrency().format((widget.product.count! * widget.product.sellPrice!))}"),
                              )
                      ],
                    )
              : Consumer<SalesProvider>(
                  builder: (context, sa, child) => TextFormField(
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                    controller: con,

                    onChanged: (value) {
                      if (value.isNotEmpty) {
                        gg = (((double.tryParse(value) ?? 0) ~/
                                (widget.product.sellPrice!)))
                            .toInt();
                        sa.updateSellListCount(index: widget.index, count: gg);
                      }
                    },
                    // enabled: ,
                  ),
                ),
        );
      },
    );
  }
}
