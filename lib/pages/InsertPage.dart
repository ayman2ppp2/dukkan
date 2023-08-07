import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../list.dart';
import '../util/product.dart';

class InPage extends StatefulWidget {
  String name;
  double buyPrice;
  double sellPrice;
  int count;
  int index;
  InPage({
    super.key,
    required this.buyPrice,
    required this.count,
    required this.name,
    required this.sellPrice,
    required this.index,
  });

  @override
  State<InPage> createState() => _InPageState();
}

class _InPageState extends State<InPage> {
  TextEditingController nameCon = TextEditingController();
  TextEditingController buyCon = TextEditingController();
  TextEditingController sellCon = TextEditingController();
  TextEditingController countCon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        if (widget.index != -1) {
          nameCon.text = widget.name;
          buyCon.text = widget.buyPrice.toString();
          sellCon.text = widget.sellPrice.toString();
          countCon.text = widget.count.toString();
        }
        return Material(
          borderRadius: BorderRadius.circular(12),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
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
                    controller: nameCon,
                    decoration: InputDecoration(
                      hintText: 'الاسم',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                //buyPrice
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
                    controller: buyCon,
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
                    controller: sellCon,
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
                    controller: countCon,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'العدد',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                // submit
                IconButton(
                  onPressed: () {
                    if (widget.index == -1) {
                      if (nameCon.text.isNotEmpty &
                          buyCon.text.isNotEmpty &
                          sellCon.text.isNotEmpty &
                          countCon.text.isNotEmpty) {
                        List<Product> temp = [];
                        Product temp2 = Product(
                            name: nameCon.text,
                            buyprice: double.parse(buyCon.text),
                            sellprice: double.parse(sellCon.text),
                            count: int.parse(countCon.text));
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
                      if (nameCon.text.isNotEmpty &
                          buyCon.text.isNotEmpty &
                          sellCon.text.isNotEmpty &
                          countCon.text.isNotEmpty) {
                        Product temp2 = Product(
                            name: nameCon.text,
                            buyprice: double.parse(buyCon.text),
                            sellprice: double.parse(sellCon.text),
                            count: int.parse(countCon.text));
                        li.updateProduct(temp2);
                        li.refreshProductsList();
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
