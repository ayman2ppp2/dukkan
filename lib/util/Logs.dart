import 'package:dukkan/list.dart';
import 'package:dukkan/util/receipt.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Logs extends StatelessWidget {
  const Logs({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.brown[50]),
        backgroundColor: Colors.brown,
        title: Text(
          'الفواتير',
          style: TextStyle(color: Colors.brown[50]),
        ),
      ),
      body: Consumer<Lists>(builder: (context, li, child) {
        li.refreshLogsList();
        return ListView.builder(
          itemCount: li.logsList.length,
          itemBuilder: (context, index) => Receipt(log: li.logsList[index]),
        );
      }),
    );
  }
}
