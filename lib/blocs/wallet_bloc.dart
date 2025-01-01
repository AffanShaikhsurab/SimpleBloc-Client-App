import 'dart:async';
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/data/Transaction.dart';
import '../services/wallet_service.dart';

// More detailed state class to represent the state of WalletCubit
// First, let's update the WalletState to include transaction status
abstract class WalletState {}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletTransactionInProgress extends WalletState {
  final double currentBalance;
  final List<Transaction> transactions;
  
  WalletTransactionInProgress(this.currentBalance, this.transactions);
}

class WalletLoaded extends WalletState {
  final double balance;
  final List<Transaction> transactions;

  WalletLoaded(this.balance, this.transactions);
}

class WalletError extends WalletState {
  final String message;
  final WalletState? previousState;

  WalletError(this.message, {this.previousState});
}
// Update the WalletCubit with improved state management
class WalletCubit extends Cubit<WalletState> {
  final SharedPreferences _prefs;
  final WalletService _walletService;
  Timer? _refreshTimer;

  WalletCubit(this._prefs, this._walletService) : super(WalletInitial()) {
    _initializeWallet();
  }

  Future<void> _initializeWallet() async {
    await getBalance();
    // Set up periodic refresh every 30 seconds
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (_) => _refreshWallet());
  }

  Future<String> sendTransaction(String recipient, double amount) async {
    if (state is WalletTransactionInProgress) {
      return 'A transaction is already in progress';
    }

    try {
      // Get current state data
      final currentState = state;
      double currentBalance = 0.0;
      List<Transaction> currentTransactions = [];
      
      if (currentState is WalletLoaded) {
        currentBalance = currentState.balance;
        currentTransactions = currentState.transactions;
      }

      // Emit transaction in progress state
      emit(WalletTransactionInProgress(currentBalance, currentTransactions));

      // Send transaction
      final result = await _walletService.sendTransaction(recipient, amount);
      
      // Wait a moment for the transaction to propagate
      await Future.delayed(Duration(seconds: 2));
      
      // Refresh wallet data
      await getBalance();
      
      return result;
    } catch (e) {
      print("Error sending transaction: $e");
      emit(WalletError("Failed to send transaction: ${e.toString()}", 
          previousState: state));
      return "Failed to send transaction: ${e.toString()}";
    }
  }

  Future<void> _refreshWallet() async {
    // Don't refresh if a transaction is in progress
    if (state is WalletTransactionInProgress) return;
    await getBalance();
  }

  Future<void> getBalance() async {
    try {
      // Don't show loading state if we're already in transaction progress
      if (!(state is WalletTransactionInProgress)) {
        emit(WalletLoading());
      }
      
      double balance = await _walletService.getBalance();
      List<Transaction> transactions = await _walletService.getTransactions();
      emit(WalletLoaded(balance, transactions));
    } catch (e) {
      print("Error loading wallet: $e");
      emit(WalletError("Failed to load wallet: ${e.toString()}"));
    }
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}