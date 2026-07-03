import 'package:dukkan/core/observability.dart';
import 'package:dukkan/pages/addExpense.dart';
import 'package:dukkan/providers/expense_provider.dart';
import 'package:dukkan/pages/spending.dart';
import 'package:dukkan/util/charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class Spendings extends StatefulWidget {
  const Spendings({super.key});

  @override
  State<Spendings> createState() => _SpendingsState();
}

class _SpendingsState extends State<Spendings> with TickerProviderStateMixin {
  late final TabController _tabCon;

  @override
  void initState() {
    super.initState();
    _tabCon = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCon.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ex = Provider.of<ExpenseProvider>(context);
    return Scaffold(
      backgroundColor: Colors.brown[200],
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.brown[400],
        title: const Text(
          'المنصرفات',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          _HeaderSection(ex: ex),
          TabBar(
            controller: _tabCon,
            labelColor: Colors.brown[900],
            unselectedLabelColor: Colors.brown[600],
            indicatorColor: Colors.brown[800],
            tabs: const [
              Tab(text: 'ثابتة'),
              Tab(text: 'كل المصروفات'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCon,
              children: [
                _FixedExpensesTab(ex: ex),
                _AllExpensesTab(ex: ex),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showGeneralDialog(
            barrierDismissible: true,
            barrierLabel: 'إضافة منصرف',
            context: context,
            pageBuilder: (context, animation, secondaryAnimation) {
              return ChangeNotifierProvider.value(
                value: ex,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 130, 20, 20),
                  child: AddExpense(),
                ),
              );
            },
          );
        },
        tooltip: 'إضافة منصرف',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final ExpenseProvider ex;
  const _HeaderSection({required this.ex});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.brown[400],
      child: Row(
        children: [
          // Pie chart
          Expanded(
            flex: 5,
            child: FutureBuilder<Map<String, double>>(
              future: _buildPieData(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد بيانات',
                      style: TextStyle(color: Colors.white70)));
                }
                final data = snapshot.data!;
                final chartData = data.entries
                    .map((e) => ChartData(e.key, e.value))
                    .toList();
                return SizedBox(
                  height: 130,
                  child: ExpensesPieChart(data: chartData, compact: true),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // Summary cards
          Expanded(
            flex: 6,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _SummaryCard(
                  label: 'إجمالي المصروفات',
                  future: ex.getTotalExpenses(),
                  color: Colors.red[100]!,
                  textColor: Colors.red[900]!,
                ),
                const SizedBox(height: 6),
                _SummaryCard(
                  label: 'صافي الربح',
                  future: ex.getRealProfit(),
                  color: Colors.green[100]!,
                  textColor: Colors.green[900]!,
                ),
                const SizedBox(height: 6),
                _SummaryCard(
                  label: 'أرباح الشهر',
                  future: ex.getProfitOfTheMonth(),
                  color: Colors.amber[100]!,
                  textColor: Colors.amber[900]!,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, double>> _buildPieData() async {
    final fixed = await ex.getIndvidualExpenses(fixed: true).first;
    final logs = await ex.getMonthExpenseLogs();
    final Map<String, double> result = {};
    for (final e in fixed) {
      result[e.name ?? 'أخرى'] = (result[e.name ?? 'أخرى'] ?? 0) + (e.amount ?? 0);
    }
    final adhocTotal = logs.fold<double>(0, (sum, l) => sum + l.price);
    if (adhocTotal > 0) {
      result['متفرقات'] = adhocTotal;
    }
    return result;
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final Future<double> future;
  final Color color;
  final Color textColor;
  const _SummaryCard({
    required this.label,
    required this.future,
    required this.color,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: textColor)),
          FutureBuilder<double>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(
                  NumberFormat.simpleCurrency(name: '').format(snapshot.data),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                );
              }
              return SpinKitChasingDots(color: textColor, size: 16);
            },
          ),
        ],
      ),
    );
  }
}

class _FixedExpensesTab extends StatelessWidget {
  final ExpenseProvider ex;
  const _FixedExpensesTab({required this.ex});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: ex.getIndvidualExpenses(fixed: true),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text(UserSafeMessages.loadFailed));
        }
        if (!snapshot.hasData) {
          return Center(
            child: SpinKitChasingDots(color: Colors.brown[400]),
          );
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.brown[300]),
                const SizedBox(height: 12),
                Text('لا توجد مصروفات ثابتة',
                    style: TextStyle(color: Colors.brown[400], fontSize: 16)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final e = items[index];
            return Material(
              color: Colors.brown[200],
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Material(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.orange[50],
                  child: ListTile(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChangeNotifierProvider.value(
                            value: ex,
                            child: Spending(id: e.ID),
                          ),
                        ),
                      );
                    },
                    title: Text(e.name ?? ''),
                    subtitle: Text(
                      e.period == 30
                          ? 'شهري'
                          : e.period == 7
                              ? 'إسبوعي'
                              : e.period == 1
                                  ? 'يومي'
                                  : '',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          NumberFormat.simpleCurrency(name: '').format(e.amount ?? 0),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.payments_rounded, size: 20),
                          onPressed: () {
                            final con = TextEditingController(
                              text: e.amount?.toStringAsFixed(2) ?? '0',
                            );
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
                                        await ex.recordFixedExpensePayment(
                                          expenseId: e.ID,
                                          amount: amount,
                                        );
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text('تم تسجيل الدفعة')),
                                          );
                                        }
                                      } catch (e, st) {
                                        await AppLogger.captureException(e,
                                            stackTrace: st,
                                            area: 'expense.pay');
                                        if (ctx.mounted) {
                                          Navigator.pop(ctx);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    UserSafeMessages.generic)),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('تأكيد'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AllExpensesTab extends StatelessWidget {
  final ExpenseProvider ex;
  const _AllExpensesTab({required this.ex});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List>(
      future: Future.wait([
        ex.getMonthExpenseLogs(),
        ex.getIndvidualExpenses(fixed: true).first,
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SpinKitChasingDots(color: Colors.brown[400]),
          );
        }
        if (snapshot.hasError) {
          return const Center(child: Text(UserSafeMessages.loadFailed));
        }
        final results = snapshot.data as List;
        final logs = results[0] as List;
        final fixedExpenses = results[1] as List;

        if (logs.isEmpty && fixedExpenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.receipt_long, size: 48, color: Colors.brown[300]),
                const SizedBox(height: 12),
                Text('لا توجد مصروفات هذا الشهر',
                    style: TextStyle(color: Colors.brown[400], fontSize: 16)),
              ],
            ),
          );
        }

        // Build unified list: fixed expenses + ad-hoc logs, sorted by date
        final items = <_ExpenseItem>[];
        for (final e in fixedExpenses) {
          items.add(_ExpenseItem(
            name: e.name ?? '',
            amount: e.amount ?? 0,
            date: e.lastCalculationDate ?? DateTime.now(),
            type: 'ثابت',
            id: e.ID,
          ));
        }
        for (final l in logs) {
          final productName = l.products.isNotEmpty
              ? (l.products.first.name ?? '')
              : '';
          items.add(_ExpenseItem(
            name: productName,
            amount: l.price,
            date: l.date,
            type: productName,
            id: l.id,
          ));
        }
        items.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Material(
              color: Colors.brown[200],
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Material(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.brown[50],
                  child: ListTile(
                    title: Text(item.name),
                    subtitle: Text(
                      DateFormat('yyyy-MM-dd').format(item.date),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      NumberFormat.simpleCurrency(name: '').format(item.amount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ExpenseItem {
  final String name;
  final double amount;
  final DateTime date;
  final String type;
  final int id;
  _ExpenseItem({
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
    required this.id,
  });
}
