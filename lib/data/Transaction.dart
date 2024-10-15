class Transaction{
  final String sender;
  final String recipient;
  final double amount;
  final DateTime timestamp;
  final String transactionId;
  final bool isOutgoing;

  Transaction({required this.sender, required this.recipient, required this.amount, required this.timestamp, required this.transactionId , required this.isOutgoing});

  Map<String, dynamic> toJson() => {
    "sender": sender,
    "recipient": recipient,
    "amount": amount,
    "timestamp": timestamp,
    "transaction_id": transactionId
  
  };


}