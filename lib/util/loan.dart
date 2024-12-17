import 'package:dukkan/pages/accountStatement.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loadingOverlay.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/receipt.dart';
import 'package:flutter/material.dart';
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
                        .isar
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
                                child:
                                    Text('المكان : ${snapshot.data!.location}'),
                              ),
                              Item(
                                child: Text(
                                    'المطلوب : ${snapshot.data!.loanedAmount}'),
                              ),
                              Item(
                                child: Text(
                                    textDirection: TextDirection.rtl,
                                    'تاريخ اخر دفعة : ${intl.DateFormat.yMEd().add_jmz().format(DateTime.parse(snapshot.data!.lastPayment!.isEmpty ? DateTime.now().toString() : snapshot.data!.lastPayment!.last.key!.toString()))}'),
                              ),
                              Item(
                                child: GestureDetector(
                                  onLongPress: () {
                                    showGeneralDialog(
                                      barrierDismissible: true,
                                      barrierLabel: 'gg',
                                      context: context,
                                      pageBuilder: (context, animation,
                                              secondaryAnimation) =>
                                          Padding(
                                        padding: const EdgeInsets.only(
                                          left: 20,
                                          right: 20,
                                          top: 100,
                                          bottom: 200,
                                        ),
                                        child: Material(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: ListView.builder(
                                            itemCount: snapshot.data
                                                    ?.lastPayment?.length ??
                                                0,
                                            itemBuilder: (context, index) {
                                              final payment = snapshot
                                                  .data?.lastPayment?[index];

                                              return ListTile(
                                                leading: Text(
                                                  '${payment?.value ?? '0'}        :',
                                                ),
                                                subtitle: Text(
                                                  intl.DateFormat.yMEd()
                                                      .add_jm()
                                                      .format(
                                                        payment != null
                                                            ? DateTime.parse(payment
                                                                    .key ??
                                                                DateTime.now()
                                                                    .toString())
                                                            : DateTime.now(),
                                                      ),
                                                  textDirection:
                                                      TextDirection.rtl,
                                                ),
                                                trailing: Text(
                                                  payment?.remaining != null
                                                      ? intl.NumberFormat
                                                              .simpleCurrency()
                                                          .format(payment!
                                                              .remaining!)
                                                      : 'N/A',
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text(
                                      'اخر دفعة :${snapshot.data!.lastPayment!.isEmpty ? 0.toString() : snapshot.data!.lastPayment!.last.value!}'),
                                ),
                              ),
                              Item(
                                child: Row(
                                  textDirection: TextDirection.rtl,
                                  children: [
                                    Text(
                                        textDirection: TextDirection.rtl,
                                        'تسديد : '),
                                    Expanded(
                                      child: TextFormField(
                                        controller: con,
                                        autocorrect: true,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        var sa = Provider.of<SalesProvider>(
                                            context,
                                            listen: false);
                                        (double.tryParse(con.text) ?? 0) <=
                                                    snapshot
                                                        .data!.loanedAmount! &&
                                                (double.tryParse(con.text) ??
                                                        0) !=
                                                    0
                                            ? showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      'هل انت متاكد من تسديد ${con.text}',
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () async {
                                                          showGeneralDialog(
                                                            context: context,
                                                            pageBuilder: (context,
                                                                    animation,
                                                                    secondaryAnimation) =>
                                                                LoadingOverlay(),
                                                          );
                                                          await sa
                                                              .payLoaner(
                                                                  double.tryParse(con
                                                                          .text) ??
                                                                      0,
                                                                  snapshot
                                                                      .data!.ID)
                                                              .then((value) =>
                                                                  Navigator.push(
                                                                      context,
                                                                      MaterialPageRoute(
                                                                        builder:
                                                                            (context) =>
                                                                                ConfirmationPage(
                                                                          clearField:
                                                                              () {
                                                                            setState(() {
                                                                              con.text = '';
                                                                            });
                                                                          },
                                                                          paied:
                                                                              con.text,
                                                                          name: snapshot
                                                                              .data!
                                                                              .name!,
                                                                          remaining:
                                                                              snapshot.data!.loanedAmount! - (double.tryParse(con.text) ?? 0),
                                                                        ),
                                                                      )));

                                                          Navigator.pop(
                                                              context);
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                          'نعم',
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                          'لا',
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              )
                                            : showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Text(
                                                      (double.tryParse(con
                                                                      .text) ??
                                                                  0) !=
                                                              0
                                                          ? 'لا يمكنك ان تسدد اكثر من المطلوب'
                                                          : 'لا يمكنك تسديد لاشيء',
                                                      style: TextStyle(
                                                          fontSize: 20),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                        },
                                                        child: const Text(
                                                          'موافق',
                                                          style: TextStyle(
                                                              fontSize: 20),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                      },
                                      icon: Icon(Icons.payments_rounded),
                                    ),
                                  ],
                                ),
                              ),
                              Item(child: Text('history')),
                              Consumer<Lists>(
                                builder: (context, li, child) {
                                  return Item(
                                    child: SizedBox(
                                      height: 260 %
                                          MediaQuery.of(context).size.height,
                                      child: FutureBuilder(
                                        future: li
                                            .getPersonsLogs(snapshot.data!.ID),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return ListView.builder(
                                              itemCount: snapshot.data!.length,
                                              itemBuilder: (context, index) =>
                                                  Receipt(
                                                log: snapshot.data![index],
                                              ),
                                            );
                                          }
                                          if (snapshot.hasError) {
                                            return AlertDialog(
                                              title: Text('Error'),
                                            );
                                          }
                                          return SpinKitChasingDots(
                                            color: Colors.brown[500],
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                              Item(
                                  child: TextButton(
                                      onPressed: () async {
                                        try {
                                          Map<String, dynamic> accountData =
                                              await Provider.of<SalesProvider>(
                                                      context,
                                                      listen: false)
                                                  .db
                                                  .getAccountStatementData(
                                                      widget.loaner.ID);

                                          // Pass the data to the AccountStatementPage
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    Provider.value(
                                                      value: Provider.of<Lists>(
                                                          context),
                                                      child:
                                                          AccountStatementPage(
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
                      })))),
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
