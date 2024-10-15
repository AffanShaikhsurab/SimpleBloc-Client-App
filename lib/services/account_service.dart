import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletClient {
    String baseUrl = "https://ecdsa-server.onrender.com";
    var _accountCreated = false;

   Future<Map<String, dynamic>> createAccount() async {
    if (_accountCreated) {
      throw Exception('Account already created');
    }
    final response = await http.get(Uri.parse('$baseUrl/create_account'));
    if (response.statusCode == 200) {
      _accountCreated = true;
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create account');
    }
  }


  Future<Map<String, dynamic>> signTransaction(String privateKey, String recipient, double amount) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sign_transaction'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'private_key': privateKey,
        'recipient': recipient,
        'amount': amount,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to sign transaction');
    }
  }
}

