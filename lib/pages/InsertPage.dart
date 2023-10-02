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
  double offerCount;
  double offerPrice;
  DateTime endDate;
  TextEditingController nameCon = TextEditingController();
  TextEditingController buyCon = TextEditingController();
  TextEditingController sellCon = TextEditingController();
  TextEditingController countCon = TextEditingController();
  TextEditingController ownerCon = TextEditingController();
  TextEditingController offerCountCon = TextEditingController();
  TextEditingController offerPriceCon = TextEditingController();
  TextEditingController wholeUnitCon = TextEditingController();
  // TextEditingController endDateCon = TextEditingController();
  bool weightable = false;
  bool offer = false;
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
    required this.offer,
    required this.offerCount,
    required this.offerPrice,
    required this.endDate,
  });

  @override
  State<InPage> createState() => _InPageState();
}

class _InPageState extends State<InPage> {
  @override
  void initState() {
    if (widget.index != -1) {
      widget.nameCon.text = widget.name;
      widget.ownerCon.text = widget.owner;
      widget.buyCon.text = widget.buyPrice.toString();
      widget.sellCon.text = widget.sellPrice.toString();
      widget.countCon.text = widget.count.toString();
      widget.wholeUnitCon.text = widget.wholeUnit;
      widget.offerCountCon.text = widget.offerCount.toString();
      widget.offerPriceCon.text = widget.offerPrice.toString();
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        li.refreshListOfOwners();
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
                  child: Consumer<Lists>(
                    builder: (context, li, child) => DropdownMenu(
                      initialSelection: widget.ownerCon.text,
                      dropdownMenuEntries: List.generate(
                        Provider.of<Lists>(context).ownersList.length,
                        (index) => DropdownMenuEntry(
                          value: li.ownersList.elementAt(index).ownerName,
                          label: li.ownersList.elementAt(index).ownerName,
                        ),
                      ),
                      controller: widget.ownerCon,
                      label: const Text('المالك'),
                    ),
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
                      hintText: 'الكمية بالجرام/العدد',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () async {
                      widget.endDate = await showDatePicker(
                              context: context,
                              initialDate: widget.endDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030)) ??
                          widget.endDate;
                      setState(() {});
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.brown[200],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                            'تاريخ الأنتهاء : ${widget.endDate.year}-${widget.endDate.month}-${widget.endDate.day}'),
                      ),
                    ),
                  ),
                ),
                //count
                widget.weightable
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: DropdownMenu(
                          dropdownMenuEntries: const [
                            DropdownMenuEntry(value: 'كيلو', label: 'كيلو'),
                            DropdownMenuEntry(value: 'تمنة', label: 'تمنة'),
                            DropdownMenuEntry(value: 'رطل', label: 'رطل')
                          ],
                          controller: widget.wholeUnitCon,
                          label: const Text("الوحدة"),
                        ),
                      )
                    : Container(),

                widget.offer
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: widget.offerCountCon,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'عدد العرض',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    : Container(),
                widget.offer
                    ? Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextFormField(
                          controller: widget.offerPriceCon,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: 'سعر الوحدة في العرض',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      )
                    : Container(),

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
                      const Text('عرض'),
                      Checkbox(
                        value: widget.offer,
                        onChanged: (value) {
                          setState(() {
                            widget.offer = value!;
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
                          barcode: '',
                          buyprice: double.parse(widget.buyCon.text),
                          sellprice: double.parse(widget.sellCon.text),
                          count: int.parse(widget.countCon.text),
                          ownerName: widget.ownerCon.text,
                          weightable: widget.weightable,
                          wholeUnit: widget.wholeUnitCon.text,
                          offer: widget.offer,
                          offerCount:
                              double.tryParse(widget.offerCountCon.text) ?? 0,
                          offerPrice:
                              double.tryParse(widget.offerPriceCon.text) ?? 0,
                          priceHistory: [],
                          endDate: widget.endDate,
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
                          barcode: '',
                          buyprice: double.parse(widget.buyCon.text),
                          sellprice: double.parse(widget.sellCon.text),
                          count: int.parse(widget.countCon.text),
                          ownerName: widget.ownerCon.text,
                          weightable: widget.weightable,
                          wholeUnit: widget.wholeUnitCon.text,
                          offer: widget.offer,
                          offerCount:
                              double.tryParse(widget.offerCountCon.text) ?? 0,
                          offerPrice:
                              double.tryParse(widget.offerPriceCon.text) ?? 0,
                          priceHistory: [],
                          endDate: widget.endDate,
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
