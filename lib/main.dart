import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/screens/home_screen.dart';
import 'package:simplicity_coin/screens/onboarding_screen.dart';
import 'package:simplicity_coin/screens/password_screen.dart';
import 'blocs/createWallet_bloc.dart';
import 'blocs/wallet_bloc.dart';
import 'services/wallet_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SharedPreferences instance
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setStringList("nodes", [
    "https://simplicity-server1.onrender.com",
    "https://simplicity-server.onrender.com",
  ]);

  // Check if the user is logged in
  bool isLoggedIn = prefs.getBool("accountCreated") ?? false;
  print(
    "the logged in status is " +
        isLoggedIn.toString() 
  );
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => CreateWalletCubit(prefs),
        ),
        BlocProvider(
          create: (_) => PasskeyCubit(prefs),
        ),
        BlocProvider(
          create: (_) => WalletCubit(prefs, WalletService()),
        ),
      ],
      child: MyApp(isLoggedIn: isLoggedIn),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  MyApp({required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MetaMask Inspired App',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.white),
          bodySmall: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.black, backgroundColor: Colors.orange,
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: isLoggedIn ? PasswordEntryScreen() : OnboardingScreen(),
    );
  }
}
// ... (previous code remains the same)

class TransactionDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> transaction;

  TransactionDetailsScreen({required this.transaction});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Transaction Details'), backgroundColor: Colors.black),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Type: ${transaction['type']}', style: Theme.of(context).textTheme.headlineMedium),
              SizedBox(height: 16),
              Text('Amount: ${transaction['amount']}', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: 8),
              Text(
                transaction['type'] == 'Sent'
                    ? 'To: ${transaction['to']}'
                    : 'From: ${transaction['from']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              SizedBox(height: 8),
              Text('Date: ${transaction['date']}', style: Theme.of(context).textTheme.bodySmall),
              SizedBox(height: 32),
              ElevatedButton(
                child: Text('View on Block Explorer'),
                onPressed: () {
                  // Implement opening transaction in block explorer
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
