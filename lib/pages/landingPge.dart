import 'package:dukkan/pages/paymentVerficaion.dart';
import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/loadingOverlay.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final TextEditingController _businessNameController = TextEditingController();
  String? _selectedPrecision;
  String? _selectedPlan;
  final List<String> _precisions = ['1g', '2g', '5g', '10g', '50g', '100g'];
  final List<Map<String, dynamic>> _plans = [
    {'name': 'شهري', 'price': 5000, 'duration': 30},
    {'name': '6 أشهر', 'price': 25000, 'duration': 180},
    {'name': 'سنوي', 'price': 50000, 'duration': 365},
  ];
  bool _isLoading = false;
  @override
  Widget build(BuildContext context) {
    var sa = Provider.of<SalesProvider>(context);
    var li = Provider.of<Lists>(context);
    var exp = Provider.of<ExpenseProvider>(context);
    var auth = Provider.of<AuthAPI>(context);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.brown[50]!, Colors.brown[200]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'أهلاً بك الى دكان',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'الرجاء إدخال بيانات المتجر واختيار خطة الاشتراك للمتابعة',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.brown[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      TextField(
                        controller: _businessNameController,
                        decoration: InputDecoration(
                          labelText: 'إسم المتجر',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedPrecision,
                        items: _precisions
                            .map((precision) => DropdownMenuItem<String>(
                                  value: precision,
                                  child: Text(precision),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedPrecision = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'دقة الميزان المستعمل',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'اختر خطة الاشتراك',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.brown[700],
                        ),
                      ),
                      const SizedBox(height: 16),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 1,
                          childAspectRatio: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: _plans.length,
                        itemBuilder: (context, index) {
                          final plan = _plans[index];
                          final isSelected = _selectedPlan == plan['name'];
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedPlan = plan['name'];
                              });
                            },
                            child: Card(
                              color:
                                  isSelected ? Colors.brown[300] : Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: isSelected
                                      ? Colors.brown
                                      : Colors.grey.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      plan['name'],
                                      textDirection: TextDirection.rtl,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.brown[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      textDirection: TextDirection.rtl,
                                      'السعر: ${plan['price']} SDG',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.brown[500],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      textDirection: TextDirection.rtl,
                                      'المدة: ${plan['duration']} يوم',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.brown[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () async {
                          final businessName =
                              _businessNameController.text.trim();
                          if (businessName.isEmpty ||
                              _selectedPrecision == null ||
                              _selectedPlan == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('الرجاء ملء جميع الحقول'),
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _isLoading = true;
                          });
                          // Handle form submission logic
                          sa.setStoreName(_businessNameController.text);
                          sa.setWeightPrececsion(int.parse(_selectedPrecision!
                              .replaceAll(RegExp(r'g'), '')));
                          await auth
                              .setSubscriptionPlan(_plans.firstWhere((plan) =>
                                  plan['name'] == _selectedPlan!)['duration'])
                              .then((value) {}, onError: (e, s) {
                            setState(() {
                              _isLoading = false;
                            });
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: Text('موافق'),
                                  ),
                                ],
                              ),
                            );
                          });

                          // move those to next page and make it after payment verfication

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ChangeNotifierProvider.value(
                                value: sa,
                                child: ChangeNotifierProvider.value(
                                  value: li,
                                  child: ChangeNotifierProvider.value(
                                    value: exp,
                                    child: ChangeNotifierProvider.value(
                                      value: auth,
                                      child: const PaymentVerificationPage(),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.brown[300],
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'متابعة',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (_isLoading) LoadingOverlay()
        ],
      ),
    );
  }
}
