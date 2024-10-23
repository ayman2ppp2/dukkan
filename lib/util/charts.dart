// import 'package:dukkan/util/models/BcLog.dart';
import 'package:dukkan/util/models/prodStats.dart';

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../providers/list.dart';
import 'models/BC_product.dart';
import 'models/Product.dart';

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
    // print('here');
    super.build(context);
    // print('daily sales');
    return SingleChildScrollView(
      // physics: NeverScrollableScrollPhysics(),
      primary: false,
      child: GestureDetector(
        onDoubleTap: () {
          showDatePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2050))
              .then((value) {
            setState(() {
              value == null ? time = time : time = value;
            });
          });
        },
        child: Flex(
          mainAxisSize: MainAxisSize.min,
          direction: Axis.vertical,
          children: [
            Consumer<Lists>(
              builder: (context, li, child) {
                return Flexible(
                  child: FutureBuilder(
                      future: li.getSaledProductsByDate(time),
                      builder: (context, snapshot) {
                        // li.refreshLogsList();
                        if (snapshot.hasError) {
                          return Text('${snapshot.error.toString()}');
                        }
                        if (snapshot.hasData) {
                          return SizedBox(
                            height: snapshot.data!.length * 60.0 > 200
                                ? snapshot.data!.length * 60
                                : 200,
                            child: SfCartesianChart(
                              title: ChartTitle(
                                text: time.day == DateTime.now().day &&
                                        time.month == DateTime.now().month &&
                                        time.year == DateTime.now().year
                                    ? 'مبيعات هذا اليوم لكل منتج'
                                    : 'المبيعات ليوم${time.month}/${time.day} لكل منتج',
                                alignment: ChartAlignment.near,
                              ),
                              primaryXAxis: CategoryAxis(
                                  // labelsExtent: 70 % (MediaQuery.of(context).size.width),
                                  ),
                              primaryYAxis: NumericAxis(
                                numberFormat: NumberFormat.compact(),
                                isVisible: true,
                              ),
                              // tooltipBehavior: TooltipBehavior(enable: true),
                              series: <ChartSeries<Product, String>>[
                                StackedBarSeries<Product, String>(
                                  // enableTooltip: true,
                                  animationDuration: 0,
                                  // borderRadius: BorderRadius.circular(12),
                                  dataSource: snapshot.data!,
                                  xValueMapper: (Product data, _) => data.name,
                                  yValueMapper: (Product data, _) => data.count,
                                  dataLabelSettings: const DataLabelSettings(
                                    isVisible: true,
                                  ),
                                  color: Colors.brown,
                                )
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
                      }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
}

class BarChart extends StatefulWidget {
  const BarChart({super.key});

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart>
    with AutomaticKeepAliveClientMixin {
  final ScrollController _scrollController = ScrollController();
  int _chunkSize = 20; // Initial chunk size
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    // Listen to scroll events to load more logs when reaching the bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMoreData();
      }
    });
  }

  // Method to increase the chunk size and trigger a new stream
  void _loadMoreData() {
    setState(() {
      _isLoadingMore = true;
      _chunkSize += 20; // Increase the chunk size by 50 logs
    });

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    // print('products sales');
    return SingleChildScrollView(
      controller: _scrollController,
      physics: ClampingScrollPhysics(),
      child: Flex(
        mainAxisSize: MainAxisSize.min,
        direction: Axis.vertical,
        children: [
          Flexible(
            child: Consumer<Lists>(
              builder: (context, li, child) => FutureBuilder(
                  future: li.getSalesPerProduct(_chunkSize),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('${snapshot.error.toString()}');
                    }
                    if (snapshot.hasData) {
                      //   if (_scrollController.position.pixels ==
                      //       _scrollController.position.maxScrollExtent) {
                      //     // Show a loading indicator at the bottom when fetching more data
                      //     return _isLoadingMore
                      //         ? Padding(
                      //             padding: const EdgeInsets.all(8.0),
                      //             child: Center(
                      //                 child: SpinKitChasingDots(
                      //               color: Colors.white,
                      //             )),
                      //           )
                      //         : SizedBox.shrink();
                      //   }
                      return SizedBox(
                        height: snapshot.data!.length * 60.0 > 200
                            ? snapshot.data!.length * 60
                            : 200,
                        child: SfCartesianChart(
                          title: ChartTitle(
                              text: 'المبيعات لكل منتج',
                              alignment: ChartAlignment.near),
                          primaryXAxis: CategoryAxis(),
                          primaryYAxis: NumericAxis(
                            numberFormat: NumberFormat.compact(),
                            isVisible: true,
                          ),
                          tooltipBehavior: TooltipBehavior(enable: true),
                          series: <ChartSeries>[
                            StackedBarSeries<ProdStats, String>(
                              animationDuration: 0,
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.brown,
                              dataSource: snapshot.data!,
                              xValueMapper: (ProdStats data, _) => data.name,
                              yValueMapper: (ProdStats data, _) => data.count,
                              dataLabelSettings: const DataLabelSettings(
                                isVisible: true,
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
                  }),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => false;
  // Provider.of<Lists>(context, listen: false).keepAlive;
}

class LineChart extends StatefulWidget {
  const LineChart({super.key});

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with AutomaticKeepAliveClientMixin {
  DateTime time = DateTime.now();
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // print(' month daily sales');
    return GestureDetector(
      onDoubleTap: () {
        showDatePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime(2050))
            .then((value) {
          setState(() {
            value == null ? time = time : time = value;
          });
        });
      },
      child: Consumer<Lists>(
        builder: (context, li, child) {
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
                  return Text('${snapshot.error.toString()}');
                }
                if (snapshot.hasData) {
                  return Container(
                    constraints: BoxConstraints(
                        maxHeight: snapshot.data![0].length * 22 < 200
                            ? 200
                            : snapshot.data![0].length * 22),
                    child: Flex(
                      mainAxisSize: MainAxisSize.min,
                      direction: Axis.vertical,
                      children: [
                        Expanded(
                          flex: 1,
                          child: SfCartesianChart(
                            tooltipBehavior: TooltipBehavior(enable: true),
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
                            series: <ChartSeries>[
                              StackedBarSeries<SalesStats, int>(
                                name: 'الأرباح',
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
  bool get wantKeepAlive => false;
  // Provider.of<Lists>(context, listen: false).keepAlive;
}

class MOY extends StatefulWidget {
  const MOY({super.key});

  @override
  State<MOY> createState() => _MOYState();
}

class _MOYState extends State<MOY> {
  DateTime time = DateTime.now();
  @override
  Widget build(BuildContext context) {
    // super.build(context);
    // print(' month daily sales');
    return GestureDetector(
      onDoubleTap: () {
        showDatePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime(2050))
            .then((value) {
          setState(() {
            value == null ? time = time : time = value;
          });
        });
      },
      child: Consumer<Lists>(
        builder: (context, li, child) {
          return FutureBuilder(
              future: Future.wait([
                li.getMonthlySalesOfTheYear(time),
                li.getMonthlyProfitsOfTheYear(time)
              ]),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('${snapshot.error.toString()}');
                }
                if (snapshot.hasData) {
                  return Container(
                    constraints: BoxConstraints(
                        maxHeight: snapshot.data!.length * 24 < 200
                            ? 250
                            : snapshot.data!.length * 25),
                    child: Flex(
                      mainAxisSize: MainAxisSize.min,
                      direction: Axis.vertical,
                      children: [
                        Expanded(
                          child: SfCartesianChart(
                            tooltipBehavior: TooltipBehavior(enable: true),
                            title: ChartTitle(
                              text: time.day == DateTime.now().day &&
                                      time.month == DateTime.now().month &&
                                      time.year == DateTime.now().year
                                  ? 'المبيعات الشهرية لهذه السنة'
                                  : '  المبيعات الشهرية لسنة ${time.year}',
                            ),
                            primaryXAxis: CategoryAxis(
                              // arrangeByIndex: false,

                              isInversed: true,
                            ),
                            primaryYAxis: NumericAxis(
                              numberFormat: NumberFormat.compact(),
                              isVisible: true,
                            ),
                            series: <ChartSeries>[
                              StackedBarSeries<SalesStats, int>(
                                name: 'الأرباح',
                                color: Colors.brown[300],
                                dataSource: snapshot.data![1],
                                xValueMapper: (SalesStats data, _) =>
                                    data.date.month,
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
                                color: Colors.brown[400],
                                dataSource: snapshot.data![0],
                                xValueMapper: (SalesStats data, _) =>
                                    data.date.month,
                                yValueMapper: (SalesStats data, _) =>
                                    data.sales.floor(),
                                dataLabelSettings: const DataLabelSettings(
                                  isVisible: true,
                                  // textStyle: TextStyle(fontSize: 12),
                                  labelAlignment: ChartDataLabelAlignment.top,
                                ),
                              ),
                            ],
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
}

class Ownertile extends StatefulWidget {
  Ownertile({super.key});

  @override
  State<Ownertile> createState() => _OwnertileState();
}

class _OwnertileState extends State<Ownertile>
    with AutomaticKeepAliveClientMixin {
  TextEditingController payCon = TextEditingController();

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder(
      future: Provider.of<Lists>(context).refreshListOfOwners(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('${snapshot.error.toString()}');
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
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: TextFormField(
                      controller: payCon,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  Consumer<Lists>(
                    builder: (context, li, child) => IconButton(
                      onPressed: () {
                        if (payCon.text.isNotEmpty) {
                          li.ownersList.elementAt(index).totalPayed +=
                              double.parse(payCon.text);
                          li.ownersList.elementAt(index).dueMoney -=
                              double.parse(payCon.text);
                          li.ownersList.elementAt(index).lastPaymentDate =
                              DateTime.now();
                          li.ownersList.elementAt(index).lastPayment =
                              double.parse(payCon.text);
                          li.updateOwner(li.ownersList.elementAt(index));
                          li.refresh();
                        }
                      },
                      icon: const Icon(Icons.payments_outlined),
                    ),
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
  bool get wantKeepAlive => false;
  // Provider.of<Lists>(context, listen: false).keepAlive;
}

class ExpensesPieChart extends StatefulWidget {
  const ExpensesPieChart({super.key});

  @override
  State<ExpensesPieChart> createState() => _ExpensesPieChartState();
}

class _ExpensesPieChartState extends State<ExpensesPieChart> {
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
                child: SfCircularChart(series: <CircularSeries>[
      // Render pie chart
      PieSeries<ChartData, String>(
          enableTooltip: true,
          explode: true,
          dataSource: chartData,
          groupMode: CircularChartGroupMode.value,
          dataLabelMapper: (datum, index) => datum.y.toString(),
          dataLabelSettings: DataLabelSettings(isVisible: true),
          pointColorMapper: (ChartData data, _) => data.color,
          xValueMapper: (ChartData data, _) => data.x,
          yValueMapper: (ChartData data, _) => data.y)
    ]))));
  }
}

class ChartData {
  ChartData(this.x, this.y, [this.color]);
  final String x;
  final double y;
  final Color? color;
}
