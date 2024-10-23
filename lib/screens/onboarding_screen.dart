import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/blocs/createWallet_bloc.dart';
import 'package:simplicity_coin/blocs/wallet_bloc.dart';
import 'package:simplicity_coin/screens/createWallet_screen.dart';
import 'package:simplicity_coin/screens/home_screen.dart';
import 'package:simplicity_coin/screens/loadWallet_screen.dart';
import 'package:simplicity_coin/main.dart';
import 'package:simplicity_coin/screens/password_screen.dart';
import 'package:simplicity_coin/screens/wallet_screen.dart';
import 'package:simplicity_coin/services/wallet_service.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  final PageController _pageController = PageController();
  bool _isAccountCreated = false;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to Simplicity!',
      'description': 'Trusted by millions, Simplicity Wallets is a secure wallet making the world of web3 accessible to all.',
      'image': './assest/coin.png',
    },
    {
      'title': 'Manage your digital assets',
      'description': 'Store, spend and send digital assets .',
      'image': 'assest/wallet.png',
    },
    {
      'title': 'Your gateway to web3',
      'description': 'Login with Simplicity and make transactions to invest, earn, play games, sell and more!',
      'image': 'assest/gateway.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkAccountCreationStatus();
  }
 Future<void> _checkPasswordStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? storedPassword = prefs.getString('password');

    if (storedPassword != null) {
      // final account = prefs.getString('account');
      // context.read<CreateWalletCubit>()
      // Password exists, navigate to PasswordEntryScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => PasswordEntryScreen()),
      );
    } else {
      // No password set, continue with onboarding
      _checkAccountCreationStatus();
    }
  }
  Future<void> _checkAccountCreationStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? isCreated = prefs.getBool("accountCreated");

    if (isCreated == true) {
      
      // Account is already created, skip to the main menu
        _checkAccountCreationStatus();
    
    } else {
      // Stay on the onboarding screen
      setState(() {
        _isAccountCreated = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  return OnboardingPage(
                    title: _pages[index]['title']!,
                    description: _pages[index]['description']!,
                    image: _pages[index]['image']!,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    child: Text('Skip', style: TextStyle(color: Colors.white)),
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MainMenuScreen()),
                    ),
                  ),
                  ElevatedButton(
                    child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                    onPressed: () {
                      if (_currentPage < _pages.length - 1) {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => MainMenuScreen()),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage extends StatelessWidget {
  final String title;
  final String description;
  final String image;

  OnboardingPage({required this.title, required this.description, required this.image});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(image, height: 150),
        SizedBox(height: 32),
        Text(title, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Text(description, textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        ),
      ],
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset('./assest/logo.png', height: 150),
              SizedBox(height: 32),
              Text(
                'Welcome to Simple',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              Text(
                'Your secure gateway to the decentralized web',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                child: Text('Create a New Wallet'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CreateWalletScreen())),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                child: Text('Load Existing Wallet'),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LoadWalletScreen())),
              ),
              SizedBox(height: 16),
              OutlinedButton(
                child: Text('Exit', style: TextStyle(color: Colors.orange)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
