import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/wallet.dart';

class WalletService {
  final Wallet wallet;
  Timer? _nodeUpdateTimer;
  final Duration _nodeUpdateInterval = Duration(minutes: 5);
  final Duration _nodeTtl = Duration(minutes: 30);

  WalletService(this.wallet) {
    _startNodeUpdateTimer();
  }

  void _startNodeUpdateTimer() {
    _nodeUpdateTimer = Timer.periodic(_nodeUpdateInterval, (_) => updateKnownNodes());
  }

  Future<void> updateKnownNodes() async {
    for (var server in wallet.servers) {
      try {
        final response = await http.get(Uri.parse('$server/nodes'));
        if (response.statusCode == 200) {
          final nodes = json.decode(response.body)['nodes'] as List<dynamic>;
          for (var node in nodes) {
            if (!wallet.nodesTtl.containsKey(node)) {
              wallet.nodesTtl[node] = DateTime.now().add(_nodeTtl).millisecondsSinceEpoch;
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
    wallet.nodesTtl.removeWhere((node, expiry) => expiry < now);
  }

  Future<String> sendTransaction(String recipient, double amount) async {
    await updateKnownNodes();

    final transactionData = wallet.prepareTransactionForSending(recipient, amount);
    final availableNodes = wallet.nodesTtl.keys.toList();

    if (availableNodes.isEmpty) {
      throw Exception('No available nodes to send transaction');
    }

    for (var node in availableNodes) {
      try {
        final response = await http.post(
          Uri.parse('$node/transactions/new'),
          body: json.encode(transactionData),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return 'Transaction sent successfully!';
        }
      } catch (e) {
        print('Error sending transaction to $node: $e');
      }
    }

    throw Exception('Failed to send transaction to any available node');
  }

  Future<List> getTransactions() async {
    await updateKnownNodes();
    final availableNodes = wallet.nodesTtl.keys.toList();

    if (availableNodes.isEmpty) {
      throw Exception('No available nodes to fetch transactions');
    }

    for (var node in availableNodes) {
      try {
        final response = await http.get(Uri.parse('$node/chain'));
        if (response.statusCode == 200) {
          final chain = json.decode(response.body)['chain'];
          final userTransactions = [];
          for (var block in chain) {
            for (var tx in block['transactions']) {
              if (tx['transaction']['sender'] == wallet.getAddress() ||
                  tx['transaction']['recipient'] == wallet.getAddress()) {
                userTransactions.add(tx);
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
        if (tx['transaction']['recipient'] == wallet.getAddress()) {
          balance += tx['transaction']['amount'];
        }
        if (tx['transaction']['sender'] == wallet.getAddress()) {
          balance -= tx['transaction']['amount'];
        }
      }
      return balance;
    } catch (e) {
      throw Exception('Error calculating balance: $e');
    }
  }

  Future<void> addNode(String nodeUrl) async {
    if (!wallet.nodesTtl.containsKey(nodeUrl)) {
      wallet.nodesTtl[nodeUrl] = DateTime.now().add(_nodeTtl).millisecondsSinceEpoch;
      await updateKnownNodes();
    }
  }

  void dispose() {
    _nodeUpdateTimer?.cancel();
  }
}