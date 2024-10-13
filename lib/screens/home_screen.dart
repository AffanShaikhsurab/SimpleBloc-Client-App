import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/wallet_bloc.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simplicity Coin'),
      ),
      body: BlocBuilder<WalletBloc, WalletState>(
        builder: (context, state) {
          if (state is WalletInitial) {
            return Center(
              child: ElevatedButton(
                child: Text('Create Wallet'),
                onPressed: () {
                  BlocProvider.of<WalletBloc>(context).add(CreateWallet());
                },
              ),
            );
          } else if (state is WalletLoading) {
            return Center(child: CircularProgressIndicator());
          } else if (state is WalletLoaded) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Address: ${state.wallet.getAddress()}'),
                Text('Balance: ${state.balance}'),
                ElevatedButton(
                  child: Text('Send Transaction'),
                  onPressed: () {
                    // TODO: Implement send transaction UI
                  },
                ),
                ElevatedButton(
                  child: Text('View Transactions'),
                  onPressed: () {
                    BlocProvider.of<WalletBloc>(context).add(GetTransactions());
                  },
                ),
              ],
            );
          } else if (state is WalletError) {
            return Center(child: Text('Error: ${state.error}'));
          }
          return Container();
        },
      ),
    );
  }
}