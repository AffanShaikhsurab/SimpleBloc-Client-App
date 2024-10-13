import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simplicity_coin/screens/recieve_screen.dart';
import 'package:simplicity_coin/screens/sendTransaction_screen.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>(); // ScaffoldKey

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // Set the key to the Scaffold
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Smart Chain', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer(); // Use ScaffoldKey to open the drawer
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(), // Add the drawer here
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black,
              Colors.black.withOpacity(0.95),
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _animation,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 20),
                  _buildAccountCard(),
                  SizedBox(height: 20),
                  _buildActionButtons(),
                  SizedBox(height: 20),
                  Expanded(child: _buildTransactionsList()),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Drawer widget
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.orange,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account 1', style: TextStyle(color: Colors.black, fontSize: 18)),
                Text('Balance: \$6750753.75', style: TextStyle(color: Colors.black54, fontSize: 16)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.orange),
            title: Text('Activity'),
            onTap: () {
              // Handle Activity navigation
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.share, color: Colors.orange),
            title: Text('Share Public Address'),
            onTap: () {
              // Handle sharing public address
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.search, color: Colors.orange),
            title: Text('BSCscan'),
            onTap: () {
              // Handle BSCscan navigation
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.settings, color: Colors.orange),
            title: Text('Settings'),
            onTap: () {
              // Handle settings navigation
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.support, color: Colors.orange),
            title: Text('Support'),
            onTap: () {
              // Handle support navigation
              Navigator.pop(context); // Close the drawer
            },
          ),
          ListTile(
            leading: Icon(Icons.block, color: Colors.orange),
            title: Text('Block'),
            onTap: () {
              // Handle block function
              Navigator.pop(context); // Close the drawer
            },
          ),
        ],
      ),
    );
  }

  // Existing widgets like _buildAccountCard, _buildActionButtons, _buildTransactionsList, etc.
  Widget _buildAccountCard() {
    return Hero(
      tag: 'accountCard',
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.3),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Account 1', style: TextStyle(color: Colors.black, fontSize: 18)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('3.875 ETH', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('\$7603.75 +5.4%', style: TextStyle(color: Colors.black54, fontSize: 16)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Network: Smart Chain', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Action Buttons for Send and Receive
  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        GestureDetector(
          child: _buildActionButton(Icons.arrow_downward, 'Receive'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => ReceiveScreen()));
          },
        ),
        GestureDetector(
          child: _buildActionButton(Icons.arrow_upward, 'Send'),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SendTransactionScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[800],
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.grey[900]!,
                blurRadius: 5,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white),
        ),
        SizedBox(height: 8),
        Text(label, style: TextStyle(color: Colors.white)),
      ],
    );
  }

  // Transaction List Widget
  Widget _buildTransactionsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('RECENT TRANSACTIONS', style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return _buildTransactionItem(
                icon: index % 2 == 0 ? Icons.arrow_upward : Icons.arrow_downward,
                title: index % 2 == 0 ? 'Sent ETH' : 'Received ETH',
                amount: '0.${index + 1} ETH',
                date: DateTime.now().subtract(Duration(days: index)),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem({required IconData icon, required String title, required String amount, required DateTime date}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: icon == Icons.arrow_upward ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text(DateFormat('dd MMM yyyy, hh:mm a').format(date), style: TextStyle(color: Colors.white54)),
              ],
            ),
          ),
          Text(amount, style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
