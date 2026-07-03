import 'package:dukkan/core/observability.dart';
import 'package:dukkan/pages/addExpense.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/util/models/Expense.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class Spending extends StatefulWidget {
  final int id;
  const Spending({super.key, required this.id});

  @override
  State<Spending> createState() => _SpendingState();
}

class _SpendingState extends State<Spending> {
  String _periodLabel(int? period) {
    switch (period) {
      case 30:
        return 'شهري';
      case 7:
        return 'إسبوعي';
      case 1:
        return 'يومي';
      default:
        return 'غير محدد';
    }
  }

  void _showPayDialog(BuildContext context, ExpenseProvider exp, Expense e) {
    final con = TextEditingController(text: e.amount?.toStringAsFixed(2) ?? '0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('تسجيل دفعة'),
        content: TextField(
          controller: con,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'المبلغ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(con.text);
              if (amount == null || amount <= 0) return;
              try {
                await exp.recordFixedExpensePayment(
                  expenseId: widget.id,
                  amount: amount,
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الدفعة')),
                  );
                }
              } catch (e, st) {
                await AppLogger.captureException(e,
                    stackTrace: st, area: 'expense.pay');
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text(UserSafeMessages.generic)),
                  );
                }
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exp = Provider.of<ExpenseProvider>(context);
    return Scaffold(
      backgroundColor: Colors.brown[50],
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              exp.deleteExpense(id: widget.id).then(
                    (value) => value ? Navigator.pop(context) : null,
                  );
            },
            icon: const Icon(Icons.delete_forever_rounded),
          ),
          StreamBuilder(
            stream: exp.watchExpense(id: widget.id),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final e = snapshot.data!;
                return IconButton(
                  onPressed: () {
                    showGeneralDialog(
                      barrierDismissible: true,
                      barrierLabel: 'تعديل المنصرف',
                      context: context,
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return ChangeNotifierProvider.value(
                          value: exp,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 130, 20, 20),
                            child: AddExpense(existing: e),
                          ),
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.edit_rounded),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        foregroundColor: Colors.brown[50],
        backgroundColor: Colors.brown[300],
        title: StreamBuilder(
          stream: exp.watchExpense(id: widget.id),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text(UserSafeMessages.loadFailed);
            }
            if (snapshot.hasData) {
              return Text(
                snapshot.data!.name ?? '',
                style: TextStyle(color: Colors.brown[50]),
              );
            }
            return SpinKitChasingDots(color: Colors.brown[200]);
          },
        ),
      ),
      body: StreamBuilder(
        stream: exp.watchExpense(id: widget.id),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Text(UserSafeMessages.loadFailed);
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return SpinKitChasingDots(color: Colors.brown[200]);
          }
          final e = snapshot.data!;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.brown[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow('المعرف', e.ID.toString()),
                      _infoRow('القيمة', NumberFormat.simpleCurrency(name: '').format(e.amount ?? 0)),
                      _infoRow('الفترة', _periodLabel(e.period)),
                      _infoRow('ثابت', e.fixed == true ? 'نعم' : 'لا'),
                      _infoRow(
                        'آخر دفعة',
                        e.lastCalculationDate != null
                            ? DateFormat('yyyy-MM-dd').format(e.lastCalculationDate!)
                            : 'لم يسجل',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (e.fixed == true)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showPayDialog(context, exp, e),
                      icon: const Icon(Icons.payments_rounded),
                      label: const Text('دفع الآن'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'سجل الدفعات',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _PaymentHistory(expenseId: widget.id),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _PaymentHistory extends StatelessWidget {
  final int expenseId;
  const _PaymentHistory({required this.expenseId});

  @override
  Widget build(BuildContext context) {
    final exp = Provider.of<ExpenseProvider>(context);
    return FutureBuilder<List>(
      future: exp.getExpenseLogs(expenseId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Text(UserSafeMessages.loadFailed);
        }
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.brown[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(child: Text('لا توجد دفعات مسجلة')),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: logs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final log = logs[index];
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: Colors.brown[200],
                child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
              ),
              title: Text(
                NumberFormat.simpleCurrency(name: '').format(log.price),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${log.products.isNotEmpty ? log.products.first.name ?? '' : ''}',
              ),
              trailing: Text(
                DateFormat('yyyy-MM-dd – HH:mm').format(log.date),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            );
          },
        );
      },
    );
  }
}

class MyContainer extends StatelessWidget {
  final Widget child;
  const MyContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: child,
      ),
    );
  }
}
