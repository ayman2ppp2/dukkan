import 'package:dukkan/util/scanner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/list.dart';

class Share extends StatefulWidget {
  const Share({super.key});

  @override
  State<Share> createState() => _ShareState();
}

class _ShareState extends State<Share> {
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مشاركة البيانات'),
          backgroundColor: Colors.brown[300],
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Consumer<Lists>(
                  builder: (context, li, child) => ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: li.shareList.length,
                    itemBuilder: (context, index) => Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: li.shareList[index],
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown[300],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          onPressed: () async {
                            Provider.of<Lists>(context, listen: false)
                                .runServer();
                          },
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                        const Text(
                          'Send',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Consumer<Lists>(
                          builder: (context, li, child) => IconButton(
                            onPressed: () async {
                              showGeneralDialog(
                                context: context,
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ChangeNotifierProvider.value(
                                  value: li,
                                  child: Scanner2(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.call_received_rounded,
                                color: Colors.white),
                          ),
                        ),
                        const Text(
                          'Receive',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
