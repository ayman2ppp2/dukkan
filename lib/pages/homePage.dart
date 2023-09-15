import 'package:dukkan/list.dart';
import 'package:dukkan/pages/inventoryPage.dart';
import 'package:dukkan/util/share.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'SellPage.dart';
import 'StatsPage.dart';

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
          leading: const Icon(
            Icons.storefront,
            color: Colors.white,
          ),
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
                onPressed: () {
                  li.refreshProductsList();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangeNotifierProvider.value(
                        value: li,
                        child: const InvPage(),
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
            Consumer<Lists>(
              builder: (context, li, child) {
                return IconButton(
                  onPressed: () {
                    showGeneralDialog(
                      barrierDismissible: true,
                      barrierLabel: 'gg',
                      context: context,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ChangeNotifierProvider.value(
                              value: li,
                              child: const Padding(
                                padding: EdgeInsets.fromLTRB(20, 130, 20, 20),
                                child: Share(),
                              )),
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
      ),
    );
  }
}
