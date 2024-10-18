import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:pointycastle/api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simplicity_coin/data/Transaction.dart';

class WalletService {
  Timer? _nodeUpdateTimer;
  final Duration _nodeUpdateInterval = Duration(minutes: 5);
  final Duration _nodeTtl = Duration(minutes: 30);
  String privateKey = "";
  String publicKey = "";
  Map<String, int> nodesTtl = {};
    String baseUrl = "https://ecdsa-server.onrender.com";

  WalletService() {
    _startNodeUpdateTimer();
    _updateKeys();
  }

  void _updateKeys() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final account = _prefs.getString("account");
    if (account == null) {
      throw Exception('No account found in SharedPreferences');
    }
        final accountJson = json.decode(account);
    print("accoutns  ${accountJson["public_address"].toString()}");

    privateKey = accountJson['privateKey'];
    publicKey = accountJson['public_address'];
  }

  void _startNodeUpdateTimer() {
    _nodeUpdateTimer = Timer.periodic(_nodeUpdateInterval, (_) => updateKnownNodes());
  }

  Future<List<String>?> getServers() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    List<String>? servers = pref.getStringList("nodes");
    return servers;
  }

  Future<void> updateKnownNodes() async {
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    List<String>? servers = await getServers();
    if (servers == null) {
      throw Exception('No nodes found in SharedPreferences');
    }
    for (var server in servers) {
      try {
        final response = await http.get(Uri.parse('$server/nodes'));
        if (response.statusCode == 200) {
          print("Updated nodes from $server the nodes are ${response.body}");
          List<String> nodes = json.decode(response.body)['nodes'] as List<String>;
          List<String> new_nodes = []..addAll(nodes)..addAll(servers);
          _prefs.setStringList('nodes', new_nodes);
          
          // Update nodesTtl
          for (var node in new_nodes) {
            if (!nodesTtl.containsKey(node)) {
              nodesTtl[node] = DateTime.now().add(_nodeTtl).millisecondsSinceEpoch;
            }
          }
        }
      } catch (e) {
        print('Error updating nodes from $server: $e');
      }
    }
    removeExpiredNodes();
  }

  void removeExpiredNodes() {
    final now = DateTime.now().millisecondsSinceEpoch;
    nodesTtl.removeWhere((node, expiry) => expiry < now);
  }

  Future<Map<String, dynamic>> prepareTransactionForSending(String recipient, double amount) async {
  
    final data = await signTransaction( privateKey , recipient, amount);

    return data;
  }

  String generateTransactionId() {
    // Implement a method to generate a unique transaction ID
    return DateTime.now().millisecondsSinceEpoch.toString() + Random().nextInt(1000).toString();
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
 



Future<String> sendTransaction(String recipient, double amount) async {
  try {
    await updateKnownNodes();
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final nodes_list = _prefs.getStringList("nodes");
    
    if (nodes_list == null || nodes_list.isEmpty) {
      throw Exception('No nodes found in SharedPreferences');
    }

    final transactionData = await prepareTransactionForSending(recipient, amount);

    // Shuffle the list of nodes to randomize the order
    nodes_list.shuffle(Random());

    for (var node in nodes_list) {
      try {
        print("Sending transaction to $node");
        final response = await http.post(
          Uri.parse('$node/transactions/new'),
          body: json.encode(transactionData),
          headers: {'Content-Type': 'application/json'},
        ).timeout(Duration(seconds: 10)); // Add a timeout to prevent long waits

        print("Response from $node: ${response.body}");
        
        if (response.statusCode == 200) {
          return 'Transaction sent successfully to $node!';
        }
      } catch (e) {
        print('Error sending transaction to $node: $e');
        // Continue to the next node if there's an error
      }
    }

    // If we've tried all nodes and none succeeded
    return 'Failed to send transaction to any available node. Please try again later.';
  } catch (e) {
    print('Error in sendTransaction: $e');
    return 'Error: ${e.toString()}';
  }
}

  Future<List<Transaction>> getTransactions() async {
    await updateKnownNodes();
    SharedPreferences _prefs = await SharedPreferences.getInstance();
    final nodes_list = _prefs.getStringList("nodes");
    if (nodes_list == null) {
      throw Exception('No nodes found in SharedPreferences');
    }

    final number = Random().nextInt(max(1, nodes_list.length));
    final node = nodes_list[number];

    for (var node in nodes_list) {
      try {
        final response = await http.get(Uri.parse('$node/chain'));
        if (response.statusCode == 200) {
          final chain = json.decode(response.body)['chain'];
          List<Transaction> userTransactions = [];
          for (var block in chain) {
            for (var tx in block['transactions']) {
              if (tx['transaction']['sender'] == publicKey ||
                  tx['transaction']['recipient'] == publicKey) {
                bool isOutgoing = tx['transaction']['sender'] == publicKey;
                DateTime timestamp =DateTime.fromMillisecondsSinceEpoch(( tx['transaction']['timestamp'] * 1000).toInt());
                userTransactions.add(
                  Transaction(
                    amount: tx['transaction']['amount'],
                    timestamp: timestamp,
                    transactionId: tx['transaction']['transaction_id'],
                    sender: tx['transaction']['sender'],
                    recipient: tx['transaction']['recipient'],
                    isOutgoing: isOutgoing,
                  ),
                );
              }
            }
          }
          return userTransactions;
        }
      } catch (e) {
        print('Error retrieving transactions from $node: $e');
      }
    }

    throw Exception('Failed to get transactions from any available node');
  }

  Future<double> getBalance() async {
    try {
      final transactions = await getTransactions();
      double balance = 0; 
      for (var tx in transactions) {
        if (tx.recipient == publicKey) {
          balance += tx.amount;
        }
        if (tx.sender == publicKey) {
          balance -= tx.amount;
        }
      }
      print("balance is $balance");
      return balance;
    } catch (e) {
      throw Exception('Error calculating balance: $e');
    }
  }

  Future<void> addNode(String nodeUrl) async {
    if (!nodesTtl.containsKey(nodeUrl)) {
      nodesTtl[nodeUrl] = DateTime.now().add(_nodeTtl).millisecondsSinceEpoch;
      await updateKnownNodes();
    }
  }

  void dispose() {
    _nodeUpdateTimer?.cancel();
  }
}