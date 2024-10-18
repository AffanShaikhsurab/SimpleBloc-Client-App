import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simplicity_coin/blocs/createWallet_bloc.dart';
import 'package:simplicity_coin/screens/wallet_screen.dart';

class LoadWalletScreen extends StatefulWidget {
  @override
  _LoadWalletScreenState createState() => _LoadWalletScreenState();
}

class _LoadWalletScreenState extends State<LoadWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> _enteredPhrase = List.filled(24, '');
  final List<TextEditingController> _controllers = List.generate(24, (_) => TextEditingController());
  final TextEditingController _pasteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Load Existing Wallet'), backgroundColor: Colors.black),
      body: BlocConsumer<CreateWalletCubit, CreateWalletState>(
        listener: (context, state) async {
          if (state == CreateWalletState.phraseKeyCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Wallet loaded successfully!')),
            );
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => WalletScreen()));
          } else if (state == CreateWalletState.failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid recovery phrase. Please try again.')),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
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
                    SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _pasteController,
                            style: TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Paste your recovery phrase here',
                              hintStyle: TextStyle(color: Colors.grey),
                              fillColor: Colors.grey[900],
                              filled: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          child: Text('Paste'),
                          onPressed: _pasteAndFill,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(24, (index) {
                        return Container(
                          width: 100,
                          child: TextField(
                            controller: _controllers[index],
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
                                _enteredPhrase[index] = value.trim();
                              });
                            },
                          ),
                        );
                      }),
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      child: Text('SUBMIT'),
                      onPressed: state == CreateWalletState.loading
                          ? null
                          : () => _validateRecoveryPhrase(context),
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
              ),
            ),
          );
        },
      ),
    );
  }

  void _pasteAndFill() async {
    ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData != null && clipboardData.text != null) {
      List<String> words = clipboardData.text!.split(' ');
      if (words.length == 24) {
        setState(() {
          for (int i = 0; i < 24; i++) {
            _controllers[i].text = words[i];
            _enteredPhrase[i] = words[i];
          }
          _pasteController.text = clipboardData.text!;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid recovery phrase. Please check and try again.')),
        );
      }
    }
  }

  void _validateRecoveryPhrase(BuildContext context) {
    List<String> cleanedPhrase = _enteredPhrase.where((word) => word.isNotEmpty).toList();

    if (cleanedPhrase.length != 24) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all 24 words of your recovery phrase.')),
      );
      return;
    }

    context.read<CreateWalletCubit>().validatedPasskey(cleanedPhrase);
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _pasteController.dispose();
    super.dispose();
  }
}