
import 'package:flutter/material.dart';
import 'package:simplicity_coin/main.dart';

import 'wallet_screen.dart';

class LoadWalletScreen extends StatefulWidget {
  @override
  _LoadWalletScreenState createState() => _LoadWalletScreenState();
}
  List<String> _enteredPhrase = List.filled(12, '');

class _LoadWalletScreenState extends State<LoadWalletScreen> {
  final _formKey = GlobalKey<FormState>();
 List<String> _recoveryPhrase = List.filled(12, '');
  String _password = '';
  bool _isPasswordValid = false;
  bool _agreedToTerms = false;
  
  /// Verifies the entered recovery phrase against the actual recovery phrase.
  ///
  /// If valid, navigates to the next page.
  /// If invalid, shows a snackbar asking the user to try again.
 void _validateRecoveryPhrase() {
    bool isValid = _enteredPhrase.join(' ') == _recoveryPhrase.join(' ');
    if (isValid) {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WalletScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect recovery phrase. Please try again.'))
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Load Existing Wallet'), backgroundColor: Colors.black),
      body: SafeArea(
        child: Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Verify Secret Recovery Keys',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'Enter the secret recovery keys given to you in the correct order.',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              return Container(
                width: 100,
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: '${index + 1}.',
                    hintStyle: TextStyle(color: Colors.grey),
                    fillColor: Colors.grey[900],
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _enteredPhrase[index] = value;
                    });
                  },
                ),
              );
            }),
          ),
          Spacer(),
          ElevatedButton(
            child: Text('SUBMIT'),
            onPressed: _validateRecoveryPhrase,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    )
  
        ));
    
  }
}
