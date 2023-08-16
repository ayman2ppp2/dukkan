import 'package:dukkan/pages/InsertPage.dart';
import 'package:dukkan/util/myGridItem.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../list.dart';

class InvPage extends StatefulWidget {
  const InvPage({super.key});

  @override
  State<InvPage> createState() => _InvPageState();
}

class _InvPageState extends State<InvPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.brown,
            iconTheme: IconThemeData(color: Colors.brown[100]),
            title: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    'المخزن',
                    style: TextStyle(
                        color: Colors.brown[50],
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    ' الكلي : ${li.getTotalBuyPrice().toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.brown[50],
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            centerTitle: true,
          ),
          body: GridView.builder(
            itemCount: Provider.of<Lists>(context).productsList.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2),
            itemBuilder: (context, index) {
              return GridItem(
                index: index,
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showGeneralDialog(
                barrierDismissible: true,
                barrierLabel: 'whatever',
                context: context,
                pageBuilder: (context, animation, secondaryAnimation) {
                  return ChangeNotifierProvider.value(
                    value: li,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 100,
                        bottom: 250,
                      ),
                      child: InPage(
                        buyPrice: 0,
                        count: 0,
                        name: '',
                        sellPrice: 0,
                        owner: '',
                        weightable: false,
                        wholeUnit: '',
                        index: -1,
                      ),
                    ),
                  );
                },
              );
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}
