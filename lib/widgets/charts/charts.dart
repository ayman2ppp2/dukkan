// import 'package:dukkan/models/BcLog.dart';
import 'dart:math';

import 'package:dukkan/core/observability.dart';
import 'package:dukkan/models/prodStats.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/owner_provider.dart';
import 'package:dukkan/models/Product.dart';

class CircularChart extends StatefulWidget {
  const CircularChart({super.key});

  @override
  State<CircularChart> createState() => _CircularChartState();
}

class _CircularChartState extends State<CircularChart>
    with AutomaticKeepAliveClientMixin {
  DateTime time = DateTime.now();
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SingleChildScrollView(
      primary: false,
      child: GestureDetector(
        onDoubleTap: () {
          showDatePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2050))
              .then((value) {
            Provider.of<Lists>(context, listen: false)
                .clearCache('saledProductsByDate');
            setState(() {
              value == null ? time = time : time = value;
            });
          });
        },
        child: FutureBuilder(
            future: context.read<Lists>().getSaledProductsByDate(time),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Text(UserSafeMessages.loadFailed);
              }
              if (snapshot.hasData) {
                final products = snapshot.data!;
                final chartHeight =
                    max(300.0, products.length * 30.0);
                return SizedBox(
                  height: chartHeight,
                  child: ExcludeSemantics(
                    excluding: true,
                    child: RepaintBoundary(
                      child: SfCartesianChart(
                        title: ChartTitle(
                          text: time.day == DateTime.now().day &&
                                  time.month == DateTime.now().month &&
                                  time.year == DateTime.now().year
                              ? 'مبيعات هذا اليوم لكل منتج'
                              : 'المبيعات ليوم${time.month}/${time.day} لكل منتج',
                          alignment: ChartAlignment.near,
                        ),
                        primaryXAxis: CategoryAxis(),
                        primaryYAxis: NumericAxis(
                          numberFormat: NumberFormat.compact(),
                          isVisible: true,
                        ),
                        series: <CartesianSeries<dynamic, dynamic>>[
                          StackedBarSeries<Product, String>(
                            animationDuration: 0,
                            dataSource: snapshot.data!,
                            xValueMapper: (Product data, _) => data.name,
                            yValueMapper: (Product data, _) => data.count,
                            color: Colors.brown,
                          )
                        ],
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
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }
}

class LoanerChart extends StatefulWidget {
  const LoanerChart({super.key});

  @override
  State<LoanerChart> createState() => _LoanerChartState();
}

class _LoanerChartState extends State<LoanerChart>
    with AutomaticKeepAliveClientMixin {
  bool _tooltipReady = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tooltipReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder(
      future: context.read<Lists>().getLoanerComparison(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(UserSafeMessages.loadFailed);
        }
        if (snapshot.hasData) {
          final data = snapshot.data!;
          if (data.isEmpty) {
            return Center(
              child: Text(
                'لا توجد قروض',
                style: TextStyle(color: Colors.brown[900]),
              ),
            );
          }
          final chartHeight = max(300.0, data.length * 50.0);
          final maxAbs = data.fold<double>(
            0,
            (m, d) => max(m, (d.loanedAmount - d.currentValue).abs()),
          );
          return SizedBox(
            height: chartHeight,
            child: ExcludeSemantics(
              excluding: true,
              child: RepaintBoundary(
                child: SfCartesianChart(
                  title: ChartTitle(
                    text: 'ربح أو خسارة القروض',
                    alignment: ChartAlignment.near,
                  ),
                  primaryXAxis: CategoryAxis(),
                  primaryYAxis: NumericAxis(
                    numberFormat: NumberFormat.compact(),
                    isVisible: true,
                    minimum: -(maxAbs <= 0 ? 1.0 : maxAbs * 1.15),
                    maximum: maxAbs <= 0 ? 1.0 : maxAbs * 1.15,
                  ),
                  tooltipBehavior: TooltipBehavior(
                    enable: _tooltipReady,
                    builder: (dynamic data, dynamic point, dynamic series,
                        int pointIndex, int seriesIndex) {
                      final d = data as LoanerComparison;
                      final diff = d.loanedAmount - d.currentValue;
                      return Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.brown[700],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              d.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'بيع: ${NumberFormat.simpleCurrency().format(d.loanedAmount)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              'شراء: ${NumberFormat.simpleCurrency().format(d.currentValue)}',
                              style: const TextStyle(color: Colors.white70),
                            ),
                            Text(
                              _formatGainLoss(diff),
                              style: TextStyle(
                                color: diff >= 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  series: <CartesianSeries>[
                    ColumnSeries<LoanerComparison, String>(
                      name: 'الربح أو الخسارة',
                      animationDuration: 0,
                      width: 0.5,
                      dataSource: data,
                      xValueMapper: (LoanerComparison d, _) => d.name,
                      yValueMapper: (LoanerComparison d, _) =>
                          d.loanedAmount - d.currentValue,
                      pointColorMapper: (LoanerComparison d, _) =>
                          (d.loanedAmount - d.currentValue) >= 0
                              ? Colors.green
                              : Colors.red,
                    ),
                  ],
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
      },
    );
  }

  String _formatGainLoss(double diff) {
    final formatted = NumberFormat.simpleCurrency().format(diff.abs());
    if (diff >= 0) {
      return '▲ ربح $formatted';
    }
    return '▼ خسارة $formatted';
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }
}

class LineChart extends StatefulWidget {
  const LineChart({super.key});

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with AutomaticKeepAliveClientMixin {
  DateTime time = DateTime.now();
  bool _tooltipReady = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tooltipReady = true);
    });
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onDoubleTap: () {
        showDatePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime(2050))
            .then((value) {
          Provider.of<Lists>(context, listen: false)
              .clearCache('dailyProfitOfTheMonth');
          Provider.of<Lists>(context, listen: false)
              .clearCache('dailySalesOfTheMonth');
          setState(() {
            value == null ? time = time : time = value;
          });
        });
      },
      child: Builder(
        builder: (context) {
          final li = context.read<Lists>();
          return FutureBuilder(
              future: Future.wait(
                [
                  li.getDailyProfitOfTheMonth(
                    time,
                  ),
                  li.getDailySalesOfTheMonth(
                    time,
                  ),
                ],
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(UserSafeMessages.loadFailed);
                }
                if (snapshot.hasData) {
                  return SizedBox(
                    height: 300,
                    child: Flex(
                      mainAxisSize: MainAxisSize.min,
                      direction: Axis.vertical,
                      children: [
                        Expanded(
                          flex: 1,
                          child: ExcludeSemantics(
                            excluding: true,
                            child: RepaintBoundary(
                              child: SfCartesianChart(
                            tooltipBehavior: TooltipBehavior(enable: _tooltipReady),
                            title: ChartTitle(
                              text: time.day == DateTime.now().day &&
                                      time.month == DateTime.now().month &&
                                      time.year == DateTime.now().year
                                  ? 'الارباح والمبيعات لهذا الشهر'
                                  : 'الأرباح و المبيعات اليومية لشهر ${time.year}/${time.month}',
                            ),
                            primaryXAxis: CategoryAxis(
                              // arrangeByIndex: false,

                              isInversed: true,
                            ),
                            primaryYAxis: NumericAxis(
                              numberFormat: NumberFormat.compact(),
                              isVisible: true,
                            ),
                            series: <CartesianSeries>[
                              StackedBarSeries<SalesStats, int>(
                                name: 'الأرباح',
                                animationDuration: 0,
                                color: Colors.brown[400],
                                dataSource: snapshot.data![0],
                                xValueMapper: (SalesStats data, _) =>
                                    data.date.day,
                                yValueMapper: (SalesStats data, _) =>
                                    data.sales.floor(),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  // textStyle: TextStyle(fontSize: 12),
                                  labelAlignment: ChartDataLabelAlignment.top,
                                ),
                              ),
                              StackedBarSeries<SalesStats, int>(
                                name: 'المبيعات',
                                animationDuration: 0,
                                color: Colors.brown,
                                dataSource: snapshot.data![1],
                                xValueMapper: (SalesStats data, _) =>
                                    data.date.day,
                                yValueMapper: (SalesStats data, _) =>
                                    data.sales.floor(),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  textStyle: TextStyle(fontSize: 12),
                                  labelAlignment: ChartDataLabelAlignment.top,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
                } else {
                  return Center(
                    child: SpinKitChasingDots(
                      color: Colors.white,
                    ),
                  );
                }
              });
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }
}

class MOY extends StatefulWidget {
  const MOY({super.key});

  @override
  State<MOY> createState() => _MOYState();
}

class _MOYState extends State<MOY>
    with AutomaticKeepAliveClientMixin {
  DateTime time = DateTime.now();
  bool _tooltipReady = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _tooltipReady = true);
    });
  }
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return GestureDetector(
      onDoubleTap: () {
        showDatePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime(2050))
            .then((value) {
          Provider.of<Lists>(context, listen: false)
              .clearCache('monthlySalesOfTheYear');
          Provider.of<Lists>(context, listen: false)
              .clearCache('monthlyProfitsOfTheYear');
          setState(() {
            value == null ? time = time : time = value;
          });
        });
      },
      child: Builder(
        builder: (context) {
          final li = context.read<Lists>();
          return FutureBuilder(
              future: Future.wait([
                li.getMonthlySalesOfTheYear(time),
                li.getMonthlyProfitsOfTheYear(time)
              ]),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Text(UserSafeMessages.loadFailed);
                }
                if (snapshot.hasData) {
                  return SizedBox(
                    height: 300,
                    child: Flex(
                      mainAxisSize: MainAxisSize.min,
                      direction: Axis.vertical,
                      children: [
                        Expanded(
                          child: ExcludeSemantics(
                            excluding: true,
                            child: RepaintBoundary(
                              child: SfCartesianChart(
                                tooltipBehavior: TooltipBehavior(enable: _tooltipReady),
                                title: ChartTitle(
                                  text: time.day == DateTime.now().day &&
                                          time.month == DateTime.now().month &&
                                          time.year == DateTime.now().year
                                      ? 'المبيعات الشهرية لهذه السنة'
                                      : '  المبيعات الشهرية لسنة ${time.year}',
                                ),
                                primaryXAxis: CategoryAxis(
                                  isInversed: true,
                                ),
                                primaryYAxis: NumericAxis(
                                  numberFormat: NumberFormat.compact(),
                                  isVisible: true,
                                ),
                                series: <CartesianSeries>[
                                  StackedBarSeries<SalesStats, int>(
                                    name: 'الأرباح',
                                    animationDuration: 0,
                                    color: Colors.brown[400],
                                    dataSource: snapshot.data![1],
                                    xValueMapper: (SalesStats data, _) =>
                                        data.date.month,
                                    yValueMapper: (SalesStats data, _) =>
                                        data.sales.floor(),
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                      labelAlignment: ChartDataLabelAlignment.top,
                                    ),
                                  ),
                                  StackedBarSeries<SalesStats, int>(
                                    name: 'المبيعات',
                                    animationDuration: 0,
                                    color: Colors.brown,
                                    dataSource: snapshot.data![0],
                                    xValueMapper: (SalesStats data, _) =>
                                        data.date.month,
                                    yValueMapper: (SalesStats data, _) =>
                                        data.sales.floor(),
                                    dataLabelSettings: const DataLabelSettings(
                                      isVisible: true,
                                      labelAlignment: ChartDataLabelAlignment.top,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: SpinKitChasingDots(
                      color: Colors.white,
                    ),
                  );
                }
              });
        },
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }
}

class Ownertile extends StatefulWidget {
  Ownertile({super.key});

  @override
  State<Ownertile> createState() => _OwnertileState();
}

class _OwnertileState extends State<Ownertile>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder(
      future: context.read<OwnerProvider>().refreshListOfOwners(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text(UserSafeMessages.loadFailed);
        }
        if (snapshot.hasData) {
          return PageView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return Column(
                children: [
                  // name
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      snapshot.data![index].ownerName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // needed and payed
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'المطلوب : ${NumberFormat.simpleCurrency().format(snapshot.data![index].dueMoney)}',
                        // textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'المدفوع : ${NumberFormat.simpleCurrency().format(snapshot.data![index].totalPayed)}',
                        // textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 50,
                  ),
                  // last payment and it's date
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        'بتاريخ : ${DateFormat.yMEd().format(snapshot.data![index].lastPaymentDate)}',
                        // textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'اخر دفعة : ${NumberFormat.simpleCurrency().format(snapshot.data![index].lastPayment)}',
                        // textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 0,
                  ),
                ],
              );
            },
          );
        } else {
          return Center(
            child: SpinKitChasingDots(
              color: Colors.white,
            ),
          );
        }
      },
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    super.dispose();
  }
}

class ExpensesPieChart extends StatefulWidget {
  const ExpensesPieChart({super.key});

  @override
  State<ExpensesPieChart> createState() => _ExpensesPieChartState();
}

class _ExpensesPieChartState extends State<ExpensesPieChart> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ChartData> chartData = [
      ChartData('David', 25),
      ChartData('Steve', 38),
      ChartData('Jack', 34),
      ChartData('Others', 52)
    ];
    return Scaffold(
      body: Center(
        child: Container(
          child: ExcludeSemantics(
            excluding: true,
            child: RepaintBoundary(
              child: SfCircularChart(
                series: <CircularSeries>[
                  PieSeries<ChartData, String>(
                    enableTooltip: true,
                    explode: true,
                    dataSource: chartData,
                    groupMode: CircularChartGroupMode.value,
                    dataLabelMapper: (datum, index) => datum.y.toString(),
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                    pointColorMapper: (ChartData data, _) => data.color,
                    xValueMapper: (ChartData data, _) => data.x,
                    yValueMapper: (ChartData data, _) => data.y,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChartData {
  ChartData(this.x, this.y, [this.color]);
  final String x;
  final double y;
  final Color? color;
}
