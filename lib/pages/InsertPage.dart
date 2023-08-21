import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../list.dart';
import '../util/product.dart';

class InPage extends StatefulWidget {
  String name;
  String wholeUnit;
  String owner;
  double buyPrice;
  double sellPrice;
  int count;
  int index;
  TextEditingController nameCon = TextEditingController();
  TextEditingController buyCon = TextEditingController();
  TextEditingController sellCon = TextEditingController();
  TextEditingController countCon = TextEditingController();
  TextEditingController ownerCon = TextEditingController();
  bool weightable = false;
  TextEditingController wholeUnitCon = TextEditingController();
  InPage({
    super.key,
    required this.buyPrice,
    required this.count,
    required this.name,
    required this.sellPrice,
    required this.index,
    required this.owner,
    required this.wholeUnit,
    required this.weightable,
  });

  @override
  State<InPage> createState() => _InPageState();
}

class _InPageState extends State<InPage> {
  @override
  void initState() {
    if (widget.index != -1) {
      widget.nameCon.text = widget.name;
      widget.buyCon.text = widget.buyPrice.toString();
      widget.sellCon.text = widget.sellPrice.toString();
      widget.countCon.text = widget.count.toString();
      widget.wholeUnitCon.text = widget.wholeUnit;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        return Material(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // add new Item
                const Text(
                  textDirection: TextDirection.rtl,
                  'إضافة منتج جديد',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // name
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    enabled: widget.index == -1 ? true : false,
                    textDirection: TextDirection.rtl,
                    controller: widget.nameCon,
                    decoration: InputDecoration(
                      hintText: 'الاسم',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // owner name
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: DropdownMenu(
                    dropdownMenuEntries: List.generate(
                      Provider.of<Lists>(context).ownersList.length,
                      (index) => DropdownMenuEntry(
                        value: Provider.of<Lists>(context)
                            .ownersList
                            .elementAt(index),
                        label: Provider.of<Lists>(context)
                            .ownersList
                            .elementAt(index),
                      ),
                    ),
                    controller: widget.ownerCon,
                    label: const Text('المالك'),
                  ),
                ),
                //buyPrice
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: widget.buyCon,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'سعر الشراء',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                //sellPrice
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: widget.sellCon,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'سعر البيع',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                //count
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: widget.countCon,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'العدد',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                //count
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: widget.wholeUnitCon,
                    keyboardType: TextInputType.name,
                    decoration: InputDecoration(
                      hintText: 'كيلو/رطل/تمنة',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('وزن'),
                      Checkbox(
                        value: widget.weightable,
                        onChanged: (value) {
                          setState(() {
                            widget.weightable = value!;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                // submit
                IconButton(
                  onPressed: () {
                    if (widget.index == -1) {
                      if (widget.nameCon.text.isNotEmpty &
                          widget.ownerCon.text.isNotEmpty &
                          widget.buyCon.text.isNotEmpty &
                          widget.sellCon.text.isNotEmpty &
                          widget.countCon.text.isNotEmpty) {
                        List<Product> temp = [];
                        Product temp2 = Product(
                          name: widget.nameCon.text,
                          buyprice: double.parse(widget.buyCon.text),
                          sellprice: double.parse(widget.sellCon.text),
                          count: int.parse(widget.countCon.text),
                          ownerName: widget.ownerCon.text,
                          weightable: widget.weightable,
                          wholeUnit: widget.wholeUnitCon.text,
                        );
                        temp.add(temp2);
                        Navigator.pop(context);
                        li.db.insertProducts(products: temp);
                        li.refreshProductsList();
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.brown[200],
                            icon: const Icon(Icons.error_outline_rounded),
                            iconColor: Colors.red,
                            title: const Text(
                              'أدخل قيم صحيحة',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                    } else {
                      if (widget.nameCon.text.isNotEmpty &
                          widget.buyCon.text.isNotEmpty &
                          widget.sellCon.text.isNotEmpty &
                          widget.countCon.text.isNotEmpty) {
                        Product temp2 = Product(
                          name: widget.nameCon.text,
                          buyprice: double.parse(widget.buyCon.text),
                          sellprice: double.parse(widget.sellCon.text),
                          count: int.parse(widget.countCon.text),
                          ownerName: widget.ownerCon.text,
                          weightable: widget.weightable,
                          wholeUnit: widget.wholeUnitCon.text,
                        );
                        li.updateProduct(temp2);
                        li.refreshProductsList();
                        li.refresh();
                        Navigator.pop(context);
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.brown[200],
                            icon: const Icon(Icons.error_outline_rounded),
                            iconColor: Colors.red,
                            title: const Text(
                              'أدخل قيم صحيحة',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(
                    Icons.done_all_rounded,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
