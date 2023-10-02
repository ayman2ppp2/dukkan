// ignore_for_file: use_build_context_synchronously

import 'package:dukkan/list.dart';
import 'package:dukkan/util/product.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
          'الفاتورة',
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
                      leading: (lst[index].offer &&
                              lst[index].count % lst[index].offerCount == 0)
                          ? Text(NumberFormat.simpleCurrency()
                              .format(lst[index].offerPrice))
                          : Text(NumberFormat.simpleCurrency()
                              .format(lst[index].sellprice)),
                      title: Text(lst[index].name),
                      trailing: Text(lst[index].count.toString()),
                      subtitle: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          (lst[index].offer &&
                                  lst[index].count % lst[index].offerCount == 0)
                              ? Text(
                                  "${NumberFormat.simpleCurrency().format((lst[index].count * lst[index].offerPrice))}")
                              : Text(
                                  "${NumberFormat.simpleCurrency().format((lst[index].count * lst[index].sellprice))}"),
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
                        child: Center(
                          child: Text(
                              'المجموع : ${NumberFormat.simpleCurrency().format(total.round())}'),
                        ),
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
