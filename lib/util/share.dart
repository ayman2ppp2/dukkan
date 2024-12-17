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
      color: Colors.brown[50],
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          // QrImageView(data: '0907900990'),
          Expanded(
            child: Consumer<Lists>(
              builder: (context, li, child) => ListView.builder(
                itemCount: li.shareList.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.brown[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: li.shareList[index],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () async {
                  Provider.of<Lists>(context, listen: false).runServer();
                },
                icon: const Icon(Icons.send),
              ),
              Consumer<Lists>(
                builder: (context, li, child) => IconButton(
                  onPressed: () async {
                    // li.client('j');

                    showGeneralDialog(
                      context: context,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          ChangeNotifierProvider.value(
                        value: li,
                        child: Scanner2(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.call_received_rounded),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}
