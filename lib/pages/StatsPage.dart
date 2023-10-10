import 'package:dukkan/util/statsItem.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../list.dart';
import '../util/charts.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        return Flex(
          direction: Axis.vertical,
          children: [
            Expanded(
              child: ListView(
                children: [
                  // الكلية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Sitem(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'الأرباح  : \n ${NumberFormat.simpleCurrency().format(li.getAllProfit())}',
                              //textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Sitem(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'المبيعات : \n ${NumberFormat.simpleCurrency().format(li.getAllSales())}',
                              ////textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // اليومية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Sitem(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'الأرباح اليومية: \n ${NumberFormat.simpleCurrency().format(li.getDailyProfits(DateTime.now()))}',
                              ////textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Sitem(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'المبيعات اليومية : \n ${NumberFormat.simpleCurrency().format(li.getDailySales(DateTime.now()))}',
                              ////textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // الشهرية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Sitem(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'الأرباح الشهرية : \n ${NumberFormat.simpleCurrency().format(li.getProfitOfTheMonth())}',
                              ////textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Sitem(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              'المبيعات الشهرية : \n ${NumberFormat.simpleCurrency().format(li.getSalesOfTheMonth())}',
                              ////textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // متوسط الارباح
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Sitem(
                          child: Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: Text(
                              ' متوسط نسبة الأرباح العامة : \n % ${li.getAverageProfitPercent().toStringAsFixed(2)}',
                              ////textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // daily saled products chart
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
                        height: 500,
                        constraints: const BoxConstraints(
                          maxWidth: 200,
                        ),
                        decoration: BoxDecoration(
                            color: Colors.brown[200],
                            borderRadius: BorderRadius.circular(12)),
                        child: ChangeNotifierProvider.value(
                          value: li,
                          child: const LineChart(),
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
        );
      },
    );
  }
}
