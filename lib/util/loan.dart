import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/receipt.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Loan extends StatefulWidget {
  final int index;
  const Loan({super.key, required this.index});

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
        iconTheme: IconThemeData(color: Colors.brown[50]),
        backgroundColor: Colors.brown,
        elevation: 0,
        title: Row(
          children: [
            Expanded(
              child: Text(
                Provider.of<SalesProvider>(context)
                    .loanersList[widget.index]
                    .name,
                style: TextStyle(color: Colors.brown[50], fontSize: 14),
              ),
            ),
            Expanded(
              child: Text(
                Provider.of<SalesProvider>(context)
                    .loanersList[widget.index]
                    .ID,
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
                child: Consumer<SalesProvider>(
                  builder: (context, sa, child) => Column(
                    children: [
                      Item(
                        child: Text(
                            'Phone number : ${sa.loanersList[widget.index].phoneNumber}'),
                      ),
                      Item(
                        child: Text(
                            'Location : ${sa.loanersList[widget.index].location}'),
                      ),
                      Item(
                        child: Text(
                            'wanted : ${sa.loanersList[widget.index].loanedAmount}'),
                      ),
                      Item(
                        child: Text(
                            'Last Payment date : ${DateFormat.yMEd().add_jmz().format(sa.loanersList[widget.index].lastPaymentDate)}'),
                      ),
                      Item(
                        child: Text(
                            'Last Payment :${sa.loanersList[widget.index].lastPayment}'),
                      ),
                      Item(
                        child: Row(
                          children: [
                            Text('Pay : '),
                            Expanded(
                              child: TextFormField(
                                controller: con,
                                autocorrect: true,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                sa.payLoaner(double.tryParse(con.text) ?? 0,
                                    sa.loanersList[widget.index].ID);

                                setState(() {
                                  con.text = '';
                                });
                              },
                              icon: Icon(Icons.payments_rounded),
                            ),
                          ],
                        ),
                      ),
                      Item(child: Text('history')),
                      Consumer<Lists>(
                        builder: (context, li, child) {
                          var list = li.getPersonsLogs(
                              Provider.of<SalesProvider>(context)
                                  .loanersList[widget.index]
                                  .ID);
                          return Item(
                            child: SizedBox(
                              height: 260 % MediaQuery.of(context).size.height,
                              child: ListView.builder(
                                itemCount: list.length,
                                itemBuilder: (context, index) => Receipt(
                                  log: list[index],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ))),
      ),
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
