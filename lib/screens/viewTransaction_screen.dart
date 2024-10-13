
import 'package:flutter/material.dart';
import 'package:simplicity_coin/main.dart';

class ViewTransactionsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _transactions = [
    {'type': 'Sent', 'amount': '-0.1 ETH', 'to': '0x5678...9012', 'date': '2023-05-01'},
    {'type': 'Received', 'amount': '+0.5 ETH', 'from': '0x3456...7890', 'date': '2023-04-28'},
    // Add more transaction data here
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction History'), backgroundColor: Colors.black),
      body: SafeArea(
        child: ListView.builder(
          itemCount: _transactions.length,
          itemBuilder: (context, index) {
            final transaction = _transactions[index];
            return ListTile(
              leading: Icon(
                transaction['type'] == 'Sent' ? Icons.arrow_upward : Icons.arrow_downward,
                color: transaction['type'] == 'Sent' ? Colors.red : Colors.green,
              ),
              title: Text(transaction['amount'], style: Theme.of(context).textTheme.bodySmall),
              subtitle: Text(
                transaction['type'] == 'Sent'
                    ? 'To: ${transaction['to']}'
                    : 'From: ${transaction['from']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              trailing: Text(transaction['date'], style: Theme.of(context).textTheme.bodyMedium),
              onTap: () {
                // Implement navigation to transaction details screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransactionDetailsScreen(transaction: transaction),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
