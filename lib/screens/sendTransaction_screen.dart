import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';
import 'package:simplicity_coin/blocs/wallet_bloc.dart';

class SendTransactionScreen extends StatefulWidget {
  @override
  _SendTransactionScreenState createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  double _amount = 0.0;
  bool _isLoading = false;

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: BlocConsumer<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            _showSnackBar(context, state.message, isError: true);
          } else if (state is WalletLoaded) {
            Navigator.pop(context);
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 32),
                      _buildAmountInput(),
                      SizedBox(height: 32),
                      _buildFromAccount(state),
                      SizedBox(height: 24),
                      _buildToAddress(),
                      SizedBox(height: 40),
                      _buildSendButton(),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: Colors.orange),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text('Send Simplicity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Icon(Icons.send_rounded, size: 64, color: Colors.orange),
        SizedBox(height: 16),
        Text(
          'Send Simplicity Coins',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[900],
            prefixIcon: Icon(Icons.attach_money, color: Colors.orange),
            suffixText: 'SMP',
            suffixStyle: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter an amount';
            if (double.tryParse(value) == null) return 'Please enter a valid number';
            return null;
          },
          onSaved: (value) => _amount = double.parse(value!),
        ),
      ],
    );
  }

  Widget _buildFromAccount(WalletState state) {
    String balance = 'Loading...';
    if (state is WalletLoaded) {
      balance = '${state.balance} SMP';
    }
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('From', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 4),
              Text('Your Wallet', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          Text('Balance: $balance', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
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
          controller: _recipientController,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter recipient address',
            hintStyle: TextStyle(color: Colors.white38),
            suffixIcon: IconButton(
              icon: Icon(Icons.qr_code_scanner, color: Colors.orange),
              onPressed: _scanQRCode,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            filled: true,
            fillColor: Colors.grey[900],
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a recipient address';
            // Add more sophisticated address validation here
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSendButton() {
    return ElevatedButton(
      child: _isLoading
          ? CircularProgressIndicator(color: Colors.white)
          : Text('SEND', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: _isLoading ? null : _sendTransaction,
    );
  }

  Future<void> _scanQRCode() async {
    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => QRScannerScreen()),
      );

      if (result != null) {
        setState(() {
          _recipientController.text = result;
        });
      }
    } catch (e) {
      _showSnackBar(context, 'Failed to scan QR code: ${e.toString()}', isError: true);
    }
  }

  void _sendTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);

      try {
        final walletCubit = context.read<WalletCubit>();
        String result = await walletCubit.sendTransaction(_recipientController.text, _amount);
        _showSnackBar(context, result);
        if (result == 'Transaction sent successfully!') {
          Navigator.pop(context);
        }
      } catch (e) {
        _showSnackBar(context, 'Failed to send transaction: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.all(10),
      ),
    );
  }
}

class QRScannerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Scan QR Code'),
        backgroundColor: Colors.black,
      ),
      body: QRCodeDartScanView(
        scanInvertedQRCode: true,
        typeScan: TypeScan.live,
        formats: [BarcodeFormat.qrCode],
        onCapture: (Result result) {
          Navigator.pop(context, result.text);
        },
      ),
    );
  }
}