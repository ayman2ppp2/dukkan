// ignore_for_file: use_build_context_synchronously

import 'package:dukkan/list.dart';
import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CheckOut extends StatelessWidget {
  final List<Product> lst;
  final double total;
  const CheckOut({super.key, required this.lst, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
        title: const Text(
          'الدفع',
          style: TextStyle(color: Colors.white, fontSize: 30),
        ),
        backgroundColor: Colors.brown,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: lst.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: Text(lst[index].sellprice.toString()),
                      title: Text(lst[index].name),
                      trailing: Text(lst[index].count.toString()),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${lst[index].sellprice * lst[index].count}'),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
              padding: const EdgeInsets.all(20),
              child: Consumer<Lists>(
                builder: (context, li, child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Container(
                        width: 180 % MediaQuery.of(context).size.width,
                        height: 55 % MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.green[400],
                        ),
                        child: Center(child: Text('المجموع : $total')),
                      ),
                      IconButton.filled(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text(
                                  'هل انت متاكد',
                                  style: TextStyle(fontSize: 20),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () async {
                                      await li.db
                                          .checkOut(lst: lst, total: total);
                                      li.refreshProductsList();
                                      li.refreshListOfOwners();
                                      Navigator.pop(context);
                                      Navigator.pop(context);
                                      li.defaultSellList();
                                    },
                                    child: const Text(
                                      'نعم',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text(
                                      'لا',
                                      style: TextStyle(fontSize: 20),
                                    ),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        icon: const Icon(
                          Icons.checklist_outlined,
                          color: Colors.white,
                          size: 40,
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStatePropertyAll(
                            Colors.green[500],
                          ),
                          elevation: const MaterialStatePropertyAll(20),
                        ),
                      )
                    ],
                  );
                },
              ))
        ],
      ),
    );
  }
}
