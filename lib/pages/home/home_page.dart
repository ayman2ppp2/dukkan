// import 'dart:io';

import 'package:dukkan/core/observability.dart';
import 'package:dukkan/providers/sales_provider.dart';

import 'package:dukkan/widgets/drawer.dart';
import 'package:dukkan/widgets/share_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:dukkan/pages/home/sell_page.dart';
import 'package:dukkan/pages/stats/stats_page.dart';
// import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> tabs = [
    const Tab(
      icon: Icon(Icons.monetization_on_outlined, semanticLabel: 'البيع'),
    ),
    const Tab(
      icon: Icon(Icons.stacked_line_chart_rounded, semanticLabel: 'الإحصائيات'),
    )
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.brown,
            title: Text(
              Provider.of<SalesProvider>(context, listen: false).getStoreName() ?? 'دكان',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Consumer<SalesProvider>(
                builder: (context, li, child) => IconButton(
                  tooltip: 'مسح الباركود',
                  onPressed: () async {
                    MobileScannerController con = MobileScannerController();
                    var ip;
                    showGeneralDialog(
                      barrierDismissible: true,
                      barrierLabel: 'ماسح الباركود',
                      context: context,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          Padding(
                        padding: const EdgeInsets.fromLTRB(100, 20, 10, 420),
                        child: Material(
                          child: MobileScanner(
                            fit: BoxFit.contain,
                            controller: con,
                            onDetect: (capture) async {
                              final List<Barcode> barcodes = capture.barcodes;
                              for (final barcode in barcodes) {
                                ip = barcode.rawValue;
                                AppLogger.debug('Barcode scanned',
                                    data: {'area': 'sale.barcode_scan'});
                                li.sellList.addAll(await li.search(
                                    barcode.rawValue!, true, true));
                                Future.delayed(
                                  const Duration(seconds: 1),
                                );
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تم المسح: $ip')));
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.barcode_reader,
                    color: Colors.white,
                  ),
                ),
              ),
              Consumer<SalesProvider>(
                builder: (context, as, child) => IconButton(
                  tooltip: 'السجلات',
                  onPressed: () => context.push('/logs'),
                  icon: Icon(
                    Icons.receipt_long_sharp,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'المخزن',
                onPressed: () {
                  context.read<SalesProvider>().refreshProductsList();
                  context.push('/inventory');
                },
                icon: const Icon(
                  Icons.inventory_2_outlined,
                  color: Colors.white,
                ),
              ),
              IconButton(
                tooltip: 'مشاركة البيانات',
                onPressed: () {
                  showGeneralDialog(
                    useRootNavigator: true,
                    barrierDismissible: true,
                    barrierLabel: 'مشاركة البيانات',
                    context: context,
                    pageBuilder: (context, animation, secondaryAnimation) =>
                        const Padding(
                      padding: EdgeInsets.fromLTRB(20, 130, 20, 20),
                      child: Share(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.share,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                color: Colors.brown,
                width: double.infinity,
                height: 50,
                child: TabBar(
                  tabs: tabs,
                  unselectedLabelColor: Colors.grey,
                  labelColor: Colors.white,
                  indicatorColor: Colors.white,
                  indicatorSize: TabBarIndicatorSize.label,
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [SellPage(), StatsPage()],
                ),
              ),
            ],
          ),
          drawer: Drawer(
            child: drawerItems(),
          ),
        ));
  }
}
