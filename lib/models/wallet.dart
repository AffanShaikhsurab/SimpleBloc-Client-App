// lib/models/wallet.dart
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart';

class Wallet {
  final AsymmetricKeyPair<PublicKey, PrivateKey> _keyPair;
  final String address;
  List<String> servers = ["http://192.168.29.49:5002", "http://192.168.29.49:5001"];
  Map<String, int> nodesTtl = {};

  Wallet._internal(this._keyPair, this.address);

  factory Wallet() {
    final keyPair = _generateKeyPair();
    final publicKey = keyPair.publicKey as ECPublicKey;
    final address = _publicKeyToAddress(publicKey);
    return Wallet._internal(keyPair, address);
  }

  static AsymmetricKeyPair<PublicKey, PrivateKey> _generateKeyPair() {
    final ecCurve = ECCurve_secp256k1();
    final keyParams = ECKeyGeneratorParameters(ecCurve);
    final secureRandom = FortunaRandom();
    final keyGenerator = ECKeyGenerator();
    keyGenerator.init(ParametersWithRandom(keyParams, secureRandom));
    return keyGenerator.generateKeyPair();
  }

  static String _publicKeyToAddress(ECPublicKey publicKey) {
    final pubKeyBytes = publicKey.Q!.getEncoded(true);
    final sha256Hash = sha256.convert(pubKeyBytes);
    final ripemd160Hash = RIPEMD160Digest().process(sha256Hash.bytes as Uint8List);
    return base64Encode(ripemd160Hash);
  }

  String getAddress() => address;

  String signTransaction(Map<String, dynamic> transaction) {
    final message = json.encode(transaction);
    final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64));
    final privParams = PrivateKeyParameter((_keyPair.privateKey as ECPrivateKey));
    signer.init(true, privParams);
    final signature = signer.generateSignature(utf8.encode(message));
    return signature.toString();
  }

  Map<String, dynamic> prepareTransactionForSending(String recipient, double amount) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final transaction = {
      "sender": (_keyPair.publicKey as ECPublicKey).Q!.getEncoded(true),
      "recipient": recipient,
      "amount": amount,
      "timestamp": timestamp,
    };
    final transactionString = json.encode(transaction);
    final transactionId = sha256.convert(utf8.encode(transactionString)).toString();
    transaction["transaction_id"] = transactionId;
    final signature = signTransaction(transaction);
    return {
      "transaction": transaction,
      "digital_signature": signature,
      "public_key": (_keyPair.publicKey as ECPublicKey).Q!.getEncoded(true),
    };
  }

  // Other methods (sendTransaction, getTransactions, getBalance, etc.) will be implemented in the WalletService
}