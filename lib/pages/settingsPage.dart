import 'package:dukkan/providers/salesProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final List<String> _precisions = ['1g', '2g', '5g', '10g', '50g', '100g'];
  int? _weightPrecision;
  String? _storeName;

  @override
  void initState() {
    super.initState();
    final salesProvider = Provider.of<SalesProvider>(context, listen: false);
    _weightPrecision = salesProvider.getWeightPrececsion();
    _storeName = salesProvider.getStoreName();
  }

  @override
  Widget build(BuildContext context) {
    final salesProvider = Provider.of<SalesProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادت'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weight Precision Setting
            Row(
              children: [
                DropdownButton<int>(
                  value: _weightPrecision,
                  items: _precisions
                      .map((precision) => DropdownMenuItem<int>(
                            value: int.parse(
                                precision.replaceAll(RegExp(r'g'), '')),
                            child: Text(precision),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _weightPrecision = value;
                    });
                  },
                ),
                const Spacer(),
                const Text(': دقة الميزان'),
              ],
            ),
            const SizedBox(height: 20),
            // Store Name Setting
            Row(
              children: [
                SizedBox(
                  width: 200,
                  child: TextField(
                    controller: TextEditingController(
                      text: _storeName,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'أدخل إسم المتجر',
                    ),
                    onChanged: (value) {
                      _storeName = value;
                    },
                  ),
                ),
                const Spacer(),
                const Text(': إسم المتجر'),
              ],
            ),
            const SizedBox(height: 30),
            // Submit Button
            Center(
              child: ElevatedButton(
                onPressed: () {
                  if (_weightPrecision != null) {
                    salesProvider.setWeightPrececsion(_weightPrecision!);
                  }
                  if (_storeName != null && _storeName!.isNotEmpty) {
                    salesProvider.setStoreName(_storeName!);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حفظ الإعدادات بنجاح'),
                    ),
                  );
                },
                child: const Text('حفظ'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
