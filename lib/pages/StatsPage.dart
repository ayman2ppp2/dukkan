import 'package:dukkan/util/statsItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';
import '../util/charts.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // print('list');
    return Consumer<Lists>(
      builder: (context, li, child) {
        ScrollController sc = ScrollController();
        // li.refreshLogsList();
        return Scaffold(
          body: Flex(
            direction: Axis.vertical,
            children: [
              Expanded(
                child: ListView(
                  controller: sc,
                  physics: ClampingScrollPhysics(),
                  addAutomaticKeepAlives: true,
                  children: [
                    // الكلية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FutureBuilder(
                            future: li.getAllProfit(),
                            builder: (context, snapshot) {
                              if (snapshot.hasData) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Sitem(
                                    child: Padding(
                                      padding: const EdgeInsets.all(10.0),
                                      child: Text(
                                        ' الارباح الكلية : \n ${NumberFormat.simpleCurrency().format(snapshot.data)}',
                                        //textDirection: TextDirection.rtl,
                                      ),
                                    ),
                                  ),
                                );
                              } else {
                                return SpinKitChasingDots(
                                  color: Colors.brown[200],
                                );
                              }
                            }),
                        FutureBuilder(
                          future: li.getAllSales(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Sitem(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      'المبيعات الكلية  : \n ${NumberFormat.simpleCurrency().format(snapshot.data)}',
                                      //textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return SpinKitChasingDots(
                                color: Colors.brown[200],
                              );
                            }
                          },
                        )
                      ],
                    ),
                    // اليومية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FutureBuilder(
                          future: li.getDailyProfits(DateTime.now()),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Sitem(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      'الأرباح اليومية: \n ${NumberFormat.simpleCurrency().format(snapshot.data)}',
                                      ////textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return SpinKitChasingDots(
                                color: Colors.brown[200],
                              );
                            }
                          },
                        ),
                        FutureBuilder(
                          future: li.getDailySales(DateTime.now()),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Sitem(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      'المبيعات اليومية: \n ${NumberFormat.simpleCurrency().format(snapshot.data)}',
                                      ////textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return SpinKitChasingDots(
                                color: Colors.brown[200],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    // الشهرية
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FutureBuilder(
                          future: li.getProfitOfTheMonth(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Sitem(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      'الأرباح الشهرية: \n ${NumberFormat.simpleCurrency().format(snapshot.data)}',
                                      ////textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return SpinKitChasingDots(
                                color: Colors.brown[200],
                              );
                            }
                          },
                        ),
                        FutureBuilder(
                          future: li.getSalesOfTheMonth(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Sitem(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      'المبيعات الشهرية: \n ${NumberFormat.simpleCurrency().format(snapshot.data)}',
                                      ////textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return SpinKitChasingDots(
                                color: Colors.brown[200],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    // متوسط الارباح
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FutureBuilder(
                          future: li.getAverageProfitPercent(),
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Sitem(
                                  child: Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      ' متوسط نسبة الأرباح العامة: \n ${NumberFormat.simpleCurrency().format(snapshot.data)}',
                                      ////textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              return SpinKitChasingDots(
                                color: Colors.brown[200],
                              );
                            }
                          },
                        ),
                      ],
                    ),
                    // daily saled products chart
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                          height: 300,
                          decoration: BoxDecoration(
                              color: Colors.brown[200],
                              borderRadius: BorderRadius.circular(12)),
                          child: ChangeNotifierProvider.value(
                            value: li,
                            child: const CircularChart(),
                          )),
                    ),
                    // total sales per product
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                          height: 300,
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                          ),
                          decoration: BoxDecoration(
                              color: Colors.brown[200],
                              borderRadius: BorderRadius.circular(12)),
                          child: ChangeNotifierProvider.value(
                            value: li,
                            child: const BarChart(),
                          )),
                    ),
                    // total sales for each day in the month
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                          // height: 650,
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.brown[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ChangeNotifierProvider.value(
                            value: li,
                            child: const LineChart(),
                          )),
                    ),
                    // monthly sales of the year
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                          // height: 650,
                          constraints: const BoxConstraints(
                            maxWidth: 200,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.brown[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ChangeNotifierProvider.value(
                            value: li,
                            child: const MOY(),
                          )),
                    ),
                    // owners list
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Container(
                        height: 300,
                        constraints: const BoxConstraints(
                          maxWidth: 200,
                        ),
                        decoration: BoxDecoration(
                            color: Colors.brown[200],
                            borderRadius: BorderRadius.circular(12)),
                        child: ChangeNotifierProvider.value(
                          value: li,
                          child: Ownertile(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              sc.animateTo(
                sc.position.maxScrollExtent,
                duration: Duration(seconds: 2),
                curve: Curves.fastOutSlowIn,
              );
            },
            child: Icon(Icons.arrow_downward_rounded),
          ),
        );
      },
    );
  }
}
