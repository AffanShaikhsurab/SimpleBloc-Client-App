import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:simplicity_coin/blocs/wallet_bloc.dart';
import 'package:simplicity_coin/data/Transaction.dart';
import 'package:simplicity_coin/screens/recieve_screen.dart';
import 'package:simplicity_coin/screens/sendTransaction_screen.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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

    // Load wallet when the screen initializes
    _refreshWallet();
  }

  void _refreshWallet() {
    context.read<WalletCubit>().getBalance();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Smart Chain', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshWallet,
          ),
          IconButton(
            icon: Icon(Icons.qr_code_scanner, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshWallet();
        },
        child: Container(
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
                child: BlocBuilder<WalletCubit, WalletState>(
                  builder: (context, state) {
                    if (state is WalletInitial) {
                      return Center(child: Text('Initializing wallet...', style: TextStyle(color: Colors.white)));
                    } else if (state is WalletLoading) {
                      return Center(child: CircularProgressIndicator());
                    } else if (state is WalletLoaded) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 20),
                          _buildAccountCard(state.balance),
                          SizedBox(height: 20),
                          _buildActionButtons(),
                          SizedBox(height: 20),
                          Expanded(child: _buildTransactionsList(state.transactions)),
                        ],
                      );
                    } else if (state is WalletError) {
                      return Center(child: Text('Error: ${state.message}', style: TextStyle(color: Colors.red)));
                    } else {
                      return Center(child: Text('Unexpected state', style: TextStyle(color: Colors.white)));
                    }
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          BlocBuilder<WalletCubit, WalletState>(
            builder: (context, state) {
              return DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.orange,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Account 1', style: TextStyle(color: Colors.black, fontSize: 18)),
                    if (state is WalletLoaded)
                      Text('Balance: ${state.balance.toStringAsFixed(4)} ETH', 
                           style: TextStyle(color: Colors.black54, fontSize: 16))
                    else
                      Text('Balance: Loading...', style: TextStyle(color: Colors.black54, fontSize: 16)),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.history, color: Colors.orange),
            title: Text('Activity'),
            onTap: () {
              Navigator.pop(context);
              // Refresh transactions
              context.read<WalletCubit>().getTransactions();
            },
          ),
          // ... (other drawer items remain the same)
        ],
      ),
    );
  }

  Widget _buildAccountCard(double balance) {
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
                    Text('${balance.toStringAsFixed(4)} ETH', 
                         style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
                    Text('\$${(balance * 1963.44).toStringAsFixed(2)}', 
                         style: TextStyle(color: Colors.black54, fontSize: 16)),
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

  Widget _buildTransactionsList(List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('RECENT TRANSACTIONS', style: TextStyle(color: Colors.white, fontSize: 16)),
        SizedBox(height: 16),
        Expanded(
          child: transactions.isEmpty
              ? Center(child: Text('No transactions yet', style: TextStyle(color: Colors.white)))
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return _buildTransactionItem(
                      icon: transaction.isOutgoing ? Icons.arrow_upward : Icons.arrow_downward,
                      title: transaction.isOutgoing ? 'Sent ETH' : 'Received ETH',
                      amount: '${transaction.amount} ETH',
                      date: transaction.timestamp,
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