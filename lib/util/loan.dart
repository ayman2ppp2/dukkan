import 'package:dukkan/core/observability.dart';
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
  TextEditingController payCon = TextEditingController();
  TextEditingController withdrawCon = TextEditingController();

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
                if (temp!.balance == 0) {
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.loaner.name!,
              style: TextStyle(
                color: Colors.brown[50],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '#${widget.loaner.ID}',
              style: TextStyle(
                color: Colors.brown[300],
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: StreamBuilder(
              stream: Provider.of<SalesProvider>(context, listen: false)
                  .watchLoaner(widget.loaner.ID),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text(UserSafeMessages.loadFailed));
                }
                if (snapshot.hasData) {
                  final bal = snapshot.data!.balance ?? 0;
                  final isPositive = bal >= 0;
                  final canWithdraw = bal < 0;
                  return Column(
                    children: [
                      Card(
                        margin: const EdgeInsets.only(bottom: 0),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          height: 180,
                          padding: EdgeInsets.only(left: 20, right: 20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isPositive
                                  ? [Colors.red.shade700, Colors.red.shade500]
                                  : [
                                      Colors.green.shade700,
                                      Colors.green.shade500
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'الرصيد',
                                style: TextStyle(
                                  color: Colors.white.withAlpha(178),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                intl.NumberFormat.simpleCurrency(
                                        decimalDigits: 0, name: '')
                                    .format(bal.abs()),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(51),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  isPositive ? 'مطلوب' : 'طالب',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'معلومات العميل',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.brown[800],
                                ),
                              ),
                              const SizedBox(height: 12),
                              _infoRow(Icons.phone_android, 'رقم الهاتف',
                                  snapshot.data!.phoneNumber ?? ''),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                              _infoRow(Icons.location_on, 'المكان',
                                  snapshot.data!.location ?? ''),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                              _infoRow(
                                  Icons.date_range,
                                  'تاريخ اخر دفعة',
                                  intl.DateFormat.yMd().format(
                                    DateTime.parse(snapshot
                                            .data!.lastPayment!.isEmpty
                                        ? DateTime.now().toString()
                                        : snapshot.data!.lastPayment!.last.key!
                                            .toString()),
                                  )),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1),
                              ),
                              GestureDetector(
                                onLongPress: () =>
                                    showPaymentHistory(context, snapshot),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _infoRow(
                                        Icons.payments,
                                        'اخر عملية',
                                        snapshot.data!.lastPayment!.isEmpty
                                            ? '0'
                                            : intl.NumberFormat.simpleCurrency(
                                                    decimalDigits: 0, name: '')
                                                .format(double.parse(snapshot
                                                    .data!
                                                    .lastPayment!
                                                    .last
                                                    .value!))),
                                    const SizedBox(height: 2),
                                    Text(
                                      'اضغط مطولاً لعرض كامل السجل',
                                      style: TextStyle(
                                        color: Colors.brown[300],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.payments_rounded,
                                      color: Colors.green[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'إيداع',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.green[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: payCon,
                                keyboardType: TextInputType.number,
                                textDirection: TextDirection.rtl,
                                inputFormatters: [
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) => TextEditingValue(
                                      selection: TextSelection.collapsed(
                                          offset:
                                              getEOLOffset(oldValue, newValue)),
                                      text: formatTextField(oldValue, newValue),
                                    ),
                                  ),
                                ],
                                decoration: InputDecoration(
                                  hintText: 'المبلغ',
                                  prefixIcon: Icon(
                                      Icons.monetization_on_outlined,
                                      color: Colors.green[600]),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  filled: true,
                                  fillColor: Colors.green[50],
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    var sa = Provider.of<SalesProvider>(context,
                                        listen: false);
                                    if (payCon.text == 'Reset') {
                                      resetAccount(context, sa, snapshot);
                                    } else {
                                      var amount =
                                          intl.NumberFormat.currency(name: '')
                                              .parse(payCon.text)
                                              .toDouble();
                                      if (amount > 0) {
                                        payLoanerWithConfirmation(
                                            context, sa, snapshot);
                                      }
                                    }
                                  },
                                  icon:
                                      const Icon(Icons.check_circle, size: 18),
                                  label: const Text('تأكيد الإيداع'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[700],
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (canWithdraw) ...[
                        const SizedBox(height: 8),
                        Card(
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.currency_exchange,
                                        color: Colors.red[700], size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'سحب',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Colors.red[800],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: withdrawCon,
                                  keyboardType: TextInputType.number,
                                  textDirection: TextDirection.rtl,
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
                                  decoration: InputDecoration(
                                    hintText: 'المبلغ',
                                    prefixIcon: Icon(
                                        Icons.monetization_on_outlined,
                                        color: Colors.red[600]),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    filled: true,
                                    fillColor: Colors.red[50],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      if (withdrawCon.text.isEmpty) {
                                        return;
                                      }
                                      var sa = Provider.of<SalesProvider>(
                                          context,
                                          listen: false);
                                      var amount =
                                          intl.NumberFormat.currency(name: '')
                                              .parse(withdrawCon.text)
                                              .toDouble();
                                      if (amount > 0 && amount <= bal.abs()) {
                                        withdrawConfirmation(
                                            context, sa, snapshot);
                                      } else {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('خطأ'),
                                            content: Text(
                                                'المبلغ يجب ان يكون بين 1 و ${intl.NumberFormat.simpleCurrency(decimalDigits: 0, name: '').format(bal.abs())}'),
                                            actions: [
                                              TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(context),
                                                  child: const Text('موافق'))
                                            ],
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.check_circle,
                                        size: 18),
                                    label: const Text('تأكيد السحب'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red[700],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Row(
                                children: [
                                  Icon(Icons.receipt_long,
                                      color: Colors.brown[600], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'الفواتير',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: Colors.brown[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 300,
                              child: StreamBuilder(
                                  stream:
                                      Provider.of<Lists>(context, listen: false)
                                          .getPersonsLogs(snapshot.data!.ID),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return ListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: snapshot.data!.length,
                                        itemBuilder: (context, index) =>
                                            Receipt(
                                          log: snapshot.data![index],
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return const Center(
                                        child:
                                            Text(UserSafeMessages.loadFailed),
                                      );
                                    }
                                    return Center(
                                      child: SpinKitChasingDots(
                                        color: Colors.brown[500],
                                      ),
                                    );
                                  }),
                            ),
                            const Divider(height: 1),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
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
                                  } catch (e, st) {
                                    await AppLogger.captureException(e,
                                        stackTrace: st,
                                        area: 'loan.account_statement');
                                  }
                                },
                                icon: const Icon(Icons.receipt, size: 18),
                                label: const Text('كشف حساب'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Center(
                  child: SpinKitChasingDots(
                    color: Colors.brown[500],
                  ),
                );
              }),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: Colors.brown[100],
          child: Icon(icon, size: 16, color: Colors.brown[600]),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.brown[500],
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<Object?> showPaymentHistory(
      BuildContext context, AsyncSnapshot<Loaner?> snapshot) {
    return showGeneralDialog(
      barrierDismissible: true,
      barrierLabel: 'تفاصيل المدفوعات',
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
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.brown,
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
                            final type = payment.type ?? 'payment';
                            final remaining = payment.remaining;
                            final value =
                                double.tryParse(payment.value ?? '0') ?? 0;
                            final double? balanceBefore;
                            if (type == 'reset') {
                              balanceBefore = null;
                            } else if (type == 'withdraw') {
                              balanceBefore = (remaining ?? 0) - value;
                            } else {
                              balanceBefore = (remaining ?? 0) + value;
                            }

                            Color typeColor;
                            String typeLabel;
                            switch (type) {
                              case 'sale':
                                typeColor = Colors.blue;
                                typeLabel = 'مشتريات';
                                break;
                              case 'withdraw':
                                typeColor = Colors.red;
                                typeLabel = 'سحب';
                                break;
                              case 'reset':
                                typeColor = Colors.orange;
                                typeLabel = 'تصفير';
                                break;
                              default:
                                typeColor = Colors.green;
                                typeLabel = 'إيداع';
                            }

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ConfirmationPage(
                                          paied:
                                              intl.NumberFormat.simpleCurrency()
                                                  .format(value),
                                          date: paymentDate,
                                          name: name!,
                                          remaining: remaining ?? 0,
                                          clearField: () {},
                                          type: type),
                                    ));
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 4, horizontal: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.brown.shade50,
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          typeLabel,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: typeColor,
                                          ),
                                        ),
                                        Text(
                                          intl.NumberFormat.simpleCurrency()
                                              .format(value),
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.brown.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    if (balanceBefore != null)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 2),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'الرصيد قبل:',
                                              style: TextStyle(
                                                color: Colors.brown.shade600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              intl.NumberFormat
                                                      .simpleCurrency()
                                                  .format(balanceBefore),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.brown.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
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
                                          remaining != null
                                              ? intl.NumberFormat
                                                      .simpleCurrency()
                                                  .format(remaining)
                                              : 'N/A',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: remaining != null &&
                                                    remaining < 0
                                                ? Colors.green
                                                : Colors.brown.shade900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
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
                  payCon.text = '';
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
            'هل انت متاكد من إيداع ${payCon.text}',
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
                            .parse(payCon.text)
                            .toDouble(),
                        snapshot.data!.ID)
                    .then((value) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmationPage(
                            clearField: () {
                              setState(() {
                                payCon.text = '';
                              });
                            },
                            paied: payCon.text,
                            date: DateTime.now(),
                            name: snapshot.data!.name!,
                            remaining: snapshot.data!.balance! -
                                (intl.NumberFormat.currency(name: '')
                                    .parse(payCon.text)),
                            type: 'payment',
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

  Future<dynamic> withdrawConfirmation(
      BuildContext context, SalesProvider sa, AsyncSnapshot<Loaner?> snapshot) {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'هل انت متاكد من سحب ${withdrawCon.text}',
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
                    .withdrawFromBalance(
                        intl.NumberFormat.currency(name: '')
                            .parse(withdrawCon.text)
                            .toDouble(),
                        snapshot.data!.ID)
                    .then((value) => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmationPage(
                            clearField: () {
                              setState(() {
                                withdrawCon.text = '';
                              });
                            },
                            paied: withdrawCon.text,
                            date: DateTime.now(),
                            name: snapshot.data!.name!,
                            remaining: snapshot.data!.balance! +
                                (intl.NumberFormat.currency(name: '')
                                    .parse(withdrawCon.text)),
                            type: 'withdraw',
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
}
