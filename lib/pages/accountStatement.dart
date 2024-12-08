import 'package:dukkan/providers/list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/db.dart';
import '../util/models/Loaner.dart';
import 'package:intl/intl.dart';

class AccountStatementPage extends StatelessWidget {
  final Loaner loaner;

  const AccountStatementPage({
    Key? key,
    required this.loaner,
  }) : super(key: key);

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(symbol: '₪', decimalDigits: 2).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Statement'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: Provider.of<Lists>(context,listen: false).db.getAccountStatementData(loaner.ID),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final data = snapshot.data!;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer Information Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow('Name', data['customerName']),
                        _buildInfoRow('Phone', data['phoneNumber']),
                        _buildInfoRow('Location', data['location']),
                        _buildInfoRow('Last Zeroing', data['zeroingDateDisplay']),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Financial Summary Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Financial Summary',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildAmountRow(
                          'Total Loaned',
                          data['totalLoaned'],
                          Colors.orange,
                        ),
                        _buildAmountRow(
                          'Total Paid',
                          data['totalPaidAmount'],
                          Colors.green,
                        ),
                        const Divider(),
                        _buildAmountRow(
                          'Current Balance',
                          data['currentBalance'],
                          data['currentBalance'] > 0 ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Transaction History
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: (data['transactionHistory'] as List).length,
                  itemBuilder: (context, index) {
                    final transaction = data['transactionHistory'][index];
                    final bool isPayment = transaction['type'] == 'payment';
                    
                    return Card(
                      child: ListTile(
                        leading: Icon(
                          isPayment ? Icons.payment : Icons.shopping_cart,
                          color: isPayment ? Colors.green : Colors.orange,
                        ),
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDate(transaction['date']),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${isPayment ? "-" : "+"} ${_formatCurrency(transaction['amount'])}',
                              style: TextStyle(
                                color: isPayment ? Colors.green : Colors.orange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          transaction['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, double amount, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
