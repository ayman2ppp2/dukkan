import 'dart:io';
import 'dart:typed_data';

import 'package:dukkan/providers/list.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

/// A simple model representing a transaction.
class Transaction {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final double balance;

  Transaction({
    required this.date,
    required this.description,
    this.debit = 0,
    this.credit = 0,
    required this.balance,
  });
}

/// This widget represents a bank-like account statement page.
class BankStatementPage extends StatefulWidget {
  final String customerName;
  final String accountNumber;
  late List<Transaction> transactions;
  final Loaner loaner;
  BankStatementPage({
    Key? key,
    required this.customerName,
    required this.accountNumber,
    required this.loaner,
  }) : super(key: key);
  // Map the loaner's last payments to transactions and append them with the loaner's receipts

  // Sort transactions by date

  @override
  State<BankStatementPage> createState() => _BankStatementPageState();
}

class _BankStatementPageState extends State<BankStatementPage> {
  void fetchTransactions(BuildContext context) {
    List<Transaction> temp = widget.loaner.lastPayment!.map((payment) {
      return Transaction(
        date: DateTime.parse(payment.key!),
        description: 'Payment',
        debit: double.tryParse(payment.value!) ?? 0,
        balance: payment.remaining!,
      );
    }).toList();

    Provider.of<Lists>(context).getPersonsLogs(widget.loaner.ID).forEach((log) {
      for (var log in log) {
        temp.add(Transaction(
          date: log.date,
          description: 'فاتورة رقم ${log.id}',
          credit: log.products.fold(
            0.0,
            (previousValue, element) =>
                previousValue + (element.sellPrice! * element.count!),
          ),
          balance: log.price,
        ));
      }
    });

    temp.sort((a, b) => a.date.compareTo(b.date));
    widget.transactions = temp;
  }

  /// Formats a [DateTime] object as 'yyyy-MM-dd'.
  String _formatDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Formats a currency value.
  String _formatCurrency(double amount) =>
      NumberFormat.currency(symbol: "\$", decimalDigits: 2).format(amount);

  /// Generates a PDF file with a bank-like statement and shares it.
  Future<void> _generateAndSharePdf(BuildContext context) async {
    fetchTransactions(context);
    try {
      final pdf = pw.Document();

      // Build the PDF content.
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Text(
                  "Bank Statement",
                  style: pw.TextStyle(
                      fontSize: 24, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 10),
                pw.Text("Customer: ${widget.customerName}"),
                pw.Text("Account Number: ${widget.accountNumber}"),
                pw.Text("Date: ${_formatDate(DateTime.now())}"),
                pw.Divider(),

                pw.SizedBox(height: 20),

                // Table header
                pw.Table.fromTextArray(
                  headerStyle: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 12),
                  cellStyle: const pw.TextStyle(fontSize: 10),
                  headers: [
                    "Date",
                    "Description",
                    "Debit",
                    "Credit",
                    "Balance"
                  ],
                  data: widget.transactions.map((t) {
                    return [
                      _formatDate(t.date),
                      t.description,
                      t.debit > 0 ? _formatCurrency(t.debit) : "",
                      t.credit > 0 ? _formatCurrency(t.credit) : "",
                      _formatCurrency(t.balance),
                    ];
                  }).toList(),
                  border: pw.TableBorder.all(
                    color: PdfColors.grey,
                    width: 0.5,
                  ),
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

                // Footer
                pw.Center(
                  child: pw.Text(
                    "Thank you for banking with us!",
                    style: pw.TextStyle(
                      fontStyle: pw.FontStyle.italic,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Convert the PDF document to bytes.
      final Uint8List pdfBytes = await pdf.save();

      // Get the temporary directory of the device.
      final tempDir = await getTemporaryDirectory();
      final pdfFile = File('${tempDir.path}/bank_statement.pdf');

      // Write the PDF file to the temporary directory.
      await pdfFile.writeAsBytes(pdfBytes);

      // Share the PDF file using share_plus.
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Your bank statement',
      );
    } catch (e) {
      // Show an error message if something goes wrong.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bank Statement"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _generateAndSharePdf(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              "Bank Statement",
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text("Customer: ${widget.customerName}"),
            Text("Account Number: ${widget.accountNumber}"),
            Text("Date: ${_formatDate(DateTime.now())}"),
            const Divider(),
            // Show a preview of transactions (optional)
            ...widget.transactions.map((t) => ListTile(
                  title: Text(t.description),
                  subtitle: Text(_formatDate(t.date)),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (t.debit > 0)
                        Text(
                          "Debit: ${_formatCurrency(t.debit)}",
                          style: const TextStyle(color: Colors.red),
                        ),
                      if (t.credit > 0)
                        Text(
                          "Credit: ${_formatCurrency(t.credit)}",
                          style: const TextStyle(color: Colors.green),
                        ),
                      Text("Balance: ${_formatCurrency(t.balance)}"),
                    ],
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
