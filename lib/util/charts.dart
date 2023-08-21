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
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enablePinching: true,
      ),
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
