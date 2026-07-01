import 'package:dukkan/util/statsItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';
import '../util/charts.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  int _lastCacheVersion = -1;
  final ScrollController _scrollController = ScrollController();
  bool _tabListenerAdded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_tabListenerAdded) {
      DefaultTabController.of(context).addListener(_onTabChanged);
      _tabListenerAdded = true;
    }
  }

  @override
  void dispose() {
    DefaultTabController.of(context).removeListener(_onTabChanged);
    _scrollController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (DefaultTabController.of(context).index != 1) return;
    final li = context.read<Lists>();
    if (_lastCacheVersion == li.cacheVersion) return;
    _lastCacheVersion = li.cacheVersion;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final li = context.read<Lists>();
    if (_lastCacheVersion == -1) _lastCacheVersion = li.cacheVersion;
    return Scaffold(
      body: Flex(
        direction: Axis.vertical,
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              physics: const ClampingScrollPhysics(),
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
                        child: CircularChart(),
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
                        child: BarChart(),
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
                        child: LineChart(),
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
                        child: MOY(),
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
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(seconds: 2),
            curve: Curves.fastOutSlowIn,
          );
        },
        child: const Icon(Icons.arrow_downward_rounded),
      ),
    );
  }
}
