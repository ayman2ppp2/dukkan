import 'package:dukkan/core/observability.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loadingOverlay.dart';
import 'package:dukkan/models/Log.dart';
import 'package:dukkan/models/Product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import '../providers/list.dart';

class Receipt extends StatefulWidget {
  final Log log;
  final String? loanerName;

  Receipt({required this.log, this.loanerName, super.key});

  @override
  State<Receipt> createState() => _ReceiptState();
}

class _ReceiptState extends State<Receipt> {
  bool expand = false;

  @override
  Widget build(BuildContext context) {
    return Consumer2<SalesProvider, Lists>(builder: (context, sa, li, child) {
      return Padding(
          padding: const EdgeInsets.all(10.0),
          child: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.brown[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        '${intl.DateFormat.yMEd().add_jmz().format(widget.log.date)}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(intl.NumberFormat.simpleCurrency()
                                .format(widget.log.price) +
                            ' : السعر'),
                        Text(intl.NumberFormat.simpleCurrency()
                                .format(widget.log.profit) +
                            ' : الربح'),
                        IconButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text(
                                    'هل أنت متأكد؟',
                                    style: TextStyle(fontSize: 20),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () async {
                                        showDialog(
                                          context: context,
                                          barrierDismissible: false,
                                          builder: (context) =>
                                              LoadingOverlay(),
                                        );

                                        try {
                                          if (widget.log.loaned) {
                                            var loaner =
                                                await sa.getLoanerName(
                                                    id: widget
                                                        .log.loanerID!);
                                            if (loaner != null &&
                                                (loaner.zeroingDate ??
                                                        DateTime(1999))
                                                    .isAfter(
                                                        widget.log.date)) {
                                              await accounAlreadyZeroed(
                                                  context, li);
                                            } else {
                                              await li.cancelReceipt(
                                                  widget.log.date,
                                                  widget.log);
                                              Navigator.pop(context);
                                            }
                                          } else {
                                            await li.cancelReceipt(
                                                widget.log.date,
                                                widget.log);
                                            Navigator.pop(context);
                                          }
                                        } catch (e, s) {
                                          await AppLogger.captureException(
                                              e,
                                              stackTrace: s,
                                              area: 'receipt.cancel');
                                        } finally {
                                          Navigator.of(context,
                                                  rootNavigator: true)
                                              .pop();
                                        }
                                      },
                                      child: const Text(
                                        'نعم',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: const Text(
                                        'لا',
                                        style: TextStyle(fontSize: 20),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          icon: Icon(Icons.keyboard_return_rounded),
                        ),
                        IconButton(
                          onPressed: () {
                            setState(() {
                              expand = !expand;
                            });
                          },
                          icon: expand
                              ? Icon(Icons.expand_less_rounded)
                              : Icon(Icons.expand_more_rounded),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Text(intl.NumberFormat.simpleCurrency()
                                .format(widget.log.discount) +
                            ' : الخصم'),
                        Text(intl.NumberFormat.simpleCurrency()
                                .format(countSpecial(widget.log)) +
                            ' : سلع خاصة'),
                        IconButton(
                          onPressed: () async {
                            final outerContext = context;
                            showDialog(
                              context: outerContext,
                              builder: (ctx) => AlertDialog(
                                title: const Text(
                                  'هل تريد تعديل الفاتورة؟',
                                  style: TextStyle(fontSize: 20),
                                ),
                                content: const Text(
                                  'سيتم إلغاء الفاتورة الحالية وإعادة المنتجات للمخزون',
                                  style: TextStyle(fontSize: 16),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      Navigator.pop(ctx);
                                      showGeneralDialog(
                                        context: outerContext,
                                        pageBuilder: (c, a, s) =>
                                            LoadingOverlay(),
                                      );
                                      try {
                                        var result =
                                            await li.editReceipt(
                                                widget.log.date,
                                                widget.log);
                                        var products = result
                                            .whereType<Product>()
                                            .toList();
                                        if (products.isEmpty) {
                                          if (outerContext.mounted) {
                                            Navigator.pop(outerContext);
                                            ScaffoldMessenger.of(
                                                    outerContext)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'لا توجد منتجات في الفاتورة'),
                                              ),
                                            );
                                          }
                                          return;
                                        }
                                        sa.sellList = products;
                                        sa.refresh();
                                        li.editing = true;
                                        li.logID = widget.log.date;
                                        if (outerContext.mounted) {
                                          Navigator.pop(outerContext);
                                          Navigator.pop(outerContext);
                                        }
                                      } catch (e, st) {
                                        await AppLogger.captureException(
                                            e,
                                            stackTrace: st,
                                            area: 'receipt.edit');
                                        if (outerContext.mounted) {
                                          Navigator.pop(outerContext);
                                          ScaffoldMessenger.of(
                                                  outerContext)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'فشل تعديل الفاتورة'),
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text(
                                      'نعم',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(ctx),
                                    child: const Text(
                                      'لا',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.edit_note_rounded,
                          ),
                        ),
                      ],
                    ),
                    expand
                        ? SizedBox(
                            height: 200,
                            child: ListView(
                              children: widget.log.products
                                  .map(
                                    (e) => ListTile(
                                      title: Text('${e.name}'),
                                      leading: Text(
                                          intl.NumberFormat.simpleCurrency()
                                              .format(e.sellPrice)),
                                      trailing: Text('${e.count}'),
                                      subtitle: Text(
                                          "المجموع: ${intl.NumberFormat.simpleCurrency().format((e.count! * e.sellPrice!))}"),
                                    ),
                                  )
                                  .toList(),
                            ),
                          )
                        : Container()
                  ],
                ),
              ),
              if (widget.log.loaned)
                Positioned.fill(
                  child: ClipRRect(
                    child: widget.loanerName != null
                        ? Banner(
                            message: widget.loanerName!,
                            location: BannerLocation.topEnd,
                            child: const SizedBox(),
                          )
                        : FutureBuilder(
                            future: sa.getLoanerName(id: widget.log.loanerID!),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return const Text(UserSafeMessages.loadFailed);
                              }
                              if (snapshot.hasData) {
                                return Banner(
                                  message: snapshot.data!.name!,
                                  location: BannerLocation.topEnd,
                                  child: const SizedBox(),
                                );
                              }
                              if (snapshot.data == null) {
                                return Banner(
                                  message: 'تم مسح العميل برقم ${widget.log.loanerID}',
                                  location: BannerLocation.topEnd,
                                  child: const SizedBox(),
                                );
                              }
                              return SpinKitChasingDots(
                                color: Colors.brown[200],
                              );
                            },
                          ),
                  ),
                )
            ],
          ));
    });
  }

  Future<dynamic> accounAlreadyZeroed(BuildContext context, Lists li) {
    /// Displays a dialog to inform the user that the account has already been zeroed.
    ///
    /// This dialog warns the user about the implications of canceling a receipt
    /// for an account that has been fully paid. It provides options to either
    /// cancel the operation or proceed with the cancellation.
    ///
    /// [context] - The build context of the widget.

    return showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'تم دفع كامل الحساب بالفعل. حذف الفاتورة سيؤدي فقط إلى إعادة منتجاتها إلى المخزن، مما قد يتسبب في أخطاء بحسابات المخزن.',
            style: TextStyle(fontSize: 20),
            textDirection: TextDirection.rtl,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close this dialog
                Navigator.pop(context); // Close the previous dialog
              },
              child: const Text(
                'إلغاء',
                style: TextStyle(fontSize: 20),
              ),
            ),
            TextButton(
              onPressed: () async {
                await li.cancelReceipt(widget.log.date, widget.log);
                Navigator.pop(context); // Close this dialog
                Navigator.pop(context); // Close this dialog
                // Navigator.pop(context); // Close this dialog

                // Navigator.pop(context);
                // Navigator.pop(context);
              },
              child: const Text(
                'متابعة',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  double countSpecial(Log log) {
    var sum = 0.0;
    for (var element in widget.log.products) {
      if (element.hot!) {
        sum += element.sellPrice! * element.count!;
      }
    }
    return sum;
  }
}
