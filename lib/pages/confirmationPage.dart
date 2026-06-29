import 'dart:typed_data';

import 'package:dukkan/core/observability.dart';
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
  final String type;

  final ScreenshotController screenshotController = ScreenshotController();

  ConfirmationPage({
    super.key,
    required this.paied,
    required this.date,
    required this.name,
    required this.remaining,
    required this.clearField,
    this.type = 'payment',
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
        AppLogger.warning('Failed to decode confirmation image',
            data: {'area': 'confirmation.share'});
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
                        _headerMessage(),
                        style: TextStyle(
                          color: Colors.brown[800],
                          fontSize: 22,
                        ),
                        textAlign: TextAlign.center,
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
                        _balanceLabel(),
                        style: TextStyle(
                          color: _balanceColor(),
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
                                    AppLogger.warning(
                                        'Screenshot capture failed',
                                        data: {'area': 'confirmation.share'});
                                  }
                                });
                              } catch (e, st) {
                                await AppLogger.captureException(e,
                                    stackTrace: st, area: 'confirmation.share');
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

  String _headerMessage() {
    switch (type) {
      case 'payment':
        return 'تم التسديد بمبلغ $paied';
      case 'withdraw':
        return 'تم السحب بمبلغ $paied';
      case 'reset':
        return 'تم تصفير الحساب';
      default:
        return 'تم إيداع $paied';
    }
  }

  String _balanceLabel() {
    if (type == 'reset') return 'الرصيد : 0';
    if (remaining > 0) {
      return 'مطلوب : ${formatter.NumberFormat.currency(name: '').format(remaining)}';
    } else if (remaining < 0) {
      return 'طالب : ${formatter.NumberFormat.currency(name: '').format(remaining.abs())}';
    }
    return 'الرصيد : 0';
  }

  Color _balanceColor() {
    if (remaining > 0) return Colors.red.shade800;
    if (remaining < 0) return Colors.green.shade800;
    return Colors.brown.shade900;
  }
}
