import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';

class inboundItem extends StatefulWidget {
  final Product product;
  TextEditingController nameCon = TextEditingController();
  TextEditingController buyCon = TextEditingController();
  TextEditingController sellCon = TextEditingController();
  TextEditingController countCon = TextEditingController();
  TextEditingController ownerCon = TextEditingController();
  TextEditingController offerCountCon = TextEditingController();
  TextEditingController offerPriceCon = TextEditingController();
  TextEditingController wholeUnitCon = TextEditingController();
  TextEditingController BarcodeCon = TextEditingController();
  inboundItem({super.key, required this.product});

  @override
  State<inboundItem> createState() => _inboundItemState();
}

class _inboundItemState extends State<inboundItem> {
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

  double padd({required String original, required String wholeUnit}) {
    return double.parse(original) / getWholeUnitNumber(wholeUnit);
  }

  double unPadd({required String padded, required String wholeUnit}) {
    return double.tryParse(padded) ?? 0 * getWholeUnitNumber(wholeUnit);
  }

  void _initializeControllers() {
    widget.nameCon.text = widget.product.name!;
    widget.BarcodeCon.text = widget.product.barcode!;
    widget.ownerCon.text = widget.product.ownerName!;
    widget.buyCon.text = (widget.product.buyprice! *
            getWholeUnitNumber(widget.product.wholeUnit!))
        .toString();
    widget.sellCon.text = (widget.product.sellPrice! *
            getWholeUnitNumber(widget.product.wholeUnit!))
        .toString();
    widget.countCon.text = widget.product.count.toString();
    widget.wholeUnitCon.text = widget.product.wholeUnit!;
    widget.offerCountCon.text = widget.product.offerCount.toString();
    widget.offerPriceCon.text = unPadd(
            padded: widget.product.offerPrice.toString(),
            wholeUnit: widget.product.offerCount.toString())
        .toString();
  }

  int productCount = 0;
  initState() {
    productCount = widget.product.count ?? 0;
    super.initState();
  }

  TextEditingController countController = TextEditingController();
  // final _formKey = GlobalKey<FormState>();
  @override
  Widget build(BuildContext context) {
    final sa = Provider.of<SalesProvider>(context, listen: false);
    final dateFormat = intl.DateFormat('yyyy-MM-dd');
    return ExpansionTile(
      title: Text(widget.product.name ?? 'إسم غير معروف'),
      subtitle: Text(
        'السعر: ${(widget.product.buyprice! * widget.product.count!).toStringAsFixed(2)}',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.product.name ?? '',
                      decoration: InputDecoration(labelText: 'الأسم'),
                      onChanged: (val) {
                        sa.updateProductName(widget.product.id, val);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.product.ownerName ?? '',
                      decoration: InputDecoration(labelText: 'اسم المالك'),
                      onChanged: (val) {
                        sa.updateProductOwnerName(widget.product.id, val);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      textDirection: TextDirection.rtl,
                      controller: countController,
                      decoration: InputDecoration(
                          labelText:
                              '${padd(original: widget.product.count!.toString(), wholeUnit: widget.product.wholeUnit ?? '')} ${widget.product.wholeUnit ?? ''}'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        sa.updateProductCount(
                            widget.product.id,
                            unPadd(
                                    padded: val,
                                    wholeUnit: widget.product.weightable!
                                        ? widget.product.wholeUnit!
                                        : '')
                                .toInt());
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.product.weightable!
                          ? (widget.product.buyprice! *
                                  getWholeUnitNumber(widget.product.wholeUnit!))
                              .toString()
                          : widget.product.buyprice!.toString(),
                      decoration: InputDecoration(labelText: 'سعر الشراء'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        sa.updateProductBuyPrice(
                            widget.product.id, double.tryParse(val) ?? 0.0);
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.product.weightable!
                          ? (widget.product.sellPrice! *
                                  getWholeUnitNumber(widget.product.wholeUnit!))
                              .toString()
                          : widget.product.sellPrice!.toString(),
                      decoration: InputDecoration(labelText: 'سعر البيع'),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      onChanged: (val) {
                        sa.updateProductSellPrice(
                            widget.product.id, double.tryParse(val) ?? 0.0);
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: widget.product.wholeUnit,
                      decoration: InputDecoration(labelText: 'وحدة القياس'),
                      items: ['كيلو', 'رطل', 'تمنة', '']
                          .map((unit) => DropdownMenuItem<String>(
                                value: unit,
                                child: unit.isEmpty
                                    ? Text('لا يوجد وحدة')
                                    : Text(unit),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          sa.updateProductWholeUnit(widget.product.id, val);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: widget.product.barcode ?? '',
                      decoration: InputDecoration(labelText: 'الباركود'),
                      onChanged: (val) {
                        sa.updateProductBarcode(widget.product.id, val);
                      },
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                title: Text('موزون'),
                value: widget.product.weightable ?? false,
                onChanged: (val) {
                  sa.updateProductWeightable(widget.product.id, val);
                },
              ),
              SwitchListTile(
                title: Text('عرض'),
                value: widget.product.offer ?? false,
                onChanged: (val) {
                  sa.updateProductOffer(widget.product.id, val);
                },
              ),
              if (widget.product.offer ?? false)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue:
                            widget.product.offerCount?.toString() ?? '0.0',
                        decoration:
                            InputDecoration(labelText: 'عدد الوحدات في العرض'),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          sa.updateProductOfferCount(
                              widget.product.id, double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        initialValue:
                            widget.product.offerPrice?.toString() ?? '0.0',
                        decoration:
                            InputDecoration(labelText: 'سعر الوحدة في العرض'),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          sa.updateProductOfferPrice(
                              widget.product.id, double.tryParse(val) ?? 0.0);
                        },
                      ),
                    ),
                  ],
                ),
              ListTile(
                title: Text('تاريخ الإنتهاء'),
                subtitle: Text(widget.product.endDate != null
                    ? dateFormat.format(widget.product.endDate!)
                    : 'لم يحدد بعد'),
                trailing: Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: widget.product.endDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    sa.updateProductEndDate(widget.product.id, picked);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
