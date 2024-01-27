import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/list.dart';
import 'package:qr_flutter/qr_flutter.dart';

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
                  // print(await NetworkInterface.list().then((value) => value
                  //     .firstWhere((element) =>
                  //         element.name.toLowerCase() == 'wi-fi' ||
                  //         element.name.toLowerCase() == 'wlan0')
                  //     .addresses[0]
                  //     .address));
                  Provider.of<Lists>(context, listen: false).runServer();
                },
                icon: const Icon(Icons.send),
              ),
              Consumer<Lists>(
                builder: (context, li, child) => IconButton(
                  onPressed: () async {
                    MobileScannerController con = MobileScannerController();
                    var ip;
                    showGeneralDialog(
                      context: context,
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          Material(
                        child: MobileScanner(
                          fit: BoxFit.contain,
                          controller: con,
                          onDetect: (capture) {
                            final List<Barcode> barcodes = capture.barcodes;
                            final Uint8List? image = capture.image;
                            for (final barcode in barcodes) {
                              ip = barcode.rawValue;
                              debugPrint('Barcode found! ${barcode.rawValue}');
                            }
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(ip)));
                            li.client(ip);
                            Navigator.pop(context);
                            con.stop();
                            con.dispose();
                          },
                        ),
                      ),
                    );

                    print(ip);
                    // Provider.of<Lists>(context, listen: false).client('ip');
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
