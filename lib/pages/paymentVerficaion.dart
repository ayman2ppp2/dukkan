import 'package:dukkan/providers/onlineProvider.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class PaymentVerificationPage extends StatefulWidget {
  const PaymentVerificationPage({super.key});

  @override
  State<PaymentVerificationPage> createState() =>
      _PaymentVerificationPageState();
}

class _PaymentVerificationPageState extends State<PaymentVerificationPage> {
  File? _receiptImage;
  final TextEditingController _pinController = TextEditingController();
  bool _isWaitingForPin = false;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _receiptImage = File(pickedFile.path);
      });
    }
  }

  void _submitReceipt() {
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء رفع صورة الإيصال')),
      );
      Provider.of<AuthAPI>(context, listen: false).uploadPaymentReceipt(
        receipt: _receiptImage!,
      );
    }

    setState(() {
      _isWaitingForPin = true;
    });

    // Simulate server upload and wait for PIN code
    Future.delayed(const Duration(seconds: 5), () {
      setState(() {
        _isWaitingForPin = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال رمز التحقق')),
      );
    });
  }

  void _verifyPin() {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رمز التحقق')),
      );
      return;
    }

    // Handle PIN verification logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم التحقق من الدفع بنجاح')),
    );
    // Navigate to the next page or perform other actions
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('التحقق من الدفع'),
        backgroundColor: Colors.brown[300],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'الرجاء رفع إيصال الدفع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.brown[50],
                  border: Border.all(color: Colors.brown[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _receiptImage == null
                    ? const Center(
                        child: Text(
                          'اضغط هنا لرفع صورة الإيصال',
                          style: TextStyle(color: Colors.brown),
                        ),
                      )
                    : Image.file(
                        _receiptImage!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submitReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown[300],
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'إرسال الإيصال',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            const SizedBox(height: 32),
            if (_isWaitingForPin) ...[
              const Center(
                child: Text(
                  'يرجى الانتظار... يتم التحقق من الإيصال',
                  style: TextStyle(color: Colors.brown),
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (!_isWaitingForPin)
              TextField(
                controller: _pinController,
                decoration: InputDecoration(
                  labelText: 'أدخل رمز التحقق',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 16),
            if (!_isWaitingForPin)
              ElevatedButton(
                onPressed: _verifyPin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown[300],
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'تحقق',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
