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
  final DateTime date;

  final ScreenshotController screenshotController = ScreenshotController();

  ConfirmationPage({
    super.key,
    required this.paied,
    required this.date,
    required this.name,
    required this.remaining,
    required this.clearField,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? cropAndConvertToJpeg(Uint8List screenshot) {
      // Decode the PNG image
      img.Image? image = img.decodePng(screenshot);

      if (image != null) {
        int cropY = (image.height * 0.2)
            .toInt(); // Start cropping at 20% of the image height
        int cropHeight =
            (image.height * 0.6).toInt(); // Crop 60% of the image height
        int cropWidth = image.width; // Full width

        // Perform the cropping
        img.Image croppedImage = img.copyCrop(
          image,
          x: 0,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );
        // Convert the cropped image to JPEG
        Uint8List jpegScreenshot = Uint8List.fromList(
          img.encodeJpg(croppedImage, quality: 90),
        );

        return jpegScreenshot;
      } else {
        debugPrint('Failed to decode the image.');
        return null;
      }
    }

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
                        'تم تسديد $paied',
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
                        formatter.DateFormat.yMEd().add_jmz().format(date),
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
                                    Uint8List? image =
                                        cropAndConvertToJpeg(screenshot);
                                    if (image != null) {
                                      // Share the converted JPEG screenshot
                                      await Share.shareXFiles(
                                        [
                                          XFile.fromData(
                                            image,
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
