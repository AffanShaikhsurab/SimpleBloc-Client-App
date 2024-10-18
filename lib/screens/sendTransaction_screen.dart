import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:simplicity_coin/blocs/wallet_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class SendTransactionScreen extends StatefulWidget {
  @override
  _SendTransactionScreenState createState() => _SendTransactionScreenState();
}

class _SendTransactionScreenState extends State<SendTransactionScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  double _amount = 0.0;
  bool _isLoading = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: Duration(milliseconds: 300));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: BlocListener<WalletCubit, WalletState>(
        listener: (context, state) {
          if (state is WalletError) {
            _showSnackBar(context, state.message, isError: true);
          } else if (state is WalletLoaded) {
            _showSnackBar(context, 'Transaction sent successfully!');
            Navigator.pop(context);
          }
        },
        child: SafeArea(
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAnimatedHeader(),
                    SizedBox(height: 32),
                    _buildAmountInput(),
                    SizedBox(height: 32),
                    _buildFromAccount(),
                    SizedBox(height: 24),
                    _buildToAddress(),
                    SizedBox(height: 40),
                    _buildSendButton(),
                  ],
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
              ),
            ),
          ),
        ),
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
      title: Text('Send Simplicity', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        .animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: -0.2, end: 0),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.black, Colors.orange.withOpacity(0.1)],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return Column(
      children: [
        Icon(Icons.send_rounded, size: 64, color: Colors.orange)
          .animate()
          .scale(duration: 600.ms, curve: Curves.elasticOut)
          .then()
          .shake(duration: 500.ms, delay: 200.ms),
        SizedBox(height: 16),
        Text(
          'Send Simplicity Coins',
          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
        ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0),
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
        ).animate().shakeX(duration: 600.ms, delay: 800.ms),
      ],
    );
  }

  Widget _buildFromAccount() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[900]!, Colors.grey[800]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
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
          Text('Balance: 1000 SMP', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
        ],
      ),
    ).animate().slideX(begin: -0.2, end: 0, duration: 600.ms, delay: 400.ms).then().shimmer(duration: 1200.ms);
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
        ).animate().slideX(begin: 0.2, end: 0, duration: 600.ms, delay: 600.ms),
      ],
    );
  }

  Widget _buildSendButton() {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ElevatedButton(
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text('SEND', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _isLoading ? null : _sendTransaction,
          ).animate().shimmer(duration: 1200.ms, delay: 800.ms),
        );
      },
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
      _controller.forward();

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
        _controller.reverse();
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