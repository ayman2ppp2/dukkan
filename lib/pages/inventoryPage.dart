import 'package:dukkan/pages/InsertPage.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/addUser.dart';
import 'package:dukkan/util/models/Product.dart';
import 'package:dukkan/util/myGridItem.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart' as ii;
import 'package:provider/provider.dart';

import '../providers/list.dart';

class InvPage extends StatefulWidget {
  const InvPage({super.key});

  @override
  State<InvPage> createState() => _InvPageState();
}

class _InvPageState extends State<InvPage> {
  void initState() {
    super.initState();
    searchFuture = Provider.of<SalesProvider>(context, listen: false)
        .search('', false, false);
  }

  Future<List<Product>>? searchFuture;
  TextEditingController controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    var as = Provider.of<SalesProvider>(context);
    var li = Provider.of<Lists>(context);
    void refresh() {
      setState(() {
        searchFuture = as.search(controller.text.trim(), false, false);
      });
    }

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
          ),
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
              StreamBuilder(
                stream: li.getTotalBuyPrice(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text(
                        style: TextStyle(
                            color: Colors.brown[50],
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                        '${snapshot.error.toString()}');
                  }
                  if (snapshot.hasData) {
                    return Text(
                      ' رأس المال : ${ii.NumberFormat.simpleCurrency().format(snapshot.data!.fold(0.0, (previousValue, element) => previousValue + element.buyprice! * element.count!))}',
                      style: TextStyle(
                          color: Colors.brown[50],
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    );
                  }
                  return SpinKitChasingDots(
                    color: Colors.brown[50],
                  );
                },
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
                    controller: controller,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(hintText: 'إبحث'),
                    onChanged: (value) {
                      setState(() {
                        searchFuture = as.search(value.trim(), false, false);
                      });
                    }),
              ),
            ),
          ),
          Expanded(
              child: FutureBuilder(
            future: searchFuture,
            // as.search(controller.text, false, false),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator());
              }

              List<Product> products = snapshot.data!;

              if (products.isEmpty) {
                return Center(child: Text('No Products found'));
              }

              return GridView.builder(
                itemCount: products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width ~/ 180,
                ),
                itemBuilder: (context, index) {
                  return GridItem(
                    refrsh: refresh,
                    id: products[index].id,
                  );
                },
              );
            },
          )),
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
                child: ChangeNotifierProvider.value(
                  value: as,
                  child: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      right: 20,
                      top: 100,
                      bottom: 200,
                    ),
                    child: InPage(
                      id: null,
                      buyPrice: 0,
                      count: 0,
                      name: '',
                      barcode: '',
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
                ),
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
