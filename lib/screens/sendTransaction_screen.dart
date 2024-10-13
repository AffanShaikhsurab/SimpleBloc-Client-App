import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class SendTransactionScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.orange),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Send', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: Colors.orange),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'You want to send',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            SizedBox(height: 8),
            _buildCurrencyDropdown(),
            SizedBox(height: 24),
            _buildAmountInput(),
            SizedBox(height: 24),
            _buildFromAccount(),
            SizedBox(height: 16),
            _buildToAddress(),
            Spacer(),
            ElevatedButton(
              child: Text('SEND', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                // Implement send logic
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('BNB', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
          Icon(Icons.arrow_drop_down, color: Colors.black),
        ],
      ),
    );
  }

  Widget _buildAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        SizedBox(height: 8),
        Text(
          '3.5789',
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
        ),
        Text(
          '\$ 1,234.56',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildFromAccount() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 4),
              Text('Account 1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Text('42.22 BNB', style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildToAddress() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To', style: TextStyle(color: Colors.white70)),
                SizedBox(height: 4),
                Text('0xF1430*1aD4......EAAa7B8A', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          Icon(Icons.qr_code_scanner, color: Colors.orange),
        ],
      ),
    );
  }
}
