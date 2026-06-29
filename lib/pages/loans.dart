import 'package:dukkan/core/observability.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart' as int;

import 'package:provider/provider.dart';

import '../providers/list.dart';

class Loans extends StatefulWidget {
  const Loans({super.key});

  @override
  State<Loans> createState() => _LoansState();
}

class _LoansState extends State<Loans> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الديون'),
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: Provider.of<SalesProvider>(context, listen: false)
            .getLoanersStream(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text(UserSafeMessages.loadFailed));
          }
          if (!snapshot.hasData) {
            return Center(
              child: SpinKitChasingDots(
                color: Colors.brown[200],
              ),
            );
          }
          var data = snapshot.data!;
          double totalTheyOwe = data
              .where((e) => (e.balance ?? 0) > 0)
              .fold(0.0, (sum, e) => sum + e.balance!);
          double totalIOwe = data
              .where((e) => (e.balance ?? 0) < 0)
              .fold(0.0, (sum, e) => sum + e.balance!.abs());
          return Column(
            children: [
              Card(
                margin: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(
                        child: Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
Icon(Icons.arrow_downward,
                                 color: Colors.red[700], size: 20),
                            const SizedBox(width: 4),
                            Text(
                              'مطلوب',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              int.NumberFormat.simpleCurrency(name: ' ')
                                  .format(totalTheyOwe),
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                          width: 1, height: 24, color: Colors.grey[300]),
                      Expanded(
                        child: Row(
                          textDirection: TextDirection.rtl,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
Icon(Icons.arrow_upward,
                                 color: Colors.green[700], size: 20),
                            const SizedBox(width: 4),
                            Text(
                              'طالب',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              int.NumberFormat.simpleCurrency(name: ' ')
                                  .format(totalIOwe),
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 80),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final loaner = data[index];
                    final bal = loaner.balance ?? 0;
                    final isPositive = bal >= 0;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      color:
                          isPositive ? Colors.red[50] : Colors.green[50],
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPositive
                              ? Colors.red[200]
                              : Colors.green[200],
                          child: Text(
                            (loaner.name ?? '?')[0],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isPositive
                                  ? Colors.red[900]
                                  : Colors.green[900],
                            ),
                          ),
                        ),
                        title: Text(
                          loaner.name ?? '',
                          style:
                              const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: loaner.phoneNumber != null &&
                                loaner.phoneNumber!.isNotEmpty
                            ? Text(
                                loaner.phoneNumber!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              )
                            : null,
                        trailing: Text(
                          isPositive
                              ? 'مطلوب : ${int.NumberFormat.simpleCurrency(name: '').format(bal)}'
                              : 'طالب : ${int.NumberFormat.simpleCurrency(name: '').format(bal.abs())}',
                          style: TextStyle(
                            color: isPositive
                                ? Colors.red[800]
                                : Colors.green[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onTap: () {
                          var sa = Provider.of<SalesProvider>(context,
                              listen: false);
                          var li =
                              Provider.of<Lists>(context, listen: false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChangeNotifierProvider.value(
                                value: sa,
                                child: ChangeNotifierProvider.value(
                                  value: li,
                                  child: Loan(
                                    loaner: loaner,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLoanerDialog(context),
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة'),
      ),
    );
  }

  void _showAddLoanerDialog(BuildContext context) {
    TextEditingController na = TextEditingController();
    TextEditingController ph = TextEditingController();
    TextEditingController lo = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إضافة دائن'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: na,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ph,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: lo,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                labelText: 'المكان',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              var sa =
                  Provider.of<SalesProvider>(context, listen: false);
              sa.addLoaner(na.text, ph.text, lo.text);
              Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }
}
