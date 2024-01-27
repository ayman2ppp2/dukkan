// import 'dart:io';

import 'package:dukkan/providers/list.dart';
import 'package:dukkan/pages/inventoryPage.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loans.dart';
import 'package:dukkan/util/models/Owner.dart';
import 'package:dukkan/util/share.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'package:hive_ui/hive_ui.dart';
import '../util/Logs.dart';
import '../util/models/Product.dart';
import 'SellPage.dart';
import 'StatsPage.dart';
// import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Widget> tabs = [
    const Tab(
      icon: Icon(Icons.monetization_on_outlined),
    ),
    const Tab(
      icon: Icon(Icons.stacked_line_chart_rounded),
    )
  ];
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.brown,
            // leading: IconButton(
            //   onPressed: () {
            //     print(Scaffold.hasDrawer(context));
            //   },
            //   icon: const Icon(
            //     Icons.storefront,
            //     color: Colors.white,
            //   ),
            // ),
            title: const Text(
              'دكــان',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Consumer<Lists>(
                builder: (context, li, child) => IconButton(
                  onPressed: () async {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => HiveBoxesView(
                                  hiveBoxes: {
                                    li.db.inventory: (json) => Product.fromJson,
                                    li.db.owners: (json) => Owner.fromJson
                                  },
                                  onError: (String errorMessage) =>
                                      {print(errorMessage)})),
                    );
                    // print(await Navigator.of(context).push(
                    //   MaterialPageRoute(
                    //     builder: (context) => AiBarcodeScanner(
                    //       validator: (value) {
                    //         return value.startsWith('https://');
                    //       },
                    //       canPop: false,
                    //       onScan: (String value) {
                    //         debugPrint(value);
                    //         // setState(() {
                    //         //   barcode = value;
                    //         // });
                    //       },
                    //       onDetect: (p0) {},
                    //       onDispose: () {
                    //         debugPrint("Barcode scanner disposed!");
                    //       },
                    //       controller: MobileScannerController(
                    //         detectionSpeed: DetectionSpeed.noDuplicates,
                    //       ),
                    //     ),
                    //   ),
                    // ));
                  },
                  icon: Icon(
                    Icons.barcode_reader,
                    color: Colors.white,
                  ),
                ),
              ),
              Consumer<SalesProvider>(
                builder: (context, as, child) => Consumer<Lists>(
                  builder: (context, li, child) => IconButton(
                    onPressed: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: as,
                            child: ChangeNotifierProvider.value(
                              value: li,
                              child: Logs(),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      Icons.receipt_long_sharp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Consumer<SalesProvider>(
                builder: (context, sa, child) => Consumer<Lists>(
                  builder: (context, li, child) => IconButton(
                    onPressed: () {
                      sa.refreshProductsList();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: li,
                            child: ChangeNotifierProvider.value(
                              value: sa,
                              child: const InvPage(),
                            ),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Consumer<Lists>(
                builder: (context, li, child) {
                  return IconButton(
                    onPressed: () {
                      showGeneralDialog(
                        useRootNavigator: true,
                        barrierDismissible: true,
                        barrierLabel: 'gg',
                        context: context,
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ChangeNotifierProvider.value(
                          value: li,
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(20, 130, 20, 20),
                            child: Share(),
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share,
                      color: Colors.white,
                    ),
                  );
                },
              )
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
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Colors.brown,
                  ),
                  child: Text(
                    'Dukkan',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.message),
                  title: Text(
                    'الديون',
                    style: TextStyle(fontSize: 15),
                  ),
                  onTap: () {
                    var li = Provider.of<Lists>(context, listen: false);
                    var as = Provider.of<SalesProvider>(context, listen: false);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: li,
                            child: ChangeNotifierProvider.value(
                              value: as,
                              child: Loans(),
                            ),
                          ),
                        ));
                  },
                ),
                ListTile(
                  onTap: () async {
                    var li = Provider.of<Lists>(context, listen: false);
                    await li.db.useBackup().then(
                          (value) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('done converting'),
                            ),
                          ),
                        );
                    Navigator.pop(context);
                  },
                  leading: Icon(Icons.restart_alt_rounded),
                  title: Text('تحويل'),
                  enabled: true,
                ),
              ],
            ),
          ),
        ));
  }
}
