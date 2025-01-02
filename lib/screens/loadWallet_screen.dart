import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simplicity_coin/blocs/createWallet_bloc.dart';
import 'package:simplicity_coin/screens/wallet_screen.dart';
import 'package:bip39/bip39.dart' as bip39;

class LoadWalletScreen extends StatefulWidget {
  @override
  _LoadWalletScreenState createState() => _LoadWalletScreenState();
}

class _LoadWalletScreenState extends State<LoadWalletScreen> {
  final _formKey = GlobalKey<FormState>();
  List<String> _enteredPhrase = List.filled(24, '');
  final List<TextEditingController> _controllers = List.generate(24, (_) => TextEditingController());
  final TextEditingController _pasteController = TextEditingController();
  final FocusNode _pasteFocusNode = FocusNode();
  
  Map<int, String> _fieldErrors = {};
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Load Existing Wallet'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: BlocConsumer<CreateWalletCubit, CreateWalletState>(
        listener: (context, state) async {
          if (state == CreateWalletState.phraseKeyCreated) {
            _showSuccess('Wallet loaded successfully!');
            context.read<CreateWalletCubit>().createAccount();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => WalletScreen()),
            );
          } else if (state == CreateWalletState.failure) {
            _showError('Invalid recovery phrase. Please try again.');
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      SizedBox(height: 24),
                      _buildPasteSection(),
                      SizedBox(height: 24),
                      _buildWordGrid(),
                      SizedBox(height: 24),
                      _buildSubmitButton(state),
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

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Verify Secret Recovery Keys',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Enter your 24-word recovery phrase in the correct order.',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _buildPasteSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paste Recovery Phrase',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pasteController,
                  focusNode: _pasteFocusNode,
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Paste your 24-word phrase here',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Colors.grey[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _pasteAndFill,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Paste',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWordGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enter Recovery Words',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: List.generate(24, (index) => _buildWordField(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildWordField(int index) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      constraints: BoxConstraints(maxWidth: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controllers[index],
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Word ${index + 1}',
              hintStyle: TextStyle(color: Colors.grey[600]),
              fillColor: _fieldErrors.containsKey(index) 
                  ? Colors.red.withOpacity(0.1) 
                  : Colors.grey[800],
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _fieldErrors.containsKey(index) 
                      ? Colors.red 
                      : Colors.transparent,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: _fieldErrors.containsKey(index) 
                      ? Colors.red 
                      : Colors.transparent,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: Colors.orange,
                ),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _enteredPhrase[index] = value.trim();
                if (_fieldErrors.containsKey(index)) {
                  _fieldErrors.remove(index);
                }
              });
            },
            textInputAction: index < 23 
                ? TextInputAction.next 
                : TextInputAction.done,
            onSubmitted: (value) {
              if (index < 23) {
                FocusScope.of(context).nextFocus();
              }
            },
          ),
          if (_fieldErrors.containsKey(index))
            Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Text(
                _fieldErrors[index]!,
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(CreateWalletState state) {
    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: state == CreateWalletState.loading || _isProcessing
            ? null
            : () => _validateRecoveryPhrase(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          disabledBackgroundColor: Colors.grey,
        ),
        child: state == CreateWalletState.loading || _isProcessing
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'VERIFY AND LOAD WALLET',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Future<void> _pasteAndFill() async {
    try {
      ClipboardData? clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null) {
        _showError('No text found in clipboard.');
        return;
      }

      String cleanedText = clipboardData!.text!
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'\s+'), ' ');
      
      List<String> words = cleanedText.split(' ');
      
      if (words.length != 24) {
        _showError('Recovery phrase must contain exactly 24 words.');
        return;
      }

      // Validate each word
    

      setState(() {
        for (int i = 0; i < 24; i++) {
          _controllers[i].text = words[i];
          _enteredPhrase[i] = words[i];
        }
        _pasteController.text = cleanedText;
        _fieldErrors.clear();
      });

      _pasteFocusNode.unfocus();
    } catch (e) {
      _showError('Error processing clipboard data');
    }
  }

  Future<void> _validateRecoveryPhrase(BuildContext context) async {
    if (_isProcessing) return;
    
    setState(() {
      _isProcessing = true;
      _fieldErrors.clear();
    });

    try {
      List<String> cleanedPhrase = _enteredPhrase
          .map((word) => word.trim().toLowerCase())
          .toList();

      // Validate all fields are filled
      bool hasEmptyFields = false;
      for (int i = 0; i < cleanedPhrase.length; i++) {
        if (cleanedPhrase[i].isEmpty) {
          _fieldErrors[i] = 'Required';
          hasEmptyFields = true;
        }
      }

      if (hasEmptyFields) {
        _showError('Please fill in all words');
        return;
      }
      // Validate each word

 

      // Validate complete phrase

      // Submit to bloc
      context.read<CreateWalletCubit>().validatedPasskey(cleanedPhrase , context);
      
    } catch (e) {
      _showError('An error occurred while validating the recovery phrase');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 4),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _pasteController.dispose();
    _pasteFocusNode.dispose();
    super.dispose();
  }
}