import 'dart:convert';
import 'package:http/http.dart' as http;

class WalletClient {
    String baseUrl = "https://ecdsa-server.onrender.com";
    var _accountCreated = false;
    String phraseKeyUrl = "https://phrase-key-server.onrender.com";

   Future<Map<String, dynamic>> createAccount() async {
    if (_accountCreated) {
      throw Exception('Account already created');
    }
    final response = await http.get(Uri.parse('$baseUrl/create_account'));
    if (response.statusCode == 200) {
      _accountCreated = true;
      print(response.body);
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create account');
    }
  }
Future<List<String>> convertToMnemonic(String privateKey) async {
  final response = await http.post(
    Uri.parse('$phraseKeyUrl/private_key_to_mnemonic'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'private_key': privateKey}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    
    // Ensure data['mnemonic'] is treated as a List<String>
    List<String> mnemonic = List<String>.from(data['mnemonic']);
    return mnemonic;
  } else {
    throw Exception('Failed to convert private key to mnemonic');
  }
}

  /// Converts a mnemonic to a private key using an external API.
  ///
  /// [mnemonic] is the mnemonic to convert.
  ///
  /// Returns the private key as a string.
  ///
  /// Throws an [Exception] if the API request fails.

  /// Converts a mnemonic to a private key using an external API.
  ///
  /// [mnemonic] is the mnemonic phrase represented as a list of strings.
  ///
  /// Returns the private key as a string.
  ///
  /// Throws an [Exception] if the API request fails.
 
  Future<Map<String, String>> convertToPrivateKey(List<String> mnemonic) async {
    try {
      final response = await http.post(
        Uri.parse('$phraseKeyUrl/mnemonic_to_private_key'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mnemonic': mnemonic}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'private_key': data['private_key'],
          'public_key': data['public_key'],
        };
      } else {
        // Handle non-200 status codes
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // Handle network errors or other exceptions
      throw Exception('Failed to convert mnemonic to private key: $e');
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

