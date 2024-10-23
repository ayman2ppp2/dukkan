import 'package:dukkan/providers/expenseProvider.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddExpense extends StatefulWidget {
  const AddExpense({super.key});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  @override
  Widget build(BuildContext context) {
    return MyCustomForm();
  }
}

class MyCustomForm extends StatefulWidget {
  @override
  _MyCustomFormState createState() => _MyCustomFormState();
}

class _MyCustomFormState extends State<MyCustomForm> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  var _amount;
  int _period = 0;
  var _payDate;
  bool _auto = false;
  bool _fixed = false;
  var periods = [
    DropdownMenuEntry(value: 30, label: "شهري"),
    DropdownMenuEntry(value: 7, label: "إسبوعي"),
    DropdownMenuEntry(value: 1, label: "يومي"),
    DropdownMenuEntry(value: 0, label: "غير محدد"),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(20),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'الأسم',
                    hintText: 'أدخل إسم المنصرف',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    setState(() {
                      _name = value!;
                    });
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الكمية',
                    hintText: 'أدخل السعر المطلوب',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاءإدخال قيمة صحيحة';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال ارقام';
                    }
                    return null;
                  },
// 0128504780
                  onSaved: (value) {
                    setState(() {
                      _amount = double.tryParse(value!);
                    });
                  },
                ),
                SizedBox(height: 20),
                DropdownMenu(
                  onSelected: (value) {
                    setState(() {
                      _period = value!;
                      if (value == 0) {
                        _auto = false;
                      }
                    });
                  },
                  hintText: "الفترة المحددة للدفع",
                  label: Text("الفترة"),
                  dropdownMenuEntries: periods,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('دفع آلي'),
                    Checkbox(
                      value: _auto,
                      onChanged: (value) {
                        setState(() {
                          _auto = !_auto;
                        });
                      },
                    ),
                    Text('معدل ثابت'),
                    Checkbox(
                      value: _fixed,
                      onChanged: (value) {
                        setState(() {
                          _fixed = !_fixed;
                        });
                      },
                    ),
                  ],
                ),
                _auto
                    ? Column(
                        children: [
                          SizedBox(height: 20),
                          DropdownMenu(
                            onSelected: (value) {
                              _payDate = value!;
                            },
                            hintText: "يوم الدفع",
                            label: Text("يوم الدفع"),
                            dropdownMenuEntries: List.generate(
                                _period,
                                (index) => DropdownMenuEntry(
                                    value: index + 1,
                                    label: (index + 1).toString()),
                                growable: true),
                          ),
                        ],
                      )
                    : SizedBox(),
                SizedBox(height: 20),
                Consumer<ExpenseProvider>(
                  builder: (context, exp, child) => ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        Future.wait([
                          exp
                              .addExpense(
                                  name: _name,
                                  amount: _amount,
                                  period: _period,
                                  payDate: _payDate,
                                  fixed: _fixed)
                              .catchError((e) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                  title: Text('Error'),
                                  content: Text('there is an error'),
                                  actions: [
                                    TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: Text('done'))
                                  ]),
                            );
                            return 0;
                          })
                        ]).then(
                          (value) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text(
                                    '(${value[0]})تمت إضافة المنصرف بنجاح')));
                            Navigator.pop(context);
                          },
                        );
                      }
                    },
                    child: Text('Submit'),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
            // autovalidateMode: AutovalidateMode.always,
          ),
        ),
      ),
    );
  }
}
