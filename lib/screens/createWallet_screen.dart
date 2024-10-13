import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simplicity_coin/blocs/createWallet_bloc.dart';
import 'package:simplicity_coin/screens/wallet_screen.dart';

class CreateWalletScreen extends StatefulWidget {
  @override
  _CreateWalletScreenState createState() => _CreateWalletScreenState();
}

class _CreateWalletScreenState extends State<CreateWalletScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _recoveryPhrase = [
    'king', 'blue', 'glow', 'black', 'true', 'phone',
    'winter', 'light', 'sorry', 'roll', 'mind', 'soul'
  ];
  List<String> _enteredPhrase = List.filled(12, '');
  String _password = '';
  bool _isPasswordValid = false;
  bool _agreedToTerms = false;

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentPage++;
      });
    }
  }

  void _validatePassword(String value) {
    // Add your password validation logic here
    setState(() {
      _password = value;
      _isPasswordValid = value.length >= 8; // Example: password must be at least 8 characters
    });
  }

  void _validateRecoveryPhrase() {
    bool isValid = _enteredPhrase.join(' ') == _recoveryPhrase.join(' ');
    if (isValid) {
      _nextPage();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect recovery phrase. Please try again.'))
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body:
       SafeArea(
        child: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            _buildCreatePasswordPage(),
            _buildSecureWalletPage(),
            _buildVerifyRecoveryKeysPage(),
            _buildCongratulationsPage(),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatePasswordPage() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create password',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'This unlocks your MetaMask wallet only on this device',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 32),
          TextField(
            obscureText: true,
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Password',
              hintStyle: TextStyle(color: Colors.grey),
              fillColor: Colors.grey[900],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: _validatePassword,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _agreedToTerms,
                onChanged: (value) {
                  setState(() {
                    _agreedToTerms = value!;
                  });
                },
                fillColor: MaterialStateProperty.resolveWith((states) => Colors.orange),
              ),
              Expanded(
                child: Text(
                  'I understand that MetaMask cannot recover this password for me.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          ),
          Spacer(),
          ElevatedButton(
            child: Text('CREATE WALLET'),
            onPressed:(){
                if (_isPasswordValid && _agreedToTerms) {
                  BlocProvider.of<CreateWalletBloc>(context).createWallet( _password);
                    _nextPage();
            }
            },
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
    );
  }

  Widget _buildSecureWalletPage() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Secure your wallet',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            'These recovery phrases are the only way to restore your wallet. Write it down in order on a piece of paper and store it in a safe place.',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 32),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(12, (index) {
              return Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${index + 1}. ${_recoveryPhrase[index]}',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }),
          ),
          SizedBox(height: 16),
          ElevatedButton.icon(
            icon: Icon(Icons.copy),
            label: Text('Copy'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _recoveryPhrase.join(' ')));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Recovery phrase copied to clipboard'))
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.orange,
            ),
          ),
          Spacer(),
          ElevatedButton(
            child: Text('SUBMIT'),
            onPressed: (){
              BlocProvider.of<CreateWalletBloc>(context).storePasskey( _recoveryPhrase);
            },
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
    );
  }

  Widget _buildVerifyRecoveryKeysPage() {
    return Padding(
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
            onPressed: (){
               BlocProvider.of<PasskeyBloc>(context).readPasskey();
               //if _Recorverpasskey == readPasskey() then go to gongratualion page 
            },
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
    );
  }

  Widget _buildCongratulationsPage() {
    return Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.thumb_up, size: 100, color: Colors.orange),
          SizedBox(height: 32),
          Text(
            'Congratulations!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 16),
          Text(
            'You have successfully created and protected your wallet! Remember to keep your Secret Recovery Phrase safe. You can start transactions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 32),
          ElevatedButton(
            child: Text('GO TO WALLET'),
            onPressed: () {
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WalletScreen()));
            },
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
    );
  }
}
