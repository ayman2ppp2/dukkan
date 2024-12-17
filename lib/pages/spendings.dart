import 'package:dukkan/pages/addExpense.dart';
import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/pages/spending.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class Spendings extends StatefulWidget {
  const Spendings({super.key});

  @override
  State<Spendings> createState() => _SpendingsState();
}

class _SpendingsState extends State<Spendings> {
  @override
  Widget build(BuildContext context) {
    var totalprofit = 0.0;
    var loans = 0.0;
    BoxShadow shadow = BoxShadow(
      color: Color.fromARGB(255, 54, 49, 49),
      spreadRadius: 1,
      blurRadius: 2,
      offset: Offset.fromDirection(1, 2.5),
    );
    return Scaffold(
        backgroundColor: Colors.brown[200],
        appBar: AppBar(
          centerTitle: true,
          backgroundColor: Colors.brown[400],
          title: Text(
            'المنصرفات',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Container(
                  height: constraints.maxHeight * 0.3,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.brown[400],
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // ExpensesPieChart()
                      Positioned(
                        left: constraints.maxWidth * 0.05,
                        top: constraints.maxHeight * 0.02,
                        child: Container(
                          height: constraints.maxHeight * 0.25,
                          width: constraints.maxWidth * 0.45,
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [shadow],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'الأرباح  الشهرية',
                                  style: TextStyle(fontSize: 18),
                                ),
                                Consumer<ExpenseProvider>(
                                  builder: (context, li, child) =>
                                      FutureBuilder<double>(
                                    future: li.getProfitOfTheMonth(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        totalprofit = snapshot.data!;
                                        return FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            NumberFormat.simpleCurrency()
                                                .format(snapshot.data),
                                            style: TextStyle(fontSize: 18),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        );
                                      } else {
                                        return Center(
                                          child: SpinKitChasingDots(
                                            color: Colors.brown[200],
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: constraints.maxHeight * 0.006,
                        right: constraints.maxWidth * 0.02,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Container(
                            height: constraints.maxHeight * 0.125,
                            width: constraints.maxWidth * 0.35,
                            decoration: BoxDecoration(
                              color: Colors.orange[50],
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [shadow],
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'الديون الشهرية',
                                          // style: TextStyle(fontSize: 18),
                                        ),
                                      ),
                                      Consumer<ExpenseProvider>(
                                        builder: (context, li, child) {
                                          return FutureBuilder<double>(
                                            future: li.getLoansOfMonth(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    NumberFormat
                                                            .simpleCurrency()
                                                        .format(snapshot.data),
                                                    style:
                                                        TextStyle(fontSize: 13),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                );
                                              } else {
                                                return SpinKitChasingDots(
                                                  color: Colors.brown[200],
                                                  size: 20,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                      // SizedBox(height: 8),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          'الديون اليومية',
                                          // style: TextStyle(fontSize: ),
                                        ),
                                      ),
                                      Consumer<ExpenseProvider>(
                                        builder: (context, li, child) {
                                          return FutureBuilder<double>(
                                            future: li.getDailyLoans(),
                                            builder: (context, snapshot) {
                                              if (snapshot.hasData) {
                                                return FittedBox(
                                                  fit: BoxFit.scaleDown,
                                                  child: Text(
                                                    NumberFormat
                                                            .simpleCurrency()
                                                        .format(snapshot.data),
                                                    style:
                                                        TextStyle(fontSize: 13),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    maxLines: 1,
                                                  ),
                                                );
                                              } else {
                                                return SpinKitChasingDots(
                                                  color: Colors.brown[200],
                                                  size: 20,
                                                );
                                              }
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Consumer<ExpenseProvider>(
                        builder: (context, exp, child) => Positioned(
                          top: constraints.maxHeight * 0.14,
                          right: constraints.maxWidth * 0.02,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              height: constraints.maxHeight * 0.125,
                              width: constraints.maxWidth * 0.35,
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [shadow],
                              ),
                              child: FutureBuilder(
                                  future: exp.getRealProfit(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      return Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Center(
                                              child: Text(
                                                'المتبقي  الشهري',
                                                style: TextStyle(fontSize: 18),
                                              ),
                                            ),
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                NumberFormat.simpleCurrency()
                                                    .format(snapshot.data),
                                                style: TextStyle(fontSize: 18),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Text('${snapshot.error}');
                                    }
                                    return SpinKitChasingDots(
                                      color: Colors.brown[400],
                                    );
                                  }),
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<ExpenseProvider>(
                    builder: (context, exp, child) => StreamBuilder(
                        stream: exp.getIndvidualExpenses(fixed: true),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('${snapshot.error.toString()}');
                          }
                          if (snapshot.hasData) {
                            return ListView.builder(
                              itemCount: snapshot.data!
                                  .length, // Replace with the actual item count
                              itemBuilder: (context, index) => Container(
                                color: Colors.brown[200],
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      color: Colors.orange[50],
                                    ),
                                    child: ListTile(
                                      onTap: () async {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ChangeNotifierProvider.value(
                                                    value: exp,
                                                    child: Spending(
                                                      id: snapshot
                                                          .data![index].ID,
                                                    )),
                                          ),
                                        );
                                      },
                                      title: Text(snapshot.data![index].name!),
                                      trailing: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        child: Text(
                                          NumberFormat.simpleCurrency(name: "")
                                              .format(snapshot
                                                  .data![index].amount!),
                                          style: TextStyle(fontSize: 16),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            return Center(
                              child: SpinKitChasingDots(
                                color: Colors.white,
                              ),
                            );
                          }
                        }),
                  ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: Consumer<ExpenseProvider>(
          builder: (context, exp, child) => FloatingActionButton(
            onPressed: () {
              showGeneralDialog(
                barrierDismissible: true,
                barrierLabel: 'gg',
                context: context,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return ChangeNotifierProvider.value(
                    value: exp,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 130, 20, 20),
                      child: AddExpense(),
                    ),
                  );
                },
              );
              // Navigator.push(context, );
            },
            child: Icon(Icons.add),
          ),
        ));
  }
}
