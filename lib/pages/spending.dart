import 'package:dukkan/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class Spending extends StatefulWidget {
  final int id;
  const Spending({super.key, required this.id});

  @override
  State<Spending> createState() => _SpendingState();
}

class _SpendingState extends State<Spending> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.brown[50],
        appBar: AppBar(
            actions: [
              IconButton(
                  onPressed: () {
                    Provider.of<ExpenseProvider>(context, listen: false)
                        .deleteExpense(id: widget.id)
                        .then((value) => value ? Navigator.pop(context) : null);
                  },
                  icon: Icon(Icons.delete_forever_rounded))
            ],
            foregroundColor: Colors.brown[50],
            backgroundColor: Colors.brown[300],
            title: StreamBuilder(
              stream: Provider.of<ExpenseProvider>(context)
                  .watchExpense(id: widget.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                }
                if (snapshot.hasData) {
                  return Text(
                    snapshot.data!.name!,
                    style: TextStyle(color: Colors.brown[50]),
                  );
                }
                return SpinKitChasingDots(
                  color: Colors.brown[200],
                );
              },
            )),
        body: StreamBuilder(
          stream:
              Provider.of<ExpenseProvider>(context).watchExpense(id: widget.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Text(snapshot.error.toString());
            }
            if (snapshot.hasData) {
              return Flex(
                direction: Axis.vertical,
                children: [
                  SizedBox(
                    height: 15,
                  ),
                  Center(
                    child: MyContainer(
                      child: Text('المعرف: ${snapshot.data?.ID}'),
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Center(
                    child: MyContainer(
                      child:
                          Text('النسبة من الإجمالي: ${snapshot.data!.amount}'),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: MyContainer(
                      child: Text('القيمة النقدية: ${snapshot.data!.amount}'),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: MyContainer(
                      child: Text(
                          'تاريخ آخر دفعة: ${snapshot.data!.lastCalculationDate}'),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: MyContainer(
                      child: Text('فترة الدفع: ${snapshot.data!.period}'),
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Center(
                    child: MyContainer(
                      child: SizedBox(
                        height: 200,
                        width: 300,
                      ),
                    ),
                  ),
                ],
              );
            }
            return SpinKitChasingDots(
              color: Colors.brown[200],
            );
          },
        ));
  }
}

class MyContainer extends StatelessWidget {
  final Widget child;
  const MyContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: child,
      ),
    );
  }
}
