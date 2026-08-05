import 'dart:io';
import 'dart:ui' as ui;
import 'package:dukkan/core/observability.dart';
import 'package:dukkan/models/Loaner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class Transaction {
  final DateTime date;
  final String description;
  final String type;
  final double debit;
  final double credit;
  final double balance;

  Transaction({
    required this.date,
    required this.description,
    required this.type,
    this.debit = 0,
    this.credit = 0,
    required this.balance,
  });
}

class BankStatementPage extends StatefulWidget {
  final String customerName;
  final String accountNumber;
  final Loaner loaner;

  const BankStatementPage({
    super.key,
    required this.customerName,
    required this.accountNumber,
    required this.loaner,
  });

  @override
  State<BankStatementPage> createState() => _BankStatementPageState();
}

class _BankStatementPageState extends State<BankStatementPage> {
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];

  DateTime? _startDate;
  DateTime? _endDate;
  String _typeFilter = 'all';

  pw.Font? _arabicFont;
  pw.Font? _arabicBoldFont;
  pw.Font? _latinFont;

  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _monthFormat = DateFormat('MMMM yyyy');

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    fetchTransactions();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    try {
      _arabicFont = await PdfGoogleFonts.notoSansArabicRegular();
      _arabicBoldFont = await PdfGoogleFonts.notoSansArabicBold();
      _latinFont = await PdfGoogleFonts.notoSansRegular();
    } catch (_) {}
  }

  void fetchTransactions() {
    final payments = widget.loaner.lastPayment ?? [];
    final temp = <Transaction>[];

    for (final payment in payments) {
      final date =
          payment.key != null ? DateTime.parse(payment.key!) : DateTime.now();
      final value = double.tryParse(payment.value ?? '0') ?? 0;

      String description;
      String type;
      double debit = 0;
      double credit = 0;

      switch (payment.type) {
        case 'payment':
          description = 'إيداع';
          type = 'payment';
          debit = value;
          break;
        case 'withdraw':
          description = 'سحب';
          type = 'withdraw';
          credit = value;
          break;
        case 'sale':
          description = 'فاتورة آجلة';
          type = 'sale';
          credit = value;
          break;
        case 'reset':
          description = 'تصفير الحساب';
          type = 'reset';
          break;
        case 'cancel':
          description = 'إلغاء فاتورة';
          type = 'cancel';
          debit = value;
          break;
        default:
          description = 'إيداع';
          type = 'other';
          debit = value;
      }

      temp.add(Transaction(
        date: date,
        description: description,
        type: type,
        debit: debit,
        credit: credit,
        balance: payment.remaining ?? 0,
      ));
    }

    temp.sort((a, b) => a.date.compareTo(b.date));
    _allTransactions = temp;
    _applyFilters();
  }

  void _applyFilters() {
    var filtered = _allTransactions.where((t) {
      if (_startDate != null && t.date.isBefore(_startDate!)) return false;
      if (_endDate != null &&
          t.date.isAfter(_endDate!.add(const Duration(days: 1)))) return false;
      if (_typeFilter != 'all' && t.type != _typeFilter) return false;
      return true;
    }).toList();

    setState(() {
      _filteredTransactions = filtered;
    });
  }

  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: 'ج ', decimalDigits: 2).format(amount);

  String _formatAmount(double amount) {
    final number = NumberFormat('#,##0.00', 'en_US').format(amount);
    return '$number ج';
  }

  String _formatBalance(double balance) {
    final abs = balance.abs();
    final label = balance > 0
        ? 'مطلوب'
        : balance < 0
            ? 'طالب'
            : 'متساوي';
    return '${_formatCurrency(abs)} $label';
  }

  double get _totalSales => _filteredTransactions
      .where((t) => t.type == 'sale')
      .fold(0.0, (sum, t) => sum + t.credit);

  double get _totalPayments => _filteredTransactions
      .where((t) => t.type == 'payment')
      .fold(0.0, (sum, t) => sum + t.debit);

  double get _totalWithdrawals => _filteredTransactions
      .where((t) => t.type == 'withdraw')
      .fold(0.0, (sum, t) => sum + t.credit);

  double get _currentBalance => _filteredTransactions.isNotEmpty
      ? _filteredTransactions.last.balance
      : 0.0;

  Future<void> _sharePdf() async {
    try {
      final font = _arabicFont ?? await PdfGoogleFonts.notoSansArabicRegular();
      final bold = _arabicBoldFont ?? await PdfGoogleFonts.notoSansArabicBold();
      final latin =
          _latinFont ?? await PdfGoogleFonts.notoSansRegular();

      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("كشف الحساب",
                    style: pw.TextStyle(
                      font: bold,
                      fontSize: 24,
                      fontFallback: [latin],
                    )),
                pw.SizedBox(height: 10),
                pw.Text("العميل: ${widget.customerName}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.Text("رقم الحساب: ${widget.accountNumber}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.Text("التاريخ: ${_dateFormat.format(DateTime.now())}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.SizedBox(height: 8),
                pw.Text(
                    "من: ${_startDate != null ? _dateFormat.format(_startDate!) : 'البداية'}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.Text(
                    "إلى: ${_endDate != null ? _dateFormat.format(_endDate!) : 'النهاية'}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.SizedBox(height: 8),
                pw.Text("إجمالي المشتريات: ${_formatCurrency(_totalSales)}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.Text("إجمالي السداد: ${_formatCurrency(_totalPayments)}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.Text(
                    "إجمالي المسحوبات: ${_formatCurrency(_totalWithdrawals)}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.Text("الرصيد الحالي: ${_formatBalance(_currentBalance)}",
                    style: pw.TextStyle(font: font, fontFallback: [latin])),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(
                      font: bold, fontWeight: pw.FontWeight.bold, fontSize: 12, fontFallback: [latin]),
                  cellStyle: pw.TextStyle(font: font, fontSize: 10, fontFallback: [latin]),
                  headers: ["التاريخ", "الوصف", "إيداع", "سحب", "الرصيد"],
                  data: _filteredTransactions.map((t) {
                    return [
                      _dateFormat.format(t.date),
                      t.description,
                      t.debit > 0 ? _formatCurrency(t.debit) : "",
                      t.credit > 0 ? _formatCurrency(t.credit) : "",
                      _formatBalance(t.balance),
                    ];
                  }).toList(),
                  border: pw.TableBorder.all(color: PdfColors.grey, width: 0.5),
                  headerDecoration:
                      const pw.BoxDecoration(color: PdfColors.grey300),
                  cellAlignment: pw.Alignment.centerLeft,
                  headerAlignments: {
                    0: pw.Alignment.centerLeft,
                    1: pw.Alignment.centerLeft,
                    2: pw.Alignment.centerRight,
                    3: pw.Alignment.centerRight,
                    4: pw.Alignment.centerRight,
                  },
                ),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Center(
                  child: pw.Text("شكراً لاستخدامك دكان",
                      style: pw.TextStyle(font: font, fontSize: 12, fontFallback: [latin])),
                ),
              ],
            );
          },
        ),
      );

      final Uint8List pdfBytes = await pdf.save();

      try {
        await Printing.sharePdf(
            bytes: pdfBytes, filename: 'account_statement.pdf');
        return;
      } catch (_) {}

      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/account_statement.pdf');
      await pdfFile.writeAsBytes(pdfBytes);

      try {
        await Share.shareXFiles([XFile(pdfFile.path)], text: 'كشف الحساب');
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم حفظ الملف في: ${pdfFile.path}')),
          );
        }
      }
    } catch (e, st) {
      await AppLogger.captureException(e,
          stackTrace: st, area: 'account_statement.pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text(UserSafeMessages.pdfFailed)),
        );
      }
    }
  }

  Future<void> _shareText() async {
    final buf = StringBuffer();
    buf.writeln('=== كشف الحساب ===');
    buf.writeln('العميل: ${widget.customerName}');
    buf.writeln('رقم الحساب: ${widget.accountNumber}');
    buf.writeln('التاريخ: ${_dateFormat.format(DateTime.now())}');
    if (_startDate != null) {
      buf.writeln('من: ${_dateFormat.format(_startDate!)}');
    }
    if (_endDate != null) {
      buf.writeln('إلى: ${_dateFormat.format(_endDate!)}');
    }
    buf.writeln('');
    buf.writeln('إجمالي المشتريات: ${_formatCurrency(_totalSales)}');
    buf.writeln('إجمالي السداد: ${_formatCurrency(_totalPayments)}');
    buf.writeln('إجمالي المسحوبات: ${_formatCurrency(_totalWithdrawals)}');
    buf.writeln('الرصيد الحالي: ${_formatBalance(_currentBalance)}');
    buf.writeln('');
    buf.writeln('التاريخ\t| الوصف\t\t| سداد\t\t| دين\t\t| الرصيد');
    buf.writeln(''.padRight(80, '-'));
    for (final t in _filteredTransactions) {
      final debitStr = t.debit > 0 ? _formatCurrency(t.debit) : '-';
      final creditStr = t.credit > 0 ? _formatCurrency(t.credit) : '-';
      buf.writeln(
          '${_dateFormat.format(t.date)}\t| ${t.description}\t| $debitStr\t| $creditStr\t| ${_formatBalance(t.balance)}');
    }
    buf.writeln('');
    buf.writeln('شكراً لاستخدامك دكان');

    final text = buf.toString();
    try {
      await Share.share(
        text,
        subject: 'كشف الحساب - ${widget.customerName}',
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نسخ النص إلى الحافظة')),
        );
      }
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'payment':
        return Colors.green;
      case 'sale':
        return Colors.blue;
      case 'withdraw':
        return Colors.red;
      case 'cancel':
        return Colors.red.shade400;
      case 'reset':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'payment':
        return Icons.arrow_downward;
      case 'sale':
        return Icons.shopping_cart;
      case 'withdraw':
        return Icons.arrow_upward;
      case 'cancel':
        return Icons.cancel;
      case 'reset':
        return Icons.refresh;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.brown[50]),
        backgroundColor: Colors.brown,
        title: Text('كشف الحساب', style: TextStyle(color: Colors.brown[50])),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.share),
            tooltip: 'مشاركة كشف الحساب',
            onSelected: (value) {
              if (value == 'pdf') {
                _sharePdf();
              } else if (value == 'text') {
                _shareText();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'text',
                child: ListTile(
                  leading: Icon(Icons.text_snippet),
                  title: Text('نص عادي'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _allTransactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.brown[200]),
                  const SizedBox(height: 16),
                  Text('لا توجد معاملات',
                      style: TextStyle(color: Colors.brown[400], fontSize: 18)),
                ],
              ),
            )
          : Column(
              children: [
                _buildSummaryCards(),
                _buildFilters(),
                const Divider(height: 1),
                Expanded(child: _buildTransactionList()),
              ],
            ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        // textDirection handled by locale
        children: [
          Expanded(
            child: _buildSummaryCard(
              'إجمالي المشتريات',
              _formatCurrency(_totalSales),
              Colors.brown[700]!,
              Colors.brown[50]!,
              Icons.shopping_cart,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'إجمالي السداد',
              _formatCurrency(_totalPayments),
              Colors.green[700]!,
              Colors.green[50]!,
              Icons.arrow_downward,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildSummaryCard(
              'إجمالي المسحوبات',
              _formatCurrency(_totalWithdrawals),
              Colors.red[700]!,
              Colors.red[50]!,
              Icons.arrow_upward,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: _buildBalanceCard()),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    Color color,
    Color bgColor,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: color.withAlpha(178), fontSize: 10),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    final balance = _currentBalance;
    final isPositive = balance >= 0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isPositive
                ? [Colors.red.shade700, Colors.red.shade500]
                : [Colors.green.shade700, Colors.green.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              isPositive ? 'مطلوب' : 'طالب',
              style:
                  TextStyle(color: Colors.white.withAlpha(178), fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.simpleCurrency(decimalDigits: 0, name: '')
                  .format(balance.abs()),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'الرصيد',
              style:
                  TextStyle(color: Colors.white.withAlpha(178), fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Column(
        children: [
          Row(
            // textDirection handled by locale
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(true),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.brown[400]),
                        Text(
                          _startDate != null
                              ? _dateFormat.format(_startDate!)
                              : 'تاريخ البداية',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(false),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.calendar_today,
                            size: 16, color: Colors.brown[400]),
                        Text(
                          _endDate != null
                              ? _dateFormat.format(_endDate!)
                              : 'تاريخ النهاية',
                          style:
                              TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // textDirection handled by locale
              children: [
                _buildTypeChip('الكل', 'all'),
                const SizedBox(width: 4),
                _buildTypeChip('مشتريات', 'sale'),
                const SizedBox(width: 4),
                _buildTypeChip('سداد', 'payment'),
                const SizedBox(width: 4),
                _buildTypeChip('سحب', 'withdraw'),
                const SizedBox(width: 4),
                _buildTypeChip('تصفير', 'reset'),
                const SizedBox(width: 4),
                _buildTypeChip('إلغاء', 'cancel'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, String value) {
    final isSelected = _typeFilter == value;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.brown[700],
        ),
      ),
      selected: isSelected,
      selectedColor: Colors.brown,
      backgroundColor: Colors.brown[50],
      onSelected: (_) {
        setState(() => _typeFilter = value);
        _applyFilters();
      },
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _applyFilters();
    }
  }

  Widget _buildTransactionList() {
    if (_filteredTransactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.brown[200]),
            const SizedBox(height: 12),
            Text(
              'لا توجد معاملات في هذا النطاق',
              style: TextStyle(color: Colors.brown[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    final groups = <String, List<Transaction>>{};
    for (final t in _filteredTransactions) {
      final key = _monthFormat.format(t.date);
      groups.putIfAbsent(key, () => []);
      groups[key]!.add(t);
    }

    final sortedKeys = groups.keys.toList()
      ..sort((a, b) {
        final aDate = groups[a]!.first.date;
        final bDate = groups[b]!.first.date;
        return bDate.compareTo(aDate);
      });

    final totalItemCount =
        sortedKeys.fold(0, (sum, k) => sum + 1 + groups[k]!.length);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: totalItemCount,
      itemBuilder: (context, index) {
        int remaining = index;
        for (final key in sortedKeys) {
          final items = groups[key]!;
          final sectionLength = 1 + items.length;
          if (remaining == 0) {
            final monthTotal = items.fold<double>(
              0,
              (sum, t) => sum + t.credit - t.debit,
            );
            return _buildMonthHeader(key, monthTotal);
          }
          if (remaining < sectionLength) {
            final t = items[remaining - 1];
            return _buildTransactionRow(t);
          }
          remaining -= sectionLength;
        }
        return null;
      },
    );
  }

  Widget _buildMonthHeader(String monthLabel, double monthTotal) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.brown[200]!),
        ),
      ),
      child: Row(
        // textDirection handled by locale
        children: [
          Icon(Icons.calendar_month, size: 16, color: Colors.brown[600]),
          const SizedBox(width: 6),
          Text(
            monthLabel,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.brown[800],
            ),
          ),
          const Spacer(),
          Text(
            _formatCurrency(monthTotal.abs()),
            style: TextStyle(
              fontSize: 12,
              color: monthTotal >= 0 ? Colors.red[600] : Colors.green[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCell(double value, Color color) {
    return Expanded(
      child: value > 0
          ? Text(
              _formatAmount(value),
              textDirection: ui.TextDirection.ltr,
              softWrap: false,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.left,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _balanceCell(double balance) {
    final abs = balance.abs();
    final label = balance > 0
        ? 'مطلوب'
        : balance < 0
            ? 'طالب'
            : 'متساوي';
    final color = balance > 0
        ? Colors.red[600]!
        : balance < 0
            ? Colors.green[600]!
            : Colors.brown[600]!;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatAmount(abs),
            textDirection: ui.TextDirection.ltr,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color.withAlpha(200),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionRow(Transaction t) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        // textDirection handled by locale
        children: [
          Expanded(
            child: Text(
              _dateFormat.format(t.date).substring(5),
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(width: 8),
          Icon(_typeIcon(t.type), size: 14, color: _typeColor(t.type)),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              t.description,
              style: TextStyle(fontSize: 13, color: Colors.brown[900]),
            ),
          ),
          t.debit == 0
              ? _amountCell(t.credit, Colors.red[700]!)
              : _amountCell(t.debit, Colors.green[700]!),
          // _amountCell(t.credit, Colors.red[700]!),
          _balanceCell(t.balance),
        ],
      ),
    );
  }
}
