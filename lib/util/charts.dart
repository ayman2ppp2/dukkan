import 'package:dukkan/util/prodStats.dart';
import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../list.dart';

class CircularChart extends StatelessWidget {
  const CircularChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: ChartTitle(
          text: 'المبيعات اليومية لكل منتج', alignment: ChartAlignment.near),
      primaryXAxis: CategoryAxis(),
      tooltipBehavior: TooltipBehavior(),
      series: <ChartSeries<Product, String>>[
        ColumnSeries<Product, String>(
          enableTooltip: true,
          borderRadius: BorderRadius.circular(12),
          dataSource: Provider.of<Lists>(context)
              .getSaledProductsByDate(DateTime.now()),
          xValueMapper: (Product data, _) => data.name,
          yValueMapper: (Product data, _) => data.count,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
          ),
          color: Colors.brown,
        )
      ],
    );
  }
}

class BarChart extends StatelessWidget {
  const BarChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title:
          ChartTitle(text: 'المبيعات لكل منتج', alignment: ChartAlignment.near),
      primaryXAxis: CategoryAxis(),
      tooltipBehavior: TooltipBehavior(),
      series: <ChartSeries<ProdStats, String>>[
        ColumnSeries<ProdStats, String>(
          enableTooltip: true,
          borderRadius: BorderRadius.circular(12),
          dataSource: Provider.of<Lists>(context).getSalesPerProduct(),
          xValueMapper: (ProdStats data, _) => data.name,
          yValueMapper: (ProdStats data, _) => data.count,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
          ),
          color: Colors.brown,
        )
      ],
    );
  }
}

class LineChart extends StatelessWidget {
  const LineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return SfCartesianChart(
      title: ChartTitle(
        text: 'المبيعات اليومية لشهر ${DateTime.now().month}',
      ),
      primaryXAxis: CategoryAxis(
        arrangeByIndex: true,
      ),
      primaryYAxis: CategoryAxis(
        minimum: 0,
      ),
      series: <ChartSeries>[
        StackedBarSeries<SalesStats, int>(
          color: Colors.brown,
          dataSource: Provider.of<Lists>(context).getDailySalesOfTheMonth(
            DateTime.now(),
          ),
          xValueMapper: (SalesStats data, _) => data.date.day,
          yValueMapper: (SalesStats data, _) => data.sales,
          dataLabelSettings: const DataLabelSettings(
            isVisible: true,
          ),
        ),
      ],
    );
  }
}

class Ownertile extends StatelessWidget {
  Ownertile({super.key});
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
                  'المطلوب : ${Provider.of<Lists>(context).ownersList.elementAt(index).dueMoney.toStringAsFixed(2)}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                Text(
                  'المدفوع : ${Provider.of<Lists>(context).ownersList.elementAt(index).totalPayed.toStringAsFixed(2)}',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Text(
                  'بتاريخ : ${Provider.of<Lists>(context).ownersList.elementAt(index).lastPaymentDate.year.toString()}-${Provider.of<Lists>(context).ownersList.elementAt(index).lastPaymentDate.month.toString()}-${Provider.of<Lists>(context).ownersList.elementAt(index).lastPaymentDate.day.toString()}(${Provider.of<Lists>(context).ownersList.elementAt(index).lastPaymentDate.hour.toString()}-${Provider.of<Lists>(context).ownersList.elementAt(index).lastPaymentDate.minute})',
                  textDirection: TextDirection.rtl,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),
                Text(
                  'اخر دفعة : ${Provider.of<Lists>(context).ownersList.elementAt(index).lastPayment.toStringAsFixed(2)}',
                  textDirection: TextDirection.rtl,
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
                  li.ownersList.elementAt(index).totalPayed +=
                      double.parse(payCon.text);
                  li.ownersList.elementAt(index).dueMoney -=
                      double.parse(payCon.text);
                  li.ownersList.elementAt(index).lastPaymentDate =
                      DateTime.now();
                  li.ownersList.elementAt(index).lastPayment =
                      double.parse(payCon.text);
                  li.refresh();
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
}
