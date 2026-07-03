import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AddExpense extends StatefulWidget {
  final Expense? existing;
  const AddExpense({super.key, this.existing});

  @override
  State<AddExpense> createState() => _AddExpenseState();
}

class _AddExpenseState extends State<AddExpense> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCon;
  late final TextEditingController _amountCon;
  int _period = 0;
  int? _payDate;
  bool _auto = false;
  bool _fixed = false;

  final _periods = [
    DropdownMenuEntry(value: 30, label: "شهري"),
    DropdownMenuEntry(value: 7, label: "إسبوعي"),
    DropdownMenuEntry(value: 1, label: "يومي"),
    DropdownMenuEntry(value: 0, label: "غير محدد"),
  ];

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCon = TextEditingController(text: e?.name ?? '');
    _amountCon = TextEditingController(
      text: e?.amount?.toStringAsFixed(2) ?? '',
    );
    if (e != null) {
      _period = e.period ?? 0;
      _payDate = e.payDate;
      _auto = e.payDate != null;
      _fixed = e.fixed ?? false;
    }
  }

  @override
  void dispose() {
    _nameCon.dispose();
    _amountCon.dispose();
    super.dispose();
  }

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
                Text(
                  _isEditing ? 'تعديل المنصرف' : 'إضافة منصرف',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameCon,
                  decoration: InputDecoration(
                    labelText: 'الأسم',
                    hintText: 'أدخل إسم المنصرف',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'الرجاء إدخال اسم';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                TextFormField(
                  controller: _amountCon,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'الكمية',
                    hintText: 'أدخل السعر المطلوب',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال قيمة صحيحة';
                    }
                    if (double.tryParse(value) == null) {
                      return 'الرجاء إدخال أرقام';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 20),
                DropdownMenu(
                  initialSelection: _period,
                  onSelected: (value) {
                    setState(() {
                      _period = value!;
                      if (value == 0) {
                        _auto = false;
                        _payDate = null;
                      }
                    });
                  },
                  hintText: "الفترة المحددة للدفع",
                  label: Text("الفترة"),
                  dropdownMenuEntries: _periods,
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
                          if (!_auto) _payDate = null;
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
                if (_auto)
                  Column(
                    children: [
                      SizedBox(height: 20),
                      DropdownMenu(
                        initialSelection: _payDate,
                        onSelected: (value) {
                          _payDate = value;
                        },
                        hintText: "يوم الدفع",
                        label: Text("يوم الدفع"),
                        dropdownMenuEntries: List.generate(
                          _period > 0 ? _period : 30,
                          (index) => DropdownMenuEntry(
                            value: index + 1,
                            label: (index + 1).toString(),
                          ),
                          growable: true,
                        ),
                      ),
                    ],
                  ),
                SizedBox(height: 20),
                Consumer<ExpenseProvider>(
                  builder: (context, exp, child) => ElevatedButton(
                    onPressed: () async {
                      if (!_formKey.currentState!.validate()) return;
                      final name = _nameCon.text.trim();
                      final amount = double.tryParse(_amountCon.text) ?? 0;
                      try {
                        if (_isEditing) {
                          await exp.updateExpense(
                            id: widget.existing!.ID,
                            name: name,
                            amount: amount,
                            period: _period,
                            payDate: _payDate,
                            fixed: _fixed,
                          );
                        } else {
                          await exp.addExpense(
                            name: name,
                            amount: amount,
                            period: _period,
                            payDate: _payDate,
                            fixed: _fixed,
                          );
                        }
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                _isEditing
                                    ? 'تم تعديل المنصرف بنجاح'
                                    : 'تمت إضافة المنصرف بنجاح',
                              ),
                            ),
                          );
                          Navigator.pop(context);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('خطأ'),
                              content: Text('حدث خطأ أثناء حفظ المنصرف'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('تم'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                    child: Text(_isEditing ? 'حفظ التعديلات' : 'إضافة'),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
