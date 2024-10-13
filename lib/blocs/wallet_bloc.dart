
// lib/blocs/wallet_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/wallet_service.dart';
import '../models/wallet.dart';

// Events
abstract class WalletEvent {}

class CreateWallet extends WalletEvent {}
class LoadWallet extends WalletEvent {}
class SendTransaction extends WalletEvent {
  final String recipient;
  final double amount;
  SendTransaction(this.recipient, this.amount);
}
class GetTransactions extends WalletEvent {}
class GetBalance extends WalletEvent {}

// States
abstract class WalletState {}

class WalletInitial extends WalletState {}
class WalletLoading extends WalletState {}
class WalletLoaded extends WalletState {
  final Wallet wallet;
  final double balance;
  WalletLoaded(this.wallet, this.balance);
}
class WalletError extends WalletState {
  final String error;
  WalletError(this.error);
}

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final WalletService _walletService;

  WalletBloc(this._walletService) : super(WalletInitial());

  @override
  Stream<WalletState> mapEventToState(WalletEvent event) async* {
    if (event is CreateWallet) {
      yield WalletLoading();
      try {
        final wallet = Wallet();
        final balance = await _walletService.getBalance();
        yield WalletLoaded(wallet, balance);
      } catch (e) {
        yield WalletError('Failed to create wallet: $e');
      }
    } else if (event is LoadWallet) {
      yield WalletLoading();
      try {
        // Implement wallet loading logic
        yield WalletLoaded(_walletService.wallet, await _walletService.getBalance());
      } catch (e) {
        yield WalletError('Failed to load wallet: $e');
      }
    } else if (event is SendTransaction) {
      yield WalletLoading();
      try {
        await _walletService.sendTransaction(event.recipient, event.amount);
        final balance = await _walletService.getBalance();
        yield WalletLoaded(_walletService.wallet, balance);
      } catch (e) {
        yield WalletError('Failed to send transaction: $e');
      }
    } else if (event is GetTransactions) {
      yield WalletLoading();
      try {
        final transactions = await _walletService.getTransactions();
        // You might want to create a new state for transactions or modify WalletLoaded
        yield WalletLoaded(_walletService.wallet, await _walletService.getBalance());
      } catch (e) {
        yield WalletError('Failed to get transactions: $e');
      }
    } else if (event is GetBalance) {
      yield WalletLoading();
      try {
        final balance = await _walletService.getBalance();
        yield WalletLoaded(_walletService.wallet, balance);
      } catch (e) {
        yield WalletError('Failed to get balance: $e');
      }
    }
  }
}
