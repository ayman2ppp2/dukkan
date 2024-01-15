import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loan.dart';
import 'package:flutter/material.dart';
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(child: Text('الديون')),
            Center(
                child: Text(
                    'الديون الكلية : ${Provider.of<SalesProvider>(context).getTotalLoans().ceil().toStringAsFixed(2)}')),
          ],
        ),
      ),
      body: Column(
        children: [
          Consumer<SalesProvider>(builder: (context, sa, child) {
            // sa.refreshLoanersList();
            return Expanded(
              child: ListView.builder(
                itemCount: sa.loanersList.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.brown[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                          title: Text(sa.loanersList[index].name),
                          trailing: Text('المطلوب : ' +
                              sa.loanersList[index].loanedAmount.toString()),
                          onTap: () {
                            var li = Provider.of<Lists>(context, listen: false);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ChangeNotifierProvider.value(
                                  value: sa,
                                  child: ChangeNotifierProvider.value(
                                    value: li,
                                    child: Loan(
                                      index: index,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () {
            var sa = Provider.of<SalesProvider>(context, listen: false);
            showGeneralDialog(
              barrierLabel: 'gg',
              barrierDismissible: true,
              context: context,
              pageBuilder: (context, animation, secondaryAnimation) {
                TextEditingController na = TextEditingController();
                TextEditingController ph = TextEditingController();
                TextEditingController lo = TextEditingController();
                return Padding(
                  padding: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 100,
                    bottom: 220,
                  ),
                  child: Material(
                    borderRadius: BorderRadius.circular(12),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: na,
                            textDirection: TextDirection.rtl,
                            keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              hintText: "الأسم",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: ph,
                            textDirection: TextDirection.rtl,
                            // keyboardType: TextInputType.name,
                            decoration: InputDecoration(
                              hintText: "الرقم",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            controller: lo,
                            textDirection: TextDirection.rtl,
                            keyboardType: TextInputType.streetAddress,
                            decoration: InputDecoration(
                              hintText: "المكان",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () {
                              sa.addLoaner(na.text, ph.text, lo.text);
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.check))
                      ],
                    ),
                  ),
                );
              },
            );
          },
          child: Icon(Icons.person_add),
          tooltip: 'إضافة دائن '),
    );
  }
}
