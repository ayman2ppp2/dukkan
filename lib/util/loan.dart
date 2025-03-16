import 'package:dukkan/pages/accountStatement.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loadingOverlay.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart' as intl;
import 'package:provider/provider.dart';
import 'package:dukkan/pages/confirmationPage.dart';

class Loan extends StatefulWidget {
  final Loaner loaner;
  const Loan({super.key, required this.loaner});

  @override
  State<Loan> createState() => _LoanState();
}

class _LoanState extends State<Loan> {
  List<Log> receipts = [];
  double payment = 0;
  TextEditingController con = TextEditingController();
  String formatTextField(oldValue, newValue) {
    try {
      return intl.NumberFormat.currency(decimalDigits: 0, name: '').format(
          intl.NumberFormat.currency(decimalDigits: 0, name: '')
              .parse(newValue.text));
    } on FormatException catch (_) {
      return '';
    }
  }

  int getEOLOffset(TextEditingValue oldValue, TextEditingValue newValue) {
    try {
      return intl.NumberFormat.currency(decimalDigits: 0, name: '')
          .format(intl.NumberFormat.currency(decimalDigits: 0, name: '')
              .parse(newValue.text))
          .length;
    } on FormatException catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    receipts = Provider.of<Lists>(context, listen: false).logsList;
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                var sa = Provider.of<SalesProvider>(context, listen: false);
                var temp =
                    await Provider.of<SalesProvider>(context, listen: false)
                        .db
                        .isar!
                        .loaners
                        .get(widget.loaner.ID);
                if (temp!.loanedAmount == 0) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: const Text(
                          'هل انت متاكد',
                          style: TextStyle(fontSize: 20),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () async {
                              // LoadingOverlay();
                              showGeneralDialog(
                                context: context,
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        LoadingOverlay(),
                              );
                              await sa.deleteLoaner(widget.loaner.ID);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              Navigator.pop(context);
                              // sa.refreshProductsList();
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
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                        actions: [
                          TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              child: Text("موافق"))
                        ],
                        content: Text(
                            'لايمكن مسح حساب عميل اذا لم يتم دفع كامل الديون')),
                  );
                }
              },
              icon: Icon(Icons.delete_forever))
        ],
        iconTheme: IconThemeData(color: Colors.brown[50]),
        backgroundColor: Colors.brown,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.loaner.name!,
                style: TextStyle(color: Colors.brown[50], fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                widget.loaner.ID.toString(),
                style: TextStyle(color: Colors.brown[50], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: StreamBuilder(
                stream: Provider.of<SalesProvider>(context, listen: false)
                    .watchLoaner(widget.loaner.ID),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (snapshot.hasData) {
                    print(snapshot.data!.toMap());
                    return Column(
                      children: [
                        Item(
                          child: Text(
                              textDirection: TextDirection.rtl,
                              'رقم الهاتف+  : ${snapshot.data!.phoneNumber} '),
                        ),
                        Item(
                          child: Text('المكان : ${snapshot.data!.location}'),
                        ),
                        Item(
                          child: Text(
                              'المطلوب : ${intl.NumberFormat.simpleCurrency(decimalDigits: 0, name: '').format(snapshot.data!.loanedAmount)}'),
                        ),
                        Item(
                          child: Text(
                              textDirection: TextDirection.rtl,
                              'تاريخ اخر دفعة : ${intl.DateFormat.yMEd().add_jmz().format(DateTime.parse(snapshot.data!.lastPayment!.isEmpty ? DateTime.now().toString() : snapshot.data!.lastPayment!.last.key!.toString()))}'),
                        ),
                        Item(
                          child: GestureDetector(
                            onLongPress: () {
                              showPaymentHistory(context, snapshot);
                            },
                            child: Text(
                                'اخر دفعة :${snapshot.data!.lastPayment!.isEmpty ? 0.toString() : intl.NumberFormat.simpleCurrency(decimalDigits: 0, name: '').format(double.parse(snapshot.data!.lastPayment!.last.value!))}'),
                          ),
                        ),
                        Item(
                          child: Row(
                            textDirection: TextDirection.rtl,
                            children: [
                              Text(
                                  textDirection: TextDirection.rtl, 'تسديد : '),
                              Expanded(
                                child: TextFormField(
                                  inputFormatters: [
                                    TextInputFormatter.withFunction(
                                      (oldValue, newValue) => TextEditingValue(
                                        selection: TextSelection.collapsed(
                                            offset: getEOLOffset(
                                                oldValue, newValue)),
                                        text:
                                            formatTextField(oldValue, newValue),
                                      ),
                                    ),
                                  ],
                                  controller: con,
                                  autocorrect: true,
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  var sa = Provider.of<SalesProvider>(context,
                                      listen: false);
                                  if (con.text == 'Reset') {
                                    resetAccount(context, sa, snapshot);
                                  } else {
                                    var sa = Provider.of<SalesProvider>(context,
                                        listen: false);
                                    (intl.NumberFormat.currency(name: '')
                                                        .parse(con.text))
                                                    .toDouble() <=
                                                snapshot.data!.loanedAmount! &&
                                            (intl.NumberFormat.currency(
                                                            name: '')
                                                        .parse(con.text))
                                                    .toDouble() !=
                                                0
                                        ? payLoanerWithConfirmation(
                                            context, sa, snapshot)
                                        : warningPayingMoreOrNothing(context);
                                  }
                                },
                                icon: Icon(Icons.payments_rounded),
                              ),
                            ],
                          ),
                        ),
                        Item(child: Text('history')),
                        Item(
                          child: SizedBox(
                            height: 260 % MediaQuery.of(context).size.height,
                            child: StreamBuilder(
                                stream:
                                    Provider.of<Lists>(context, listen: false)
                                        .getPersonsLogs(snapshot.data!.ID),
                                builder: (context, snapshot) {
                                  if (snapshot.hasData) {
                                    return ListView.builder(
                                      itemCount: snapshot.data!.length,
                                      itemBuilder: (context, index) => Receipt(
                                        log: snapshot.data![index],
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return AlertDialog(
                                      title: Text('Error: ${snapshot.error}'),
                                    );
                                  }
                                  return SpinKitChasingDots(
                                    color: Colors.brown[500],
                                  );
                                }),
                          ),
                        ),
                        Item(
                            child: TextButton(
                                onPressed: () async {
                                  var li = Provider.of<Lists>(context,
                                      listen: false);
                                  try {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ChangeNotifierProvider.value(
                                                value: li,
                                                child: BankStatementPage(
                                                  accountNumber: snapshot
                                                      .data!.ID
                                                      .toString(),
                                                  customerName: snapshot
                                                      .data!.name
                                                      .toString(),
                                                  loaner: snapshot.data!,
                                                ),
                                              )),
                                    );
                                  } catch (e) {
                                    // Handle error (e.g., loaner not found)
                                    print(
                                        'Error loading account statement: $e');
                                  }
                                },
                                child: Text('account statement')))
                      ],
                    );
                  }
                  return SpinKitChasingDots(
                    color: Colors.brown[500],
                  );
                }),
          ),
        ),
      ),
    );
  }

  Future<Object?> showPaymentHistory(
      BuildContext context, AsyncSnapshot<Loaner?> snapshot) {
    return showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: 'paymentDialog',
      context: context,
      pageBuilder: (context, animation, secondaryAnimation) {
        return Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 100,
            bottom: 200,
          ),
          child: Material(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white, // Background color
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.brown, // Brown header
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'تفاصيل المدفوعات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Payment List
                Expanded(
                  child: snapshot.data?.lastPayment?.isNotEmpty ?? false
                      ? ListView.separated(
                          itemCount: snapshot.data!.lastPayment!.length,
                          separatorBuilder: (context, index) => Divider(
                            color: Colors.grey.shade300,
                            height: 1,
                          ),
                          itemBuilder: (context, index) {
                            final payment = snapshot.data!.lastPayment![index];
                            final name = snapshot.data!.name;
                            final paymentDate = payment.key != null
                                ? DateTime.parse(payment.key!)
                                : DateTime.now();

                            // Calculate balance before payment
                            double? remaining = payment.remaining;
                            double? value = double.tryParse(
                                payment.value ?? 'تم تصفير الحساب');
                            double? balanceBefore =
                                (remaining != null && value != null)
                                    ? remaining + value
                                    : null;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConfirmationPage(
                                          paied:
                                              intl.NumberFormat.simpleCurrency()
                                                  .format(value ?? 0),
                                          date: paymentDate,
                                          name: name!,
                                          remaining: remaining!,
                                          clearField: () {}),
                                    ));
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors
                                      .brown.shade50, // Light brown background
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.brown.shade100,
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Balance Before Payment (Top)
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'الرصيد قبل الدفع:',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown.shade800,
                                          ),
                                        ),
                                        Text(
                                          balanceBefore != null
                                              ? intl.NumberFormat
                                                      .simpleCurrency()
                                                  .format(balanceBefore)
                                              : 'N/A',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Amount Paid
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'المبلغ المدفوع:',
                                          style: TextStyle(
                                            color: Colors.brown.shade700,
                                          ),
                                        ),
                                        Text(
                                          '${intl.NumberFormat.simpleCurrency().format(double.tryParse(payment.value ?? '0') ?? 0)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    // Remaining Balance
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'الرصيد المتبقي:',
                                          style: TextStyle(
                                            color: Colors.brown.shade700,
                                          ),
                                        ),
                                        Text(
                                          payment.remaining != null
                                              ? intl.NumberFormat
                                                      .simpleCurrency()
                                                  .format(payment.remaining!)
                                              : 'N/A',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // Payment Date
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        intl.DateFormat.yMEd()
                                            .add_jm()
                                            .format(paymentDate),
                                        style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12,
                                        ),
                                        textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            'لا توجد مدفوعات متاحة',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
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

  Future<dynamic> resetAccount(
      BuildContext context, SalesProvider sa, AsyncSnapshot<Loaner?> snapshot) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'هل انت متاكد من تصفير حساب العميل؟',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'لا',
                style: TextStyle(fontSize: 20),
              ),
            ),
            TextButton(
              onPressed: () {
                sa.resetLoanerAcount(snapshot.data!.ID).then((_) {
                  con.text = '';
                  Navigator.pop(context);
                });
              },
              child: const Text(
                'نعم',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<dynamic> payLoanerWithConfirmation(
      BuildContext context, SalesProvider sa, AsyncSnapshot<Loaner?> snapshot) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'هل انت متاكد من تسديد ${con.text}',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                showGeneralDialog(
                  context: context,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      LoadingOverlay(),
                );
                await sa
                    .payLoaner(
                        intl.NumberFormat.currency(name: '')
                            .parse(con.text)
                            .toDouble(),
                        snapshot.data!.ID)
                    .then((value) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmationPage(
                            clearField: () {
                              setState(() {
                                con.text = '';
                              });
                            },
                            paied: con.text,
                            date: DateTime.now(),
                            name: snapshot.data!.name!,
                            remaining: snapshot.data!.loanedAmount! -
                                (intl.NumberFormat.currency(name: '')
                                    .parse(con.text)),
                          ),
                        )));

                Navigator.pop(context);
                Navigator.pop(context);
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
  }

  Future<dynamic> warningPayingMoreOrNothing(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            (intl.NumberFormat.currency(name: '').parse(con.text)) != 0
                ? 'لا يمكنك ان تسدد اكثر من المطلوب'
                : 'لا يمكنك تسديد لاشيء',
            style: TextStyle(fontSize: 20),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'موافق',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        );
      },
    );
  }
}

class Item extends StatefulWidget {
  final child;
  const Item({super.key, required this.child});

  @override
  State<Item> createState() => _ItemState();
}

class _ItemState extends State<Item> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 0, 5, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.brown[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(8),
          child: widget.child,
        ),
      ),
    );
  }
}
