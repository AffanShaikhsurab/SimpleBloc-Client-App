import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:simplicity_coin/blocs/wallet_bloc.dart';

class SendTransactionScreen extends StatefulWidget {
  @override
  _SendTransactionScreenState createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _recipient = '';
  double _amount = 0.0;
  bool _isLoading = false;
  
  // Add a recent Bitcoin address
  final String _recentAddress = '02e0cd3cc43abbc54dfa39c89d893b84878041b4c81dfa98deef63e09395fe262a';

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
      body: BlocListener<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is WalletLoaded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Transaction sent successfully!')),
            );
            Navigator.pop(context);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
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
                SizedBox(height: 16),
                _buildRecentAddressButton(),
                Spacer(),
                ElevatedButton(
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('SEND', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _isLoading ? null : _sendTransaction,
                ),
              ],
            ),
          ),
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
        TextFormField(
          style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(color: Colors.white38),
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter an amount';
            }
            if (double.tryParse(value) == null) {
              return 'Please enter a valid number';
            }
            return null;
          },
          onSaved: (value) {
            _amount = double.parse(value!);
          },
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('To', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 8),
        TextFormField(
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter recipient address',
            hintStyle: TextStyle(color: Colors.white38),
            suffixIcon: Icon(Icons.qr_code_scanner, color: Colors.orange),
            border: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange)),
            focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.orange, width: 2)),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a recipient address';
            }
            // Add more sophisticated address validation here
            return null;
          },
          onSaved: (value) {
            _recipient = value!;
          },
          controller: TextEditingController(text: _recipient),
        ),
      ],
    );
  }

  Widget _buildRecentAddressButton() {
    return TextButton(
      onPressed: () {
        setState(() {
          _recipient = _recentAddress;
        });
      },
      child: Text(
        'Use Recent Address',
        style: TextStyle(color: Colors.orange),
      ),
    );
  }

  void _sendTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        final walletCubit = context.read<WalletCubit>();
        String result = await walletCubit.sendTransaction(_recipient, _amount);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result)),
        );

        if (result == 'Transaction sent successfully!') {
          Navigator.pop(context);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send transaction: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
