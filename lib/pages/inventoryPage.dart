import 'package:dukkan/pages/InsertPage.dart';
import 'package:dukkan/util/addUser.dart';
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
            iconTheme: IconThemeData(color: Colors.brown[50]),
            actions: [
              IconButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return ChangeNotifierProvider.value(
                        value: li,
                        child: AddUser(),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.person_add),
                tooltip: 'إضافة مالك',
              )
            ],
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
                    ' رأس المال : ${li.getTotalBuyPrice().toStringAsFixed(2)}',
                    style: TextStyle(
                        color: Colors.brown[50],
                        fontSize: 15,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.brown[200],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      textDirection: TextDirection.rtl,
                      decoration: const InputDecoration(hintText: 'إبحث'),
                      onChanged: (value) => li.search(value),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: li.searchTemp.isNotEmpty
                    ? GridView.builder(
                        itemCount: li.searchTemp.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2),
                        itemBuilder: (context, index) {
                          return GridItem(
                            name: li.searchTemp.elementAt(index).name,
                          );
                        },
                      )
                    : GridView.builder(
                        itemCount:
                            Provider.of<Lists>(context).productsList.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2),
                        itemBuilder: (context, index) {
                          // Provider.of<Lists>(context).refreshListOfOwners();
                          // debugPrint(Provider.of<Lists>(context).ownersList.toString());
                          return GridItem(
                            name: li.productsList.elementAt(index).name,
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () async {
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
                        bottom: 220,
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
                        offer: false,
                        offerCount: 0,
                        offerPrice: 0,
                        endDate: DateTime.now(),
                        priceHistory: [],
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
