import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/data/Transaction.dart';
import '../services/wallet_service.dart';

// More detailed state class to represent the state of WalletCubit
abstract class WalletState {}

class WalletInitial extends WalletState {}

class WalletLoading extends WalletState {}

class WalletLoaded extends WalletState {
  final double balance;
  final List<Transaction> transactions;

  WalletLoaded(this.balance, this.transactions);
}

class WalletError extends WalletState {
  final String message;

  WalletError(this.message);
}

class WalletCubit extends Cubit<WalletState> {
  final SharedPreferences _prefs;
  final WalletService _walletService;

  WalletCubit(this._prefs, this._walletService) : super(WalletInitial());

 Future<String> sendTransaction(String recipient, double amount) async {
    emit(WalletLoading());
    try {
      String result = await _walletService.sendTransaction(recipient, amount);
      await _loadWallet(); // Reload wallet data after transaction
      return result;
    } catch (e) {
      print("Error sending transaction: $e");
      emit(WalletError("Failed to send transaction: ${e.toString()}"));
      return "Failed to send transaction: ${e.toString()}";
    }
  }

  Future<void> getBalance() async {
    emit(WalletLoading());
    try {
      double balance = await _walletService.getBalance();
      List<Transaction> transactions = await _walletService.getTransactions();
      emit(WalletLoaded(balance, transactions));
    } catch (e) {
      print("Error getting balance: $e");
      emit(WalletError("Failed to get balance: ${e.toString()}"));
    }
  }

  Future<void> getTransactions() async {
    emit(WalletLoading());
    try {
      double balance = await _walletService.getBalance();
      List<Transaction> transactions = await _walletService.getTransactions();
      emit(WalletLoaded(balance, transactions));
    } catch (e) {
      print("Error getting transactions: $e");
      emit(WalletError("Failed to get transactions: ${e.toString()}"));
    }
  }

  Future<void> _loadWallet() async {
    emit(WalletLoading());
    try {
      double balance = await _walletService.getBalance();
      List<Transaction> transactions = await _walletService.getTransactions();
      emit(WalletLoaded(balance, transactions));
    } catch (e) {
      print("Error loading wallet: $e");
      emit(WalletError("Failed to load wallet: ${e.toString()}"));
    }
  }

  // Uncomment and implement this method if you need to store wallet data
  // Future<void> _storeWallet(Wallet wallet) async {
  //   try {
  //     final walletJson = jsonEncode(wallet.toJson());
  //     await _prefs.setString("wallet", walletJson);
  //   } catch (e) {
  //     print("Error storing wallet: $e");
  //     emit(WalletError("Failed to store wallet: ${e.toString()}"));
  //   }
  // }
}