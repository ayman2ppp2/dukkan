import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../list.dart';

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
                onPressed: () {
                  Provider.of<Lists>(context, listen: false).runServer();
                },
                icon: const Icon(Icons.send),
              ),
              IconButton(
                onPressed: () {
                  Provider.of<Lists>(context, listen: false).reciveInv();
                },
                icon: const Icon(Icons.call_received_rounded),
              )
            ],
          )
        ],
      ),
    );
  }
}
