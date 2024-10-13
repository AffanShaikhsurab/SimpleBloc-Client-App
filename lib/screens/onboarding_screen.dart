import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:simplicity_coin/main.dart';
import 'package:simplicity_coin/screens/createWallet_screen.dart';
import 'package:simplicity_coin/screens/loadWallet_screen.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}



class _OnboardingScreenState extends State<OnboardingScreen> {

  int _currentPage = 0;
  final PageController _pageController = PageController();

  final List<Map<String, String>> _pages = [
    {
      'title': 'Welcome to MetaMask!',
      'description': 'Trusted by millions, Picco Wallets is a secure wallet making the world of web3 accessible to all.',
      'image': 'assets/fox_logo.png',
    },
    {
      'title': 'Manage your digital assets',
      'description': 'Store, spend and send digital assets like tokens, ethereum, unique collectibles.',
      'image': 'assets/wallet.png',
    },
    {
      'title': 'Your gateway to web3',
      'description': 'Login with MetaMask and make transactions to invest, earn, play games, sell and more!',
      'image': 'assets/gateway.png',
    },
  ];

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

Future<bool> isRegistered() async {
            final storage = new FlutterSecureStorage();

        List<String> passkey = (await storage.read(key: "passkey")) as List<String>;

        return passkey != [];
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
        title: Text('MetaMask', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SvgPicture.asset('assets/fox_logo.svg', height: 100),
              SizedBox(height: 32),
              Text(
                'Welcome to MetaMask',
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
