import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as formatter;
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;

class ConfirmationPage extends StatelessWidget {
  final String paied;
  final String name;
  final double remaining;
  final Function clearField;

  final ScreenshotController screenshotController = ScreenshotController();

  ConfirmationPage({
    super.key,
    required this.paied,
    required this.name,
    required this.remaining,
    required this.clearField,
  });

  @override
  Widget build(BuildContext context) {
    return Screenshot(
      controller: screenshotController,
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: Colors.brown[50], // Light background color
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'دكان',
                        style: TextStyle(
                          color: Colors.brown,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'تم تسديد ${formatter.NumberFormat.currency(name: '').format(double.tryParse(paied) ?? 0)}',
                        style: TextStyle(
                          color: Colors.brown[800],
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'لحساب : $name',
                        style: TextStyle(
                          color: Colors.brown[700],
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Divider(color: Colors.brown[300]),
                      const SizedBox(height: 10),
                      Text(
                        'بتاريخ :',
                        style: TextStyle(
                          color: Colors.brown[600],
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        formatter.DateFormat.yMEd()
                            .add_jmz()
                            .format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.brown[800],
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'المتبقي: ${formatter.NumberFormat.currency(name: '').format(remaining)}',
                        style: TextStyle(
                          color: Colors.brown[900],
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              clearField();
                              Navigator.pop(context);
                            },
                            icon: Icon(Icons.check_circle, color: Colors.white),
                            label: Text(
                              'موافق',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.brown[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                WidgetsBinding.instance
                                    .addPostFrameCallback((_) async {
                                  // Capture the screenshot
                                  Uint8List? screenshot =
                                      await screenshotController.capture();

                                  if (screenshot != null) {
                                    // Convert the PNG screenshot to JPEG
                                    img.Image? image =
                                        img.decodeImage(screenshot);
                                    if (image != null) {
                                      Uint8List jpegScreenshot =
                                          Uint8List.fromList(
                                        img.encodeJpg(image,
                                            quality: 90), // Convert to JPEG
                                      );

                                      // Share the converted JPEG screenshot
                                      await Share.shareXFiles(
                                        [
                                          XFile.fromData(
                                            jpegScreenshot,
                                            name:
                                                'confirmation.jpg', // Save as .jpg
                                            mimeType:
                                                'image/jpeg', // Correct MIME type
                                          )
                                        ],
                                        text: 'إيصال الدفع من دكان',
                                      );
                                    }
                                  } else {
                                    debugPrint('Screenshot capture failed.');
                                  }
                                });
                              } catch (e) {
                                debugPrint(
                                    'Error while capturing or sharing: $e');
                              }
                            },
                            icon: Icon(Icons.share, color: Colors.white),
                            label: Text(
                              'مشاركة',
                              style:
                                  TextStyle(fontSize: 20, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: const EdgeInsets.symmetric(
                                horizontal: 30,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
