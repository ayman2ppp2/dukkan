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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Center(child: Text('الديون')),
            Center(
              child: StreamBuilder(
                stream: Provider.of<SalesProvider>(context, listen: false)
                    .getLoanersStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(snapshot.error.toString());
                  }
                  if (snapshot.hasData) {
                    return Text(
                      textDirection: TextDirection.rtl,
                      'الديون الكلية : ${int.NumberFormat.simpleCurrency(name: ' ').format(snapshot.data!.fold(0.0, (previousValue, element) => previousValue + element.loanedAmount!))}',
                    );
                  }
                  return SpinKitChasingDots(
                    color: Colors.brown[200],
                  );
                },
              ),
            )
          ],
        ),
      ),
      body: Column(
        children: [
          // sa.refreshLoanersList();FutureBuilder(
          StreamBuilder(
            stream: Provider.of<SalesProvider>(context, listen: false)
                .getLoanersStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error : ${snapshot.error}');
              }
              if (snapshot.hasData) {
                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(2, 0, 2, 8),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.brown[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                              title: Text(snapshot.data![index].name!),
                              trailing: Text('المطلوب : ' +
                                  int.NumberFormat.simpleCurrency(name: '')
                                      .format(
                                          snapshot.data![index].loanedAmount)),
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
                                          loaner: snapshot.data![index],
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
              }
              return SpinKitChasingDots(
                color: Colors.brown,
              );
            },
          )
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
                  padding: EdgeInsets.only(
                    left: MediaQuery.of(context).size.width * 0.05,
                    right: MediaQuery.of(context).size.width * 0.05,
                    top: MediaQuery.of(context).size.height * 0.1,
                    bottom: MediaQuery.of(context).size.height * 0.3,
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
