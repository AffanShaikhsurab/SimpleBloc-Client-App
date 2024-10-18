import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/blocs/createWallet_bloc.dart';

class ReceiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreateWalletCubit, CreateWalletState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: Text('Receive', style: TextStyle(color: Colors.white)),
            actions: [
              IconButton(
                icon: Icon(Icons.close, color: Colors.orange),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          body: FutureBuilder<String>(
            future: _getPublicAddress(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Colors.orange));
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('No public address found', style: TextStyle(color: Colors.white)));
              }

              final publicAddress = snapshot.data!;
              return _buildContent(context, publicAddress);
            },
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, String publicAddress) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QrImageView(
                    data: publicAddress,
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Scan the QR code to receive payment',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => _copyToClipboard(context, publicAddress),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _truncateAddress(publicAddress),
                          style: TextStyle(color: Colors.orange, fontSize: 18),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.copy, color: Colors.orange, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton(
            child: Text('REQUEST PAYMENT', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              // Implement request payment logic
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Payment request functionality not implemented yet')),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<String> _getPublicAddress(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final accountJson = prefs.getString("account");
    if (accountJson != null) {
      final account = jsonDecode(accountJson);
      return account['public_address'] ?? '';
    }
    return '';
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Address copied to clipboard')),
    );
  }

  String _truncateAddress(String address) {
    if (address.length > 10) {
      return '${address.substring(0, 6)}...${address.substring(address.length - 4)}';
    }
    return address;
  }
}