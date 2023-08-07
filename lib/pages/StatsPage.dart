import 'package:dukkan/util/prodStats.dart';
import 'package:dukkan/util/product.dart';
import 'package:dukkan/util/statsItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../list.dart';

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
                              'الأرباح  : \n ${li.getAllProfit().toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
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
                              'المبيعات : \n ${li.getAllSales().toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
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
                              'الأرباح اليومية: \n ${li.getDailyProfits().toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
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
                              'المبيعات اليومية : \n ${li.getDailySales().toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
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
                              'الأرباح الشهرية : \n ${li.getProfitOfTheMonth().toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
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
                              'المبيعات الشهرية : \n ${li.getSalesOfTheMonth().toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
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
                              ' متوسط نسبة الأرباح العامة : \n  % ${li.getAverageProfitPercent().toStringAsFixed(2)}',
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // pie chart
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
                      child: SfCircularChart(
                        title: ChartTitle(
                            text: 'المبيعات اليومية لكل منتج',
                            alignment: ChartAlignment.near),
                        legend: const Legend(
                          isVisible: true,
                          overflowMode: LegendItemOverflowMode.scroll,
                          shouldAlwaysShowScrollbar: true,
                          isResponsive: true,
                          textStyle: TextStyle(
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        series: <CircularSeries>[
                          PieSeries<Product, String>(
                              animationDuration: 600,
                              dataSource: li.getSaledProductsByDate(
                                DateTime.now(),
                              ),
                              xValueMapper: (datum, index) => datum.name,
                              yValueMapper: (datum, index) => datum.count,
                              dataLabelSettings:
                                  const DataLabelSettings(isVisible: true)),
                        ],
                      ),
                    ),
                  ),

                  Table(
                    children: [],
                  ),

                  // stacked chart

                  // Padding(
                  //   padding: const EdgeInsets.all(10.0),
                  //   child: Container(
                  //     height: 300,
                  //     constraints: const BoxConstraints(
                  //       maxWidth: 200,
                  //     ),
                  //     decoration: BoxDecoration(
                  //         color: Colors.brown[200],
                  //         borderRadius: BorderRadius.circular(12)),
                  //     child: SfCartesianChart(
                  //       title: ChartTitle(
                  //           text: 'المبيعات اليومية',
                  //           alignment: ChartAlignment.near),
                  //       legend: const Legend(
                  //         isVisible: true,
                  //         overflowMode: LegendItemOverflowMode.scroll,
                  //         shouldAlwaysShowScrollbar: true,
                  //         isResponsive: true,
                  //         textStyle: TextStyle(
                  //           overflow: TextOverflow.ellipsis,
                  //         ),
                  //       ),
                  //       series: <StackedColumnSeries>[
                  //         StackedColumnSeries<ProdStats, DateTime>(
                  //           dataSource: li.getSalesPerProduct(),
                  //           xValueMapper: (datum, index) => datum.date,
                  //           yValueMapper: (datum, index) => datum.count,
                  //           enableTooltip: true,
                  //           dataLabelSettings:
                  //               DataLabelSettings(isVisible: true),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // SfCartesianChart(
                  //     primaryXAxis: CategoryAxis(),
                  //     // Chart title
                  //     title: ChartTitle(text: 'Half yearly sales analysis'),
                  //     // Enable legend
                  //     legend: Legend(isVisible: true),
                  //     // Enable tooltip
                  //     tooltipBehavior: TooltipBehavior(enable: true),
                  //     series: <ChartSeries<ProdStats, String>>[
                  //       LineSeries<ProdStats, String>(
                  //           dataSource: li.getSalesPerProduct(),
                  //           xValueMapper: (ProdStats sales, _) => sales.name,
                  //           yValueMapper: (ProdStats sales, _) => sales.count,
                  //           name: 'Sales',

                  //           // Enable data label
                  //           dataLabelSettings:
                  //               DataLabelSettings(isVisible: true)),
                  //     ]),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
