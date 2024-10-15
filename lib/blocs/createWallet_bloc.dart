import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/services/account_service.dart';

// Enum to represent the state of CreateWalletCubit
enum CreateWalletState { initial, loading, success, failure , keysCreated }

class CreateWalletCubit extends Cubit<CreateWalletState> {
  final SharedPreferences _prefs;
  var accountCreated = false;
  CreateWalletCubit(this._prefs) : super(CreateWalletState.initial);

  Future<void> createWallet(String password) async {
    emit(CreateWalletState.loading);
    try {
      await _prefs.setString("password", password); // Store password
      emit(CreateWalletState.success);
    } catch (e) {
      print("the issue is $e");
      emit(CreateWalletState.failure);
    }
  }

  Future<void> storePasskey(List<String> passkey) async {
    emit(CreateWalletState.loading);
    try {
      await _prefs.setStringList("passkey", passkey); // Store passkey as a List<String>
      emit(CreateWalletState.success);
    } catch (e) {
      emit(CreateWalletState.failure);
    }
  }

   Future<void> createAccount() async {
    emit(CreateWalletState.loading);
    try {
      await _prefs.setBool("accountCreated", true); // Store passkey as a List<String>
      emit(CreateWalletState.success);
    } catch (e) {
      emit(CreateWalletState.failure);
    }
  }

   Future<void> isAccountCreated() async {
    emit(CreateWalletState.loading);
    if (_prefs.getBool("accountCreated") == true) {
      emit(CreateWalletState.success);
    }else{
      emit(CreateWalletState.failure);
    }      
      emit(CreateWalletState.success);
   
  }
  Future<void> createKeys() async {
    if (state == CreateWalletState.keysCreated) {
      return;
    }

    emit(CreateWalletState.loading);
    try {
      final account = await WalletClient().createAccount();
      String accountJson = jsonEncode(account);
      await _prefs.setString("account", accountJson);
      emit(CreateWalletState.keysCreated);
    } catch (e) {
      print("Error creating keys: $e");
      emit(CreateWalletState.failure);
    }
  }

  Future<void> readAccount() async {
  try {

    final accountJson = _prefs.getString("account"); // Retrieve JSON string from SharedPreferences
    if (accountJson != null) {
      final account = jsonDecode(accountJson); // Convert JSON string back to a Dart object
      // Use the account object as needed
    } else {
      // Handle the case where account is not found
    }
  } catch (e) {
    print("Error reading account: $e");
  }
}
}




class PasskeyCubit extends Cubit<List<String>> {
  final SharedPreferences _prefs;

  PasskeyCubit(this._prefs) : super([]);

  Future<void> readPasskey() async {
    try {
      final passkey = _prefs.getStringList("passkey"); // Retrieve passkey list
      if (passkey != null) {
        emit(passkey);
      } else {
        emit([]); // Emit empty list if no passkey found
      }
    } catch (e) {
      emit([]);
    }
  }
}
