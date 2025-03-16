import 'dart:io';

import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

class Scanner extends StatefulWidget {
  const Scanner({super.key});

  @override
  State<Scanner> createState() => _ScannerState();
}

class _ScannerState extends State<Scanner> {
  MobileScannerController con = MobileScannerController();
  var ip;
  @override
  Widget build(BuildContext context) {
    return Consumer<SalesProvider>(
      builder: (context, li, child) => Material(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: MobileScanner(
                fit: BoxFit.contain,
                controller: con,
                onDetect: (capture) async {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    li.sellList
                        .addAll(await li.search(barcode.rawValue!, true, true));
                    break;
                  }
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(ip)));
                  // li.client(ip);
                  Navigator.pop(context);
                  con.stop();
                  con.dispose();
                },
              ),
            ),
            Expanded(
              flex: 1,
              child: Slider.adaptive(
                value: con.zoomScaleState.value,
                onChanged: (value) {
                  setState(() {
                    con.setZoomScale(value);
                  });
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class Scanner2 extends StatefulWidget {
  const Scanner2({super.key});

  @override
  State<Scanner2> createState() => _Scanner2State();
}

class _Scanner2State extends State<Scanner2> {
  MobileScannerController con = MobileScannerController();
  var ip;
  @override
  Widget build(BuildContext context) {
    return Consumer<Lists>(
      builder: (context, li, child) => Material(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Platform.isWindows
                  ? IconButton(
                      onPressed: () {
                        li.client('192.168.8.103:30000');
                        Navigator.pop(context);
                        // con.stop();
                        // con.dispose();
                      },
                      icon: Icon(Icons.abc))
                  : MobileScanner(
                      fit: BoxFit.contain,
                      controller: con,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;

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
            Expanded(
                flex: 1,
                child: Slider.adaptive(
                  value: con.zoomScaleState.value,
                  onChanged: (value) {
                    setState(() {
                      con.setZoomScale(value);
                    });
                  },
                ))
          ],
        ),
      ),
    );
  }
}
