import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/blocs/wallet_bloc.dart';
import 'package:simplicity_coin/data/Transaction.dart';
import 'package:simplicity_coin/screens/mining_scrren.dart';
import 'package:simplicity_coin/screens/onboarding_screen.dart';

import 'package:simplicity_coin/screens/recieve_screen.dart';
import 'package:simplicity_coin/screens/sendTransaction_screen.dart';

class WalletScreen extends StatefulWidget {
  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _refreshWallet();
  }

  void _refreshWallet() {
    context.read<WalletCubit>().getBalance();
  }
 void _logout() async {
    // Add your logout logic here
    var pref = await SharedPreferences.getInstance();
    pref.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => OnboardingScreen()),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF1E1E1E),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 200,
      color: const Color(0xFF2D2D2D),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Smart Chain',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildSidebarButton(
            icon: Icons.account_balance_wallet,
            label: 'Wallet',
            isSelected: true,
          ),
          _buildSidebarButton(
            icon: Icons.electrical_services,
            label: 'Mining',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => MiningDashboard()),
            ),
          ),
           Spacer(),
          _buildSidebarButton(
            icon: Icons.logout,
            label: 'Logout',
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarButton({
    required IconData icon,
    required String label,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: isSelected ? const Color(0xFF3D3D3D) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: Colors.white70, size: 20),
              SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return BlocBuilder<WalletCubit, WalletState>(
      builder: (context, state) {
        if (state is WalletLoading) {
          return Center(child: CircularProgressIndicator());
        }
        if (state is WalletLoaded) {
          return Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildLeftPanel(state),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }
        return Center(
          child: Text('Error loading wallet', style: TextStyle(color: Colors.white)),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border(bottom: BorderSide(color: Colors.grey[850]!)),
      ),
      child: Row(
        children: [
          Text(
            'Wallet Overview',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          Spacer(),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refreshWallet,
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel(WalletLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBalanceCard(state.balance),
        SizedBox(height: 24),
        _buildQuickActions(),
        SizedBox(height: 24),
        Expanded(child: _buildTransactionsList(state.transactions)),
      ],
    );
  }

  Widget _buildBalanceCard(double balance) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF3D3D3D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total Balance', style: TextStyle(color: Colors.white70)),
          SizedBox(height: 8),
          Text(
            '${balance.toStringAsFixed(4)} ETH',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _buildActionButton(
          icon: Icons.arrow_downward,
          label: 'Receive',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ReceiveScreen()),
          ),
        ),
        SizedBox(width: 16),
        _buildActionButton(
          icon: Icons.arrow_upward,
          label: 'Send',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SendTransactionScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF3D3D3D),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white70),
              SizedBox(height: 8),
              Text(label, style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<Transaction> transactions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF3D3D3D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: transactions.isEmpty
                ? Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.white70),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return _buildTransactionItem(transaction);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionItem(Transaction transaction) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[850]!, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: transaction.isOutgoing
                  ? Colors.red.withOpacity(0.2)
                  : Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              transaction.isOutgoing
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              color: Colors.white70,
              size: 16,
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.isOutgoing ? 'Sent' : 'Received',
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(transaction.timestamp),
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${transaction.amount} ETH',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}