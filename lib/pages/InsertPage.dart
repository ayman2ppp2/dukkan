import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Emap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';
import '../util/models/Product.dart';

// ignore: must_be_immutable
class InPage extends StatefulWidget {
  String name;
  String barcode;
  String wholeUnit;
  String owner;
  double buyPrice;
  double sellPrice;
  int count;
  int index;
  double offerCount;
  double offerPrice;
  List<Emap> priceHistory = List.empty(growable: true);
  DateTime endDate;
  TextEditingController nameCon = TextEditingController();
  TextEditingController buyCon = TextEditingController();
  TextEditingController sellCon = TextEditingController();
  TextEditingController countCon = TextEditingController();
  TextEditingController ownerCon = TextEditingController();
  TextEditingController offerCountCon = TextEditingController();
  TextEditingController offerPriceCon = TextEditingController();
  TextEditingController wholeUnitCon = TextEditingController();
  TextEditingController BarcodeCon = TextEditingController();
  // TextEditingController endDateCon = TextEditingController();
  bool weightable = false;
  bool offer = false;
  int? id;
  InPage({
    super.key,
    required this.id,
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
    required this.priceHistory,
    required this.barcode,
  });

  @override
  State<InPage> createState() => _InPageState();
}

class _InPageState extends State<InPage> {
  double getWholeUnitNumber(String wholeUnit) {
    switch (wholeUnit) {
      case 'كيلو':
        return 1000;
      case 'رطل':
        return 450;
      case 'تمنة':
        return 850;
      case '':
        return 1;
      default:
        return double.tryParse(wholeUnit) ?? 0;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.index != -1) {
      _initializeControllers();
    }
  }

  void _initializeControllers() {
    widget.nameCon.text = widget.name;
    widget.BarcodeCon.text = widget.barcode;
    widget.ownerCon.text = widget.owner;
    widget.buyCon.text =
        (widget.buyPrice * getWholeUnitNumber(widget.wholeUnit)).toString();
    widget.sellCon.text =
        (widget.sellPrice * getWholeUnitNumber(widget.wholeUnit)).toString();
    widget.countCon.text =
        padd(original: widget.count.toString(), wholeUnit: widget.wholeUnit)
            .toString();
    widget.wholeUnitCon.text = widget.wholeUnit;
    widget.offerCountCon.text = widget.offerCount.toString();
    widget.offerPriceCon.text = unPadd(
            padded: widget.offerPrice.toString(),
            wholeUnit: widget.offerCount.toString())
        .toString();
  }

  bool _validateFields() {
    return widget.nameCon.text.isNotEmpty &&
        widget.ownerCon.text.isNotEmpty &&
        widget.buyCon.text.isNotEmpty &&
        widget.sellCon.text.isNotEmpty &&
        widget.countCon.text.isNotEmpty;
  }

  void _showErrorDialog(BuildContext context, String message) {
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

  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
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
                Text(
                  textDirection: TextDirection.rtl,
                  widget.index == -1 ? 'إضافة منتج جديد' : 'تعديل منتج',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // name
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextFormField(
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

                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FutureBuilder(
                    future: Provider.of<Lists>(context, listen: false)
                        .refreshListOfOwners(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SpinKitChasingDots(
                            color: Colors.white, size: 50);
                      }
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        var temp = snapshot.data!
                            .map((e) => DropdownMenuEntry(
                                value: e.ownerName, label: e.ownerName))
                            .toList();
                        return DropdownMenu(
                          onSelected: (value) {
                            widget.ownerCon.text = value!;
                          },
                          initialSelection: widget.ownerCon.text,
                          controller: widget.ownerCon,
                          dropdownMenuEntries: temp,
                          label: Text('المالك'),
                          width: 114,
                          menuHeight: 300,
                          menuStyle:
                              MenuStyle(visualDensity: VisualDensity.compact),
                        );
                      }
                      return Text('No owners available');
                    },
                  ),
                ),
                // barcode
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Flex(
                    direction: Axis.horizontal,
                    children: [
                      Expanded(
                        flex: 6,
                        child: TextFormField(
                          controller: widget.BarcodeCon,
                          decoration: InputDecoration(
                            hintText: 'الباركود',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                          child: IconButton(
                              onPressed: () {
                                MobileScannerController con =
                                    MobileScannerController();
                                showGeneralDialog(
                                  context: context,
                                  pageBuilder:
                                      (context, animation, secondaryAnimation) {
                                    return Material(
                                      child: MobileScanner(
                                        fit: BoxFit.contain,
                                        controller: con,
                                        onDetect: (capture) async {
                                          final List<Barcode> barcodes =
                                              capture.barcodes;
                                          for (final barcode in barcodes) {
                                            widget.BarcodeCon.text =
                                                barcode.rawValue!;
                                            debugPrint(
                                                'Barcode found! ${barcode.rawValue}');
                                          }

                                          Navigator.pop(context);
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                              icon: Icon(Icons.qr_code_scanner))),
                    ],
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
                      prefix: Text(widget.wholeUnitCon.text.isEmpty
                          ? 'قطعة'
                          : widget.wholeUnitCon.text),
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
                          'تاريخ الأنتهاء : ${widget.endDate.year}-${widget.endDate.month}-${widget.endDate.day}',
                        ),
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
                          onSelected: (value) => setState(() {}),
                          controller: widget.wholeUnitCon,
                          initialSelection: widget.wholeUnit,
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
                Consumer<SalesProvider>(
                  builder: (context, sa, child) => IconButton(
                    onPressed: () {
                      if (widget.index == -1) {
                        if (_validateFields()) {
                          List<Product> temp = [];
                          Product temp2 = Product.named(
                            name: widget.nameCon.text,
                            barcode: widget.BarcodeCon.text,
                            buyprice: widget.weightable
                                ? double.parse(widget.buyCon.text) /
                                    getWholeUnitNumber(widget.wholeUnitCon.text)
                                        .toDouble()
                                : double.parse(widget.buyCon.text),
                            sellPrice: widget.weightable
                                ? double.parse(widget.sellCon.text) /
                                    getWholeUnitNumber(widget.wholeUnitCon.text)
                                        .toDouble()
                                : double.parse(widget.sellCon.text),
                            count: widget.weightable
                                ? unPadd(
                                        padded: widget.countCon.text,
                                        wholeUnit: widget.wholeUnitCon.text)
                                    .toInt()
                                : (double.tryParse(widget.countCon.text) ?? 0)
                                    .toInt(),
                            ownerName: widget.ownerCon.text,
                            weightable: widget.weightable,
                            wholeUnit: widget.wholeUnitCon.text,
                            offer: widget.offer,
                            offerCount:
                                double.tryParse(widget.offerCountCon.text) ?? 0,
                            offerPrice: padd(
                                original: widget.offerPriceCon.text.isEmpty
                                    ? '0'
                                    : widget.offerPriceCon.text,
                                wholeUnit: widget.offerCountCon.text),
                            // double.tryParse(widget.offerPriceCon.text) ?? 0,
                            priceHistory: widget.priceHistory,
                            endDate: widget.endDate,
                            hot: false,
                          );
                          temp.add(temp2);
                          Navigator.pop(context);
                          li.db.insertProducts(products: temp);
                          // sa.refreshProductsList();
                          // sa.refresh();
                        } else {
                          _showErrorDialog(context, 'ادخل قيم صحيحة');
                        }
                      } else {
                        if (_validateFields()) {
                          Emap emap = Emap()
                            ..buyPrice = widget.buyPrice
                            ..sellPrice = widget.sellPrice
                            ..date = DateTime.now();
                          widget.priceHistory.add(emap);
                          Product temp2 = Product.named2(
                            id: widget.id!,
                            name: widget.nameCon.text,
                            barcode: widget.BarcodeCon.text,
                            buyprice: widget.weightable
                                ? double.parse(widget.buyCon.text) /
                                    getWholeUnitNumber(widget.wholeUnitCon.text)
                                        .toDouble()
                                : double.parse(widget.buyCon.text),
                            sellPrice: widget.weightable
                                ? double.parse(widget.sellCon.text) /
                                    getWholeUnitNumber(widget.wholeUnitCon.text)
                                        .toDouble()
                                : double.parse(widget.sellCon.text),
                            count: widget.weightable
                                ? unPadd(
                                        padded: widget.countCon.text,
                                        wholeUnit: widget.wholeUnitCon.text)
                                    .toInt()
                                : (double.tryParse(widget.countCon.text) ?? 0)
                                    .toInt(),
                            ownerName: widget.ownerCon.text,
                            weightable: widget.weightable,
                            wholeUnit: widget.wholeUnitCon.text,
                            offer: widget.offer,
                            offerCount:
                                double.tryParse(widget.offerCountCon.text) ?? 0,
                            offerPrice: padd(
                                original: widget.offerPriceCon.text.isEmpty
                                    ? '0'
                                    : widget.offerPriceCon.text,
                                wholeUnit: widget.offerCountCon.text),
                            // double.tryParse(widget.offerPriceCon.text) ?? 0,
                            priceHistory: widget.priceHistory,
                            endDate: widget.endDate,
                            hot: false,
                          );
                          sa.updateProduct(temp2);
                          // sa.refreshProductsList();
                          // li.refresh();
                          Navigator.pop(context);
                        } else {
                          _showErrorDialog(context, 'ادخل قيم صحيحة');
                        }
                      }
                    },
                    icon: const Icon(
                      Icons.done_all_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double padd({required String original, required String wholeUnit}) {
    return double.parse(original) / getWholeUnitNumber(wholeUnit);
  }

  double unPadd({required String padded, required String wholeUnit}) {
    return double.parse(padded) * getWholeUnitNumber(wholeUnit);
  }
}
