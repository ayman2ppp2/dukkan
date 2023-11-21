import 'package:dukkan/util/prodStats.dart';
import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../list.dart';

class CircularChart extends StatefulWidget {
  const CircularChart({super.key});

  @override
  State<CircularChart> createState() => _CircularChartState();
}

class _CircularChartState extends State<CircularChart>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    // print('daily sales');
    return SingleChildScrollView(
      // physics: NeverScrollableScrollPhysics(),
      primary: false,
      child: Flex(
        mainAxisSize: MainAxisSize.min,
        direction: Axis.vertical,
        children: [
          Consumer<Lists>(
            builder: (context, li, child) {
              return Flexible(
                child: FutureBuilder(
                    future: li.getSaledProductsByDate(DateTime.now()),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text('${snapshot.error.toString()}');
                      }
                      if (snapshot.hasData) {
                        return SizedBox(
                          height: snapshot.data!.length * 30.0,
                          child: SfCartesianChart(
                            title: ChartTitle(
                                text: 'المبيعات اليومية لكل منتج',
                                alignment: ChartAlignment.near),
                            primaryXAxis: CategoryAxis(
                                // labelsExtent: 70 % (MediaQuery.of(context).size.width),
                                ),
                            // tooltipBehavior: TooltipBehavior(enable: true),
                            series: <ChartSeries<Product, String>>[
                              StackedBarSeries<Product, String>(
                                // enableTooltip: true,
                                animationDuration: 0,
                                borderRadius: BorderRadius.circular(12),
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
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
}

class BarChart extends StatelessWidget {
  const BarChart({super.key});

  @override
  Widget build(BuildContext context) {
    // print('products sales');
    return SingleChildScrollView(
      physics: ClampingScrollPhysics(),
      child: Flex(
        mainAxisSize: MainAxisSize.min,
        direction: Axis.vertical,
        children: [
          Flexible(
            child: Consumer<Lists>(
              builder: (context, li, child) => FutureBuilder(
                  future: li.getSalesPerProduct(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('${snapshot.error.toString()}');
                    }
                    if (snapshot.hasData) {
                      return SizedBox(
                        height: snapshot.data!.length * 20.0,
                        child: SfCartesianChart(
                          title: ChartTitle(
                              text: 'المبيعات لكل منتج',
                              alignment: ChartAlignment.near),
                          primaryXAxis: CategoryAxis(),
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
}

class LineChart extends StatefulWidget {
  const LineChart({super.key});

  @override
  State<LineChart> createState() => _LineChartState();
}

class _LineChartState extends State<LineChart>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    // print(' month daily sales');
    return Consumer<Lists>(
      builder: (context, li, child) {
        return FutureBuilder(
            future: Future.wait(
              [
                li.getDailyProfitOfTheMonth(
                  DateTime.now(),
                ),
                li.getDailySalesOfTheMonth(
                  DateTime.now(),
                ),
              ],
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('${snapshot.error.toString()}');
              }
              if (snapshot.hasData) {
                return SizedBox(
                    height: snapshot.data!.length * 60.0,
                    child: SfCartesianChart(
                      title: ChartTitle(
                        text:
                            'الأرباح و المبيعات اليومية لشهر ${DateTime.now().month}',
                      ),
                      primaryXAxis: CategoryAxis(
                        arrangeByIndex: false,
                      ),
                      primaryYAxis: CategoryAxis(
                        minimum: 0,
                      ),
                      series: <ChartSeries>[
                        StackedBarSeries<SalesStats, int>(
                          color: Colors.brown[400],
                          dataSource: snapshot.data![0],
                          xValueMapper: (SalesStats data, _) => data.date.day,
                          yValueMapper: (SalesStats data, _) => data.sales,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                        ),
                        StackedBarSeries<SalesStats, int>(
                          color: Colors.brown,
                          dataSource: snapshot.data![1],
                          xValueMapper: (SalesStats data, _) => data.date.day,
                          yValueMapper: (SalesStats data, _) => data.sales,
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                          ),
                        ),
                      ],
                    ));
              } else {
                return Center(
                  child: SpinKitChasingDots(
                    color: Colors.white,
                  ),
                );
              }
            });
      },
    );
  }

  @override
  // TODO: implement wantKeepAlive
  bool get wantKeepAlive => true;
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
    Provider.of<Lists>(context).refreshListOfOwners();
    return PageView.builder(
      itemBuilder: (context, index) {
        return Column(
          children: [
            // name
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                Provider.of<Lists>(context)
                    .ownersList
                    .elementAt(index)
                    .ownerName,
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
                  'المطلوب : ${NumberFormat.simpleCurrency().format(Provider.of<Lists>(context).ownersList.elementAt(index).dueMoney)}',
                  // textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                Text(
                  'المدفوع : ${NumberFormat.simpleCurrency().format(Provider.of<Lists>(context).ownersList.elementAt(index).totalPayed)}',
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
                  'بتاريخ : ${DateFormat.yMEd().format(Provider.of<Lists>(context).ownersList.elementAt(index).lastPaymentDate)}',
                  // textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                Text(
                  'اخر دفعة : ${NumberFormat.simpleCurrency().format(Provider.of<Lists>(context).ownersList.elementAt(index).lastPayment)}',
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
      itemCount: Provider.of<Lists>(context).ownersList.length,
    );
  }

  @override
  bool get wantKeepAlive => true;
}
