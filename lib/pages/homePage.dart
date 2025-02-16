// import 'dart:io';

import 'package:dukkan/pages/landingPge.dart';
import 'package:dukkan/pages/settingsPage.dart';
import 'package:dukkan/pages/spendings.dart';
import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/pages/inventoryPage.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/pages/loans.dart';
import 'package:dukkan/util/share.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
// import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';
import 'Logs.dart';
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
            title: Text(
              Provider.of<SalesProvider>(context).getStoreName() ?? 'دكان',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              Consumer<SalesProvider>(
                builder: (context, li, child) => IconButton(
                  onPressed: () async {
                    MobileScannerController con = MobileScannerController();
                    var ip;
                    showGeneralDialog(
                      barrierDismissible: true,
                      barrierLabel: 'gg',
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
                                debugPrint(
                                    'Barcode found! ${barcode.rawValue}');
                                li.sellList.addAll(await li.search(
                                    barcode.rawValue!, true, true));
                                Future.delayed(
                                  Duration(seconds: 1),
                                );
                              }
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(SnackBar(content: Text(ip)));
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
                // 0116219798
                ListTile(
                  leading: Icon(Icons.receipt_long_rounded),
                  title: Text(
                    'الديون',
                    style: TextStyle(fontSize: 15),
                  ),
                  onTap: () {
                    var li = Provider.of<Lists>(context, listen: false);
                    var as = Provider.of<SalesProvider>(context, listen: false);
                    var exp =
                        Provider.of<ExpenseProvider>(context, listen: false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: exp,
                          child: ChangeNotifierProvider.value(
                            value: li,
                            child: ChangeNotifierProvider.value(
                              value: as,
                              child: Loans(),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(Icons.manage_accounts_rounded),
                  title: Text(
                    'المنصرفات',
                    style: TextStyle(fontSize: 15),
                  ),
                  onTap: () {
                    var li = Provider.of<Lists>(context, listen: false);
                    var exp =
                        Provider.of<ExpenseProvider>(context, listen: false);
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: li,
                            child: ChangeNotifierProvider.value(
                              value: exp,
                              child: Spendings(),
                            ),
                          ),
                        ));
                  },
                ),
                ListTile(
                  onTap: () async {
                    var li = Provider.of<AuthAPI>(context, listen: false);
                    await li.uploadBackup().then(
                          (value) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم رفع نسخة احتياطية'),
                            ),
                          ),
                        );
                    // Navigator.pop(context);
                  },
                  leading: Icon(Icons.upload_rounded),
                  title: Text('رفع نسخة احتياطية'),
                  enabled: true,
                ),
                ListTile(
                  onTap: () async {
                    var li = Provider.of<AuthAPI>(context, listen: false);
                    await li.downloadBackup().then(
                          (value) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('تم تنزيل النسخة الاحتياطية'),
                            ),
                          ),
                        );
                    // Navigator.pop(context);
                  },
                  leading: Icon(Icons.download_rounded),
                  title: Text('تنزيل النسخة الإحتياطية'),
                  enabled: true,
                ),
                ListTile(
                  onTap: () async {
                    var li = Provider.of<Lists>(context, listen: false);
                    await li.db.useLocalBacup().then(
                          (value) => ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('تم استخدام النسخة الاحتياطيةالمحلية'),
                            ),
                          ),
                        );
                    // var li = Provider.of<Lists>(context, listen: false);
                    // await li.db.useBackup().then(
                    //       (value) => ScaffoldMessenger.of(context).showSnackBar(
                    //         SnackBar(
                    //           content: Text('done converting'),
                    //         ),
                    //       ),
                    //     );
                    // Navigator.pop(context);
                  },
                  leading: Icon(Icons.restart_alt_rounded),
                  title: Text('إستخدام نسخة احتياطية محلية'),
                  enabled: true,
                ),
                ListTile(
                  onTap: () async {
                    var sa = Provider.of<SalesProvider>(context, listen: false);

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: sa,
                            child: SettingsPage(),
                          ),
                        ));
                  },
                  leading: Icon(Icons.settings),
                  title: Text('الإعدادات'),
                  enabled: true,
                ),
                ListTile(
                  onTap: () async {
                    var li = Provider.of<AuthAPI>(context, listen: false);
                    li.signOut();
                    // li.db.importData().then((value) {
                    //   ScaffoldMessenger.of(context)
                    //       .showSnackBar(SnackBar(content: Text('import done')));
                    // });
                  },
                  leading: Icon(Icons.logout_rounded),
                  title: Text('تسجيل الخروج'),
                  enabled: true,
                ),
              ],
            ),
          ),
        ));
  }
}
