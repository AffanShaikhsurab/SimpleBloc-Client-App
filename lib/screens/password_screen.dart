import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/blocs/createWallet_bloc.dart';
import 'package:simplicity_coin/blocs/wallet_bloc.dart';
import 'package:simplicity_coin/screens/wallet_screen.dart';

class PasswordEntryScreen extends StatefulWidget {
  @override
  _PasswordEntryScreenState createState() => _PasswordEntryScreenState();
}

class _PasswordEntryScreenState extends State<PasswordEntryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isCreatingPassword = false;
  bool _agreedToTerms = false;
  bool _isPasswordValid = false;
  String? _passwordError;
  
  @override
  void initState() {
    super.initState();
    _initializeScreen();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('password');
    setState(() {
      _isCreatingPassword = storedPassword == null;
    });
  }

  void _validatePassword(String password) {
    setState(() {
      if (password.length < 8) {
        _passwordError = 'Password must be at least 8 characters';
        _isPasswordValid = false;
      } else if (!password.contains(RegExp(r'[A-Z]'))) {
        _passwordError = 'Password must contain at least one uppercase letter';
        _isPasswordValid = false;
      } else if (!password.contains(RegExp(r'[0-9]'))) {
        _passwordError = 'Password must contain at least one number';
        _isPasswordValid = false;
      } else {
        _passwordError = null;
        _isPasswordValid = true;
      }
    });
  }

  Future<void> _verifyPassword() async {
    final prefs = await SharedPreferences.getInstance();
    final storedPassword = prefs.getString('password');

    if (storedPassword == _passwordController.text) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => WalletScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect password. Please try again.')),
      );
    }
  }

  Future<void> _createPassword() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    if (!_isPasswordValid || !_agreedToTerms) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', _passwordController.text);

    context.read<CreateWalletCubit>().createWallet(_passwordController.text);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => WalletScreen()),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Widget _buildPasswordEntryScreen() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Image.asset('assets/logo.png', height: 150),
          ),
        ),
        SizedBox(height: 48),
        FadeTransition(
          opacity: _fadeAnimation,
          child: Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 24),
        SlideTransition(
          position: _slideAnimation,
          child: _buildPasswordField(
            controller: _passwordController,
            hint: 'Enter your password',
          ),
        ),
        SizedBox(height: 24),
        SlideTransition(
          position: _slideAnimation,
          child: ElevatedButton(
            child: Text('Unlock', style: TextStyle(fontSize: 18)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: EdgeInsets.symmetric(horizontal: 48, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: _verifyPassword,
          ),
        ),
      ],
    );
  }

  Widget _buildCreatePasswordScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Password',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(
          'This unlocks your Simple wallet only on this device',
          style: TextStyle(color: Colors.grey),
        ),
        SizedBox(height: 32),
        _buildPasswordField(
          controller: _passwordController,
          hint: 'Enter new password',
          onChanged: _validatePassword,
          errorText: _passwordError,
        ),
        SizedBox(height: 16),
        _buildPasswordField(
          controller: _confirmPasswordController,
          hint: 'Confirm password',
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: _agreedToTerms,
              onChanged: (value) {
                setState(() {
                  _agreedToTerms = value ?? false;
                });
              },
              fillColor: MaterialStateProperty.resolveWith((states) => Colors.orange),
            ),
            Expanded(
              child: Text(
                'I understand that Simple cannot recover this password for me.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
        Spacer(),
        ElevatedButton(
          child: Text('CREATE WALLET'),
          onPressed: (_isPasswordValid && _agreedToTerms) ? _createPassword : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    Function(String)? onChanged,
    String? errorText,
  }) {
    return TextField(
      controller: controller,
      obscureText: true,
      onChanged: onChanged,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white54),
        errorText: errorText,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.orange, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(Icons.lock, color: Colors.orange),
        fillColor: Colors.grey[900],
        filled: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _isCreatingPassword
              ? _buildCreatePasswordScreen()
              : _buildPasswordEntryScreen(),
        ),
      ),
    );
  }
}