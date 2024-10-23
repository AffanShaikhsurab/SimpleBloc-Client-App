import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pointycastle/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/services/account_service.dart';
// Enum to represent the state of CreateWalletCubit
enum CreateWalletState {
  initial,
  loading,
  success,
  failure,
  keysCreated,
  phraseKeyCreated
}
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
Future<void> generateAndStorePasskey() async {
    emit(CreateWalletState.loading);
    try {
      final account = await WalletClient().createAccount();
      final privateKey = account['privateKey'];

      
      // Convert private key to mnemonic
      final mnemonic = await WalletClient().convertToMnemonic(privateKey);
      
      await _prefs.setStringList("passkey", mnemonic);
      await _prefs.setString("privateKey", privateKey);
      await _prefs.setString("publicKey", account['public_address']);
      await _storeKeysLocally(account['public_address'], privateKey);
      emit(CreateWalletState.phraseKeyCreated);
    } catch (e) {
      print("Error generating passkey: $e");
      emit(CreateWalletState.failure);
    }
  }




Future<void> _storeKeysLocally(String publicKey, String privateKey) async {
  try {
    // Get the current directory where the app is running
    final currentDir = Directory.current.path;
    final filePath = path.join(currentDir, 'server/accounts.json');
    final file = File(filePath);

    print("The public key is $publicKey and the private key is $privateKey");

    List<Map<String, dynamic>> accounts = [];
    if (await file.exists()) {
      final contents = await file.readAsString();
      accounts = List<Map<String, dynamic>>.from(json.decode(contents));
    }

    final newAccount = {
      "publicKey": publicKey,
      "privateKey": privateKey,
    };

    // Find the index of the existing account with the same public key, if any
    final existingIndex = accounts.indexWhere((a) => a["publicKey"] == newAccount["publicKey"]);

    if (existingIndex != -1) {
      // Overwrite the existing account
      accounts[existingIndex] = newAccount;
      print("Existing account updated for public key: $publicKey");
    } else {
      // Add new account
      accounts.add(newAccount);
      print("New account added for public key: $publicKey");
    }

    // Write the updated accounts list to the file
    await file.writeAsString(json.encode(accounts));
    print("Keys stored successfully in ${file.path}");
  } catch (e) {
    print("Error storing keys locally: $e");
    rethrow;
  }
}

 Future<void> validatedPasskey(List<String> mnemonic) async {
    emit(CreateWalletState.loading);
    try {
      final keyPair = await WalletClient().convertToPrivateKey(mnemonic);
      await _prefs.setStringList("passkey", mnemonic);
      await _prefs.setString("privateKey", keyPair['private_key']!);
      await _prefs.setString("publicKey", keyPair['public_key']!);
      _storeKeysLocally(keyPair['public_key']!, keyPair['private_key']!);
      emit(CreateWalletState.phraseKeyCreated);
    } catch (e) {
      print("Error validating passkey: $e");
      emit(CreateWalletState.failure);
    }
  }


  Future<void> verifyRecoveryPhrase(List<String> enteredPhrase) async {
    emit(CreateWalletState.loading);
    try {
      final storedPhrase = _prefs.getStringList("passkey");
      if (storedPhrase != null && listEquals(enteredPhrase, storedPhrase)) {
        emit(CreateWalletState.success);
      } else {
        emit(CreateWalletState.failure);
      }
    } catch (e) {
      print("Error verifying recovery phrase: $e");
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
      await _prefs.setString("privateKey", account['private_key']);
      await _prefs.setString("publicKey", account['public_address']);
      emit(CreateWalletState.keysCreated);
    } catch (e) {
      print("Error creating keys: $e");
      emit(CreateWalletState.failure);
    }
  }

  Future<void> readAccount() async {
  try {

    final accountJson = _prefs.getString("publicKey"); // Retrieve JSON string from SharedPreferences
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
      final passkey = _prefs.getStringList("passkey");
      if (passkey != null) {
        emit(passkey);
      } else {
        emit([]);
      }
    } catch (e) {
      print("Error reading passkey: $e");
      emit([]);
    }
  }
}
